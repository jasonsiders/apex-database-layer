@IsTest
private class DatabaseLayerTest {
	@IsTest
	static void shouldInitRealDmlObjectByDefault() {
		Test.startTest();
		Dml result = DatabaseLayer.get()?.initDml();
		Test.stopTest();

		Assert.isInstanceOfType(result, Dml.class, 'Should be Dml');
		Assert.isNotInstanceOfType(result, MockDml.class, 'Should not be MockDml');
		Assert.isNotInstanceOfType(result, OtherDml.class, 'Should not be OtherDml');
	}

	@IsTest
	static void shouldInitMockDmlObject() {
		Test.startTest();
		Dml result = DatabaseLayer.get().useMocks()?.initDml();
		Test.stopTest();

		Assert.isInstanceOfType(result, Dml.class, 'Should be Dml');
		Assert.isInstanceOfType(result, MockDml.class, 'Should be MockDml');
		Assert.isNotInstanceOfType(result, OtherDml.class, 'Should not be OtherDml');
	}

	@IsTest
	static void shouldInitCustomDmlObject() {
		Dml otherDml = new OtherDml();

		Test.startTest();
		Dml result = DatabaseLayer.get().useDml(otherDml)?.initDml();
		Test.stopTest();

		Assert.isInstanceOfType(result, Dml.class, 'Should be Dml');
		Assert.isNotInstanceOfType(result, MockDml.class, 'Should not be MockDml');
		Assert.isInstanceOfType(result, OtherDml.class, 'Should be OtherDml');
	}

	@IsTest
	static void shouldSwitchToRealDmlObject() {
		DatabaseLayer db = DatabaseLayer.get()?.useMocks();

		Test.startTest();
		// Now switch back to using real database objects
		Dml result = db?.useDatabase()?.initDml();
		Test.stopTest();

		Assert.isInstanceOfType(result, Dml.class, 'Should be Dml');
		Assert.isNotInstanceOfType(result, MockDml.class, 'Should not be MockDml');
		Assert.isNotInstanceOfType(result, OtherDml.class, 'Should not be OtherDml');
	}

	@IsTest
	static void shouldInitRealSoqlObjectByDefault() {
		Test.startTest();
		Soql result = DatabaseLayer.get()?.initSoql(Account.SObjectType);
		Test.stopTest();

		Assert.isInstanceOfType(result, Soql.class, 'Should be Soql');
		Assert.isNotInstanceOfType(result, MockSoql.class, 'Should not be MockSoql');
		Assert.isNotInstanceOfType(result, OtherSoql.class, 'Should not be OtherSoql');
	}

	@IsTest
	static void shouldInitMockSoqlObject() {
		Test.startTest();
		Soql result = DatabaseLayer.get().useMocks()?.initSoql(Account.SObjectType);
		Test.stopTest();

		Assert.isInstanceOfType(result, Soql.class, 'Should be Soql');
		Assert.isInstanceOfType(result, MockSoql.class, 'Should be MockSoql');
		Assert.isNotInstanceOfType(result, OtherSoql.class, 'Should not be OtherSoql');
	}

	@IsTest
	static void shouldInitCustomSoqlObject() {
		Soql otherSoql = new OtherSoql();

		Test.startTest();
		Soql result = DatabaseLayer.get().useSoql(otherSoql)?.initSoql(Account.SObjectType);
		Test.stopTest();

		Assert.isInstanceOfType(result, Soql.class, 'Should be Soql');
		Assert.isNotInstanceOfType(result, MockSoql.class, 'Should not be MockSoql');
		Assert.isInstanceOfType(result, OtherSoql.class, 'Should be OtherSoql');
	}

	@IsTest
	static void shouldSwitchToRealSoqlObject() {
		DatabaseLayer db = DatabaseLayer.get()?.useMocks();

		Test.startTest();
		// Now switch back to using real database objects
		Soql result = db?.useDatabase()?.initSoql(Account.SObjectType);
		Test.stopTest();

		Assert.isInstanceOfType(result, Soql.class, 'Should be Soql');
		Assert.isNotInstanceOfType(result, MockSoql.class, 'Should not be MockSoql');
		Assert.isNotInstanceOfType(result, OtherSoql.class, 'Should not be OtherSoql');
	}

	@IsTest
	static void shouldInitSoqlUsingQueryString() {
		String queryString = 'SELECT Id FROM Account';

		Test.startTest();
		Soql result = DatabaseLayer.get()?.initSoql(queryString);
		Test.stopTest();

		Assert.areEqual(queryString, result?.toString(), 'Query string does not match');
		Assert.isInstanceOfType(result, Soql.class, 'Should be Soql');
		Assert.isNotInstanceOfType(result, MockSoql.class, 'Should not be MockSoql');
		Assert.isNotInstanceOfType(result, OtherSoql.class, 'Should not be OtherSoql');
	}

	@IsTest 
	static void shouldInitSoqlMockUsingQueryString() {
		String queryString = 'SELECT Id FROM Account';

		Test.startTest();
		Soql result = DatabaseLayer.get()?.useMocks()?.initSoql(queryString);
		Test.stopTest();

		Assert.areEqual(queryString, result?.toString(), 'Query string does not match');
		Assert.isInstanceOfType(result, Soql.class, 'Should be Soql');
		Assert.isInstanceOfType(result, MockSoql.class, 'Should not be MockSoql');
		Assert.isNotInstanceOfType(result, OtherSoql.class, 'Should not be OtherSoql');
	}

	// **** INNER **** // 
	public class OtherDml extends Dml {}

	public class OtherSoql extends Soql {}
}
