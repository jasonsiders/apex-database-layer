@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class DatabaseLayerTest {
	@IsTest
	static void shouldInitCmdtObject() {
		// There's only one CMDT object, and it can provision real or mock data in tests split by SObjectType
		Test.startTest();
		Cmdt result = DatabaseLayer.Cmdt;
		Test.stopTest();

		Assert.isNotNull(result, 'Did not return result');
	}
	@IsTest
	static void shouldInitRealDmlObjectByDefault() {
		Test.startTest();
		Dml result = DatabaseLayer.Dml;
		Test.stopTest();

		Assert.isInstanceOfType(result, Dml.class, 'Should be Dml');
		Assert.isNotInstanceOfType(result, MockDml.class, 'Should not be MockDml');
	}

	@IsTest
	static void shouldInitMockDmlObject() {
		DatabaseLayer.useMocks();

		Test.startTest();
		Dml result = DatabaseLayer.Dml;
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
		Dml result = DatabaseLayer.Dml;
		Test.stopTest();

		Assert.isInstanceOfType(result, Dml.class, 'Should be Dml');
		Assert.isNotInstanceOfType(result, MockDml.class, 'Should not be MockDml');
	}

	@IsTest
	static void shouldInitRealSoqlObjectByDefault() {
		Test.startTest();
		Soql result = DatabaseLayer.Soql?.newQuery(Account.SObjectType);
		Test.stopTest();

		Assert.isInstanceOfType(result, Soql.class, 'Should be Soql');
		Assert.isNotInstanceOfType(result, MockSoql.class, 'Should not be MockSoql');
	}

	@IsTest
	static void shouldInitMockSoqlObject() {
		DatabaseLayer.useMocks();

		Test.startTest();
		Soql result = DatabaseLayer.Soql?.newQuery(Account.SObjectType);
		Test.stopTest();

		Assert.isInstanceOfType(result, Soql.class, 'Should be Soql');
		Assert.isInstanceOfType(result, MockSoql.class, 'Should be MockSoql: ' + result);
	}

	@IsTest
	static void shouldSwitchToRealSoqlObject() {
		DatabaseLayer.useMocks();

		Test.startTest();
		// Now switch back to using real database objects
		DatabaseLayer.useRealData();
		Soql result = DatabaseLayer.Soql?.newQuery(Account.SObjectType);
		Test.stopTest();

		Assert.isInstanceOfType(result, Soql.class, 'Should be Soql');
		Assert.isNotInstanceOfType(result, MockSoql.class, 'Should not be MockSoql');
	}
}
