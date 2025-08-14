/**
 * @description Provides access to Custom Metadata Type records with caching and namespace support.
 *              Supports both DeveloperName and qualified namespace__DeveloperName lookups.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing virtual class Cmdt {
	@TestVisible
	private static final String DEVELOPER_NAME = 'DeveloperName';
	private static final String NAMESPACE_PREFIX = 'NamespacePrefix';
	@SuppressWarnings('PMD.FieldNamingConventions')
	@TestVisible
	private static DatabaseLayer.SoqlProvider Soql;

	@TestVisible
	private Set<String> cacheObjectApiNames;
	protected Map<String, Cmdt.Repository> repos;

	/**
	 * @description Creates a new Cmdt instance with the specified DatabaseLayer factory.
	 * @param factory The DatabaseLayer factory to use for SOQL operations
	 */
	public Cmdt(DatabaseLayer factory) {
		Cmdt.Soql = Cmdt.Soql ?? new Cmdt.SoqlProvider(factory);
		this.repos = new Map<String, Cmdt.Repository>{};
	}

	/**
	 * @description Gets or creates a Repository for the specified Custom Metadata Type.
	 * @param objectType The SObjectType of the Custom Metadata Type
	 * @return A Repository instance for accessing records of the specified type
	 */
	global Cmdt.Repository ofType(SObjectType objectType) {
		String objectApiName = objectType?.toString();
		Cmdt.Repository repo = this.repos?.get(objectApiName) ?? this.initRepository(objectType);
		this.repos?.put(objectApiName, repo);
		return repo;
	}

	protected virtual Cmdt.Repository initRepository(SObjectType objectType) {
		// TODO: Add conditional, something like this: `if DatabaseLayer.mockCmdtByDefault == true, return new MockRepository();`
		if (this.includesLongTextFields(objectType) == true) {
			return new CacheBasedRepository(objectType);
		} else {
			return new QueryBasedRepository(objectType);
		}
	}

	private Boolean includesLongTextFields(SObjectType objectType) {
		// Returns true if the SObjectType includes long-text fields
		if (this.cacheObjectApiNames == null) {
			this.cacheObjectApiNames = new Set<String>{};
			for (EntityDefinition entity : [
				SELECT QualifiedApiName
				FROM EntityDefinition
				WHERE
					DurableId IN (
						SELECT EntityDefinitionId
						FROM FieldDefinition
						WHERE DataType LIKE 'Long Text%'
					)
					AND QualifiedApiName LIKE '%__mdt'
				WITH SYSTEM_MODE
			]) {
				String objectApiName = entity?.QualifiedApiName;
				this.cacheObjectApiNames?.add(objectApiName);
			}
		}
		String objectApiName = objectType?.toString();
		return this.cacheObjectApiNames?.contains(objectApiName);
	}

	@TestVisible
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
	 */
	global inherited sharing virtual class CacheBasedRepository extends Cmdt.QueryBasedRepository {
		// This Repository caches query results to avoid repeated SOQL queries
		// Use this for custom metadata types that include long-text area fields,
		// as queries for these objects **do** count towards SOQL governor limits:
		// https://help.salesforce.com/s/articleView?language=en_US&id=platform.custommetadatatypes_limits.htm&type=5
		// TODO: Consider using platform cache instead of an in-memory Map
		protected transient Map<String, SObject> records;

		protected CacheBasedRepository(SObjectType objectType) {
			super(objectType);
		}

		global override Map<String, SObject> getAll() {
			this.retrieve();
			return this.records;
		}

		protected virtual void retrieve() {
			if (this.records == null) {
				List<SObject> recordList = this.queryAll();
				this.records = Cmdt.mapByKey(recordList);
			}
		}
	}

	/**
	 * @description Repository implementation that issues a new SOQL query each time.
	 *              Use this for most Custom Metadata Types; unless the object contains a long-text area field,
	 *              SOQL queries will not count towards governor limits.
	 */
	global inherited sharing virtual class QueryBasedRepository implements Cmdt.Repository {
		// This repository issues a new SOQL query each time
		// Use this for most custom metadata types; unless the object contains a long-text area field,
		// SOQL queries will **not** count towards governor limits:
		// https://help.salesforce.com/s/articleView?language=en_US&id=platform.custommetadatatypes_limits.htm&type=5
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
			return Cmdt.mapByKey(records);
		}

		/**
		 * @description Retrieves a specific Custom Metadata Type record by its DeveloperName.
		 * @param qualifiedApiName The DeveloperName of the record to retrieve, including Namespace (if applicable)
		 * @return The SObject record, or null if not found
		 */
		global SObject getInstance(String qualifiedApiName) {
			return this.getAll()?.get(qualifiedApiName);
		}

		protected List<SObject> queryAll() {
			// CMDT SOQL queries don't count against SOQL query limits (!)
			// This is nececessary because the CMDT .getAll/.getInstance methods aren't dynamically accessible
			return Cmdt.Soql.newQuery(this.objectType)?.selectAll()?.toSoql()?.query();
		}
	}

	private class SoqlProvider extends DatabaseLayer.SoqlProvider {
		// Custom Metadata queries can/should be mocked independently of other SOQL queries
		// Normal CMDT operations should always use real Soql, even when MockSoql is used elsewhere
		private DatabaseLayer factory;

		private SoqlProvider(DatabaseLayer factory) {
			super(factory);
		}

		@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
		public virtual override DatabaseLayer.SoqlProvider useMocks(Boolean value) {
			// Always use a real Soql query, regardless of the provided value:
			this.useMocks = false;
			return this;
		}
	}
}
