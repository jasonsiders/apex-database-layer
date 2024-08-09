@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
private class SoqlTest {
	@IsTest
	static void shouldAggregateQuery() {
		Soql.Aggregation count = new Soql.Aggregation(Soql.Function.COUNT, User.Id);
		Soql soql = (Soql) DatabaseLayer.newSoql(User.SObjectType)?.addSelect(count);

		Test.startTest();
		List<Soql.AggregateResult> results = soql?.aggregateQuery();
		Test.stopTest();

		Integer expected = Database.countQuery('SELECT COUNT() FROM User');
		Assert.areEqual(1, results?.size(), 'Wrong # of Aggregate Results');
		for (Soql.AggregateResult result : results) {
			Assert.areEqual(expected, result?.get('expr0'), 'Wrong # of users');
		}
	}

	@IsTest
	static void shouldHandleAggregateQueryErrors() {
		// Calling aggregateQuery() with a non-aggregate query will yield a System.TypeException
		Soql soql = (Soql) DatabaseLayer.newSoql(User.SObjectType);

		Test.startTest();
		try {
			soql?.aggregateQuery();
			Assert.fail('Illegal query did not throw an error');
		} catch (System.TypeException error) {
			Assert.areEqual(true, error?.getMessage()?.contains(soql?.toString()), 'Did not append query to error');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldCountQuery() {
		Soql soql = (Soql) DatabaseLayer.newSoql(User.SObjectType)
			?.addWhere('Profile.Name', Soql.EQUALS, 'System Administrator');

		Test.startTest();
		Integer results = soql?.countQuery();
		Test.stopTest();

		Integer expected = Database.countQuery(
			'SELECT COUNT() FROM User WHERE Profile.Name = \'System Administrator\''
		);
		Assert.areEqual(expected, results, 'Wrong # of countQuery results');
	}

	@IsTest
	static void shouldHandleCountQueryErrors() {
		SObjectType illegalEntity = null; // Will cause a System.QueryException when run
		Soql soql = (Soql) DatabaseLayer.newSoql(illegalEntity);

		Test.startTest();
		try {
			soql?.countQuery();
			Assert.fail('Illegal query did not throw an error');
		} catch (System.QueryException error) {
			String msg = error?.getMessage();
			Assert.areEqual(true, msg?.contains(soql?.toString()), 'Did not append query to the error');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldGetQueryLocator() {
		Soql soql = DatabaseLayer.newSoql(User.SObjectType);

		Test.startTest();
		Soql.QueryLocator locator = soql?.getQueryLocator();
		Test.stopTest();

		Assert.areNotEqual(null, locator?.getCursor(), 'Did not return Database.QueryLocator cursor');
		Assert.areEqual(soql?.toString(), locator?.getQuery(), 'Unexpected Query');
		Assert.areNotEqual(null, locator?.iterator(), 'Did not return iterator');
	}

	@IsTest
	static void shouldHandleQueryLocatorErrors() {
		String illegalFieldName = 'abcd'; // Will cause a System.QueryException when run
		Soql soql = (Soql) DatabaseLayer.newSoql(Account.SObjectType)?.addSelect(illegalFieldName);

		Test.startTest();
		try {
			soql?.getQueryLocator();
			Assert.fail('Illegal query did not throw an error');
		} catch (System.QueryException error) {
			String msg = error?.getMessage();
			Assert.areEqual(true, msg?.contains(illegalFieldName), 'Did not append query to the error');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldQueryRecords() {
		Soql soql = DatabaseLayer.newSoql(User.SObjectType);

		Test.startTest();
		List<User> users = soql?.query();
		Test.stopTest();

		Integer expected = Database.countQuery('SELECT COUNT() FROM User');
		Assert.areEqual(expected, users?.size(), 'Wrong # of Users returned');
	}

	@IsTest
	static void shouldQuerySingleRecord() {
		Soql soql = DatabaseLayer.newSoql(User.SObjectType);

		Test.startTest();
		User user = (User) soql?.queryFirst();
		Test.stopTest();

		Assert.areNotEqual(null, user, 'No records returned');
	}

	@IsTest
	static void shouldReturnNullIfNoResults() {
		Soql soql = DatabaseLayer.newSoql(Account.SObjectType);
		// No accounts have been inserted yet, so this shouldn't return anything

		Test.startTest();
		Account account = (Account) soql?.queryFirst();
		Test.stopTest();

		Assert.areEqual(null, account, 'Returned a result anyway? ' + account);
	}

	@IsTest
	static void shouldHandleQueryErrors() {
		String illegalFieldName = 'abcd'; // Will cause a System.QueryException when run
		Soql soql = (Soql) DatabaseLayer.newSoql(Account.SObjectType)?.addSelect(illegalFieldName);

		Test.startTest();
		try {
			soql?.query();
			Assert.fail('Illegal query did not throw an error');
		} catch (System.QueryException error) {
			String msg = error?.getMessage();
			Assert.areEqual(true, msg?.contains(soql?.toString()), 'Did not append query to the error');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldQueryRecordsAndCastToType() {
		Soql.Aggregation count = new Soql.Aggregation(Soql.Function.COUNT, User.Id)?.withAlias('numRecords');
		Soql soql = (Soql) DatabaseLayer.newSoql(User.SObjectType)
			?.addSelect('Profile.Name', 'profileName')
			?.addSelect(count)
			?.groupBy('Profile.Name');

		Test.startTest();
		List<SampleWrapper> results = (List<SampleWrapper>) soql?.query(List<SampleWrapper>.class);
		Test.stopTest();

		List<AggregateResult> raw = [
			SELECT Profile.Name, COUNT(Id)
			FROM User
			GROUP BY Profile.Name
		];
		Assert.areEqual(raw?.size(), results?.size(), 'Wrong # of results returned');
	}

	@IsTest
	static void shouldSetAccessLevel() {
		System.AccessLevel level = System.AccessLevel.SYSTEM_MODE;
		Soql soql = (Soql) DatabaseLayer.newSoql(User.SObjectType)?.defineAccess(level);
		Assert.areEqual(level, soql?.accessLevel, 'Did not set access level');
	}

	@IsTest
	static void shouldBindVariableToQuery() {
		Soql.Binder binder = new Soql.Binder('userId', UserInfo.getUserId());
		Soql soql = (Soql) DatabaseLayer.newSoql(User.SObjectType)
			?.addSelect(User.Username)
			?.addWhere(User.Id, Soql.EQUALS, binder);
		String expected = 'SELECT Id, Username FROM User WHERE Id = :userId';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	static void shouldDeselectAllFields() {
		Soql soql = (Soql) DatabaseLayer.newSoql(User.SObjectType)?.selectAll();
		Assert.areEqual(true, soql?.selectClauses?.size() > 1, 'Wrong # of SELECT clauses');

		Test.startTest();
		soql.deselectAll();
		Test.stopTest();

		Assert.areEqual(true, soql?.selectClauses?.isEmpty(), 'Did not clear SELECT clauses');
	}

	@IsTest
	static void shouldDeselectSpecificField() {
		Soql soql = (Soql) DatabaseLayer.newSoql(User.SObjectType)?.selectAll();
		Assert.areEqual(true, soql?.selectClauses?.size() > 1, 'Wrong # of SELECT clauses');

		Test.startTest();
		soql?.deselect(User.Username);
		Test.stopTest();

		Set<String> fields = new Set<String>(soql?.selectClauses);
		Assert.areEqual(false, fields?.contains(User.Username?.toString()), 'Did not deselect Username');
	}

	@IsTest
	static void shouldSelectAllFields() {
		Set<String> userFields = SObjectType.User?.fields?.getMap()?.keySet();

		Test.startTest();
		Soql soql = (Soql) DatabaseLayer.newSoql(User.SObjectType)?.selectAll();
		Test.stopTest();

		Assert.areEqual(userFields?.size(), soql?.selectClauses?.size(), 'Wrong # of SELECT clauses');
	}

	@IsTest
	static void shouldSelectSpecificFields() {
		Soql soql = (Soql) DatabaseLayer.newSoql(User.SObjectType)?.addSelect(User.FirstName)?.setRowLimit(1);
		String expected = 'SELECT Id, FirstName FROM User LIMIT 1';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	static void shouldSelectFieldWithAlias() {
		Soql soql = (Soql) DatabaseLayer.newSoql(User.SObjectType)
			?.addSelect(User.ProfileId, 'profile')
			?.groupBy(User.ProfileId);
		String expected = 'SELECT ProfileId profile FROM User GROUP BY ProfileId';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	static void shouldSelectAggregation() {
		Soql.Aggregation count = new Soql.Aggregation(Soql.Function.COUNT, User.Id);
		Soql soql = (Soql) DatabaseLayer.newSoql(User.SObjectType)?.addSelect(count);
		String expected = 'SELECT COUNT(Id) FROM User';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	static void shouldSelectSubquery() {
		Soql.Subquery subquery = new Soql.Subquery(User.ProfileId);
		Soql soql = (Soql) DatabaseLayer.newSoql(Profile.SObjectType)?.addSelect(subquery)?.setRowLimit(1);
		String expected = 'SELECT Id, (SELECT Id FROM Users) FROM Profile LIMIT 1';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	static void shouldSetQueryScope() {
		Soql soql = (Soql) DatabaseLayer.newSoql(User.SObjectType)?.usingScope(Soql.Scope.EVERYTHING)?.setRowLimit(1);
		String expected = 'SELECT Id FROM User USING SCOPE EVERYTHING LIMIT 1';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	static void shouldAddCriteriaToWhereClause() {
		Soql soql = (Soql) DatabaseLayer.newSoql(User.SObjectType)
			?.addWhere(User.IsActive, Soql.EQUALS, true)
			?.setRowLimit(1);
		String expected = 'SELECT Id FROM User WHERE IsActive = true LIMIT 1';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	static void shouldAddCriteriaWithBindToWhereClause() {
		Soql.Binder binder = new Soql.Binder('userId', UserInfo.getUserId());
		Soql soql = (Soql) DatabaseLayer.newSoql(User.SObjectType)?.addWhere(User.Id, Soql.EQUALS, binder);
		String expected = 'SELECT Id FROM User WHERE Id = :userId';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	static void shouldHandleMultipleWhereClauses() {
		Soql soql = (Soql) DatabaseLayer.newSoql(User.SObjectType)
			?.addWhere(User.IsActive, Soql.EQUALS, true)
			?.addWhere('Profile.Name', Soql.EQUALS, 'System Administrator')
			?.setRowLimit(1);
		String expected = 'SELECT Id FROM User WHERE IsActive = true AND Profile.Name = \'System Administrator\' LIMIT 1';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	static void shouldSetWhereClauseOuterLogic() {
		Soql soql = (Soql) DatabaseLayer.newSoql(User.SObjectType)
			?.addWhere(User.IsActive, Soql.EQUALS, true)
			?.addWhere('Profile.Name', Soql.EQUALS, 'System Administrator')
			?.setOuterWhereLogic(Soql.LogicType.ANY_CONDITIONS)
			?.setRowLimit(1);
		String expected = 'SELECT Id FROM User WHERE IsActive = true OR Profile.Name = \'System Administrator\' LIMIT 1';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	static void shouldSetNestedWhereClause() {
		Soql.ConditionalLogic innerCondition = new Soql.ConditionalLogic()
			?.addCondition(User.FirstName, Soql.EQUALS, 'Jason')
			?.addCondition(User.LastName, Soql.EQUALS, 'Siders')
			?.setLogicType(Soql.LogicType.ANY_CONDITIONS);
		Soql soql = (Soql) DatabaseLayer.newSoql(User.SObjectType)
			?.addWhere(User.IsActive, Soql.EQUALS, true)
			?.addWhere(innerCondition)
			?.setRowLimit(1);
		String expected = 'SELECT Id FROM User WHERE IsActive = true AND (FirstName = \'Jason\' OR LastName = \'Siders\') LIMIT 1';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	static void shouldSetWithSecurityEnforcedClause() {
		Soql soql = (Soql) DatabaseLayer.newSoql(User.SObjectType)?.withSecurityEnforced()?.setRowLimit(1);
		String expected = 'SELECT Id FROM User WITH SECURITY_ENFORCED LIMIT 1';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	static void shouldGroupByField() {
		Soql soql = (Soql) DatabaseLayer.newSoql(User.SObjectType)?.addSelect(User.ProfileId)?.groupBy(User.ProfileId);
		String expected = 'SELECT ProfileId FROM User GROUP BY ProfileId';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	static void shouldAddHavingClause() {
		Soql.Aggregation count = new Soql.Aggregation(Soql.Function.COUNT, User.Id);
		Soql soql = (Soql) DatabaseLayer.newSoql(User.SObjectType)
			?.addSelect(User.ProfileId)
			?.groupBy(User.ProfileId)
			?.addHaving(count, Soql.GREATER_THAN, 1);
		String expected = 'SELECT ProfileId FROM User GROUP BY ProfileId HAVING COUNT(Id) > 1';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	static void shouldSupportMultipleHavingClauses() {
		Soql.Aggregation count = new Soql.Aggregation(Soql.Function.COUNT, User.Id);
		Soql soql = (Soql) DatabaseLayer.newSoql(User.SObjectType)
			?.addSelect(User.ProfileId)
			?.groupBy(User.ProfileId)
			?.addHaving(count, Soql.GREATER_THAN, 1)
			?.addHaving(count, Soql.LESS_OR_EQUAL, 100);
		String expected = 'SELECT ProfileId FROM User GROUP BY ProfileId HAVING COUNT(Id) > 1 AND COUNT(Id) <= 100';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	static void shouldSetOuterHavingLogic() {
		Soql.Aggregation count = new Soql.Aggregation(Soql.Function.COUNT, User.Id);
		Soql soql = (Soql) DatabaseLayer.newSoql(User.SObjectType)
			?.addSelect(User.ProfileId)
			?.groupBy(User.ProfileId)
			?.addHaving(count, Soql.GREATER_THAN, 1)
			?.addHaving(count, Soql.LESS_OR_EQUAL, 100)
			?.setOuterHavingLogic(Soql.LogicType.ANY_CONDITIONS);
		String expected = 'SELECT ProfileId FROM User GROUP BY ProfileId HAVING COUNT(Id) > 1 OR COUNT(Id) <= 100';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	static void shouldSetOrderByClause() {
		Soql soql = (Soql) DatabaseLayer.newSoql(User.SObjectType)
			?.orderBy(User.CreatedDate, Soql.SortDirection.DESCENDING)
			?.setRowLimit(1);
		String expected = 'SELECT Id FROM User ORDER BY CreatedDate DESC NULLS LAST LIMIT 1';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	static void shouldSupportMultipleOrderByClauses() {
		Soql soql = (Soql) DatabaseLayer.newSoql(User.SObjectType)
			?.orderBy('Profile.Name', Soql.SortDirection.ASCENDING)
			?.orderBy(User.CreatedDate, Soql.SortDirection.DESCENDING)
			?.setRowLimit(1);
		String expected = 'SELECT Id FROM User ORDER BY Profile.Name ASC NULLS LAST, CreatedDate DESC NULLS LAST LIMIT 1';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	static void shouldSetRowLimit() {
		Soql soql = (Soql) DatabaseLayer.newSoql(User.SObjectType)?.setRowLimit(1);
		String expected = 'SELECT Id FROM User LIMIT 1';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	static void shouldSetRowOffset() {
		Soql soql = (Soql) DatabaseLayer.newSoql(User.SObjectType)?.setRowOffset(1)?.setRowLimit(1);
		String expected = 'SELECT Id FROM User LIMIT 1 OFFSET 1';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	static void shouldSetUsage() {
		Soql soql = (Soql) DatabaseLayer.newSoql(User.SObjectType)?.setUsage(Soql.Usage.FOR_VIEW)?.setRowLimit(1);
		String expected = 'SELECT Id FROM User LIMIT 1 FOR VIEW';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	static void shouldComposeFairlyComplexQuery() {
		Soql soql = (Soql) DatabaseLayer.newSoql(User.SObjectType)
			?.addSelect(User.FirstName)
			?.addSelect(User.LastName)
			?.addSelect(User.Email)
			?.addWhere(User.IsActive, Soql.EQUALS, true)
			?.addWhere('Profile.Name', Soql.EQUALS, 'System Administrator')
			?.orderBy(User.CreatedDate, Soql.SortDirection.ASCENDING)
			?.setRowLimit(1);
		String expected =
			'SELECT Id, FirstName, LastName, Email ' +
			'FROM User ' +
			'WHERE IsActive = true AND Profile.Name = \'System Administrator\' ' +
			'ORDER BY CreatedDate ASC NULLS LAST ' +
			'LIMIT 1';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	static void shouldResetQuery() {
		Soql soql = (Soql) DatabaseLayer.newSoql(User.SObjectType)
			?.addSelect(User.FirstName)
			?.addSelect(User.LastName)
			?.addSelect(User.Email)
			?.addWhere(User.IsActive, Soql.EQUALS, true)
			?.addWhere('Profile.Name', Soql.EQUALS, 'System Administrator')
			?.orderBy(User.CreatedDate, Soql.SortDirection.ASCENDING)
			?.setRowLimit(1);
		// Callers may have a need to reset the same query object
		soql?.reset()?.setRowLimit(1);
		String expected = 'SELECT Id FROM User LIMIT 1';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	static void shouldGenerateInnerQuery() {
		Test.startTest();
		String result = new Soql.InnerQuery(Account.SObjectType)?.addSelect(Account.OwnerId)?.toString();
		Test.stopTest();

		String expected = '(SELECT OwnerId FROM Account)';
		Assert.areEqual(expected, result, 'Unexpected inner query output');
	}

	@IsTest
	static void shouldGenerateSubqueryFromChildRelationship() {
		Schema.ChildRelationship rel = ChildRelationshipService.getChildRelationshipFrom(Case.AccountId);

		Test.startTest();
		String result = new Soql.Subquery(rel)?.addSelect(Case.Id)?.toString();
		Test.stopTest();

		String expected = '(SELECT Id FROM Cases)';
		Assert.areEqual(expected, result, 'Unexpected inner query output');
	}

	@IsTest
	static void shouldGenerateSubqueryFromLookupField() {
		Test.startTest();
		String result = new Soql.Subquery(Case.AccountId)?.addSelect(Case.Id)?.toString();
		Test.stopTest();

		String expected = '(SELECT Id FROM Cases)';
		Assert.areEqual(expected, result, 'Unexpected inner query output');
	}

	@IsTest
	static void shouldOutputLogicWithSingleCondition() {
		Soql.Condition condition1 = new Soql.Condition(Account.Id, Soql.EQUALS, null);

		Test.startTest();
		String result = new Soql.ConditionalLogic().addCondition(condition1)?.toString();
		Test.stopTest();

		// If only one condition, should just display the inner condition
		String expected = condition1?.toString();
		Assert.areEqual(expected, result, 'Unexpected logic output');
	}

	@IsTest
	static void shouldOutputLogicWithMultipleConditions() {
		Soql.Condition condition1 = new Soql.Condition(Account.Id, Soql.EQUALS, null);
		Soql.Condition condition2 = new Soql.Condition(Account.OwnerId, Soql.NOT_EQUALS, null);

		Test.startTest();
		String result = new Soql.ConditionalLogic()?.addCondition(condition1)?.addCondition(condition2)?.toString();
		Test.stopTest();

		String expected = 'Id = null AND OwnerId != null';
		Assert.areEqual(expected, result, 'Unexpected logic output');
	}

	@IsTest
	static void shouldOutputOrLogicWithMultipleConditions() {
		Soql.Condition condition1 = new Soql.Condition(Account.Id, Soql.EQUALS, null);
		Soql.Condition condition2 = new Soql.Condition(Account.OwnerId, Soql.NOT_EQUALS, null);

		Test.startTest();
		String result = new Soql.ConditionalLogic()
			?.addCondition(condition1)
			?.addCondition(condition2)
			?.setLogicType(Soql.LogicType.ANY_CONDITIONS)
			?.toString();
		Test.stopTest();

		String expected = 'Id = null OR OwnerId != null';
		Assert.areEqual(expected, result, 'Unexpected logic output');
	}

	@IsTest
	static void shouldOutputNestedConditionalLogic() {
		Soql.ConditionalLogic nested = new Soql.ConditionalLogic()
			?.addCondition(new Soql.Condition(Account.Id, Soql.EQUALS, null))
			?.addCondition(new Soql.Condition(Account.OwnerId, Soql.NOT_EQUALS, null))
			?.setLogicType(Soql.LogicType.ANY_CONDITIONS);
		Soql.Condition otherCondition = new Soql.Condition(Account.Name, Soql.STARTS_WITH, 'test');

		Test.startTest();
		String result = new Soql.ConditionalLogic()?.addCondition(nested)?.addCondition(otherCondition)?.toString();
		Test.stopTest();

		String expected = '(Id = null OR OwnerId != null) AND Name LIKE \'test%\'';
		Assert.areEqual(expected, result, 'Unexpected logic output');
	}

	@IsTest
	static void shouldOutputBooleanCondition() {
		Object value = true;
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.EQUALS, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String expected = 'Id = true';
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	static void shouldOutputBooleanListCondition() {
		Object value = new List<Boolean>{ true, false };
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String expected = 'Id IN (true, false)';
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	static void shouldOutputBooleanSetCondition() {
		Object value = new Set<Boolean>{ true, false };
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String expected = 'Id IN (true, false)';
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	static void shouldOutputDateCondition() {
		Object value = Date.newInstance(2024, 3, 15);
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.EQUALS, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String expected = 'Id = 2024-03-15';
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	static void shouldOutputDateListCondition() {
		Object value = new List<Date>{ Date.newInstance(2024, 3, 15), Date.newInstance(2024, 4, 15) };
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String expected = 'Id IN (2024-03-15, 2024-04-15)';
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	static void shouldOutputDateSetCondition() {
		Object value = new Set<Date>{ Date.newInstance(2024, 3, 15), Date.newInstance(2024, 4, 15) };
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String expected = 'Id IN (2024-03-15, 2024-04-15)';
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	static void shouldOutputDateTimeCondition() {
		DateTime now = DateTime.now();
		Object value = now;
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.EQUALS, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String dtFormat = 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'';
		String expected = 'Id = ' + now?.formatGmt(dtFormat);
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	static void shouldOutputDateTimeListCondition() {
		DateTime dt1 = DateTime.now();
		DateTime dt2 = DateTime.now()?.addDays(30);
		Object value = new List<DateTime>{ dt1, dt2 };
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String dtFormat = 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'';
		List<String> dtStrings = new List<String>{ dt1?.formatGmt(dtFormat), dt2?.formatGmt(dtFormat) };
		String expected = 'Id IN (' + String.join(dtStrings, ', ') + ')';
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	static void shouldOutputDateTimeSetCondition() {
		DateTime dt1 = DateTime.now();
		DateTime dt2 = DateTime.now()?.addDays(30);
		Object value = new Set<DateTime>{ dt1, dt2 };
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String dtFormat = 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'';
		List<String> dtStrings = new List<String>{ dt1?.formatGmt(dtFormat), dt2?.formatGmt(dtFormat) };
		String expected = 'Id IN (' + String.join(dtStrings, ', ') + ')';
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	static void shouldOutputDecimalCondition() {
		Object value = 123.45;
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.EQUALS, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String expected = 'Id = 123.45';
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	static void shouldOutputDecimalListCondition() {
		Object value = new List<Decimal>{ 123.45, 987.65 };
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String expected = 'Id IN (123.45, 987.65)';
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	static void shouldOutputDecimalSetCondition() {
		Object value = new Set<Decimal>{ 123.45, 987.65 };
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String expected = 'Id IN (123.45, 987.65)';
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	static void shouldOutputIdCondition() {
		Object value = UserInfo.getUserId();
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.EQUALS, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String expected = 'Id = \'' + UserInfo.getUserId() + '\'';
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	static void shouldOutputIdListCondition() {
		Id mockAccountId = SObjectType.Account.getKeyPrefix() + '0'?.repeat(15);
		Object value = new List<Id>{ UserInfo.getUserId(), mockAccountId };
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String expected = 'Id IN (\'' + UserInfo.getUserId() + '\', \'' + mockAccountId + '\')';
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	static void shouldOutputIdSetCondition() {
		Id mockAccountId = SObjectType.Account.getKeyPrefix() + '0'?.repeat(15);
		Object value = new Set<Id>{ UserInfo.getUserId(), mockAccountId };
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String expected = 'Id IN (\'' + UserInfo.getUserId() + '\', \'' + mockAccountId + '\')';
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	static void shouldOutputIntegerCondition() {
		Object value = 123;
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.EQUALS, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String expected = 'Id = 123';
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	static void shouldOutputIntegerListCondition() {
		Object value = new List<Integer>{ 123, 456 };
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String expected = 'Id IN (123, 456)';
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	static void shouldOutputIntegerSetCondition() {
		Object value = new Set<Integer>{ 123, 456 };
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String expected = 'Id IN (123, 456)';
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	static void shouldOutputStringCondition() {
		Object value = 'foo';
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.EQUALS, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String expected = 'Id = \'foo\'';
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	static void shouldOutputStringListCondition() {
		Object value = new List<String>{ 'foo', 'bar' };
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String expected = 'Id IN (\'foo\', \'bar\')';
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	static void shouldOutputStringSetCondition() {
		Object value = new List<String>{ 'foo', 'bar' };
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String expected = 'Id IN (\'foo\', \'bar\')';
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	static void shouldOutputNullCondition() {
		Object value = null;
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.EQUALS, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String expected = 'Id = null';
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	static void shouldOutputBindCondition() {
		Object value = new Soql.Binder('myList');
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String expected = 'Id IN :myList';
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	static void shouldOutputManualBind() {
		// Alternatively, callers can pass a string variable starting with ":" to indicate a bind
		Object value = ':myList';
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String expected = 'Id IN :myList';
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	static void shouldOutputExactMatchString() {
		Soql.Operator operator = Soql.EQUALS;
		String value = 'foo';

		Test.startTest();
		String result = operator?.processStringValue(value);
		Test.stopTest();

		Assert.areEqual('\'' + value + '\'', result, 'Wrong string value');
	}

	@IsTest
	static void shouldOuptutStartsWithString() {
		Soql.Operator operator = Soql.STARTS_WITH;
		String value = 'foo';

		Test.startTest();
		String result = operator?.processStringValue(value);
		Test.stopTest();

		Assert.areEqual('\'' + value + '%\'', result, 'Wrong string value');
	}

	@IsTest
	static void shouldOuptutEndsWithString() {
		Soql.Operator operator = Soql.ENDS_WITH;
		String value = 'foo';

		Test.startTest();
		String result = operator?.processStringValue(value);
		Test.stopTest();

		Assert.areEqual('\'%' + value + '\'', result, 'Wrong string value');
	}

	@IsTest
	static void shouldOuptutContainsString() {
		Soql.Operator operator = Soql.CONTAINS;
		String value = 'foo';

		Test.startTest();
		String result = operator?.processStringValue(value);
		Test.stopTest();

		Assert.areEqual('\'%' + value + '%\'', result, 'Wrong string value');
	}

	@IsTest
	static void shouldCreateAggregateClause() {
		String value = new Soql.Aggregation(Soql.Function.COUNT, Account.Id)?.toString();
		Assert.areEqual('COUNT(Id)', value, 'Wrong toString() value');
	}

	@IsTest
	static void shouldCreateAggregateClauseWithAlias() {
		String value = new Soql.Aggregation(Soql.Function.COUNT, Account.Id)?.withAlias('num')?.toString();
		Assert.areEqual('COUNT(Id) num', value, 'Wrong toString() value');
	}

	@IsTest
	static void shouldCreateAggregateClauseWithoutInnerField() {
		String value = new Soql.Aggregation(Soql.Function.COUNT)?.toString();
		Assert.areEqual('COUNT()', value, 'Wrong toString() value');
	}

	@IsTest
	static void shouldCreateBinderObject() {
		String key = 'ownerIds';
		List<Id> ownerIds = new List<Id>{ UserInfo.getUserId() };

		Test.startTest();
		Soql.Binder binder = new Soql.Binder(key, ownerIds);
		Test.stopTest();

		Assert.areEqual(key, binder?.getKey(), 'Wrong key');
		Assert.areEqual(':' + key, binder?.toString(), 'Wrong toString() value');
		Assert.areEqual(true, binder?.getValue() instanceof List<Id>, 'Wrong bind value type');
		List<Id> bindValues = (List<Id>) binder?.getValue();
		Assert.areEqual(1, bindValues?.size(), 'Wrong # of values');
	}

	@IsTest
	static void shouldCreateEmptyBinder() {
		String key = 'ownerIds';

		Test.startTest();
		Soql.Binder binder = new Soql.Binder(key);
		Test.stopTest();

		Assert.areEqual(key, binder?.getKey(), 'Wrong key');
		Assert.areEqual(':' + key, binder?.toString(), 'Wrong toString() value');
		Assert.areEqual(null, binder?.getValue(), 'Wrong bind value');
	}

	@IsTest
	static void shouldOrderByField() {
		String value = new Soql.SortOrder(Account.CreatedDate, Soql.SortDirection.ASCENDING)?.toString();
		Assert.areEqual('CreatedDate ASC NULLS LAST', value, 'Wrong value');
	}

	@IsTest
	static void shouldSpecifyNullOrder() {
		String value = new Soql.SortOrder(Account.CreatedDate, Soql.SortDirection.DESCENDING)
			?.setNullOrder(Soql.NullOrder.NULLS_FIRST)
			?.toString();
		Assert.areEqual('CreatedDate DESC NULLS FIRST', value, 'Wrong value');
	}

	// **** HELPER **** //
	static Object validateQuery(Soql soql, String expected) {
		Assert.areEqual('"' + expected + '"', '"' + soql?.toString() + '"', 'Unexpected SOQL output');
		return soql?.query();
	}

	// **** INNER **** //
	private class SampleWrapper {
		public Integer numRecords;
		public String profileName;
	}
}
