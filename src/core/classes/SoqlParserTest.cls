@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs,PMD.CyclomaticComplexity')
@IsTest
private class SoqlParserTest {
	@IsTest
	private static void shouldRoundTripSimpleQuery() {
		DatabaseLayer.useMocks();
		String queryStr = 'SELECT Id, AccountId FROM Opportunity WHERE IsClosed = true ORDER BY CloseDate DESC LIMIT 1';
		Soql soql = DatabaseLayer.newSoql(queryStr);

		Test.startTest();
		String result = soql?.toString();
		Test.stopTest();

		Assert.areEqual(queryStr, result, 'Expected exact query round-trip');
	}

	@IsTest
	private static void shouldPreserveStateAfterMutation() {
		DatabaseLayer.useMocks();
		String queryStr = 'SELECT Id, AccountId FROM Opportunity WHERE IsClosed = true ORDER BY CloseDate DESC LIMIT 1';
		Soql soql = DatabaseLayer.newSoql(queryStr);
		soql.addSelect('CloseDate');
		soql.addWhere('Amount', Soql.GREATER_THAN, 100000);

		Test.startTest();
		String result = soql?.toString();
		Test.stopTest();

		String expected = 'SELECT Id, AccountId, CloseDate FROM Opportunity WHERE IsClosed = true AND Amount > 100000 ORDER BY CloseDate DESC LIMIT 1';
		Assert.areEqual(expected, result, 'Expected fields and conditions appended after parse');
	}

	@IsTest
	private static void shouldRoundTripOrWhere() {
		DatabaseLayer.useMocks();
		String queryStr = 'SELECT Id FROM Account WHERE Name = \'Foo\' OR Name = \'Bar\'';
		Soql soql = DatabaseLayer.newSoql(queryStr);

		Test.startTest();
		String result = soql?.toString();
		Test.stopTest();

		Assert.areEqual(queryStr, result, 'Expected exact query round-trip');
	}

	@IsTest
	private static void shouldRoundTripNestedAndOr() {
		DatabaseLayer.useMocks();
		String queryStr = 'SELECT Id FROM Contact WHERE (FirstName = \'John\' AND LastName = \'Doe\') OR Email != null';
		Soql soql = DatabaseLayer.newSoql(queryStr);

		Test.startTest();
		String result = soql?.toString();
		Test.stopTest();

		Assert.areEqual(queryStr, result, 'Expected exact query round-trip');
	}

	@IsTest
	private static void shouldRoundTripAggregateSelect() {
		DatabaseLayer.useMocks();
		String queryStr = 'SELECT COUNT(Id), SUM(Amount) totalAmount FROM Opportunity';
		Soql soql = DatabaseLayer.newSoql(queryStr);

		Test.startTest();
		String result = soql?.toString();
		Test.stopTest();

		Assert.areEqual(queryStr, result, 'Expected exact query round-trip');
	}

	@IsTest
	private static void shouldRoundTripSubqueryInSelect() {
		DatabaseLayer.useMocks();
		String queryStr = 'SELECT Id, (SELECT Id, LastName FROM Contacts) FROM Account';
		Soql soql = DatabaseLayer.newSoql(queryStr);

		Test.startTest();
		String result = soql?.toString();
		Test.stopTest();

		Assert.areEqual(queryStr, result, 'Expected exact query round-trip');
	}

	@IsTest
	private static void shouldRoundTripMultiFieldOrderBy() {
		DatabaseLayer.useMocks();
		String queryStr = 'SELECT Id FROM Account ORDER BY Name ASC, CreatedDate DESC';
		Soql soql = DatabaseLayer.newSoql(queryStr);

		Test.startTest();
		String result = soql?.toString();
		Test.stopTest();

		Assert.areEqual(queryStr, result, 'Expected exact query round-trip');
	}

	@IsTest
	private static void shouldRoundTripGroupByWithHaving() {
		DatabaseLayer.useMocks();
		String queryStr = 'SELECT AccountId, COUNT(Id) FROM Opportunity GROUP BY AccountId HAVING COUNT(Id) > 5';
		Soql soql = DatabaseLayer.newSoql(queryStr);

		Test.startTest();
		String result = soql?.toString();
		Test.stopTest();

		Assert.areEqual(queryStr, result, 'Expected exact query round-trip');
	}

	@IsTest
	private static void shouldRoundTripUsingScope() {
		DatabaseLayer.useMocks();
		String queryStr = 'SELECT Id FROM Account USING SCOPE MINE';
		Soql soql = DatabaseLayer.newSoql(queryStr);

		Test.startTest();
		String result = soql?.toString();
		Test.stopTest();

		Assert.areEqual(queryStr, result, 'Expected exact query round-trip');
	}

	@IsTest
	private static void shouldRoundTripWithSecurityEnforced() {
		DatabaseLayer.useMocks();
		String queryStr = 'SELECT Id FROM Account WITH SECURITY_ENFORCED';
		Soql soql = DatabaseLayer.newSoql(queryStr);

		Test.startTest();
		String result = soql?.toString();
		Test.stopTest();

		Assert.areEqual(queryStr, result, 'Expected exact query round-trip');
	}

	@IsTest
	private static void shouldRoundTripLimitAndOffset() {
		DatabaseLayer.useMocks();
		String queryStr = 'SELECT Id FROM Account LIMIT 10 OFFSET 20';
		Soql soql = DatabaseLayer.newSoql(queryStr);

		Test.startTest();
		String result = soql?.toString();
		Test.stopTest();

		Assert.areEqual(queryStr, result, 'Expected exact query round-trip');
	}

	@IsTest
	private static void shouldRoundTripForUpdate() {
		DatabaseLayer.useMocks();
		String queryStr = 'SELECT Id FROM Account FOR UPDATE';
		Soql soql = DatabaseLayer.newSoql(queryStr);

		Test.startTest();
		String result = soql?.toString();
		Test.stopTest();

		Assert.areEqual(queryStr, result, 'Expected exact query round-trip');
	}

	@IsTest
	private static void shouldRoundTripParentFieldNotation() {
		DatabaseLayer.useMocks();
		String queryStr = 'SELECT Id, Account.Name FROM Contact WHERE Account.Industry = \'Technology\'';
		Soql soql = DatabaseLayer.newSoql(queryStr);

		Test.startTest();
		String result = soql?.toString();
		Test.stopTest();

		Assert.areEqual(queryStr, result, 'Expected exact query round-trip');
	}

	@IsTest
	private static void shouldRoundTripInList() {
		DatabaseLayer.useMocks();
		String queryStr = 'SELECT Id FROM Account WHERE Name IN (\'Acme\', \'Salesforce\')';
		Soql soql = DatabaseLayer.newSoql(queryStr);

		Test.startTest();
		String result = soql?.toString();
		Test.stopTest();

		Assert.areEqual(queryStr, result, 'Expected exact query round-trip');
	}

	@IsTest
	private static void shouldRoundTripInOperatorOnInPrefixedField() {
		// Regression: word-boundary guard must prevent 'IN' matching at position 0 of 'INDUSTRY'
		DatabaseLayer.useMocks();
		String queryStr = 'SELECT Id FROM Account WHERE Industry IN (\'Technology\', \'Finance\')';
		Soql soql = DatabaseLayer.newSoql(queryStr);

		Test.startTest();
		String result = soql?.toString();
		Test.stopTest();

		Assert.areEqual(queryStr, result, 'Expected exact query round-trip');
	}

	@IsTest
	private static void shouldRoundTripNestedAndInsideOr() {
		DatabaseLayer.useMocks();
		String queryStr = 'SELECT Id FROM Opportunity WHERE (Amount > 1000 AND IsClosed = false) OR (Amount > 5000 AND IsClosed = true)';
		Soql soql = DatabaseLayer.newSoql(queryStr);

		Test.startTest();
		String result = soql?.toString();
		Test.stopTest();

		Assert.areEqual(queryStr, result, 'Expected exact query round-trip');
	}

	@IsTest
	private static void shouldRoundTripAllRows() {
		DatabaseLayer.useMocks();
		String queryStr = 'SELECT Id FROM Account ALL ROWS';
		Soql soql = DatabaseLayer.newSoql(queryStr);

		Test.startTest();
		String result = soql?.toString();
		Test.stopTest();

		Assert.areEqual(queryStr, result, 'Expected exact query round-trip');
	}

	@IsTest
	private static void shouldRoundTripDateFilter() {
		DatabaseLayer.useMocks();
		String queryStr = 'SELECT Id FROM Account WHERE CreatedDate > 2020-01-01';
		Soql soql = DatabaseLayer.newSoql(queryStr);

		Test.startTest();
		String result = soql?.toString();
		Test.stopTest();

		Assert.areEqual(queryStr, result, 'Expected exact query round-trip');
	}

	@IsTest
	private static void shouldRoundTripBindVariable() {
		DatabaseLayer.useMocks();
		String queryStr = 'SELECT Id FROM Account WHERE Name = :accountName';
		Soql soql = DatabaseLayer.newSoql(queryStr);

		Test.startTest();
		String result = soql?.toString();
		Test.stopTest();

		Assert.areEqual(queryStr, result, 'Expected exact query round-trip');
	}

	@IsTest
	private static void shouldRoundTripMultiFieldGroupBy() {
		DatabaseLayer.useMocks();
		String queryStr = 'SELECT AccountId, StageName, COUNT(Id) FROM Opportunity GROUP BY AccountId, StageName';
		Soql soql = DatabaseLayer.newSoql(queryStr);

		Test.startTest();
		String result = soql?.toString();
		Test.stopTest();

		Assert.areEqual(queryStr, result, 'Expected exact query round-trip');
	}

	@IsTest
	private static void shouldRoundTripComplexNestedWhere() {
		DatabaseLayer.useMocks();
		String queryStr = 'SELECT Id FROM Account WHERE (Name = \'test\' AND Industry = \'Tech\') OR (BillingCity = \'SF\' AND BillingState = \'CA\')';
		Soql soql = DatabaseLayer.newSoql(queryStr);

		Test.startTest();
		String result = soql?.toString();
		Test.stopTest();

		Assert.areEqual(queryStr, result, 'Expected exact query round-trip');
	}

	@IsTest
	private static void shouldRoundTripNotInOperator() {
		DatabaseLayer.useMocks();
		String queryStr = 'SELECT Id FROM Account WHERE Name NOT IN (\'A\', \'B\')';
		Soql soql = DatabaseLayer.newSoql(queryStr);

		Test.startTest();
		String result = soql?.toString();
		Test.stopTest();

		Assert.areEqual(queryStr, result, 'Expected exact query round-trip');
	}

	@IsTest
	private static void shouldRoundTripMultipleAggregations() {
		DatabaseLayer.useMocks();
		String queryStr = 'SELECT COUNT(Id) count, AVG(Amount) avgAmount, MAX(Amount) maxAmount FROM Opportunity';
		Soql soql = DatabaseLayer.newSoql(queryStr);

		Test.startTest();
		String result = soql?.toString();
		Test.stopTest();

		Assert.areEqual(queryStr, result, 'Expected exact query round-trip');
	}

	@IsTest
	private static void shouldRoundTripDateTimeValue() {
		DatabaseLayer.useMocks();
		String queryStr = 'SELECT Id FROM Account WHERE CreatedDate > 2020-01-01T10:00:00Z';
		Soql soql = DatabaseLayer.newSoql(queryStr);

		Test.startTest();
		String result = soql?.toString();
		Test.stopTest();

		Assert.areEqual(queryStr, result, 'Expected exact query round-trip');
	}

	@IsTest
	private static void shouldRoundTripNullComparison() {
		DatabaseLayer.useMocks();
		String queryStr = 'SELECT Id FROM Account WHERE BillingCity = null';
		Soql soql = DatabaseLayer.newSoql(queryStr);

		Test.startTest();
		String result = soql?.toString();
		Test.stopTest();

		Assert.areEqual(queryStr, result, 'Expected exact query round-trip');
	}

	@IsTest
	private static void shouldRoundTripBooleanComparison() {
		DatabaseLayer.useMocks();
		String queryStr = 'SELECT Id FROM Opportunity WHERE IsClosed = true';
		Soql soql = DatabaseLayer.newSoql(queryStr);

		Test.startTest();
		String result = soql?.toString();
		Test.stopTest();

		Assert.areEqual(queryStr, result, 'Expected exact query round-trip');
	}

	@IsTest
	private static void shouldRoundTripGreaterOrEqualFilter() {
		DatabaseLayer.useMocks();
		String queryStr = 'SELECT Id FROM Opportunity WHERE Amount >= 10000';
		Soql soql = DatabaseLayer.newSoql(queryStr);

		Test.startTest();
		String result = soql?.toString();
		Test.stopTest();

		Assert.areEqual(queryStr, result, 'Expected exact query round-trip');
	}

	@IsTest
	private static void shouldRoundTripLessOrEqualFilter() {
		DatabaseLayer.useMocks();
		String queryStr = 'SELECT Id FROM Account WHERE NumberOfEmployees <= 100';
		Soql soql = DatabaseLayer.newSoql(queryStr);

		Test.startTest();
		String result = soql?.toString();
		Test.stopTest();

		Assert.areEqual(queryStr, result, 'Expected exact query round-trip');
	}

	@IsTest
	private static void shouldRoundTripForReference() {
		DatabaseLayer.useMocks();
		String queryStr = 'SELECT Id FROM Account FOR REFERENCE';
		Soql soql = DatabaseLayer.newSoql(queryStr);

		Test.startTest();
		String result = soql?.toString();
		Test.stopTest();

		Assert.areEqual(queryStr, result, 'Expected exact query round-trip');
	}

	@IsTest
	private static void shouldRoundTripForView() {
		DatabaseLayer.useMocks();
		String queryStr = 'SELECT Id FROM Account FOR VIEW';
		Soql soql = DatabaseLayer.newSoql(queryStr);

		Test.startTest();
		String result = soql?.toString();
		Test.stopTest();

		Assert.areEqual(queryStr, result, 'Expected exact query round-trip');
	}

	@IsTest
	private static void shouldRoundTripHavingWithAndLogic() {
		DatabaseLayer.useMocks();
		String queryStr = 'SELECT AccountId, COUNT(Id) FROM Opportunity GROUP BY AccountId HAVING COUNT(Id) > 5 AND Amount > 10000';
		Soql soql = DatabaseLayer.newSoql(queryStr);

		Test.startTest();
		String result = soql?.toString();
		Test.stopTest();

		Assert.areEqual(queryStr, result, 'Expected exact query round-trip');
	}

	@IsTest
	private static void shouldRoundTripLikeOperator() {
		DatabaseLayer.useMocks();
		String queryStr = 'SELECT Id FROM Account WHERE Name LIKE \'%Test%\'';
		Soql soql = DatabaseLayer.newSoql(queryStr);

		Test.startTest();
		String result = soql?.toString();
		Test.stopTest();

		Assert.areEqual(queryStr, result, 'Expected exact query round-trip');
	}

	@IsTest
	private static void shouldSkipSubqueryMissingFrom() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();
		Soql.Builder builder = DatabaseLayer.newSoql('SELECT Id FROM Account');

		Test.startTest();
		parser.parseSubquery(builder, '(SELECT Id, Name)');
		Test.stopTest();

		Assert.isNotNull(builder?.toString(), 'Expected builder to remain valid after malformed subquery');
	}

	@IsTest
	private static void shouldReturnStringLengthForUnclosedParen() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();

		Test.startTest();
		Integer result = parser.findMatchingParen('(unclosed text here', 0);
		Test.stopTest();

		Assert.areEqual(19, result, 'Expected string length when no closing paren found');
	}

	@IsTest
	private static void shouldDefaultEqualsForNoOperator() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();

		Test.startTest();
		Soql.Condition condition = parser.parseCondition('Name');
		Test.stopTest();

		Assert.areEqual('Name', condition.property, 'Expected field name preserved');
		Assert.areEqual('=', condition.operator.toString(), 'Expected default = operator');
		Assert.isNull(condition.value, 'Expected null value for bare field');
	}

	@IsTest
	private static void shouldParseNullLiteral() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();

		Test.startTest();
		Object result = parser.parseValue('null');
		Test.stopTest();

		Assert.isNull(result, 'Expected null for null literal');
	}

	@IsTest
	private static void shouldParseTrueLiteral() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();

		Test.startTest();
		Object result = parser.parseValue('true');
		Test.stopTest();

		Assert.areEqual(true, (Boolean) result, 'Expected Boolean true');
	}

	@IsTest
	private static void shouldParseFalseLiteral() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();

		Test.startTest();
		Object result = parser.parseValue('false');
		Test.stopTest();

		Assert.areEqual(false, (Boolean) result, 'Expected Boolean false');
	}

	@IsTest
	private static void shouldParseIntegerLiteral() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();

		Test.startTest();
		Object result = parser.parseValue('12345');
		Test.stopTest();

		Assert.areEqual(12345, (Integer) result, 'Expected Integer 12345');
	}

	@IsTest
	private static void shouldParseDecimalLiteral() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();

		Test.startTest();
		Object result = parser.parseValue('123.45');
		Test.stopTest();

		Assert.areEqual(123.45, (Decimal) result, 'Expected Decimal 123.45');
	}

	@IsTest
	private static void shouldParseQuotedString() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();

		Test.startTest();
		Object result = parser.parseValue('\'test value\'');
		Test.stopTest();

		Assert.areEqual('test value', (String) result, 'Expected unquoted string value');
	}

	@IsTest
	private static void shouldParseBindVariable() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();

		Test.startTest();
		Object result = parser.parseValue(':bindVar');
		Test.stopTest();

		Assert.areEqual(':bindVar', (String) result, 'Expected bind variable passed through unchanged');
	}

	@IsTest
	private static void shouldParseListValue() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();

		Test.startTest();
		Object result = parser.parseValue('(\'A\', \'B\', \'C\')');
		Test.stopTest();

		Assert.isNotNull(result, 'Expected non-null list result');
	}

	@IsTest
	private static void shouldParseDateValue() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();

		Test.startTest();
		Object result = parser.parseValue('2020-06-15');
		Test.stopTest();

		Assert.isNotNull(result, 'Expected non-null date result');
	}

	@IsTest
	private static void shouldParseDateTimeValue() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();

		Test.startTest();
		Object result = parser.parseValue('2020-06-15T10:30:00Z');
		Test.stopTest();

		Assert.isNotNull(result, 'Expected non-null datetime result');
	}

	@IsTest
	private static void shouldPassThroughSoqlDateLiteral() {
		// SOQL date functions (TODAY, LAST_WEEK, etc.) are not parseable as Date/DateTime
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();

		Test.startTest();
		Object result = parser.parseValue('TODAY');
		Test.stopTest();

		Assert.areEqual('TODAY', (String) result, 'Expected unrecognized token returned as-is');
	}

	@IsTest
	private static void shouldParseConditionFields() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();

		Test.startTest();
		Soql.Condition condition = parser.parseCondition('Amount = 5000');
		Test.stopTest();

		Assert.isNotNull(condition, 'Expected a condition to be returned');
		Assert.areEqual('Amount', condition.property, 'Expected field name parsed correctly');
	}

	@IsTest
	private static void shouldFindAllKeywordPositions() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();

		Test.startTest();
		Map<String, Integer> positions = parser.findKeywordPositions('SELECT Id FROM Account WHERE Name = \'Test\'');
		Test.stopTest();

		Assert.isTrue(positions.containsKey('SELECT'), 'Expected SELECT position');
		Assert.isTrue(positions.containsKey('FROM'), 'Expected FROM position');
		Assert.isTrue(positions.containsKey('WHERE'), 'Expected WHERE position');
	}

	@IsTest
	private static void shouldExtractSelectClause() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();
		String queryStr = 'SELECT Id, Name FROM Account WHERE Active = true';
		Map<String, Integer> positions = parser.findKeywordPositions(queryStr);

		Test.startTest();
		String selectClause = parser.extractClause(queryStr, positions, 'SELECT', 'FROM');
		Test.stopTest();

		Assert.isTrue(selectClause.containsIgnoreCase('Id'), 'Expected Id in SELECT clause');
		Assert.isTrue(selectClause.containsIgnoreCase('Name'), 'Expected Name in SELECT clause');
	}

	@IsTest
	private static void shouldPreserveSubqueryInListValue() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();

		Test.startTest();
		Object result = parser.parseValue('(SELECT Id FROM Account)');
		Test.stopTest();

		Assert.areEqual('(SELECT Id FROM Account)', (String) result, 'Expected subquery preserved as raw string');
	}

	@IsTest
	private static void shouldReturnStringForOutOfRangeDate() {
		// Feb 30 is not a real date; parser should fall back to raw string rather than throw
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();

		Test.startTest();
		Object result = parser.parseValue('2025-02-30');
		Test.stopTest();

		Assert.areEqual('2025-02-30', (String) result, 'Expected raw string for unparseable date');
	}

	@IsTest
	private static void shouldReturnStringForInvalidDateFormat() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();

		Test.startTest();
		Object result = parser.parseValue('20200615XX');
		Test.stopTest();

		Assert.areEqual('20200615XX', (String) result, 'Expected raw string for non-date token');
	}

	@IsTest
	private static void shouldReturnStringForNonNumericDate() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();

		Test.startTest();
		Object result = parser.parseValue('XXXX-06-15');
		Test.stopTest();

		Assert.areEqual('XXXX-06-15', (String) result, 'Expected raw string for non-numeric year');
	}

	@IsTest
	private static void shouldReturnStringForPartialDateString() {
		DatabaseLayer.useMocks();
		SoqlParser parser = new SoqlParser();

		Test.startTest();
		Object result = parser.parseValue('2020-06');
		Test.stopTest();

		Assert.areEqual('2020-06', (String) result, 'Expected raw string for partial date');
	}

}
