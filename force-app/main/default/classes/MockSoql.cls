public virtual class MockSoql extends Soql {
    // Note: @IsTest classes cannot also be virtual.
    // Test-only usage is enforced via the constructors
    Exception error; 
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

    public virtual Soql injectError(Exception error) {
        // Inject the provided exception, to be thrown when the query runs
        this.error = error;
        return this; 
    }

    public Soql injectError() {
        // Inject an System.QueryException, to be thrown when the query runs
        System.QueryException queryError = new System.QueryException();
        return this.injectError(queryError);
    }

    public virtual Soql injectResults(List<SObject> records) {
        // Inject a list of mock records to return when the query runs
        this.mockResults = records;
        return this; 
    }
}