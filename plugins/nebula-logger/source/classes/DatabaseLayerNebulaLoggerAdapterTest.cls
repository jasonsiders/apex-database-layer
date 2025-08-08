@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class DatabaseLayerNebulaLoggerAdapterTest {
	private static final Lead MOCK_RECORD;
	private static final String PLUGIN_NAME = DatabaseLayerNebulaLoggerAdapter.class.getName();

	static {
		DatabaseLayer.useMocks();
		MOCK_RECORD = (Lead) new MockRecord(Lead.SObjectType)?.withId()?.toSObject();
		MockSoql.setGlobalMock().withResults(new List<Lead>{ MOCK_RECORD });
		DatabaseLayerTestUtils.initDmlAndSoqlPlugins(PLUGIN_NAME);
	}

	@IsTest
	static void shouldLogDmlSaveOperations() {
		Test.startTest();
		DatabaseLayer.Dml.doUpdate(MOCK_RECORD);
		Test.stopTest();

		LogSummary summary = new LogSummary();
		Assert.areEqual(2, summary?.numTotalEntries(), 'Wrong # of log entries');
		Assert.areEqual(2, summary?.numEntriesWithLevel(System.LoggingLevel.FINEST), 'Wrong # of FINEST logs');
	}

	@IsTest 
	static void shouldLogDmlConvertOperations() {
		// Mostly for coverage -- necessary since Nebula Logger doesn't support using generic Objects for its `setDatabaseResult` method
		Database.LeadConvert leadToConvert = new Database.LeadConvert();
		leadToConvert.setConvertedStatus('Some Status');
		leadToConvert.setLeadId(MOCK_RECORD?.Id);

		Test.startTest();
		DatabaseLayer.Dml.doConvert(leadToConvert);
		Test.stopTest();

		LogSummary summary = new LogSummary();
		Assert.areEqual(2, summary?.numTotalEntries(), 'Wrong # of log entries');
		Assert.areEqual(2, summary?.numEntriesWithLevel(System.LoggingLevel.FINEST), 'Wrong # of FINEST logs');
	}

	@IsTest 
	static void shouldLogDmlDeleteOperations() {
		// Mostly for coverage -- necessary since Nebula Logger doesn't support using generic Objects for its `setDatabaseResult` method
		Test.startTest();
		DatabaseLayer.Dml.doDelete(MOCK_RECORD);
		Test.stopTest();

		LogSummary summary = new LogSummary();
		Assert.areEqual(2, summary?.numTotalEntries(), 'Wrong # of log entries');
		Assert.areEqual(2, summary?.numEntriesWithLevel(System.LoggingLevel.FINEST), 'Wrong # of FINEST logs');
	}

	@IsTest 
	static void shouldLogDmlUndeleteOperations() {
		// Mostly for coverage -- necessary since Nebula Logger doesn't support using generic Objects for its `setDatabaseResult` method
		Test.startTest();
		DatabaseLayer.Dml.doUndelete(MOCK_RECORD);
		Test.stopTest();

		LogSummary summary = new LogSummary();
		Assert.areEqual(2, summary?.numTotalEntries(), 'Wrong # of log entries');
		Assert.areEqual(2, summary?.numEntriesWithLevel(System.LoggingLevel.FINEST), 'Wrong # of FINEST logs');
	}

	@IsTest 
	static void shouldLogDmlUpsertOperations() {
		// Mostly for coverage -- necessary since Nebula Logger doesn't support using generic Objects for its `setDatabaseResult` method
		Test.startTest();
		DatabaseLayer.Dml.doUpsert(MOCK_RECORD);
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
	static void shouldLogSoqlOperations() {
		Test.startTest();
		DatabaseLayer.Soql.newQuery(Lead.SObjectType)?.query();
		Test.stopTest();

		LogSummary summary = new LogSummary();
		Assert.areEqual(2, summary?.numTotalEntries(), 'Wrong # of log entries');
		Assert.areEqual(2, summary?.numEntriesWithLevel(System.LoggingLevel.FINEST), 'Wrong # of FINEST logs');
	}

	@IsTest 
	static void shouldLogSoqlQueryLocatorOperations() {
		// Mostly for coverage -- Database.QueryLocators are not serializable, 
		// and therefore have special log handling to prevent errors:
		Test.startTest();
		DatabaseLayer.Soql.newQuery(Lead.SObjectType)?.getQueryLocator();
		Test.stopTest();

		LogSummary summary = new LogSummary();
		Assert.areEqual(2, summary?.numTotalEntries(), 'Wrong # of log entries');
		Assert.areEqual(2, summary?.numEntriesWithLevel(System.LoggingLevel.FINEST), 'Wrong # of FINEST logs');
	}

	@IsTest 
	static void shouldLogOtherSoqlOperations() {
		// This is mostly for coverage; results from query operations 
		// that return something other than a List<SObject> are serialized
		Test.startTest();
		DatabaseLayer.Soql.newQuery(Lead.SObjectType)?.countQuery();
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
			DatabaseLayer.Soql.newQuery(Lead.SObjectType)?.query();
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
