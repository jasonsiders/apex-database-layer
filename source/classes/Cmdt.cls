/**
 * @description Provides access to Custom Metadata Type records with caching and namespace support.
 * Supports both DeveloperName and qualified namespace__DeveloperName lookups.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class Cmdt {
	@TestVisible
	private static final String DEVELOPER_NAME = 'DeveloperName';
	private static final String LONG_TEXT_CACHE_KEY = 'CmdtsWithLongTextFields';
	private static final String NAMESPACE_PREFIX = 'NamespacePrefix';
	@TestVisible
	private static Set<String> cachedObjectNames;
	@TestVisible
	private static Map<String, Cmdt.Repository> repos;
	@TestVisible
	private static DatabaseLayer.SoqlProvider soqlProvider;

	static {
		List<EntityDefinition> cachedEntities = Cmdt.getCachedObjects();
		Cmdt.cachedObjectNames = Cmdt.extractEntityNames(cachedEntities);
		Cmdt.repos = new Map<String, Cmdt.Repository>{};
	}

	/**
	 * @description Creates a new Cmdt instance with the specified DatabaseLayer factory.
	 * @param factory The DatabaseLayer factory to use for SOQL operations
	 */
	public Cmdt(DatabaseLayer factory) {
		Cmdt.soqlProvider = Cmdt.soqlProvider ?? new Cmdt.SoqlProvider(factory);
	}

	/**
	 * @description Gets or creates a Repository for the specified Custom Metadata Type.
	 * @param objectType The SObjectType of the Custom Metadata Type
	 * @return A Repository instance for accessing records of the specified type
	 */
	global Cmdt.Repository ofType(SObjectType objectType) {
		String objectApiName = objectType?.toString();
		Cmdt.Repository repo = Cmdt.repos?.get(objectApiName) ?? this.initRepository(objectType);
		Cmdt.repos?.put(objectApiName, repo);
		return repo;
	}

	private Cmdt.Repository initRepository(SObjectType objectType) {
		// Maximize tradeoffs between heap size storage & query limits
		if (this.includesLongTextFields(objectType) == true) {
			// CMDT objects w/Long Text fields count towards query limits; query once and then cache
			return new CacheBasedRepository(objectType);
		} else {
			// All other CMDT objects are "free" to query; avoid cacheing to minimize heap usage
			return new QueryBasedRepository(objectType);
		}
	}

	private Boolean includesLongTextFields(SObjectType objectType) {
		// Returns true if the SObjectType includes long-text fields
		String objectApiName = objectType?.toString();
		return Cmdt.cachedObjectNames?.contains(objectApiName) == true;
	}

	// **** STATIC **** //
	/**
	 * @description Map each custom metadata record by its QualifiedApiName (NamespacePrefix + DeveloperName)
	 * @param recordList A list of custom metadata SObject records
	 * @return A map of custom metadata SObject records by their QualifiedApiName
	 */
	public static Map<String, SObject> mapByQualifiedApiName(List<SObject> recordList) {
		Map<String, SObject> results = new Map<String, SObject>{};
		for (SObject record : recordList) {
			String namespace = (String) record?.get(NAMESPACE_PREFIX);
			String developerName = (String) record?.get(DEVELOPER_NAME);
			Set<String> components = new Set<String>{ namespace, developerName };
			components?.remove(null);
			String key = String.join(components, '__');
			results?.put(key, record);
		}
		return results;
	}

	@TestVisible
	private static Set<String> extractEntityNames(List<EntityDefinition> entities) {
		Set<String> results = new Set<String>{};
		for (EntityDefinition entity : entities) {
			String objectApiName = entity?.QualifiedApiName;
			results?.add(objectApiName);
		}
		return results;
	}

	private static List<EntityDefinition> getCachedObjects() {
		if (DatabaseLayer.Utils.Cache.contains(LONG_TEXT_CACHE_KEY)) {
			return (List<EntityDefinition>) DatabaseLayer.Utils.Cache.get(LONG_TEXT_CACHE_KEY);
		} else {
			List<EntityDefinition> entities = Cmdt.queryEntityDefinitions();
			DatabaseLayer.Utils.Cache.put(LONG_TEXT_CACHE_KEY, entities);
			// Recurse and get the results of the newly cached objects:
			return Cmdt.getCachedObjects();
		}
	}

	private static List<EntityDefinition> queryEntityDefinitions() {
		// This static query must **always** execute using real SOQL
		return [
			SELECT QualifiedApiName
			FROM EntityDefinition
			WHERE
				QualifiedApiName LIKE '%__mdt'
				AND DurableId IN (SELECT EntityDefinitionId FROM FieldDefinition WHERE DataType LIKE 'Long Text%')
			WITH SYSTEM_MODE
		];
	}

	// **** INNER **** //
	/**
	 * @description Repository implementation that caches query results to avoid repeated SOQL queries.
	 * Use this for Custom Metadata Types that include long-text area fields, as queries for
	 * these objects count towards SOQL governor limits.
	 * https://help.salesforce.com/s/articleView?language=en_US&id=platform.custommetadatatypes_limits.htm&type=5
	 */
	global inherited sharing virtual class CacheBasedRepository extends Cmdt.QueryBasedRepository {
		protected transient Map<String, SObject> records;

		protected CacheBasedRepository(SObjectType objectType) {
			super(objectType);
		}

		global override Map<String, SObject> getAll() {
			this.retrieve();
			return this.records;
		}

		global override SObject getInstance(String qualifiedApiName) {
			return this.getAll()?.get(qualifiedApiName);
		}

		private void retrieve() {
			if (this.records == null) {
				List<SObject> recordList = this.queryAll();
				this.records = Cmdt.mapByQualifiedApiName(recordList);
			}
		}
	}

	/**
	 * @description Repository implementation that issues a new SOQL query each time.
	 * Use this for most Custom Metadata Types; SOQL queries will not count towards governor limits,
	 * unless the object contains a long-text area field
	 * https://help.salesforce.com/s/articleView?language=en_US&id=platform.custommetadatatypes_limits.htm&type=5
	 */
	global inherited sharing virtual class QueryBasedRepository implements Cmdt.Repository {
		protected transient SObjectType objectType;

		protected QueryBasedRepository(SObjectType objectType) {
			this.objectType = objectType;
		}

		/**
		 * @description Retrieves all Custom Metadata Type records as a map keyed by DeveloperName.
		 * @return Map of DeveloperName to SObject record
		 */
		global virtual Map<String, SObject> getAll() {
			List<SObject> records = this.queryAll();
			return Cmdt.mapByQualifiedApiName(records);
		}

		/**
		 * @description Retrieves a specific Custom Metadata Type record by its DeveloperName.
		 * @param qualifiedApiName The DeveloperName of the record to retrieve, including Namespace (if applicable)
		 * @return The SObject record, or null if not found
		 */
		global virtual SObject getInstance(String qualifiedApiName) {
			return this.initQuery()?.addWhere(DEVELOPER_NAME, Soql.EQUALS, qualifiedApiName)?.toSoql()?.queryFirst();
		}

		private Soql initQuery() {
			// Note: CMDT SOQL queries don't count against SOQL query limits (!)
			return Cmdt.soqlProvider.newQuery(this.objectType)?.selectAll()?.toSoql();
		}

		private List<SObject> queryAll() {
			return this.initQuery()?.query();
		}
	}

	/**
	 * @description Interface for accessing Custom Metadata Type records.
	 * Provides methods for retrieving all records or specific instances by developer name.
	 */
	global interface Repository {
		/**
		 * @description Retrieves all Custom Metadata Type records as a map keyed by DeveloperName.
		 * @return Map of DeveloperName to SObject record
		 */
		Map<String, SObject> getAll();
		/**
		 * @description Retrieves a specific Custom Metadata Type record by its DeveloperName.
		 * @param qualifiedApiName The DeveloperName of the record to retrieve, including Namespace (if applicable)
		 * @return The SObject record, or null if not found
		 */
		SObject getInstance(String qualifiedApiName);
	}

	/**
	 * @description Custom SoqlProvider that will always return a real (not mock) Soql object
	 * 				This enables CMDT operations to use real Soql, even when MockSoql is used elsewhere
	 */
	private class SoqlProvider extends DatabaseLayer.SoqlProvider {
		private DatabaseLayer factory;

		private SoqlProvider(DatabaseLayer factory) {
			super(factory);
			this.useMocks = false;
		}
	}
}
