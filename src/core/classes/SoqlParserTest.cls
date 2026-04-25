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

	@IsTest
	private static void testAllRows() {
		DatabaseLayer.useMocks();
		String input = 'SELECT Id FROM Account ALL ROWS';
		Soql query = DatabaseLayer.newSoql(input);
		String output = query?.toString();
		Assert.areEqual(input, output);
	}

	@IsTest
	private static void testDateFiltering() {
		DatabaseLayer.useMocks();
		String input = 'SELECT Id FROM Account WHERE CreatedDate > 2020-01-01';
		Soql query = DatabaseLayer.newSoql(input);
		String output = query?.toString();
		Assert.areEqual(input, output);
	}

	@IsTest
	private static void testBindVariables() {
		DatabaseLayer.useMocks();
		String input = 'SELECT Id FROM Account WHERE Name = :accountName';
		Soql query = DatabaseLayer.newSoql(input);
		String output = query?.toString();
		Assert.areEqual(input, output);
	}

	@IsTest
	private static void testMultipleGroupByFields() {
		DatabaseLayer.useMocks();
		String input = 'SELECT AccountId, StageName, COUNT(Id) FROM Opportunity GROUP BY AccountId, StageName';
		Soql query = DatabaseLayer.newSoql(input);
		String output = query?.toString();
		Assert.areEqual(input, output);
	}

	@IsTest
	private static void testComplexWhereWithNesting() {
		DatabaseLayer.useMocks();
		String input = 'SELECT Id FROM Account WHERE (Name = \'test\' AND Industry = \'Tech\') OR (BillingCity = \'SF\' AND BillingState = \'CA\')';
		Soql query = DatabaseLayer.newSoql(input);
		String output = query?.toString();
		Assert.areEqual(input, output);
	}

	@IsTest
	private static void testNotInOperator() {
		DatabaseLayer.useMocks();
		String input = 'SELECT Id FROM Account WHERE Name NOT IN (\'A\', \'B\')';
		Soql query = DatabaseLayer.newSoql(input);
		String output = query?.toString();
		Assert.areEqual(input, output);
	}

	@IsTest
	private static void testMultipleAggregations() {
		DatabaseLayer.useMocks();
		String input = 'SELECT COUNT(Id) count, AVG(Amount) avgAmount, MAX(Amount) maxAmount FROM Opportunity';
		Soql query = DatabaseLayer.newSoql(input);
		String output = query?.toString();
		Assert.areEqual(input, output);
	}

	@IsTest
	private static void testDateTimeValue() {
		DatabaseLayer.useMocks();
		String input = 'SELECT Id FROM Account WHERE CreatedDate > 2020-01-01T10:00:00Z';
		Soql query = DatabaseLayer.newSoql(input);
		String output = query?.toString();
		Assert.areEqual(input, output);
	}

	@IsTest
	private static void testNullInWhere() {
		DatabaseLayer.useMocks();
		String input = 'SELECT Id FROM Account WHERE BillingCity = null';
		Soql query = DatabaseLayer.newSoql(input);
		String output = query?.toString();
		Assert.areEqual(input, output);
	}

	@IsTest
	private static void testBooleanInWhere() {
		DatabaseLayer.useMocks();
		String input = 'SELECT Id FROM Opportunity WHERE IsClosed = true';
		Soql query = DatabaseLayer.newSoql(input);
		String output = query?.toString();
		Assert.areEqual(input, output);
	}

	@IsTest
	private static void testGreaterThanOperator() {
		DatabaseLayer.useMocks();
		String input = 'SELECT Id FROM Opportunity WHERE Amount >= 10000';
		Soql query = DatabaseLayer.newSoql(input);
		String output = query?.toString();
		Assert.areEqual(input, output);
	}

	@IsTest
	private static void testLessThanOperator() {
		DatabaseLayer.useMocks();
		String input = 'SELECT Id FROM Account WHERE NumberOfEmployees <= 100';
		Soql query = DatabaseLayer.newSoql(input);
		String output = query?.toString();
		Assert.areEqual(input, output);
	}

	@IsTest
	private static void testMalformedSubqueryNoFrom() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();
		Soql.Builder builder = DatabaseLayer.newSoql('SELECT Id FROM Account');
		parser.parseSubquery(builder, '(SELECT Id, Name)');
		String output = builder?.toString();
		Assert.isNotNull(output);
	}

	@IsTest
	private static void testUnmatchedParenthesis() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();
		Integer result = parser.findMatchingParen('(unclosed text here', 0);
		Assert.areEqual(19, result);
	}

	@IsTest
	private static void testConditionWithoutOperator() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();
		Soql.Condition condition = parser.parseCondition('Name');
		Assert.areEqual('Name', condition.property);
		Assert.areEqual('=', condition.operator.toString());
		Assert.isNull(condition.value);
	}

	@IsTest
	private static void testParseValueWithNull() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();
		Object result = parser.parseValue('null');
		Assert.isNull(result);
	}

	@IsTest
	private static void testParseValueWithTrue() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();
		Object result = parser.parseValue('true');
		Assert.areEqual(true, (Boolean) result);
	}

	@IsTest
	private static void testParseValueWithFalse() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();
		Object result = parser.parseValue('false');
		Assert.areEqual(false, (Boolean) result);
	}

	@IsTest
	private static void testParseValueWithInteger() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();
		Object result = parser.parseValue('12345');
		Assert.areEqual(12345, (Integer) result);
	}

	@IsTest
	private static void testParseValueWithDecimal() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();
		Object result = parser.parseValue('123.45');
		Assert.areEqual(123.45, (Decimal) result);
	}

	@IsTest
	private static void testParseValueWithString() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();
		Object result = parser.parseValue('\'test value\'');
		Assert.areEqual('test value', (String) result);
	}

	@IsTest
	private static void testParseValueWithBindVariable() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();
		Object result = parser.parseValue(':bindVar');
		Assert.areEqual(':bindVar', (String) result);
	}

	@IsTest
	private static void testParseValueWithList() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();
		Object result = parser.parseValue('(\'A\', \'B\', \'C\')');
		Assert.isNotNull(result);
	}

	@IsTest
	private static void testParseValueWithDate() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();
		Object result = parser.parseValue('2020-06-15');
		Assert.isNotNull(result);
	}

	@IsTest
	private static void testParseValueWithDateTime() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();
		Object result = parser.parseValue('2020-06-15T10:30:00Z');
		Assert.isNotNull(result);
	}

	@IsTest
	private static void testParseValueWithDateLiteral() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();
		Object result = parser.parseValue('TODAY');
		Assert.areEqual('TODAY', (String) result);
	}

	@IsTest
	private static void testConditionWithUnknownOperator() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();
		Soql.Condition condition = parser.parseCondition('Amount = 5000');
		Assert.isNotNull(condition);
		Assert.areEqual('Amount', condition.property);
	}

	@IsTest
	private static void testFindKeywordPositions() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();
		Map<String, Integer> positions = parser.findKeywordPositions('SELECT Id FROM Account WHERE Name = \'Test\'');
		Assert.isTrue(positions.containsKey('SELECT'));
		Assert.isTrue(positions.containsKey('FROM'));
		Assert.isTrue(positions.containsKey('WHERE'));
	}

	@IsTest
	private static void testExtractClause() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();
		String query = 'SELECT Id, Name FROM Account WHERE Active = true';
		Map<String, Integer> positions = parser.findKeywordPositions(query);
		String selectClause = parser.extractClause(query, positions, 'SELECT', 'FROM');
		Assert.isTrue(selectClause.containsIgnoreCase('Id'));
		Assert.isTrue(selectClause.containsIgnoreCase('Name'));
	}

	@IsTest
	private static void testParseValueWithSubqueryInList() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();
		Object result = parser.parseValue('(SELECT Id FROM Account)');
		Assert.areEqual('(SELECT Id FROM Account)', (String) result);
	}

	@IsTest
	private static void testParseValueWithInvalidDate() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();
		Object result = parser.parseValue('2025-02-30');
		Assert.areEqual('2025-02-30', (String) result);
	}

	@IsTest
	private static void testForReference() {
		DatabaseLayer.useMocks();
		String input = 'SELECT Id FROM Account FOR REFERENCE';
		Soql query = DatabaseLayer.newSoql(input);
		String output = query?.toString();
		Assert.areEqual(input, output);
	}

	@IsTest
	private static void testForView() {
		DatabaseLayer.useMocks();
		String input = 'SELECT Id FROM Account FOR VIEW';
		Soql query = DatabaseLayer.newSoql(input);
		String output = query?.toString();
		Assert.areEqual(input, output);
	}

	@IsTest
	private static void testHavingWithComplexLogic() {
		DatabaseLayer.useMocks();
		String input = 'SELECT AccountId, COUNT(Id) FROM Opportunity GROUP BY AccountId HAVING COUNT(Id) > 5 AND Amount > 10000';
		Soql query = DatabaseLayer.newSoql(input);
		String output = query?.toString();
		Assert.areEqual(input, output);
	}

	@IsTest
	private static void testParseValueWithInvalidDateFormat() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();
		Object result = parser.parseValue('20200615XX');
		Assert.areEqual('20200615XX', (String) result);
	}

	@IsTest
	private static void testParseValueWithNonNumericDateParts() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();
		Object result = parser.parseValue('XXXX-06-15');
		Assert.areEqual('XXXX-06-15', (String) result);
	}

	@IsTest
	private static void testParseValueWithTooShortDateLiteral() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();
		Object result = parser.parseValue('2020-06');
		Assert.areEqual('2020-06', (String) result);
	}

}
