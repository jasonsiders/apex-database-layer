/**
 * @description Test class for SoqlParser - validates SOQL string parsing functionality
 */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts,PMD.MethodNamingConventions')
@IsTest
private class SoqlParserTest {
	/**
	 * @description Tests parsing a basic SELECT query with simple field selection
	 */
	@IsTest
	private static void shouldParseBasicSelectFromQuery() {
		String soqlString = 'SELECT Id, Name FROM Account';

		Test.startTest();
		Soql query = DatabaseLayer.Soql.newQuery(soqlString);
		Test.stopTest();

		String expected = 'SELECT Id, Name FROM Account';
		Assert.areEqual(expected, query?.toString(), 'Query string mismatch');
	}

	/**
	 * @description Tests parsing SELECT query with WHERE clause
	 */
	@IsTest
	private static void shouldParseQueryWithWhereClause() {
		String soqlString = 'SELECT Id FROM User WHERE IsActive = true';

		Test.startTest();
		Soql query = DatabaseLayer.Soql.newQuery(soqlString);
		Test.stopTest();

		String expected = 'SELECT Id FROM User WHERE IsActive = true';
		Assert.areEqual(expected, query?.toString(), 'Query string mismatch');
	}

	/**
	 * @description Tests parsing SELECT query with bind variables
	 */
	@IsTest
	private static void shouldParseQueryWithBindVariables() {
		String soqlString = 'SELECT Id FROM User WHERE Id = :userId';

		Test.startTest();
		Soql query = DatabaseLayer.Soql.newQuery(soqlString);
		Test.stopTest();

		String expected = 'SELECT Id FROM User WHERE Id = :userId';
		Assert.areEqual(expected, query?.toString(), 'Query string mismatch');
	}

	/**
	 * @description Tests parsing SELECT query with parent field references
	 */
	@IsTest
	private static void shouldParseQueryWithParentFields() {
		String soqlString = 'SELECT Id, Account.Name FROM Opportunity';

		Test.startTest();
		Soql query = DatabaseLayer.Soql.newQuery(soqlString);
		Test.stopTest();

		String expected = 'SELECT Id, Account.Name FROM Opportunity';
		Assert.areEqual(expected, query?.toString(), 'Query string mismatch');
	}

	/**
	 * @description Tests parsing SELECT query with multiple level parent field references
	 */
	@IsTest
	private static void shouldParseQueryWithMultiLevelParentFields() {
		String soqlString = 'SELECT Id, Account.Owner.Name FROM Opportunity';

		Test.startTest();
		Soql query = DatabaseLayer.Soql.newQuery(soqlString);
		Test.stopTest();

		String expected = 'SELECT Id, Account.Owner.Name FROM Opportunity';
		Assert.areEqual(expected, query?.toString(), 'Query string mismatch');
	}

	/**
	 * @description Tests parsing SELECT query with ORDER BY clause
	 */
	@IsTest
	private static void shouldParseQueryWithOrderBy() {
		String soqlString = 'SELECT Id FROM User ORDER BY CreatedDate DESC';

		Test.startTest();
		Soql query = DatabaseLayer.Soql.newQuery(soqlString);
		Test.stopTest();

		String expected = 'SELECT Id FROM User ORDER BY CreatedDate DESC';
		// Note: The builder may add NULLS LAST by default
		Assert.isTrue(query?.toString()?.contains('ORDER BY CreatedDate DESC'), 'Query should contain ORDER BY clause');
	}

	/**
	 * @description Tests parsing SELECT query with ORDER BY and NULLS LAST
	 */
	@IsTest
	private static void shouldParseQueryWithOrderByNullsLast() {
		String soqlString = 'SELECT Id FROM User ORDER BY CreatedDate DESC NULLS LAST';

		Test.startTest();
		Soql query = DatabaseLayer.Soql.newQuery(soqlString);
		Test.stopTest();

		String expected = 'SELECT Id FROM User ORDER BY CreatedDate DESC NULLS LAST';
		Assert.areEqual(expected, query?.toString(), 'Query string mismatch');
	}

	/**
	 * @description Tests parsing SELECT query with multiple ORDER BY fields
	 */
	@IsTest
	private static void shouldParseQueryWithMultipleOrderByFields() {
		String soqlString = 'SELECT Id FROM User ORDER BY Name ASC, CreatedDate DESC';

		Test.startTest();
		Soql query = DatabaseLayer.Soql.newQuery(soqlString);
		Test.stopTest();

		Assert.isTrue(query?.toString()?.contains('ORDER BY'), 'Query should contain ORDER BY clause');
		Assert.isTrue(query?.toString()?.contains('Name'), 'Query should order by Name');
		Assert.isTrue(query?.toString()?.contains('CreatedDate'), 'Query should order by CreatedDate');
	}

	/**
	 * @description Tests parsing SELECT query with LIMIT clause
	 */
	@IsTest
	private static void shouldParseQueryWithLimit() {
		String soqlString = 'SELECT Id FROM User LIMIT 10';

		Test.startTest();
		Soql query = DatabaseLayer.Soql.newQuery(soqlString);
		Test.stopTest();

		String expected = 'SELECT Id FROM User LIMIT 10';
		Assert.areEqual(expected, query?.toString(), 'Query string mismatch');
	}

	/**
	 * @description Tests parsing SELECT query with LIMIT and OFFSET
	 */
	@IsTest
	private static void shouldParseQueryWithLimitAndOffset() {
		String soqlString = 'SELECT Id FROM User LIMIT 10 OFFSET 5';

		Test.startTest();
		Soql query = DatabaseLayer.Soql.newQuery(soqlString);
		Test.stopTest();

		String expected = 'SELECT Id FROM User LIMIT 10 OFFSET 5';
		Assert.areEqual(expected, query?.toString(), 'Query string mismatch');
	}

	/**
	 * @description Tests parsing SELECT query with WHERE and AND conditions
	 */
	@IsTest
	private static void shouldParseQueryWithAndConditions() {
		String soqlString = 'SELECT Id FROM User WHERE IsActive = true AND Name = \'Test\'';

		Test.startTest();
		Soql query = DatabaseLayer.Soql.newQuery(soqlString);
		Test.stopTest();

		String result = query?.toString();
		Assert.isTrue(result?.contains('WHERE'), 'Query should contain WHERE clause');
		Assert.isTrue(result?.contains('IsActive = true'), 'Query should filter by IsActive');
		Assert.isTrue(result?.contains('Name = \'Test\''), 'Query should filter by Name');
	}

	/**
	 * @description Tests parsing SELECT query with WHERE and OR conditions
	 */
	@IsTest
	private static void shouldParseQueryWithOrConditions() {
		String soqlString = 'SELECT Id FROM User WHERE IsActive = true OR Name = \'Test\'';

		Test.startTest();
		Soql query = DatabaseLayer.Soql.newQuery(soqlString);
		Test.stopTest();

		String result = query?.toString();
		Assert.isTrue(result?.contains('WHERE'), 'Query should contain WHERE clause');
		Assert.isTrue(result?.contains('IsActive = true'), 'Query should filter by IsActive');
		Assert.isTrue(result?.contains('Name = \'Test\''), 'Query should filter by Name');
	}

	/**
	 * @description Tests parsing SELECT query with date literals
	 */
	@IsTest
	private static void shouldParseQueryWithDateLiterals() {
		String soqlString = 'SELECT Id FROM Account WHERE CreatedDate = TODAY';

		Test.startTest();
		Soql query = DatabaseLayer.Soql.newQuery(soqlString);
		Test.stopTest();

		String result = query?.toString();
		Assert.isTrue(result?.contains('WHERE'), 'Query should contain WHERE clause');
		Assert.isTrue(result?.contains('CreatedDate'), 'Query should filter by CreatedDate');
	}

	/**
	 * @description Tests parsing SELECT query with COUNT aggregate function
	 */
	@IsTest
	private static void shouldParseQueryWithCountFunction() {
		String soqlString = 'SELECT COUNT(Id) FROM User';

		Test.startTest();
		Soql query = DatabaseLayer.Soql.newQuery(soqlString);
		Test.stopTest();

		String expected = 'SELECT COUNT(Id) FROM User';
		Assert.areEqual(expected, query?.toString(), 'Query string mismatch');
	}

	/**
	 * @description Tests parsing SELECT query with multiple aggregate functions
	 */
	@IsTest
	private static void shouldParseQueryWithMultipleAggregateFunctions() {
		String soqlString = 'SELECT COUNT(Id), AVG(NumberOfEmployees), SUM(NumberOfEmployees) FROM Account';

		Test.startTest();
		Soql query = DatabaseLayer.Soql.newQuery(soqlString);
		Test.stopTest();

		String result = query?.toString();
		Assert.isTrue(result?.contains('COUNT(Id)'), 'Query should contain COUNT function');
		Assert.isTrue(result?.contains('AVG(NumberOfEmployees)'), 'Query should contain AVG function');
		Assert.isTrue(result?.contains('SUM(NumberOfEmployees)'), 'Query should contain SUM function');
	}

	/**
	 * @description Tests parsing SELECT query with GROUP BY clause
	 */
	@IsTest
	private static void shouldParseQueryWithGroupBy() {
		String soqlString = 'SELECT ProfileId FROM User GROUP BY ProfileId';

		Test.startTest();
		Soql query = DatabaseLayer.Soql.newQuery(soqlString);
		Test.stopTest();

		String expected = 'SELECT ProfileId FROM User GROUP BY ProfileId';
		Assert.areEqual(expected, query?.toString(), 'Query string mismatch');
	}

	/**
	 * @description Tests parsing SELECT query with parent field in GROUP BY
	 */
	@IsTest
	private static void shouldParseQueryWithParentFieldGroupBy() {
		String soqlString = 'SELECT Owner.ProfileId FROM Account GROUP BY Owner.ProfileId';

		Test.startTest();
		Soql query = DatabaseLayer.Soql.newQuery(soqlString);
		Test.stopTest();

		String result = query?.toString();
		Assert.isTrue(result?.contains('GROUP BY'), 'Query should contain GROUP BY clause');
		Assert.isTrue(result?.contains('Owner.ProfileId'), 'Query should group by Owner.ProfileId');
	}

	/**
	 * @description Tests parsing SELECT query with USING SCOPE clause
	 */
	@IsTest
	private static void shouldParseQueryWithUsingScope() {
		String soqlString = 'SELECT Id FROM User USING SCOPE EVERYTHING';

		Test.startTest();
		Soql query = DatabaseLayer.Soql.newQuery(soqlString);
		Test.stopTest();

		String expected = 'SELECT Id FROM User USING SCOPE EVERYTHING';
		Assert.areEqual(expected, query?.toString(), 'Query string mismatch');
	}

	/**
	 * @description Tests parsing SELECT query with FOR VIEW clause
	 */
	@IsTest
	private static void shouldParseQueryWithForView() {
		String soqlString = 'SELECT Id FROM User FOR VIEW';

		Test.startTest();
		Soql query = DatabaseLayer.Soql.newQuery(soqlString);
		Test.stopTest();

		String expected = 'SELECT Id FROM User FOR VIEW';
		Assert.areEqual(expected, query?.toString(), 'Query string mismatch');
	}

	/**
	 * @description Tests parsing SELECT query with WITH SECURITY_ENFORCED
	 */
	@IsTest
	private static void shouldParseQueryWithSecurityEnforced() {
		String soqlString = 'SELECT Id FROM User WITH SECURITY_ENFORCED';

		Test.startTest();
		Soql query = DatabaseLayer.Soql.newQuery(soqlString);
		Test.stopTest();

		String expected = 'SELECT Id FROM User WITH SECURITY_ENFORCED';
		Assert.areEqual(expected, query?.toString(), 'Query string mismatch');
	}

	/**
	 * @description Tests parsing a complex SELECT query with multiple clauses
	 */
	@IsTest
	private static void shouldParseComplexQuery() {
		String soqlString = 'SELECT Id, Name FROM Account WHERE CreatedDate = TODAY ORDER BY Name ASC LIMIT 10';

		Test.startTest();
		Soql query = DatabaseLayer.Soql.newQuery(soqlString);
		Test.stopTest();

		String result = query?.toString();
		Assert.isTrue(result?.contains('SELECT Id, Name'), 'Query should select Id and Name');
		Assert.isTrue(result?.contains('FROM Account'), 'Query should query Account');
		Assert.isTrue(result?.contains('WHERE'), 'Query should have WHERE clause');
		Assert.isTrue(result?.contains('ORDER BY'), 'Query should have ORDER BY clause');
		Assert.isTrue(result?.contains('LIMIT 10'), 'Query should have LIMIT 10');
	}

	/**
	 * @description Tests that parser throws exception for invalid SOQL (missing FROM)
	 */
	@IsTest
	private static void shouldThrowExceptionForMissingFrom() {
		String soqlString = 'SELECT Id, Name';

		Test.startTest();
		try {
			Soql query = DatabaseLayer.Soql.newQuery(soqlString);
			Assert.fail('Should have thrown ParserException for missing FROM clause');
		} catch (Soql.Parser.ParserException e) {
			Assert.isTrue(e?.getMessage()?.contains('FROM'), 'Exception should mention FROM clause');
		}
		Test.stopTest();
	}

	/**
	 * @description Tests that parser throws exception for invalid SOQL (missing SELECT)
	 */
	@IsTest
	private static void shouldThrowExceptionForMissingSelect() {
		String soqlString = 'FROM Account';

		Test.startTest();
		try {
			Soql query = DatabaseLayer.Soql.newQuery(soqlString);
			Assert.fail('Should have thrown ParserException for missing SELECT clause');
		} catch (Soql.Parser.ParserException e) {
			Assert.isTrue(e?.getMessage()?.contains('SELECT'), 'Exception should mention SELECT clause');
		}
		Test.stopTest();
	}

	/**
	 * @description Tests that parser throws exception for blank query
	 */
	@IsTest
	private static void shouldThrowExceptionForBlankQuery() {
		String soqlString = '';

		Test.startTest();
		try {
			Soql query = DatabaseLayer.Soql.newQuery(soqlString);
			Assert.fail('Should have thrown ParserException for blank query');
		} catch (Soql.Parser.ParserException e) {
			Assert.isTrue(e?.getMessage()?.contains('blank'), 'Exception should mention blank query');
		}
		Test.stopTest();
	}

	/**
	 * @description Tests that parser throws exception for invalid SObject type
	 */
	@IsTest
	private static void shouldThrowExceptionForInvalidSObjectType() {
		String soqlString = 'SELECT Id FROM InvalidObject123';

		Test.startTest();
		try {
			Soql query = DatabaseLayer.Soql.newQuery(soqlString);
			Assert.fail('Should have thrown ParserException for invalid SObject type');
		} catch (Soql.Parser.ParserException e) {
			Assert.isTrue(
				e?.getMessage()?.contains('Invalid SObject') || e?.getMessage()?.contains('InvalidObject123'),
				'Exception should mention invalid SObject: ' + e?.getMessage()
			);
		}
		Test.stopTest();
	}

	/**
	 * @description Tests parsing query with string value containing quotes
	 */
	@IsTest
	private static void shouldParseQueryWithQuotedStringValue() {
		String soqlString = 'SELECT Id FROM Account WHERE Name = \'Test Account\'';

		Test.startTest();
		Soql query = DatabaseLayer.Soql.newQuery(soqlString);
		Test.stopTest();

		String result = query?.toString();
		Assert.isTrue(result?.contains('WHERE'), 'Query should contain WHERE clause');
		Assert.isTrue(result?.contains('Name'), 'Query should filter by Name');
	}

	/**
	 * @description Tests parsing query with numeric value
	 */
	@IsTest
	private static void shouldParseQueryWithNumericValue() {
		String soqlString = 'SELECT Id FROM Account WHERE NumberOfEmployees > 100';

		Test.startTest();
		Soql query = DatabaseLayer.Soql.newQuery(soqlString);
		Test.stopTest();

		String result = query?.toString();
		Assert.isTrue(result?.contains('WHERE'), 'Query should contain WHERE clause');
		Assert.isTrue(result?.contains('NumberOfEmployees'), 'Query should filter by NumberOfEmployees');
	}

	/**
	 * @description Tests parsing query with different comparison operators
	 */
	@IsTest
	private static void shouldParseQueryWithDifferentOperators() {
		Test.startTest();

		// Test EQUALS
		Soql query1 = DatabaseLayer.Soql.newQuery('SELECT Id FROM Account WHERE Name = \'Test\'');
		Assert.isTrue(query1?.toString()?.contains('WHERE'), 'EQUALS query should have WHERE');

		// Test NOT_EQUALS
		Soql query2 = DatabaseLayer.Soql.newQuery('SELECT Id FROM Account WHERE Name != \'Test\'');
		Assert.isTrue(query2?.toString()?.contains('WHERE'), 'NOT_EQUALS query should have WHERE');

		// Test LESS_THAN
		Soql query3 = DatabaseLayer.Soql.newQuery('SELECT Id FROM Account WHERE NumberOfEmployees < 100');
		Assert.isTrue(query3?.toString()?.contains('WHERE'), 'LESS_THAN query should have WHERE');

		// Test GREATER_THAN
		Soql query4 = DatabaseLayer.Soql.newQuery('SELECT Id FROM Account WHERE NumberOfEmployees > 100');
		Assert.isTrue(query4?.toString()?.contains('WHERE'), 'GREATER_THAN query should have WHERE');

		Test.stopTest();
	}

	/**
	 * @description Tests that parsed query can be executed
	 */
	@IsTest
	private static void shouldExecuteParsedQuery() {
		String soqlString = 'SELECT Id FROM User LIMIT 1';

		Test.startTest();
		Soql query = DatabaseLayer.Soql.newQuery(soqlString);
		List<User> users = query?.query();
		Test.stopTest();

		Assert.isNotNull(users, 'Query should return results');
		Assert.isTrue(users?.size() <= 1, 'Query should respect LIMIT 1');
	}

	/**
	 * @description Tests that parsed query with bind variables can be executed
	 */
	@IsTest
	private static void shouldExecuteParsedQueryWithBinds() {
		String soqlString = 'SELECT Id FROM User WHERE Id = :userId LIMIT 1';

		Test.startTest();
		Soql query = DatabaseLayer.Soql.newQuery(soqlString);
		// Add the bind value
		User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
		query?.addBind('userId', currentUser?.Id);
		List<User> users = query?.query();
		Test.stopTest();

		Assert.isNotNull(users, 'Query should return results');
		Assert.areEqual(1, users?.size(), 'Query should return the current user');
		Assert.areEqual(currentUser?.Id, users[0]?.Id, 'Should return the correct user');
	}
}
