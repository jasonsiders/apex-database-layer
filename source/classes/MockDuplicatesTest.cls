@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class MockDuplicatesTest {
	private static final Contact DUPE_CONTACT;
	private static final Lead DUPE_LEAD;
	private static final Lead LEAD;

	static {
		DatabaseLayer.useMocks();
		LEAD = (Lead) new MockRecord(Schema.Lead.SObjectType)?.withId()?.toSObject();
		DUPE_LEAD = (Lead) new MockRecord(Schema.Lead.SObjectType)?.withId()?.toSObject();
		DUPE_CONTACT = (Contact) new MockRecord(Schema.Contact.SObjectType)?.withId()?.toSObject();
	}

	@IsTest
	private static void shouldUseBaseSimulatorByDefault() {
		Test.startTest();
		Duplicates.FindDuplicatesResult result = DatabaseLayer.Duplicates.findDuplicates(LEAD);
		Test.stopTest();

		Assert.areEqual(0, result?.getDuplicateResults()?.size(), 'Wrong # of DuplicateResults');
		Assert.areEqual(0, result?.getErrors()?.size(), 'Wrong # of errors');
		Assert.areEqual(true, result?.isSuccess(), 'Wrong isSuccess value');
		Assert.isInstanceOfType(MockDuplicates.simulator, MockDuplicates.BaseSimulator.class, 'Wrong type');
	}

	@IsTest
	private static void shouldUseCustomSimulator() {
		MockDuplicates.Simulator simulator = new MockDuplicatesTest.SimpleSimulator();
		MockDuplicates.setMock(simulator);

		Test.startTest();
		Duplicates.FindDuplicatesResult result = DatabaseLayer.Duplicates.findDuplicates(LEAD);
		Test.stopTest();

		Assert.isInstanceOfType(MockDuplicates.simulator, MockDuplicatesTest.SimpleSimulator.class, 'Wrong type');
	}

	@IsTest
	private static void shouldReturnEmptyResultsByDefault() {
		Test.startTest();
		Duplicates.FindDuplicatesResult result = DatabaseLayer.Duplicates.findDuplicates(LEAD);
		Test.stopTest();

		Assert.areEqual(0, result?.getDuplicateResults()?.size(), 'Wrong # of DuplicateResults');
		Assert.areEqual(0, result?.getErrors()?.size(), 'Wrong # of errors');
		Assert.areEqual(true, result?.isSuccess(), 'Wrong isSuccess value');
	}

	@IsTest
	private static void shouldReturnWithErrors() {
		Assert.fail('You still need to build this test');
	}

	@IsTest
	private static void shouldReturnWithSingleDuplicateResult() {
		Assert.fail('You still need to build this test');
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
	private static void shouldThrowExceptionIfNullOrEmptyRecords() {
		Assert.fail('You still need to build this test');
	}

	@IsTest
	private static void shouldThrowExceptionIfMoreThan50Records() {
		Assert.fail('You still need to build this test');
	}

	@IsTest
	private static void shouldThrowExceptionIfMixedSObjectTypes() {
		// System.HandledException: The list of records to check contains more than one type of record.
		Assert.fail('You still need to build this test');
	}

	@IsTest
	private static void shouldThrowCustomInjectedException() {
		Assert.fail('You still need to build this test');
	}

	// **** INNER **** //
	private class SimpleSimulator implements MockDuplicates.Simulator {
		public MockDuplicates.FindDuplicatesResult simulate(SObject record) {
			// The implementation here doesn't matter
			SObjectType objectType = record?.getSObjectType();
			return new MockDuplicates.FindDuplicatesResult(objectType);
		}
	}
}
