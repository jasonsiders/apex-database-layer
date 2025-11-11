@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs,PMD.EmptyCatchBlock')
@IsTest
private class MockDuplicatesTest {
	private static final Contact DUPE_CONTACT;
	private static final Lead DUPE_LEAD;
	private static final Lead TEST_LEAD;

	static {
		DatabaseLayer.useMocks();
		TEST_LEAD = (Lead) new MockRecord(Schema.Lead.SObjectType)?.withId()?.toSObject();
		DUPE_LEAD = (Lead) new MockRecord(Schema.Lead.SObjectType)?.withId()?.toSObject();
		DUPE_CONTACT = (Contact) new MockRecord(Schema.Contact.SObjectType)?.withId()?.toSObject();
	}

	@IsTest
	private static void shouldUseBaseSimulatorByDefault() {
		Test.startTest();
		MockDuplicates.Simulator defaultSimulator = MockDuplicates.simulator;
		Test.stopTest();

		Assert.isInstanceOfType(defaultSimulator, MockDuplicates.BaseSimulator.class, 'Wrong type');
	}

	@IsTest
	private static void shouldUseCustomSimulator() {
		MockDuplicates.Simulator customSimulator = new MockDuplicatesTest.DummySimulator();

		Test.startTest();
		MockDuplicates.setMock(customSimulator);
		Test.stopTest();

		Assert.isInstanceOfType(MockDuplicates.simulator, MockDuplicatesTest.DummySimulator.class, 'Wrong type');
	}

	@IsTest
	private static void shouldReturnEmptyResultsByDefault() {
		Test.startTest();
		Duplicates.FindDuplicatesResult result = DatabaseLayer.Duplicates.findDuplicates(TEST_LEAD);
		Test.stopTest();

		Assert.areEqual(0, result?.getErrors()?.size(), 'Wrong # of errors');
		Assert.areEqual(true, result?.isSuccess(), 'Wrong isSuccess value');
		Assert.areEqual(0, result?.getDuplicateResults()?.size(), 'Wrong # of DuplicateResults');
	}

	@IsTest
	private static void shouldReturnWithErrors() {
		MockDuplicates.setMock()?.withResults(Lead.SObjectType)?.addError();

		Test.startTest();
		Duplicates.FindDuplicatesResult result = DatabaseLayer.Duplicates.findDuplicates(TEST_LEAD);
		Test.stopTest();

		Assert.areEqual(1, result?.getErrors()?.size(), 'Wrong # of errors');
		Assert.areEqual(false, result?.isSuccess(), 'Wrong isSuccess value');
		Assert.areEqual(0, result?.getDuplicateResults()?.size(), 'Wrong # of DuplicateResults');
	}

	@IsTest
	private static void shouldReturnWithSingleDuplicateResult() {
		MockDuplicates.setMock()?.withResults(Lead.SObjectType)?.addRule()?.addMatch()?.addRecord();

		Test.startTest();
		Duplicates.FindDuplicatesResult result = DatabaseLayer.Duplicates.findDuplicates(TEST_LEAD);
		Test.stopTest();

		Assert.areEqual(0, result?.getErrors()?.size(), 'Wrong # of errors');
		Assert.areEqual(true, result?.isSuccess(), 'Wrong isSuccess value');
		List<Duplicates.DuplicateResult> dupeResults = result?.getDuplicateResults();
		Assert.areEqual(1, dupeResults?.size(), 'Wrong # of DuplicateResults');
		Duplicates.DuplicateResult dupeResult = dupeResults?.get(0);
		Assert.isTrue(dupeResult?.allowSave, 'Wrong allowSave value');
		Assert.isTrue(
			dupeResult?.duplicateRule?.startsWith('Mock_'),
			'Wrong duplicateRule: ' + dupeResult?.duplicateRule
		);
		Assert.areEqual('Lead', dupeResult?.duplicateRuleEntityType, 'Wrong duplicateRuleEntityType value');
		Assert.areEqual('Duplicate Alert', dupeResult?.errorMessage, 'Wrong errorMessage value');
		List<Duplicates.MatchResult> matchResults = dupeResult?.getMatchResults();
		Assert.areEqual(1, matchResults?.size(), 'Wrong duplicateRuleEntityType value');
		Duplicates.MatchResult matchResult = matchResults?.get(0);
		Assert.areEqual('Lead', matchResult?.entityType, 'Wrong entityType value');
		Assert.areEqual(0, matchResult?.errors?.size(), 'Wrong # of MatchResult.errors');
		Assert.areEqual('MockMatchEngine', matchResult?.matchEngine, 'Wrong matchEngine value');
		Assert.isTrue(
			matchResult?.rule?.startsWith('Mock_') == true,
			'Wrong rule value: ' + matchResult?.rule + '\n' + JSON.serialize(matchResult)
		);
		List<Duplicates.MatchRecord> matchRecords = matchResult?.getMatchRecords();
		Duplicates.MatchRecord matchRecord = matchRecords?.get(0);
		Assert.areEqual(100.0, matchRecord?.matchConfidence, 'Wrong matchConfidence');
		Assert.areEqual(0, matchRecord?.additionalInformation?.size(), 'Wrong # of additionalInformation');
		Assert.areEqual(0, matchRecord?.fieldDiffs?.size(), 'Wrong # of fieldDiffs');
		Assert.areEqual(Lead.SObjectType, matchRecord?.record?.Id?.getSObjectType(), 'Wrong type of record');
	}

	@IsTest
	private static void shouldReturnWithMultipleDuplicateResults() {
		Assert.fail('You still need to build this test');
	}

	@IsTest
	private static void shouldReturnWithDuplicatesOfDifferentSObjectTypes() {
		Assert.fail('You still need to build this test');
	}

	@IsTest
	private static void shouldReturnWithOptionalMatchDetails() {
		Assert.fail('You still need to build this test');
	}

	@IsTest
	private static void shouldAllowFluentMockNavigation() {
		Assert.fail('You still need to build this test');
	}

	@IsTest
	private static void shouldThrowExceptionIfEmptyRecords() {
		// The standard Datacloud.FindDuplicates.findDuplicates method requires at least 1 record
		List<SObject> records = new List<SObject>{};

		Test.startTest();
		try {
			DatabaseLayer.Duplicates.findDuplicates(records);
			Assert.fail('Did not throw a System.HandledException');
		} catch (System.HandledException error) {
			// As expected...
		}
		Test.stopTest();
	}

	@IsTest
	private static void shouldThrowExceptionIfNullRecords() {
		// The standard Datacloud.FindDuplicates.findDuplicates method requires at least 1 record
		List<SObject> records = null;

		Test.startTest();
		try {
			DatabaseLayer.Duplicates.findDuplicates(records);
			Assert.fail('Did not throw a System.HandledException');
		} catch (System.HandledException error) {
			// As expected...
		}
		Test.stopTest();
	}

	@IsTest
	private static void shouldThrowExceptionIfMoreThan50Records() {
		// The standard Datacloud.FindDuplicates.findDuplicates method does not allow more than 50 records at a time
		List<SObject> records = new List<SObject>{};
		for (Integer i = 0; i < 51; i++) {
			records?.add(new Account());
		}

		Test.startTest();
		try {
			DatabaseLayer.Duplicates.findDuplicates(records);
			Assert.fail('Did not throw a System.HandledException');
		} catch (System.HandledException error) {
			// As expected...
		}
		Test.stopTest();
	}

	@IsTest
	private static void shouldThrowExceptionIfMixedSObjectTypes() {
		List<SObject> records = new List<SObject>{};
		records?.add(new Account());
		records?.add(new Contact());

		Test.startTest();
		try {
			DatabaseLayer.Duplicates.findDuplicates(records);
			Assert.fail('Did not throw a System.HandledException');
		} catch (System.HandledException error) {
			// As expected...
		}
		Test.stopTest();
	}

	@IsTest
	private static void shouldThrowCustomInjectedException() {
		Assert.fail('You still need to build this test');
	}

	// **** INNER **** //
	private class DummySimulator implements MockDuplicates.Simulator {
		/**
		 * @description A mock/empty simulator used to test the simulator mechanism
		 * @param record Each record in the findDuplicates call
		 * @return A null MockDuplicates.FindDuplicatesResult object
		 */
		public MockDuplicates.FindDuplicatesResult simulate(SObject record) {
			// The implementation here doesn't matter
			return null;
		}
	}
}
