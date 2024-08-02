@IsTest
private class DatabaseLayerTest {
	@IsTest
	static void shouldInitRealDmlObjectByDefault() {
		Test.startTest();
		Dml result = DatabaseLayer.newDml();
		Test.stopTest();

		Assert.isInstanceOfType(result, Dml.class, 'Should be Dml');
		Assert.isNotInstanceOfType(result, MockDml.class, 'Should not be MockDml');
	}

	@IsTest
	static void shouldInitMockDmlObject() {
		DatabaseLayer.useMocks();

		Test.startTest();
		Dml result = DatabaseLayer.newDml();
		Test.stopTest();

		Assert.isInstanceOfType(result, Dml.class, 'Should be Dml');
		Assert.isInstanceOfType(result, MockDml.class, 'Should be MockDml');
	}

	@IsTest
	static void shouldSwitchToRealDmlObject() {
		DatabaseLayer.useMocks();

		Test.startTest();
		// Now switch back to using real database objects
		DatabaseLayer.useRealData();
		Dml result = DatabaseLayer.newDml();
		Test.stopTest();

		Assert.isInstanceOfType(result, Dml.class, 'Should be Dml');
		Assert.isNotInstanceOfType(result, MockDml.class, 'Should not be MockDml');
	}

	@IsTest
	static void shouldInitRealSoqlObjectByDefault() {
		Test.startTest();
		Soql result = DatabaseLayer.newSoql(Account.SObjectType);
		Test.stopTest();

		Assert.isInstanceOfType(result, Soql.class, 'Should be Soql');
		Assert.isNotInstanceOfType(result, MockSoql.class, 'Should not be MockSoql');
	}

	@IsTest
	static void shouldInitMockSoqlObject() {
		DatabaseLayer.useMocks();

		Test.startTest();
		Soql result = DatabaseLayer.newSoql(Account.SObjectType);
		Test.stopTest();

		Assert.isInstanceOfType(result, Soql.class, 'Should be Soql');
		Assert.isInstanceOfType(result, MockSoql.class, 'Should be MockSoql');
	}

	@IsTest
	static void shouldSwitchToRealSoqlObject() {
		DatabaseLayer.useMocks();

		Test.startTest();
		// Now switch back to using real database objects
		DatabaseLayer.useRealData();
		Soql result = DatabaseLayer.newSoql(Account.SObjectType);
		Test.stopTest();

		Assert.isInstanceOfType(result, Soql.class, 'Should be Soql');
		Assert.isNotInstanceOfType(result, MockSoql.class, 'Should not be MockSoql');
	}
}
