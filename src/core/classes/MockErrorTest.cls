@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class MockErrorTest {
	@IsTest
	private static void shouldConstructDatabaseError() {
		MockError mock = new MockError();

		Test.startTest();
		Database.Error error = mock?.toDatabaseError();
		Test.stopTest();

		Assert.isNotNull(error?.getMessage(), 'Missing message');
		Assert.isNotNull(error?.getStatusCode(), 'Missing status code');
	}

	@IsTest
	private static void shouldConstructDatabaseErrorWithCustomException() {
		Exception customEx = new System.HandledException('Testing 123');
		MockError mock = new MockError(customEx);

		Test.startTest();
		Database.Error error = mock?.toDatabaseError();
		Test.stopTest();

		Assert.areEqual(customEx?.getMessage(), error?.getMessage(), 'Wrong message');
		Assert.isNotNull(error?.getStatusCode(), 'Missing status code');
	}

	@IsTest
	private static void shouldConvertToDmlException() {
		MockError mock = new MockError();

		Test.startTest();
		Exception ex = mock?.toDmlException();
		Test.stopTest();

		Assert.isInstanceOfType(ex, System.DmlException.class, 'Not a DML Exception');
		Assert.isTrue(ex?.getMessage()?.startsWith('DML failed'), 'Missing message');
	}
}
