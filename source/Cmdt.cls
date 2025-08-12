/**
 * @description Provides access to Custom Metadata Type records with caching and namespace support.
 *              Supports both DeveloperName and qualified namespace__DeveloperName lookups.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing virtual class Cmdt {
    private static final String DEVELOPER_NAME = 'DeveloperName';
    private static final String NAMESPACE_PREFIX = 'NamespacePrefix';
    
    protected DatabaseLayer factory;
    protected Map<String, Cmdt.Repository> repos;

    /**
     * @description Creates a new Cmdt instance with the specified DatabaseLayer factory.
     * @param factory The DatabaseLayer factory to use for SOQL operations
     */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    public Cmdt(DatabaseLayer factory) {
        this.factory = factory;
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
        return new Cmdt.Repository(this.factory, objectType);
    }

    // **** INNER **** //
    /**
     * @description Repository for accessing Custom Metadata Type records with caching support.
     *              Records are indexed by DeveloperName and optionally by qualified namespace__DeveloperName.
     */
    global inherited sharing virtual class Repository {
        protected Map<String, SObject> records;

        protected Repository(DatabaseLayer factory, SObjectType objectType) {
            this.records = new Map<String, SObject>{};
            List<SObject> recordList = this.queryAll(factory, objectType);
            this.mapRecords(recordList);
        }

        /**
         * @description Returns all cached Custom Metadata Type records indexed by their keys.
         * @return Map of DeveloperName/qualified name to SObject records
         */
        global Map<String, SObject> getAll() {
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
            return new Soql(factory);
        }

        protected void mapRecords(List<SObject> recordList) {
            for (SObject record : recordList) {
                // Map records by their DeveloperName
                String developerName = (String) record?.get(DEVELOPER_NAME);
                this.records?.put(developerName, record);
                // If namespaced, also map records by their NamespacePrefix + DeveloperName
                String namespace = (String) record?.get(NAMESPACE_PREFIX);
                if (namespace != null) {
                    String qualifiedApiName = String.join(new List<String>{ namespace, developerName}, '__');
                    this.records?.put(qualifiedApiName, record);
                }
            }
        }

        protected List<SObject> queryAll(DatabaseLayer factory, SObjectType objectType) {
            // CMDT SOQL queries don't count against SOQL query limits (!)
            // This is nececessary because the CMDT .getAll/.getInstance methods aren't dynamically accessible
            return this.initQuery(factory)?.setFrom(objectType)?.selectAll()?.toSoql()?.query();
        }
    }
}