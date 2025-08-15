/**
 * @description Provides access to Custom Metadata Type records with caching and namespace support.
 *              Supports both DeveloperName and qualified namespace__DeveloperName lookups.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier,PMD.CognitiveComplexity')
global inherited sharing class Cmdt {
	@TestVisible
	private static final String DEVELOPER_NAME = 'DeveloperName';
	private static final String NAMESPACE_PREFIX = 'NamespacePrefix';
	@TestVisible
	private static Set<String> objectsToCache;
	@TestVisible
	private static DatabaseLayer.SoqlProvider soqlProvider;
	private static Map<String, Cmdt.Repository> repos;

	static {
		Cmdt.repos = new Map<String, Cmdt.Repository>{};
		Cmdt.objectsToCache = Cmdt.getObjectsToCache();
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
		if (this.includesLongTextFields(objectType) == true) {
			return new CacheBasedRepository(objectType);
		} else {
			return new QueryBasedRepository(objectType);
		}
	}

	private Boolean includesLongTextFields(SObjectType objectType) {
		// Returns true if the SObjectType includes long-text fields
		String objectApiName = objectType?.toString();
		return Cmdt.objectsToCache?.contains(objectApiName) == true;
	}

	// **** STATIC **** //
	/**
	 * @description Creates and configures a MockRepository for the specified Custom Metadata Type.
	 *              This allows mocking CMDT records in tests without database operations.
	 * @param objectType The SObjectType of the Custom Metadata Type to mock
	 * @return A MockRepository instance that can be configured with test data
	 */
	@TestVisible
	private static Cmdt.MockRepository mock(SObjectType objectType) {
		String objectApiName = objectType?.toString();
		Cmdt.MockRepository repo = new Cmdt.MockRepository();
		Cmdt.repos?.put(objectApiName, repo);
		return repo;
	}

	private static Set<String> getObjectsToCache() {
		Set<String> results = new Set<String>{};
		for (EntityDefinition entity : Cmdt.queryEntityDefinitions()) {
			String objectApiName = entity?.QualifiedApiName;
			results?.add(objectApiName);
		}
		return results;
	}

	private static Map<String, SObject> mapByKey(List<SObject> recordList) {
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

	private static List<EntityDefinition> queryEntityDefinitions() {
		// This query must **always** execute using real SOQL
		// TODO: Use platform cache to store the query results
		return [
			SELECT QualifiedApiName
			FROM EntityDefinition
			WHERE
				QualifiedApiName LIKE '%__mdt'
				AND DurableId IN (SELECT EntityDefinitionId FROM FieldDefinition WHERE DataType LIKE 'Long Text%')
			WITH SYSTEM_MODE
		];
	}

	// **** INTERFACE **** //
	/**
	 * @description Interface for accessing Custom Metadata Type records.
	 *              Provides methods for retrieving all records or specific instances by developer name.
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

	// **** INNER **** //
	/**
	 * @description Repository implementation that caches query results to avoid repeated SOQL queries.
	 *              Use this for Custom Metadata Types that include long-text area fields, as queries for
	 *              these objects count towards SOQL governor limits.
	 * 				https://help.salesforce.com/s/articleView?language=en_US&id=platform.custommetadatatypes_limits.htm&type=5
	 */
	global inherited sharing class CacheBasedRepository extends Cmdt.QueryBasedRepository {
		// TODO: Consider using platform cache instead of an in-memory Map
		// TODO: If not, consider modifying MockRepository to extend this
		private transient Map<String, SObject> records;

		private CacheBasedRepository(SObjectType objectType) {
			super(objectType);
		}

		global override Map<String, SObject> getAll() {
			this.retrieve();
			return this.records;
		}

		global override SObject getInstance(String qualifiedApiName) {
			return this.getAll()?.get(qualifiedApiName);
		}

		private virtual void retrieve() {
			if (this.records == null) {
				List<SObject> recordList = this.queryAll();
				this.records = Cmdt.mapByKey(recordList);
			}
		}
	}

	/**
	 * @description Mock implementation of the Repository interface for testing purposes.
	 *              Allows in-memory storage and manipulation of Custom Metadata Type records without database operations.
	 */
	global class MockRepository implements Cmdt.Repository {
		private Map<String, SObject> records;

		private MockRepository() {
			this.records = new Map<String, SObject>{};
		}

		/**
		 * @description Adds multiple records from a map to the mock repository.
		 * @param recordMap Map of record keys to SObject records
		 * @return This repository instance for method chaining
		 */
		global Cmdt.MockRepository add(Map<String, SObject> recordMap) {
			this.records?.putAll(recordMap);
			return this;
		}

		/**
		 * @description Adds multiple records from a list to the mock repository.
		 * @param recordList List of SObject records to add
		 * @return This repository instance for method chaining
		 */
		global Cmdt.MockRepository add(List<SObject> recordList) {
			Map<String, SObject> records = Cmdt.mapByKey(recordList);
			return this.add(records);
		}

		/**
		 * @description Adds a single record to the mock repository.
		 * @param record The SObject record to add
		 * @return This repository instance for method chaining
		 */
		global Cmdt.MockRepository add(SObject record) {
			return this.add(new List<SObject>{ record });
		}

		/**
		 * @description Removes all records from the mock repository.
		 * @return This repository instance for method chaining
		 */
		global Cmdt.MockRepository clear() {
			this.records?.clear();
			return this;
		}

		/**
		 * @description Retrieves all records from the mock repository.
		 * @return Map of all records indexed by their qualified API names
		 */
		global Map<String, SObject> getAll() {
			return this.records;
		}

		/**
		 * @description Retrieves a specific record by its qualified API name.
		 * @param qualifiedApiName The qualified API name of the record to retrieve
		 * @return The SObject record if found, null otherwise
		 */
		global SObject getInstance(String qualifiedApiName) {
			return this.getAll()?.get(qualifiedApiName);
		}

		/**
		 * @description Removes records with the specified keys from the mock repository.
		 * @param keys Set of record keys to remove
		 * @return This repository instance for method chaining
		 */
		global Cmdt.MockRepository remove(Set<String> keys) {
			this.records?.keySet()?.removeAll(keys);
			return this;
		}

		/**
		 * @description Removes records specified in the map from the mock repository.
		 * @param recordMap Map containing records to remove
		 * @return This repository instance for method chaining
		 */
		global Cmdt.MockRepository remove(Map<String, SObject> recordMap) {
			Set<String> keys = recordMap?.keySet();
			return this.remove(keys);
		}

		/**
		 * @description Removes records specified in the list from the mock repository.
		 * @param recordList List of records to remove
		 * @return This repository instance for method chaining
		 */
		global Cmdt.MockRepository remove(List<SObject> recordList) {
			Map<String, SObject> recordMap = Cmdt.mapByKey(recordList);
			return this.remove(recordMap);
		}

		/**
		 * @description Removes a single record from the mock repository.
		 * @param record The SObject record to remove
		 * @return This repository instance for method chaining
		 */
		global Cmdt.MockRepository remove(SObject record) {
			return this.remove(new List<SObject>{ record });
		}

		/**
		 * @description Removes a record with the specified key from the mock repository.
		 * @param key The record key to remove
		 * @return This repository instance for method chaining
		 */
		global Cmdt.MockRepository remove(String key) {
			return this.remove(new Set<String>{ key });
		}
	}

	/**
	 * @description Repository implementation that issues a new SOQL query each time.
	 *              Use this for most Custom Metadata Types; unless the object contains a long-text area field,
	 *              SOQL queries will not count towards governor limits.
	 * 				https://help.salesforce.com/s/articleView?language=en_US&id=platform.custommetadatatypes_limits.htm&type=5
	 */
	global inherited sharing virtual class QueryBasedRepository implements Cmdt.Repository {
		private transient SObjectType objectType;

		private QueryBasedRepository(SObjectType objectType) {
			this.objectType = objectType;
		}

		/**
		 * @description Retrieves all Custom Metadata Type records as a map keyed by DeveloperName.
		 * @return Map of DeveloperName to SObject record
		 */
		global virtual Map<String, SObject> getAll() {
			List<SObject> records = this.queryAll();
			return Cmdt.mapByKey(records);
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
