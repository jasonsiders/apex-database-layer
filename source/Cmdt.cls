/**
 * @description Provides access to Custom Metadata Type records with caching and namespace support.
 *              Supports both DeveloperName and qualified namespace__DeveloperName lookups.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing virtual class Cmdt {
	private static final String DEVELOPER_NAME = 'DeveloperName';
	private static final String NAMESPACE_PREFIX = 'NamespacePrefix';
	@SuppressWarnings('PMD.FieldNamingConventions')
	private static DatabaseLayer Factory;

	protected Map<String, Cmdt.Repository> repos;

	/**
	 * @description Creates a new Cmdt instance with the specified DatabaseLayer factory.
	 * @param factory The DatabaseLayer factory to use for SOQL operations
	 */
	@SuppressWarnings('PMD.EmptyStatementBlock')
	public Cmdt(DatabaseLayer factory) {
		Cmdt.Factory = factory;
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
		return new Cmdt.Repository(objectType);
	}

	// **** INNER **** //
	/**
	 * @description Repository for accessing Custom Metadata Type records with caching support.
	 *              Records are indexed by DeveloperName and optionally by qualified namespace__DeveloperName.
	 */
	global inherited sharing virtual class Repository {
		protected transient SObjectType objectType;
		protected transient Map<String, SObject> records;

		protected Repository(SObjectType objectType) {
			this.objectType = objectType;
		}

		/**
		 * @description Returns all cached Custom Metadata Type records indexed by their keys.
		 * @return Map of DeveloperName/qualified name to SObject records
		 */
		global Map<String, SObject> getAll() {
			this.retrieve();
			return this.records;
		}

		/**
		 * @description Retrieves a specific Custom Metadata Type record by its key.
		 * @param key The DeveloperName or qualified namespace__DeveloperName
		 * @return The matching SObject record, or null if not found
		 */
		global SObject getInstance(String key) {
			return this.getAll()?.get(key);
		}

		protected virtual Soql initQuery(DatabaseLayer factory) {
			// CMDT queries are made independently of the configured DatabaseLayer.Soql instance
			// Callers can define mock SOQL queries, while still using real SOQL to retrieve CMDT if desired
			return new Soql(factory);
		}

		protected Map<String, SObject> mapRecords(List<SObject> recordList) {
			Map<String, SObject> results = new Map<String, SObject>{};
			for (SObject record : recordList) {
				// Map records by their DeveloperName
				String developerName = (String) record?.get(DEVELOPER_NAME);
				results?.put(developerName, record);
				// Also map records by their NamespacePrefix + DeveloperName
				String namespace = (String) record?.get(NAMESPACE_PREFIX);
				String qualifiedApiName = String.join(new List<String>{ namespace, developerName }, '__');
				results?.put(qualifiedApiName, record);
			}
			return results;
		}

		protected List<SObject> queryAll() {
			// CMDT SOQL queries don't count against SOQL query limits (!)
			// This is nececessary because the CMDT .getAll/.getInstance methods aren't dynamically accessible
			return this.initQuery(Cmdt.Factory)?.setFrom(this.objectType)?.selectAll()?.toSoql()?.query();
		}

		protected void retrieve() {
			if (this.records == null) {
				List<SObject> recordList = this.queryAll();
				this.records = this.mapRecords(recordList);
			}
		}
	}
}
