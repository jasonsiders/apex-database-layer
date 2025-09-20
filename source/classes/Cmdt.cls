/**
 * @description Provides access to Custom Metadata Type records with caching and namespace support.
 * Supports both DeveloperName and qualified namespace__DeveloperName lookups.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class Cmdt {
	@TestVisible
	private static final String DEVELOPER_NAME = 'DeveloperName';
	private static final String NAMESPACE_PREFIX = 'NamespacePrefix';
	@TestVisible
	private static Map<String, Cmdt.Repository> repos = new Map<String, Cmdt.Repository>{};
	@TestVisible
	private static DatabaseLayer.SoqlProvider soqlProvider;

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
		Cmdt.Repository repo = Cmdt.repos?.get(objectApiName) ?? new Cmdt.Repository(objectType);
		return repo;
	}

	// **** INNER **** //
	/**
	 * @description Virtual class used to accessing Custom Metadata Type records.
	 * Provides methods for retrieving all records or specific instances by developer name.
	 */
	global virtual class Repository {
		protected Map<String, SObject> records;
		protected transient SObjectType objectType;

		/**
		 * @description Constructor for Repository class
		 * @param objectType The SObjectType of the Custom Metadata Type
		 */
		protected Repository(SObjectType objectType) {
			this.objectType = objectType;
			this.register();
		}

		/**
		 * @description Retrieves all Custom Metadata Type records as a map keyed by DeveloperName.
		 * @return Map of DeveloperName to SObject record
		 */
		global virtual Map<String, SObject> getAll() {
			if (this.records == null) {
				List<SObject> results = this.queryAll();
				return this.mapByQualifiedApiName(results);
			} else {
				return this.records;
			}
		}

		/**
		 * @description Retrieves a specific Custom Metadata Type record by its DeveloperName.
		 * @param qualifiedApiName The DeveloperName of the record to retrieve, including Namespace (if applicable)
		 * @return The SObject record, or null if not found
		 */
		global virtual SObject getInstance(String qualifiedApiName) {
			return this.getAll()?.get(qualifiedApiName);
		}

		/**
		 * @description Inject a custom repository object to handle CMDT retrieval instead of the current instance
		 * @param repository the repository object to use to retrieve objects of the current type going forward
		 * @return the same repository object passed as an input
		 */
		global Cmdt.Repository withRepository(Cmdt.Repository repository) {
			repository?.register();
			return repository;
		}

		/**
		 * @description Builds the base SOQL query for the Custom Metadata Type
		 * @return A Soql query builder instance
		 */
		protected virtual Soql buildQuery() {
			Soql query = Cmdt.SoqlProvider.newQuery(this.objectType)?.toSoql();
			this.selectAllFieldsExceptLongText(query);
			return query;
		}

		/**
		 * @description Map each custom metadata record by its QualifiedApiName (NamespacePrefix + DeveloperName)
		 * @param recordList A list of custom metadata SObject records
		 * @return A map of custom metadata SObject records by their QualifiedApiName
		 */
		protected Map<String, SObject> mapByQualifiedApiName(List<SObject> records) {
			Map<String, SObject> results = new Map<String, SObject>{};
			for (SObject record : records) {
				String namespace = (String) record?.get(NAMESPACE_PREFIX);
				String developerName = (String) record?.get(DEVELOPER_NAME);
				Set<String> components = new Set<String>{ namespace, developerName };
				components?.remove(null);
				String key = String.join(components, '__');
				results?.put(key, record);
			}
			return results;
		}

		/**
		 * @description Executes the query to retrieve all Custom Metadata Type records
		 * @return List of SObject records
		 */
		protected virtual List<SObject> queryAll() {
			return this.buildQuery()?.query();
		}

		/**
		 * @description Registers this repository instance for the associated SObjectType
		 */
		protected void register() {
			String objectApiName = this.objectType?.toString();
			Cmdt.repos?.put(objectApiName, this);
		}

		/**
		 * @description Adds all fields except long text area fields to the query
		 * @param query The Soql query builder to modify
		 */
		protected void selectAllFieldsExceptLongText(Soql.Builder query) {
			List<SObjectField> allFields = this.objectType?.getDescribe()?.fields?.getMap()?.values();
			for (SObjectField field : allFields) {
				DescribeFieldResult describe = field?.getDescribe();
				Integer len = describe?.getLength() ?? 0;
				if (len < 255) {
					query?.addSelect(field);
				}
			}
		}
	}

	/**
	 * @description Custom SoqlProvider that will always return a real (not mock) Soql object
	 * This enables CMDT operations to use real Soql, even when MockSoql is used elsewhere
	 */
	private class SoqlProvider extends DatabaseLayer.SoqlProvider {
		private DatabaseLayer factory;

		/**
		 * @description Constructor for SoqlProvider that ensures real SOQL operations
		 * @param factory The DatabaseLayer factory to use for SOQL operations
		 */
		private SoqlProvider(DatabaseLayer factory) {
			super(factory);
			this.useMocks = false;
		}
	}
}
