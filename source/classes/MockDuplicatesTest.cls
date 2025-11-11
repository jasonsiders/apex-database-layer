@IsTest
private class MockDuplicatesTest {
	static {
		DatabaseLayer.useMocks();
	}

	@IsTest
	private static void shouldReturnEmptyResultsByDefault() {
		Assert.fail('You still need to build this test');
	}

	@IsTest
	private static void shouldUseCustomSimulator() {
		Assert.fail('You still need to build this test');
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
			return new MockDuplicates.FindDuplicatesResult(record);
		}
	}
}
