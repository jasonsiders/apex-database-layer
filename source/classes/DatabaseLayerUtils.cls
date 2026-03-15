/**
 * @description Internal utility class providing framework-specific functionality in a pseudo-namespace pattern.
 */
public without sharing class DatabaseLayerUtils {
	// Note: These properties do not use traditional naming conventions to support a 'namespace-like' API
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
	 * @description Utility for working with SObject instances.
	 */
	@SuppressWarnings('PMD.PropertyNamingConventions')
	public DatabaseLayerUtils.SObjects SObjects { get; private set; }

	private Map<String, String> Parameters {
		get {
			this.Parameters = this.Parameters ?? this.loadParameters();
			return this.Parameters;
		}
		private set;
	}

	/**
	 * @description Constructor that initializes all utility sub-components
	 * @param factory The DatabaseLayer factory instance
	 */
	@SuppressWarnings('PMD.EmptyStatementBlock')
	public DatabaseLayerUtils(DatabaseLayer factory) {
		this.ChildRelationships = new DatabaseLayerUtils.ChildRelationships();
		this.Plugins = new DatabaseLayerUtils.Plugins();
		this.SObjects = new DatabaseLayerUtils.SObjects();
	}

	/**
	 * @description Retrieves the value of a named DatabaseLayerParameter__mdt record.
	 * @param developerName The DeveloperName of the parameter to retrieve
	 * @return The Value__c of the matching parameter, or null if not found
	 */
	public String getParameter(String developerName) {
		return this.Parameters?.get(developerName);
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
		this.Parameters = null;
	}

	// **** INNER **** //
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
		private static final String DML_PARAM = 'DmlPreAndPostProcessor';
		private static final String SOQL_PARAM = 'SoqlPreAndPostProcessor';

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
			this.Dml = (Dml.PreAndPostProcessor) this.initPlugin(DML_PARAM);
			this.Soql = (Soql.PreAndPostProcessor) this.initPlugin(SOQL_PARAM);
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
