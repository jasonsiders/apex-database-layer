@IsTest
public class MockSoql extends Soql {
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

    public Soql injectError(Exception error) {
        // Inject the provided exception, to be thrown when the query runs
        this.error = error;
        return this; 
    }
    
    public Soql injectError() {
        // Overload which always injects a System.QueryException
        System.QueryException queryError = new System.QueryException();
        return this.injectError(queryError);
    }

    public Soql injectResults(List<SObject> records) {
        // Inject a list of mock records to return when the query runs
        this.mockResults = records;
        return this; 
    }

    // **** OVERRIDES **** // 
    public override Integer countQuery() {
        return this.query()?.size();
    }

    public override Database.QueryLocator getQueryLocator() {
        // TODO!
        List<SObject> results = this.query();
        return null; 
    }

    public override List<SObject> query() {
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
}