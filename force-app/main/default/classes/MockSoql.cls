public virtual class MockSoql extends Soql {
    // Note: @IsTest classes cannot also be virtual.
    // Test-only usage is enforced via the constructors
    System.QueryException error; 
    List<SObject> mockResults;

    @TestVisible
    private MockSoql(SObjectType objectType) {
        super(objectType);
    }

    @TestVisible
    private MockSoql(String queryString) {
        super(queryString);
    }

    public virtual override Integer countQuery() {
        return this.query()?.size();
    }

    public virtual override Database.QueryLocator getQueryLocator() {
        // TODO!
        List<SObject> results = this.query();
        return null; 
    }

    public virtual override List<SObject> query() {
        try {
            if (this.error != null) {
                throw error;
            } else {
                return this.mockResults ?? new List<SObject>();
            }
        } catch (System.QueryException error) {
            this.handleQueryError(error);
            throw error; 
        }
    }

    public virtual Soql withError() {
        // Inject an Exception to be returned when the query runs
        this.error = new System.QueryException(); 
        return this; 
    }

    public virtual Soql withMockResults(List<SObject> records) {
        // Inject a list of mock records to return when the query runs
        this.mockResults = records;
        return this; 
    }
}