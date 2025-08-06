@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest 
private class DatabaseLayerNebulaLoggerAdapterTest {
    private static final Account MOCK_RECORD;

    static {
        DatabaseLayer.useMocks();
        MOCK_RECORD = (Account) new MockRecord(Account.SObjectType)?.withId()?.toSObject();
        MockSoql.setGlobalMock().withResults(new List<Account>{ MOCK_RECORD });
        // TODO: Figure out how to enable nebula logger plugins
    }

    @IsTest 
    static void shouldLogSuccessfulDmlOperations() {
        Test.startTest();
        DatabaseLayer.Dml.doUpdate(MOCK_RECORD);
        Logger.saveLog();
        Test.stopTest();

        List<LogEntry__c> entries = DatabaseLayerNebulaLoggerAdapterTest.getLogs();
        Assert.isFalse(entries?.isEmpty(), 'Did not log via nebula logger');
    }

    @IsTest 
    static void shouldLogFailedDmlOperations() {
        MockDml.shouldFail();

        Test.startTest();
        Exception caughtError;
        try {
            DatabaseLayer.Dml.doUpdate(MOCK_RECORD);
            Assert.fail('A System.DmlException was not thrown');
        } catch (System.DmlException error) {
            caughtError = error; 
        } finally {
            Logger.saveLog();
        }
        Test.stopTest();

        List<LogEntry__c> entries = DatabaseLayerNebulaLoggerAdapterTest.getLogs();
        Assert.isFalse(entries?.isEmpty(), 'Did not log via nebula logger');
    }

    @IsTest 
    static void shouldLogSuccessfulSoqlOperations() {
        Test.startTest();
        DatabaseLayer.Soql.newQuery(Account.SObjectType)?.query();
        Logger.saveLog();
        Test.stopTest();

        List<LogEntry__c> entries = DatabaseLayerNebulaLoggerAdapterTest.getLogs();
        Assert.isFalse(entries?.isEmpty(), 'Did not log via nebula logger');
    }

    @IsTest 
    static void shouldLogFailedSoqlOperations() {
        MockSoql.setGlobalMock()?.withError();

        Test.startTest();
        Exception caughtError; 
        try {
            DatabaseLayer.Soql.newQuery(Account.SObjectType)?.query();
            Assert.fail('Did not throw a System.QueryException');
        } catch (System.QueryException error) {
            caughtError = error; 
        } finally {
            Logger.saveLog();
        }
        Test.stopTest();

        List<LogEntry__c> entries = DatabaseLayerNebulaLoggerAdapterTest.getLogs();
        Assert.isFalse(entries?.isEmpty(), 'Did not log via nebula logger');
    }

    // **** HELPER **** //
    private static List<LogEntry__c> getLogs() {
        // Note: Nebula Logger DML is not encompassed by apex-database-layer; this will always create real log entries
        return [
            SELECT Id
            FROM LogEntry__c
            WHERE EntryScenario__r.Name = :DatabaseLayerNebulaLoggerAdapter.SCENARIO_NAME
        ];
    }
}