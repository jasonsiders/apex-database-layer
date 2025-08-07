@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class DatabaseLayerNebulaLoggerAdapterTest {
	private static final Account MOCK_RECORD;
	private static final String PLUGIN_NAME = DatabaseLayerNebulaLoggerAdapter.class.getName();

	static {
		DatabaseLayer.useMocks();
		MOCK_RECORD = (Account) new MockRecord(Account.SObjectType)?.withId()?.toSObject();
		MockSoql.setGlobalMock().withResults(new List<Account>{ MOCK_RECORD });
		DatabaseLayerTestUtils.initDmlAndSoqlPlugins(PLUGIN_NAME);
	}

	@IsTest
	static void shouldLogSuccessfulDmlOperations() {
		Test.startTest();
		DatabaseLayer.Dml.doUpdate(MOCK_RECORD);
		Test.stopTest();

		LogSummary summary = new LogSummary();
		Assert.areEqual(2, summary?.numTotalEntries(), 'Wrong # of log entries');
		Assert.areEqual(2, summary?.numEntriesWithLevel(System.LoggingLevel.FINEST), 'Wrong # of FINEST logs');
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
		}
		Test.stopTest();

		LogSummary summary = new LogSummary();
		Assert.areEqual(2, summary?.numTotalEntries(), 'Wrong # of log entries');
		Assert.areEqual(1, summary?.numEntriesWithLevel(System.LoggingLevel.FINEST), 'Wrong # of FINEST logs');
		Assert.areEqual(1, summary?.numEntriesWithLevel(System.LoggingLevel.ERROR), 'Wrong # of ERROR logs');
	}

	@IsTest
	static void shouldLogSuccessfulSoqlOperations() {
		Test.startTest();
		DatabaseLayer.Soql.newQuery(Account.SObjectType)?.query();
		Test.stopTest();

		LogSummary summary = new LogSummary();
		Assert.areEqual(2, summary?.numTotalEntries(), 'Wrong # of log entries');
		Assert.areEqual(2, summary?.numEntriesWithLevel(System.LoggingLevel.FINEST), 'Wrong # of FINEST logs');
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
		}
		Test.stopTest();

		LogSummary summary = new LogSummary();
		Assert.areEqual(2, summary?.numTotalEntries(), 'Wrong # of log entries');
		Assert.areEqual(1, summary?.numEntriesWithLevel(System.LoggingLevel.FINEST), 'Wrong # of FINEST logs');
		Assert.areEqual(1, summary?.numEntriesWithLevel(System.LoggingLevel.ERROR), 'Wrong # of ERROR logs');
	}

	// **** INNER **** //
	private class LogSummary {
		private List<LogEntryTag__c> taggedEntries;
		private Map<String, Set<Id>> entryIdsByLevel;

		/**
		 * @description Creates a new LogSummary by saving logs, delivering events, and querying tagged entries
		 */
		public LogSummary() {
			Logger.saveLog();
			Test.getEventBus().deliver();
			this.queryTaggedEntries();
			this.mapTaggedEntriesByLevel();
		}

		/**
		 * @description Returns the number of log entries with the specified logging level
		 * @param level The logging level to count entries for
		 * @return The number of entries with the specified level, or 0 if none exist
		 */
		public Integer numEntriesWithLevel(System.LoggingLevel level) {
			return this.entryIdsByLevel?.get(level?.name())?.size() ?? 0;
		}

		/**
		 * @description Returns the total number of tagged log entries
		 * @return The total number of tagged entries, or 0 if none exist
		 */
		public Integer numTotalEntries() {
			return this.taggedEntries?.size() ?? 0;
		}

		private void mapTaggedEntriesByLevel() {
			// Group LogEntry Ids by their common Logging Level name
			this.entryIdsByLevel = new Map<String, Set<Id>>{};
			for (LogEntryTag__c taggedEntry : this.taggedEntries) {
				String level = taggedEntry?.LogEntry__r?.LoggingLevel__c;
				Set<Id> matching = this.entryIdsByLevel?.get(level) ?? new Set<Id>{};
				matching?.add(taggedEntry?.LogEntry__c);
				this.entryIdsByLevel?.put(level, matching);
			}
		}

		private void queryTaggedEntries() {
			// Query for all log entries that were tagged with 'apex-database-layer'
			this.taggedEntries = [
				SELECT Id, LogEntry__c, LogEntry__r.LoggingLevel__c, LogEntry__r.Message__c, Tag__r.Name
				FROM LogEntryTag__c
				WHERE Tag__r.Name = :DatabaseLayerNebulaLoggerAdapter.TAG_NAME
			];
		}
	}
}
