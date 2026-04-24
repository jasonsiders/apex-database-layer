@IsTest
private class SoqlParserTest {
	private static final String OPPORTUNITY = 'Opportunity';
	private static final String ACCOUNT = 'Account';
	private static final String CONTACT = 'Contact';

	@IsTest
	private static void testSimpleRoundTrip() {
		DatabaseLayer.useMocks();
		String input = 'SELECT Id, AccountId FROM Opportunity WHERE IsClosed = true ORDER BY CloseDate DESC LIMIT 1';
		Soql query = DatabaseLayer.newSoql(input);
		String output = query?.toString();
		Assert.areEqual(input, output);
	}

	@IsTest
	private static void testMutationAfterParse() {
		DatabaseLayer.useMocks();
		String input = 'SELECT Id, AccountId FROM Opportunity WHERE IsClosed = true ORDER BY CloseDate DESC LIMIT 1';
		Soql query = DatabaseLayer.newSoql(input);
		query.addSelect('CloseDate');
		query.addWhere('Amount', Soql.GREATER_THAN, 100000);
		String output = query?.toString();
		String expected = 'SELECT Id, AccountId, CloseDate FROM Opportunity WHERE IsClosed = true AND Amount > 100000 ORDER BY CloseDate DESC LIMIT 1';
		Assert.areEqual(expected, output);
	}

	@IsTest
	private static void testFlatOrWhere() {
		DatabaseLayer.useMocks();
		String input = 'SELECT Id FROM Account WHERE Name = \'Foo\' OR Name = \'Bar\'';
		Soql query = DatabaseLayer.newSoql(input);
		String output = query?.toString();
		Assert.areEqual(input, output);
	}

	@IsTest
	private static void testNestedAndOr() {
		DatabaseLayer.useMocks();
		String input = 'SELECT Id FROM Contact WHERE (FirstName = \'John\' AND LastName = \'Doe\') OR Email != null';
		Soql query = DatabaseLayer.newSoql(input);
		String output = query?.toString();
		Assert.areEqual(input, output);
	}

	@IsTest
	private static void testAggregateSelect() {
		DatabaseLayer.useMocks();
		String input = 'SELECT COUNT(Id), SUM(Amount) totalAmount FROM Opportunity';
		Soql query = DatabaseLayer.newSoql(input);
		String output = query?.toString();
		Assert.areEqual(input, output);
	}

	@IsTest
	private static void testSubqueryInSelect() {
		DatabaseLayer.useMocks();
		String input = 'SELECT Id, (SELECT Id, LastName FROM Contacts) FROM Account';
		Soql query = DatabaseLayer.newSoql(input);
		String output = query?.toString();
		Assert.areEqual(input, output);
	}

	@IsTest
	private static void testOrderByMultiField() {
		DatabaseLayer.useMocks();
		String input = 'SELECT Id FROM Account ORDER BY Name ASC, CreatedDate DESC';
		Soql query = DatabaseLayer.newSoql(input);
		String output = query?.toString();
		Assert.areEqual(input, output);
	}

	@IsTest
	private static void testGroupByAndHaving() {
		DatabaseLayer.useMocks();
		String input = 'SELECT AccountId, COUNT(Id) FROM Opportunity GROUP BY AccountId HAVING COUNT(Id) > 5';
		Soql query = DatabaseLayer.newSoql(input);
		String output = query?.toString();
		Assert.areEqual(input, output);
	}

	@IsTest
	private static void testUsingScope() {
		DatabaseLayer.useMocks();
		String input = 'SELECT Id FROM Account USING SCOPE MINE';
		Soql query = DatabaseLayer.newSoql(input);
		String output = query?.toString();
		Assert.areEqual(input, output);
	}

	@IsTest
	private static void testWithSecurityEnforced() {
		DatabaseLayer.useMocks();
		String input = 'SELECT Id FROM Account WITH SECURITY_ENFORCED';
		Soql query = DatabaseLayer.newSoql(input);
		String output = query?.toString();
		Assert.areEqual(input, output);
	}

	@IsTest
	private static void testLimitAndOffset() {
		DatabaseLayer.useMocks();
		String input = 'SELECT Id FROM Account LIMIT 10 OFFSET 20';
		Soql query = DatabaseLayer.newSoql(input);
		String output = query?.toString();
		Assert.areEqual(input, output);
	}

	@IsTest
	private static void testForUpdate() {
		DatabaseLayer.useMocks();
		String input = 'SELECT Id FROM Account FOR UPDATE';
		Soql query = DatabaseLayer.newSoql(input);
		String output = query?.toString();
		Assert.areEqual(input, output);
	}

	@IsTest
	private static void testParentFieldDotNotation() {
		DatabaseLayer.useMocks();
		String input = 'SELECT Id, Account.Name FROM Contact WHERE Account.Industry = \'Technology\'';
		Soql query = DatabaseLayer.newSoql(input);
		String output = query?.toString();
		Assert.areEqual(input, output);
	}

	@IsTest
	private static void testInList() {
		DatabaseLayer.useMocks();
		String input = 'SELECT Id FROM Account WHERE Name IN (\'Acme\', \'Salesforce\')';
		Soql query = DatabaseLayer.newSoql(input);
		String output = query?.toString();
		Assert.areEqual(input, output);
	}

	@IsTest
	private static void testNestedAndInsideOr() {
		DatabaseLayer.useMocks();
		String input = 'SELECT Id FROM Opportunity WHERE (Amount > 1000 AND IsClosed = false) OR (Amount > 5000 AND IsClosed = true)';
		Soql query = DatabaseLayer.newSoql(input);
		String output = query?.toString();
		Assert.areEqual(input, output);
	}
}
