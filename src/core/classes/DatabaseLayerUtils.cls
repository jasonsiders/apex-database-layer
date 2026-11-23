/**
 * @description Internal utility class providing framework-specific functionality in a pseudo-namespace pattern.
 */
public without sharing class DatabaseLayerUtils {
	/** @description Flows pass access levels as text, so each valid value maps to its System.AccessLevel **/
	private static final Map<String, System.AccessLevel> ACCESS_LEVELS = new Map<String, System.AccessLevel>{
		'SYSTEM_MODE' => System.AccessLevel.SYSTEM_MODE,
		'USER_MODE' => System.AccessLevel.USER_MODE
	};
	// Matches the SOQL date literal grammar: the fixed keywords, plus the parameterized <LITERAL>:<n> forms.
	// See https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql_select_dateformats.htm
	private static final Pattern DATE_LITERAL_PATTERN = Pattern.compile(
		'(?i)^(YESTERDAY|TODAY|TOMORROW|(LAST|THIS|NEXT)_(WEEK|MONTH|QUARTER|YEAR|FISCAL_QUARTER|FISCAL_YEAR)|' +
			'(LAST|NEXT)_90_DAYS|(LAST_N|NEXT_N)_(DAYS|WEEKS|MONTHS|QUARTERS|YEARS|FISCAL_QUARTERS|FISCAL_YEARS):\\d+|' +
			'N_(DAYS|WEEKS|MONTHS|QUARTERS|YEARS|FISCAL_QUARTERS|FISCAL_YEARS)_AGO:\\d+)$'
	);
	/** @description The object SOQL resolves a name-pointing lookup to, ex: Case.Owner **/
	private static final String POLYMORPHIC_ENTITY = 'Name';
	/** @description Objects SOQL resolves their name-pointing lookups to, ex: ObjectPermissions.Parent **/
	private static final Set<String> SELF_RESOLVING_ENTITIES = new Set<String>{ 'LegalEntity', 'PermissionSet' };
	// Note: These properties do not use traditional naming conventions to support a 'namespace-like' API
	/**
	 * @description Utility for converting System.AccessLevel to and from its name.
	 */
	@SuppressWarnings('PMD.PropertyNamingConventions')
	public final DatabaseLayerUtils.AccessLevels AccessLevels { get; private set; }
	/**
	 * @description Utility for managing Schema.ChildRelationship objects.
	 */
	@SuppressWarnings('PMD.PropertyNamingConventions')
	public final DatabaseLayerUtils.ChildRelationships ChildRelationships { get; private set; }
	/**
	 * @description Utility for managing plugin implementations.
	 * Note: Plugins are loaded dynamically based on custom metadata configuration.
	 */
	@SuppressWarnings('PMD.PropertyNamingConventions')
	public final DatabaseLayerUtils.Plugins Plugins { get; private set; }
	/**
	 * @description Utility for describing objects and fields the way SOQL reads them.
	 */
	@SuppressWarnings('PMD.PropertyNamingConventions')
	public final DatabaseLayerUtils.Schema Schema { get; private set; }

	/**
	 * @description Utility for working with SObject instances.
	 */
	@SuppressWarnings('PMD.PropertyNamingConventions')
	public DatabaseLayerUtils.SObjects SObjects { get; private set; }

	private Map<String, String> parameters {
		get {
			this.parameters = this.parameters ?? this.loadParameters();
			return this.parameters;
		}
		private set;
	}

	/**
	 * @description Constructor that initializes all utility sub-components
	 * @param factory The DatabaseLayer factory instance
	 */
	@SuppressWarnings('PMD.EmptyStatementBlock')
	public DatabaseLayerUtils(DatabaseLayer factory) {
		this.AccessLevels = new DatabaseLayerUtils.AccessLevels();
		this.ChildRelationships = new DatabaseLayerUtils.ChildRelationships();
		this.Plugins = new DatabaseLayerUtils.Plugins();
		this.Schema = new DatabaseLayerUtils.Schema();
		this.SObjects = new DatabaseLayerUtils.SObjects();
	}

	/**
	 * @description Retrieves the value of a named DatabaseLayerParameter__mdt record.
	 * @param developerName The DeveloperName of the parameter to retrieve
	 * @return The Value__c of the matching parameter, or null if not found
	 */
	public String getParameter(String developerName) {
		return this.parameters?.get(developerName);
	}

	/**
	 * @description Date literals are rendered as-is, since SOQL can't bind them, so only SOQL's own literals pass
	 * @param value The text to check, ex: LAST_N_DAYS:7
	 * @return True when the value is a SOQL date literal
	 */
	public Boolean isDateLiteral(String value) {
		return value != null && DatabaseLayerUtils.DATE_LITERAL_PATTERN?.matcher(value)?.matches() == true;
	}

	private Map<String, String> loadParameters() {
		Map<String, String> result = new Map<String, String>();
		Map<String, SObject> allParameters = DatabaseLayer.Cmdt
			?.ofType(DatabaseLayerParameter__mdt.SObjectType)
			?.getAll();
		if (allParameters != null) {
			for (SObject record : allParameters.values()) {
				DatabaseLayerParameter__mdt param = (DatabaseLayerParameter__mdt) record;
				result.put(param.DeveloperName, param.Value__c);
			}
		}
		return result;
	}

	@TestVisible
	private void resetParameters() {
		this.parameters = null;
	}

	// **** INNER **** //
	/**
	 * @description Utility for converting System.AccessLevel, which has no name() and doesn't serialize, to and from
	 * its name, ex: for flow inputs and JSON output
	 */
	public class AccessLevels {
		@SuppressWarnings('PMD.EmptyStatementBlock')
		private AccessLevels() {
			// Don't allow construction outside of this file
		}

		/**
		 * @description Names an access level, the reverse of {@link parse}
		 * @param level The access level
		 * @return SYSTEM_MODE, or USER_MODE for anything else, including null
		 */
		public String getName(System.AccessLevel level) {
			return (level == System.AccessLevel.SYSTEM_MODE) ? 'SYSTEM_MODE' : 'USER_MODE';
		}

		/**
		 * @description Blank runs in the safer USER_MODE; anything else must name an access level exactly, so a typo fails
		 * instead of running in a mode the caller didn't ask for
		 * @param name The access level's name, ex: from a flow input
		 * @return The matching System.AccessLevel
		 * @throws System.IllegalArgumentException When the value isn't blank, USER_MODE, or SYSTEM_MODE
		 */
		public System.AccessLevel parse(String name) {
			String levelName = String.isBlank(name) ? 'USER_MODE' : name;
			System.AccessLevel level = DatabaseLayerUtils.ACCESS_LEVELS?.get(levelName);
			if (level == null) {
				throw new IllegalArgumentException('Invalid access level: ' + levelName);
			}
			return level;
		}
	}

	/**
	 * @description Utility for retrieving and caching Schema.ChildRelationship objects from SObjectFields.
	 * Provides efficient access to relationship metadata with built-in caching for performance.
	 */
	public class ChildRelationships {
		private Map<SObjectType, DatabaseLayerUtils.CachedDescribe> describes;

		/**
		 * @description Constructor for ChildRelationships class
		 */
		private ChildRelationships() {
			this.describes = new Map<SObjectType, DatabaseLayerUtils.CachedDescribe>();
		}

		/**
		 * @description Retrieves the child relationship for a lookup field on a specific parent object type.
		 * @param lookupField The lookup field to find the relationship for
		 * @param referenceTo The parent SObject type
		 * @return The corresponding Schema.ChildRelationship
		 */
		public Schema.ChildRelationship getChildRelationshipFrom(SObjectField lookupField, SObjectType referenceTo) {
			return this.getDescribeFromCache(referenceTo)?.get(lookupField);
		}

		/**
		 * @description Retrieves the child relationship for a non-polymorphic lookup field.
		 * @param lookupField The lookup field to find the relationship for
		 * @return The corresponding Schema.ChildRelationship
		 */
		public Schema.ChildRelationship getChildRelationshipFrom(SObjectField lookupField) {
			List<SObjectType> references = lookupField?.getDescribe()?.getReferenceTo();
			// Note: the Schema.getReferenceTo() method returns a List<SObjectType>, not a single SObjectType.
			// Typically, a field is only be related to a single SObjectType; excluding polymorphic fields (ie, Task.WhatId).
			SObjectType referenceTo = references?.isEmpty() == false ? references?.get(0) : null;
			return this.getChildRelationshipFrom(lookupField, referenceTo);
		}

		private DatabaseLayerUtils.CachedDescribe getDescribeFromCache(SObjectType objectType) {
			// Retrieves a CachedDescribe object, which represents a cached Schema.ChildRelationships for the SObjectType
			DatabaseLayerUtils.CachedDescribe describe = this.describes?.containsKey(objectType)
				? this.describes?.get(objectType)
				: new DatabaseLayerUtils.CachedDescribe(objectType);
			this.describes?.put(objectType, describe);
			return describe;
		}
	}

	/**
	 * @description Utility for managing and initializing plugin implementations.
	 */
	@SuppressWarnings('PMD.AvoidDebugStatements')
	public class Plugins {
		/**
		 * @description The DML pre and post processor instance for this plugin configuration.
		 */
		@SuppressWarnings('PMD.PropertyNamingConventions')
		public Dml.PreAndPostProcessor Dml { get; private set; }
		/**
		 * @description The SOQL pre and post processor instance for this plugin configuration.
		 */
		@SuppressWarnings('PMD.PropertyNamingConventions')
		public Soql.PreAndPostProcessor Soql { get; private set; }

		/**
		 * @description Default constructor that initializes plugin instances.
		 */
		private Plugins() {
			this.init();
		}

		/**
		 * @description Initializes a plugin instance based on a named DatabaseLayerParameter__mdt record.
		 * @param parameterName The DeveloperName of the parameter containing the plugin class name
		 * @return The instantiated plugin object, or null if initialization fails
		 */
		public Object initPlugin(String parameterName) {
			String className;
			try {
				className = DatabaseLayer.Utils?.getParameter(parameterName);
				return (className != null) ? Type.forName(className)?.newInstance() : null;
			} catch (Exception error) {
				String source = DatabaseLayerUtils.Plugins.class.getName();
				String msg = source + ': Invalid "' + parameterName + '": "' + className + '". Details: ' + error;
				System.debug(System.LoggingLevel.WARN, msg);
				return null;
			}
		}

		/**
		 * @description Initialize the Dml/Soql plugins based on current DatabaseLayerParameter__mdt values
		 */
		/* prettier-ignore */
		@TestVisible
		private void init() {
			DatabaseLayer.Utils?.resetParameters();
			this.Dml = (Dml.PreAndPostProcessor) this.initPlugin('DmlPreAndPostProcessor');
			this.Soql = (Soql.PreAndPostProcessor) this.initPlugin('SoqlPreAndPostProcessor');
		}
	}

	/**
	 * @description Utility for describing objects and fields the way SOQL reads them.
	 */
	public class Schema {
		@SuppressWarnings('PMD.EmptyStatementBlock')
		private Schema() {
			// Don't allow construction outside of this file
		}

		/**
		 * @description Lightning only shows an AuraHandledException's message, so editors that call this show the reason
		 * @param objectApiName The object to describe
		 * @return The object's fields
		 * @throws System.AuraHandledException When the object doesn't exist
		 */
		public List<SObjectField> describeFields(String objectApiName) {
			try {
				DescribeSObjectResult objectDescribe = this.describeObject(objectApiName);
				return objectDescribe?.fields?.getMap()?.values();
			} catch (System.InvalidParameterValueException error) {
				String message = error?.getMessage();
				throw new System.AuraHandledException(message);
			}
		}

		/**
		 * @description Describes an object, DEFERRED so its fields are only described once read
		 * @param objectApiName The object's API name
		 * @return The object's describe
		 * @throws System.InvalidParameterValueException When the object doesn't exist
		 */
		public DescribeSObjectResult describeObject(String objectApiName) {
			List<String> objectApiNames = new List<String>{ objectApiName };
			// This class's name hides the Schema namespace's methods
			List<DescribeSObjectResult> objects = System.Schema.describeSObjects(
				objectApiNames,
				SObjectDescribeOptions.DEFERRED
			);
			return objects?.get(0);
		}

		/**
		 * @description Finds an object's lookup by its relationship name, ex: Contact.AccountId for "Account"
		 * @param objectDescribe The object holding the lookup
		 * @param relationshipName The relationship name, in any case
		 * @return The lookup, or null when the object has no relationship by that name
		 */
		public SObjectField findLookup(DescribeSObjectResult objectDescribe, String relationshipName) {
			List<SObjectField> fields = objectDescribe?.fields?.getMap()?.values() ?? new List<SObjectField>{};
			SObjectField lookup;
			for (SObjectField field : fields) {
				String candidate = field?.getDescribe()?.getRelationshipName();
				lookup = (relationshipName?.equalsIgnoreCase(candidate) == true) ? field : lookup;
			}
			return lookup;
		}

		/**
		 * @description Names the object SOQL resolves a lookup's relationship to. A name-pointing lookup, ex: Case.OwnerId
		 * or AccountHistory.CreatedById, resolves to the Name object, the only one whose fields SOQL allows on it without
		 * TYPEOF, unless it points only to an object in SELF_RESOLVING_ENTITIES. Other lookups resolve to their first
		 * object, even with several, ex: Document.FolderId to Folder
		 * @param lookup The lookup's describe
		 * @return The object's name, or null for a field that isn't a lookup
		 */
		public String toEntityName(DescribeFieldResult lookup) {
			List<SObjectType> parentTypes = lookup?.getReferenceTo();
			String firstParent = parentTypes?.isEmpty() == false ? parentTypes?.get(0)?.toString() : null;
			// Apex's describe can't tell these apart; probing every target type in an org found only these
			Boolean isSelfResolving =
				parentTypes?.size() == 1 && DatabaseLayerUtils.SELF_RESOLVING_ENTITIES?.contains(firstParent);
			Boolean isPolymorphic = lookup?.isNamePointing() == true && isSelfResolving == false;
			return isPolymorphic ? DatabaseLayerUtils.POLYMORPHIC_ENTITY : firstParent;
		}
	}

	/**
	 * @description Utility for working with SObject instances and performing common transformations.
	 */
	public class SObjects {
		@SuppressWarnings('PMD.EmptyStatementBlock')
		private SObjects() {
			// Don't allow construction outside of this file
		}

		/**
		 * @description Converts a collection of record IDs into a list of SObject instances with those IDs.
		 * @param recordIds The collection of record IDs to convert
		 * @return List of SObject instances with the provided IDs
		 */
		public List<SObject> newSObjects(Iterable<Id> recordIds) {
			// Converts a List<Id> into a List<SObject> with those Ids:
			List<SObject> records = new List<SObject>();
			for (Id recordId : recordIds) {
				SObject record = recordId?.getSObjectType()?.newSObject(recordId);
				records?.add(record);
			}
			return records;
		}

		/**
		 * @description Converts a single record ID into an SObject instance with that ID.
		 * @param recordId The record ID to convert
		 * @return SObject instance with the provided ID
		 */
		public SObject newSObject(Id recordId) {
			return this.newSObjects(new List<Id>{ recordId })?.get(0);
		}
	}

	private class CachedDescribe {
		// Object used to map & cache Schema.ChildRelationships by their lookup field.
		// Useful since the operation to retrieve Schema.ChildRelationships from an object can be expensive,
		// and Salesforce's built in Schema caching mechanism doesn't seem to handle this.
		// Note: In the future, consider upgrading this to use actual System.Cache.
		private Map<SObjectField, Schema.ChildRelationship> relationshipMap;

		/**
		 * @description Constructor that initializes the cached relationships for the specified object type.
		 * @param objectType The SObject type to cache relationships for
		 */
		public CachedDescribe(SObjectType objectType) {
			this.mapRelationships(objectType);
		}

		/**
		 * @description Retrieves the cached child relationship for the specified field.
		 * @param field The SObjectField to get the relationship for
		 * @return The corresponding Schema.ChildRelationship or null if not found
		 */
		public Schema.ChildRelationship get(SObjectField field) {
			return this.relationshipMap?.get(field);
		}

		private List<Schema.ChildRelationship> getRelationshipList(SObjectType objectType) {
			return objectType?.getDescribe(Schema.SObjectDescribeOptions.DEFERRED)?.getChildRelationships() ??
				new List<Schema.ChildRelationship>();
		}

		private void mapRelationships(SObjectType objectType) {
			this.relationshipMap = new Map<SObjectField, Schema.ChildRelationship>();
			for (Schema.ChildRelationship relationship : this.getRelationshipList(objectType)) {
				SObjectField field = relationship?.getField();
				this.relationshipMap?.put(field, relationship);
			}
		}
	}
}
