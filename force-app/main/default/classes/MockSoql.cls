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

    public override Soql.QueryLocator getQueryLocator() {
        return new MockSoql.QueryLocator(this);
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

    // **** PRIVATE **** //
    public class QueryLocator extends Soql.QueryLocator {
        // Note: This mock implementation has one big shortcoming.
        // Because the underlying Database.QueryLocator object cannot be mocked, 
        // getCursor() will always return null in mock scenarios.
        // Most custom implementations will call getQuery() or iterator() directly,
        // but standard mechanisms (ie., Database.Batchable classes) won't work with this.
        // One workaround is to individually test the start(), execute(), and finish() methods,
        // instead of testing via Database.executeBatch()
        String query; 
        List<SObject> records;
        
        private QueryLocator(MockSoql mockQuery) {
            super(null);
            this.query = mockQuery?.toString();
            this.records = mockQuery?.query();
        }

        public override String getQuery() {
            return this.query; 
        }

        public override Iterator<SObject> iterator() {
            return new MockSoql.QueryLocatorIterator(this.records);
        }
    }

    public class QueryLocatorIterator implements Iterator<SObject> {
        // This custom iterator mirrors the Database.QueryLocatorIterator,
        // which is really just an Iterator<SObject> under the hood
        Integer index = 0;
        List<SObject> records;

        private QueryLocatorIterator(List<SObject> records) {
            this.records = records;
        }

        public Boolean hasNext() {
            return this.index < records?.size();
        }

        public SObject next() {
            if (this.hasNext() == true) {
                return this.records[index++];
            } else {
                String msg = 'Iterator has no more elements.';
                throw new System.NoSuchElementException(msg);
            }
        }
    }
}