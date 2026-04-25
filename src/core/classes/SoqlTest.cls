@SuppressWarnings(
	'PMD.ApexUnitTestClassShouldHaveAsserts,PMD.ApexUnitTestClassShouldHaveRunAs,PMD.CyclomaticComplexity,PMD.NcssCount'
)
@IsTest
private class SoqlTest {
	@IsTest
	private static void shouldAggregateQuery() {
		Soql.Aggregation count = new Soql.Aggregation(Soql.Function.COUNT, User.Id);
		Soql soql = DatabaseLayer.Soql.newQuery(User.SObjectType)?.addSelect(count)?.toSoql();

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
	private static void shouldHandleAggregateQueryErrors() {
		// Calling aggregateQuery() with a non-aggregate query will yield a System.TypeException
		Soql soql = DatabaseLayer.Soql.newQuery(User.SObjectType)?.toSoql();

		Test.startTest();
		try {
			soql?.aggregateQuery();
			Assert.fail('Illegal query did not throw an error');
		} catch (System.TypeException error) {
			Assert.isTrue(
				error?.getMessage()?.contains(soql?.toString()),
				'Did not append query to error: ' + error?.getMessage() + '\n' + error?.getStackTraceString()
			);
		}
		Test.stopTest();
	}

	@IsTest
	private static void shouldCountQuery() {
		Soql.ParentField field = new Soql.ParentField(User.ProfileId, Profile.Name);
		Soql soql = DatabaseLayer.Soql.newQuery(User.SObjectType)
			?.addWhere(field, Soql.EQUALS, 'System Administrator')
			?.toSoql();

		Test.startTest();
		Integer results = soql?.countQuery();
		Test.stopTest();

		Integer expected = Database.countQuery(
			'SELECT COUNT() FROM User WHERE Profile.Name = \'System Administrator\''
		);
		Assert.areEqual(expected, results, 'Wrong # of countQuery results');
	}

	@IsTest
	private static void shouldHandleCountQueryErrors() {
		SObjectType illegalEntity = null; // Will cause a System.QueryException when run
		Soql soql = DatabaseLayer.Soql.newQuery(illegalEntity)?.toSoql();

		Test.startTest();
		try {
			soql?.countQuery();
			Assert.fail('Illegal query did not throw an error');
		} catch (System.QueryException error) {
			String msg = error?.getMessage();
			Assert.isTrue(msg?.contains(soql?.toString()), 'Did not append query to the error');
		}
		Test.stopTest();
	}

	@IsTest
	private static void shouldGetCursor() {
		Soql soql = DatabaseLayer.Soql.newQuery(User.SObjectType)?.setRowLimit(1)?.toSoql();

		Test.startTest();
		Soql.Cursor cursor = soql?.getCursor();
		Test.stopTest();

		Assert.areNotEqual(null, cursor?.getCursor(), 'Did not return Database.Cursor object');
		Assert.areNotEqual(null, cursor?.getNumRecords(), 'Did not return the number of records');
		List<User> users = cursor?.fetch(0, 1);
		Assert.areEqual(1, users?.size(), 'Wrong # of records fetched from the cursor');
	}

	@IsTest
	private static void shouldHandleCursorQueryErrors() {
		String illegalFieldName = 'abcd'; // Will cause a System.QueryException when run
		Soql soql = DatabaseLayer.Soql.newQuery(Account.SObjectType)?.addSelect(illegalFieldName)?.toSoql();

		Test.startTest();
		try {
			soql?.getCursor();
			Assert.fail('Illegal query did not throw an error');
		} catch (System.QueryException error) {
			String msg = error?.getMessage();
			Assert.isTrue(msg?.contains(illegalFieldName), 'Did not append query to the error');
		}
		Test.stopTest();
	}

	@IsTest
	private static void shouldWrapInvalidCursorFetchErrors() {
		Soql soql = DatabaseLayer.Soql.newQuery(User.SObjectType)?.setRowLimit(1)?.toSoql();

		Test.startTest();
		Exception caughtError;
		try {
			// Negative parameters are not allowed!
			soql?.getCursor()?.fetch(0, -1);
			Assert.fail('Did not throw a Soql.InvalidParameterValueException for batch fetch params');
		} catch (Soql.InvalidParameterValueException error) {
			// As expected...
			caughtError = error;
		}
		Test.stopTest();
	}

	@IsTest
	private static void shouldGetQueryLocator() {
		Soql soql = DatabaseLayer.Soql.newQuery(User.SObjectType)?.setRowLimit(1)?.toSoql();

		Test.startTest();
		Soql.QueryLocator locator = soql?.getQueryLocator();
		Test.stopTest();

		Assert.areNotEqual(null, locator?.getLocator(), 'Did not return Database.QueryLocator object');
		Assert.areEqual(soql?.toString(), locator?.getQuery(), 'Unexpected Query');
		Assert.areNotEqual(null, locator?.iterator(), 'Did not return iterator');
	}

	@IsTest
	private static void shouldHandleQueryLocatorErrors() {
		String illegalFieldName = 'abcd'; // Will cause a System.QueryException when run
		Soql soql = DatabaseLayer.Soql.newQuery(Account.SObjectType)?.addSelect(illegalFieldName)?.toSoql();

		Test.startTest();
		try {
			soql?.getQueryLocator();
			Assert.fail('Illegal query did not throw an error');
		} catch (System.QueryException error) {
			String msg = error?.getMessage();
			Assert.isTrue(msg?.contains(illegalFieldName), 'Did not append query to the error');
		}
		Test.stopTest();
	}

	@IsTest
	private static void shouldQueryRecords() {
		Soql soql = DatabaseLayer.Soql.newQuery(User.SObjectType)?.setRowLimit(1)?.toSoql();

		Test.startTest();
		List<User> users = soql?.query();
		Test.stopTest();

		Assert.areEqual(1, users?.size(), 'Wrong # of Users returned');
	}

	@IsTest
	private static void shouldQueryAndMapRecords() {
		Soql soql = DatabaseLayer.Soql.newQuery(User.SObjectType)?.setRowLimit(1)?.toSoql();

		Test.startTest();
		Map<Id, SObject> users = soql?.queryAndMap();
		Test.stopTest();

		Assert.areEqual(1, users?.size(), 'Wrong # of Users returned');
	}

	@IsTest
	private static void shouldQuerySingleRecord() {
		Soql soql = DatabaseLayer.Soql.newQuery(User.SObjectType);

		Test.startTest();
		User user = (User) soql?.queryFirst();
		Test.stopTest();

		Assert.areNotEqual(null, user, 'No records returned');
	}

	@IsTest
	private static void shouldReturnNullIfNoResults() {
		Soql soql = DatabaseLayer.Soql.newQuery(Account.SObjectType);
		// No accounts have been inserted yet, so this shouldn't return anything

		Test.startTest();
		Account account = (Account) soql?.queryFirst();
		Test.stopTest();

		Assert.areEqual(null, account, 'Returned a result anyway? ' + account);
	}

	@IsTest
	private static void shouldHandleQueryErrors() {
		String illegalFieldName = 'abcd'; // Will cause a System.QueryException when run
		Soql soql = DatabaseLayer.Soql.newQuery(Account.SObjectType)?.addSelect(illegalFieldName)?.toSoql();

		Test.startTest();
		try {
			soql?.query();
			Assert.fail('Illegal query did not throw an error');
		} catch (System.QueryException error) {
			String msg = error?.getMessage();
			Assert.isTrue(msg?.contains(soql?.toString()), 'Did not append query to the error');
		}
		Test.stopTest();
	}

	@IsTest
	private static void shouldQueryRecordsAndCastToType() {
		Soql.ParentField profile = new Soql.ParentField(User.ProfileId, Profile.Name);
		Soql.Aggregation count = new Soql.Aggregation(Soql.Function.COUNT, User.Id)?.withAlias('numRecords');
		Soql soql = DatabaseLayer.Soql.newQuery(User.SObjectType)
			?.addSelect(profile, 'profileName')
			?.addSelect(count)
			?.addGroupBy(profile)
			?.toSoql();

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
	private static void shouldSetAccessLevel() {
		System.AccessLevel level = System.AccessLevel.SYSTEM_MODE;
		Soql soql = DatabaseLayer.Soql.newQuery(User.SObjectType)?.setAccessLevel(level)?.toSoql();
		Assert.areEqual(level, soql?.accessLevel, 'Did not set access level');
	}

	@IsTest
	private static void shouldBindVariableToQuery() {
		Soql.Binder binder = new Soql.Binder('userId', UserInfo.getUserId());
		Soql soql = DatabaseLayer.Soql.newQuery(User.SObjectType)
			?.addSelect(User.Username)
			?.addWhere(User.Id, Soql.EQUALS, binder)
			?.setRowLimit(1)
			?.toSoql();
		String expected = 'SELECT Id, Username FROM User WHERE Id = :userId LIMIT 1';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	private static void shouldDeselectAllFields() {
		Soql soql = DatabaseLayer.Soql.newQuery(User.SObjectType)?.selectAll()?.toSoql();
		Assert.isTrue(soql?.selectClauses?.size() > 1, 'Wrong # of SELECT clauses');

		Test.startTest();
		soql.deselectAll();
		Test.stopTest();

		Assert.isTrue(soql?.selectClauses?.isEmpty(), 'Did not clear SELECT clauses');
	}

	@IsTest
	private static void shouldDeselectSpecificClauses() {
		Soql.ParentField profile = new Soql.ParentField(User.ProfileId, Profile.Name);
		Soql soql = DatabaseLayer.Soql.newQuery(User.SObjectType)?.addSelect(profile)?.selectAll()?.toSoql();
		Assert.isTrue(soql?.selectClauses?.size() > 1, 'Wrong # of SELECT clauses');

		Test.startTest();
		soql?.deselect(User.Username);
		soql?.deselect(profile);
		Test.stopTest();

		Set<String> fields = new Set<String>(soql?.selectClauses);
		Assert.isFalse(fields?.contains(User.Username?.toString()), 'Did not deselect Username');
		Assert.isFalse(fields?.contains(profile?.toString()), 'Did not deselect Profile.Name');
	}

	@IsTest
	private static void shouldSelectAllFields() {
		Set<String> userFields = SObjectType.User?.fields?.getMap()?.keySet();

		Test.startTest();
		Soql soql = DatabaseLayer.Soql.newQuery(User.SObjectType)?.selectAll()?.toSoql();
		Test.stopTest();

		Assert.areEqual(userFields?.size(), soql?.selectClauses?.size(), 'Wrong # of SELECT clauses');
	}

	@IsTest
	private static void shouldSelectSpecificFields() {
		Soql soql = DatabaseLayer.Soql.newQuery(User.SObjectType)?.addSelect(User.FirstName)?.setRowLimit(1)?.toSoql();
		String expected = 'SELECT Id, FirstName FROM User LIMIT 1';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	private static void shouldSelectFieldWithAlias() {
		Soql soql = DatabaseLayer.Soql.newQuery(User.SObjectType)
			?.addSelect(User.ProfileId, 'profile')
			?.addGroupBy(User.ProfileId)
			?.toSoql();
		String expected = 'SELECT ProfileId profile FROM User GROUP BY ProfileId';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	private static void shouldSelectParentFieldWithAlias() {
		Soql.ParentField field = new Soql.ParentField(Account.OwnerId, User.ProfileId);
		Soql soql = DatabaseLayer.Soql.newQuery(Account.SObjectType)
			?.addSelect(field, 'profile')
			?.addGroupBy(field)
			?.toSoql();
		String expected = 'SELECT Owner.ProfileId profile FROM Account GROUP BY Owner.ProfileId';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	private static void shouldSelectListOfFields() {
		List<SObjectField> fields = new List<SObjectField>{
			Account.Name,
			Account.NumberOfEmployees,
			Account.OwnerId,
			Account.CreatedDate,
			Account.LastModifiedDate
		};
		Soql soql = DatabaseLayer.Soql.newQuery(Account.SObjectType)?.addSelect(fields)?.toSoql();
		String expected = 'SELECT Id, Name, NumberOfEmployees, OwnerId, CreatedDate, LastModifiedDate FROM Account';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	private static void shouldSelectUpTo5Fields() {
		Soql soql = DatabaseLayer.Soql.newQuery(Account.SObjectType)
			?.addSelect(
				Account.Name,
				Account.NumberOfEmployees,
				Account.OwnerId,
				Account.CreatedDate,
				Account.LastModifiedDate
			)
			?.toSoql();
		String expected = 'SELECT Id, Name, NumberOfEmployees, OwnerId, CreatedDate, LastModifiedDate FROM Account';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	private static void shouldSelectMultipleFields() {
		Soql soql = DatabaseLayer.Soql.newQuery(Account.SObjectType)
			?.addSelect(Account.Name, Account.NumberOfEmployees)
			?.toSoql();
		String expected = 'SELECT Id, Name, NumberOfEmployees FROM Account';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	private static void shouldSelectParentField() {
		Soql.ParentField field = new Soql.ParentField(Opportunity.AccountId, Account.Name);
		Soql soql = DatabaseLayer.Soql.newQuery(Opportunity.SObjectType)?.addSelect(field)?.toSoql();
		String expected = 'SELECT Id, Account.Name FROM Opportunity';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	private static void shouldSelectListOfParentFields() {
		List<Soql.ParentField> fields = new List<Soql.ParentField>{
			new Soql.ParentField(Opportunity.AccountId, Account.Name),
			new Soql.ParentField(Opportunity.AccountId, Account.OwnerId)
		};

		Soql soql = DatabaseLayer.Soql.newQuery(Opportunity.SObjectType)?.addSelect(fields)?.toSoql();
		String expected = 'SELECT Id, Account.Name, Account.OwnerId FROM Opportunity';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	private static void shouldSelectUpTo5ParentFields() {
		Soql.ParentField accName = new Soql.ParentField(Opportunity.AccountId, Account.Name);
		Soql.ParentField accOwner = new Soql.ParentField(Opportunity.AccountId, Account.OwnerId);
		Soql.ParentField ownerProfile = new Soql.ParentField(
			Opportunity.AccountId,
			Account.OwnerId,
			User.ProfileId,
			Profile.Name
		);
		Soql.ParentField accCreated = new Soql.ParentField(Opportunity.AccountId, Account.CreatedDate);
		Soql.ParentField accModified = new Soql.ParentField(Opportunity.AccountId, Account.LastModifiedDate);

		Soql soql = DatabaseLayer.Soql.newQuery(Opportunity.SObjectType)
			?.addSelect(accName, accOwner, ownerProfile, accCreated, accModified)
			?.toSoql();
		String expected = 'SELECT Id, Account.Name, Account.OwnerId, Account.Owner.Profile.Name, Account.CreatedDate, Account.LastModifiedDate FROM Opportunity';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	private static void shouldSelectMultipleParentFields() {
		Soql.ParentField accountName = new Soql.ParentField(Opportunity.AccountId, Account.Name);
		Soql.ParentField accountOwner = new Soql.ParentField(Opportunity.AccountId, Account.OwnerId);

		Soql soql = DatabaseLayer.Soql.newQuery(Opportunity.SObjectType)
			?.addSelect(accountName, accountOwner)
			?.toSoql();
		String expected = 'SELECT Id, Account.Name, Account.OwnerId FROM Opportunity';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	private static void shouldSelectAggregation() {
		Soql.Aggregation count = new Soql.Aggregation(Soql.Function.COUNT, User.Id);
		Soql soql = DatabaseLayer.Soql.newQuery(User.SObjectType)?.addSelect(count)?.toSoql();
		String expected = 'SELECT COUNT(Id) FROM User';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	private static void shouldSelectListOfAggregations() {
		List<Soql.Aggregation> aggs = new List<Soql.Aggregation>{
			new Soql.Aggregation(Soql.Function.COUNT, Account.Id),
			new Soql.Aggregation(Soql.Function.AVG, Account.NumberOfEmployees),
			new Soql.Aggregation(Soql.Function.SUM, Account.NumberOfEmployees),
			new Soql.Aggregation(Soql.Function.MIN, new Soql.ParentField(Account.OwnerId, User.CreatedDate)),
			new Soql.Aggregation(Soql.Function.MAX, new Soql.ParentField(Account.OwnerId, User.CreatedDate))
		};
		Soql soql = DatabaseLayer.Soql.newQuery(Account.SObjectType)?.addSelect(aggs)?.toSoql();
		String expected = 'SELECT COUNT(Id), AVG(NumberOfEmployees), SUM(NumberOfEmployees), MIN(Owner.CreatedDate), MAX(Owner.CreatedDate) FROM Account';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	private static void shouldSelectUpTo5Aggregations() {
		Soql soql = DatabaseLayer.Soql.newQuery(Account.SObjectType)
			?.addSelect(
				new Soql.Aggregation(Soql.Function.COUNT, Account.Id),
				new Soql.Aggregation(Soql.Function.SUM, Account.NumberOfEmployees),
				new Soql.Aggregation(Soql.Function.MIN, Account.NumberOfEmployees),
				new Soql.Aggregation(Soql.Function.MAX, Account.NumberOfEmployees),
				new Soql.Aggregation(Soql.Function.AVG, Account.NumberOfEmployees)
			)
			?.toSoql();
		String expected = 'SELECT COUNT(Id), SUM(NumberOfEmployees), MIN(NumberOfEmployees), MAX(NumberOfEmployees), AVG(NumberOfEmployees) FROM Account';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	private static void shouldSelectMultipleAggregations() {
		Soql soql = DatabaseLayer.Soql.newQuery(Account.SObjectType)
			?.addSelect(
				new Soql.Aggregation(Soql.Function.COUNT, Account.Id),
				new Soql.Aggregation(Soql.Function.SUM, Account.NumberOfEmployees)
			)
			?.toSoql();
		String expected = 'SELECT COUNT(Id), SUM(NumberOfEmployees) FROM Account';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	private static void shouldSelectSubquery() {
		Soql.Subquery subquery = new Soql.Subquery(User.ProfileId);
		Soql soql = DatabaseLayer.Soql.newQuery(Profile.SObjectType)?.addSelect(subquery)?.setRowLimit(1)?.toSoql();
		String expected = 'SELECT Id, (SELECT Id FROM Users) FROM Profile LIMIT 1';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	private static void shouldSelectListOfSubqueries() {
		List<Soql.Subquery> subqueries = new List<Soql.Subquery>{
			new Soql.Subquery(Account.ParentId),
			new Soql.Subquery(Case.AccountId),
			new Soql.Subquery(Contact.AccountId),
			new Soql.Subquery(Opportunity.AccountId),
			new Soql.Subquery(AccountContactRole.AccountId)
		};
		Soql soql = DatabaseLayer.Soql.newQuery(Account.SObjectType)?.addSelect(subqueries)?.toSoql();
		String expected = 'SELECT Id, (SELECT Id FROM ChildAccounts), (SELECT Id FROM Cases), (SELECT Id FROM Contacts), (SELECT Id FROM Opportunities), (SELECT Id FROM AccountContactRoles) FROM Account';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	private static void shouldSelectUpTo5Subqueries() {
		Soql soql = DatabaseLayer.Soql.newQuery(Account.SObjectType)
			?.addSelect(
				new Soql.Subquery(Account.ParentId),
				new Soql.Subquery(Case.AccountId),
				new Soql.Subquery(Contact.AccountId),
				new Soql.Subquery(Opportunity.AccountId),
				new Soql.Subquery(AccountContactRole.AccountId)
			)
			?.toSoql();
		String expected = 'SELECT Id, (SELECT Id FROM ChildAccounts), (SELECT Id FROM Cases), (SELECT Id FROM Contacts), (SELECT Id FROM Opportunities), (SELECT Id FROM AccountContactRoles) FROM Account';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	private static void shouldSelectMultipleSubqueries() {
		Soql soql = DatabaseLayer.Soql.newQuery(Account.SObjectType)
			?.addSelect(new Soql.Subquery(Account.ParentId), new Soql.Subquery(Case.AccountId))
			?.toSoql();
		String expected = 'SELECT Id, (SELECT Id FROM ChildAccounts), (SELECT Id FROM Cases) FROM Account';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	private static void shouldSetQueryScope() {
		Soql soql = DatabaseLayer.Soql.newQuery(User.SObjectType)
			?.setScope(Soql.Scope.EVERYTHING)
			?.setRowLimit(1)
			?.toSoql();
		String expected = 'SELECT Id FROM User USING SCOPE EVERYTHING LIMIT 1';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	private static void shouldAddCriteriaToWhereClause() {
		Soql soql = DatabaseLayer.Soql.newQuery(User.SObjectType)
			?.addWhere(User.IsActive, Soql.EQUALS, true)
			?.setRowLimit(1)
			?.toSoql();
		String expected = 'SELECT Id FROM User WHERE IsActive = true LIMIT 1';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	private static void shouldAddCriteriaWithBindsToWhereClause() {
		Soql.Binder profileName = new Soql.Binder('profileName', 'System Administrator');
		Soql.Binder userId = new Soql.Binder('userId', UserInfo.getUserId());
		Soql soql = DatabaseLayer.Soql.newQuery(User.SObjectType)
			?.addWhere(User.Id, Soql.NOT_EQUALS, userId)
			?.addWhere(new Soql.ParentField(User.ProfileId, Profile.Name), Soql.EQUALS, profileName)
			?.toSoql();
		String expected = 'SELECT Id FROM User WHERE Id != :userId AND Profile.Name = :profileName';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	private static void shouldHandleMultipleWhereClauses() {
		Soql soql = DatabaseLayer.Soql.newQuery(User.SObjectType)
			?.addWhere(User.IsActive, Soql.EQUALS, true)
			?.addWhere(new Soql.ParentField(User.ProfileId, Profile.Name), Soql.EQUALS, 'System Administrator')
			?.setRowLimit(1)
			?.toSoql();
		String expected = 'SELECT Id FROM User WHERE IsActive = true AND Profile.Name = \'System Administrator\' LIMIT 1';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	private static void shouldSetWhereClauseOuterLogic() {
		Soql soql = DatabaseLayer.Soql.newQuery(User.SObjectType)
			?.addWhere(User.IsActive, Soql.EQUALS, true)
			?.addWhere(new Soql.ParentField(User.ProfileId, Profile.Name), Soql.EQUALS, 'System Administrator')
			?.setOuterWhereLogic(Soql.LogicType.ANY_CONDITIONS)
			?.setRowLimit(1)
			?.toSoql();
		String expected = 'SELECT Id FROM User WHERE IsActive = true OR Profile.Name = \'System Administrator\' LIMIT 1';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	private static void shouldSetNestedWhereClause() {
		Soql.ConditionalLogic innerCondition = new Soql.ConditionalLogic()
			?.addCondition(User.FirstName, Soql.EQUALS, 'Jason')
			?.addCondition(new Soql.ParentField(User.ProfileId, Profile.Name), Soql.EQUALS, 'System Administrator')
			?.setLogicType(Soql.LogicType.ANY_CONDITIONS);
		Soql soql = DatabaseLayer.Soql.newQuery(User.SObjectType)
			?.addWhere(User.IsActive, Soql.EQUALS, true)
			?.addWhere(innerCondition)
			?.setRowLimit(1)
			?.toSoql();
		String expected = 'SELECT Id FROM User WHERE IsActive = true AND (FirstName = \'Jason\' OR Profile.Name = \'System Administrator\') LIMIT 1';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	private static void shouldSetWithSecurityEnforcedClause() {
		Soql soql = DatabaseLayer.Soql.newQuery(User.SObjectType)?.withSecurityEnforced()?.setRowLimit(1)?.toSoql();
		String expected = 'SELECT Id FROM User WITH SECURITY_ENFORCED LIMIT 1';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	private static void shouldGroupByField() {
		Soql soql = DatabaseLayer.Soql.newQuery(User.SObjectType)
			?.addSelect(User.ProfileId)
			?.addGroupBy(User.ProfileId)
			?.toSoql();
		String expected = 'SELECT ProfileId FROM User GROUP BY ProfileId';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	private static void shouldAddHavingClause() {
		Soql.Aggregation count = new Soql.Aggregation(Soql.Function.COUNT, User.Id);
		Soql soql = DatabaseLayer.Soql.newQuery(User.SObjectType)
			?.addSelect(User.ProfileId)
			?.addGroupBy(User.ProfileId)
			?.addHaving(count, Soql.GREATER_THAN, 1)
			?.toSoql();
		String expected = 'SELECT ProfileId FROM User GROUP BY ProfileId HAVING COUNT(Id) > 1';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	private static void shouldSupportMultipleHavingClauses() {
		Soql.Aggregation count = new Soql.Aggregation(Soql.Function.COUNT, User.Id);
		Soql soql = DatabaseLayer.Soql.newQuery(User.SObjectType)
			?.addSelect(User.ProfileId)
			?.addGroupBy(User.ProfileId)
			?.addHaving(count, Soql.GREATER_THAN, 1)
			?.addHaving(count, Soql.LESS_OR_EQUAL, 100)
			?.toSoql();
		String expected = 'SELECT ProfileId FROM User GROUP BY ProfileId HAVING COUNT(Id) > 1 AND COUNT(Id) <= 100';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	private static void shouldSetOuterHavingLogic() {
		Soql.Aggregation count = new Soql.Aggregation(Soql.Function.COUNT, User.Id);
		Soql soql = DatabaseLayer.Soql.newQuery(User.SObjectType)
			?.addSelect(User.ProfileId)
			?.addGroupBy(User.ProfileId)
			?.addHaving(count, Soql.GREATER_THAN, 1)
			?.addHaving(count, Soql.LESS_OR_EQUAL, 100)
			?.setOuterHavingLogic(Soql.LogicType.ANY_CONDITIONS)
			?.toSoql();
		String expected = 'SELECT ProfileId FROM User GROUP BY ProfileId HAVING COUNT(Id) > 1 OR COUNT(Id) <= 100';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	private static void shouldSetOrderByClause() {
		Soql soql = DatabaseLayer.Soql.newQuery(User.SObjectType)
			?.addOrderBy(User.CreatedDate, Soql.SortDirection.DESCENDING)
			?.setRowLimit(1)
			?.toSoql();
		String expected = 'SELECT Id FROM User ORDER BY CreatedDate DESC NULLS LAST LIMIT 1';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	private static void shouldSetOrderByClauseWithParentField() {
		Soql.ParentField field = new Soql.ParentField(Account.OwnerId, User.CreatedDate);
		Soql soql = DatabaseLayer.Soql.newQuery(Account.SObjectType)
			?.addOrderBy(field, Soql.SortDirection.DESCENDING)
			?.setRowLimit(1)
			?.toSoql();
		String expected = 'SELECT Id FROM Account ORDER BY Owner.CreatedDate DESC NULLS LAST LIMIT 1';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	private static void shouldSupportMultipleOrderByClauses() {
		Soql soql = DatabaseLayer.Soql.newQuery(User.SObjectType)
			?.addOrderBy(new Soql.ParentField(User.ProfileId, Profile.Name), Soql.SortDirection.ASCENDING)
			?.addOrderBy(User.CreatedDate, Soql.SortDirection.DESCENDING)
			?.setRowLimit(1)
			?.toSoql();
		String expected = 'SELECT Id FROM User ORDER BY Profile.Name ASC NULLS LAST, CreatedDate DESC NULLS LAST LIMIT 1';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	private static void shouldSetRowLimit() {
		Soql soql = DatabaseLayer.Soql.newQuery(User.SObjectType)?.setRowLimit(1)?.toSoql();
		String expected = 'SELECT Id FROM User LIMIT 1';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	private static void shouldSetRowOffset() {
		Soql soql = DatabaseLayer.Soql.newQuery(User.SObjectType)?.setRowOffset(1)?.setRowLimit(1)?.toSoql();
		String expected = 'SELECT Id FROM User LIMIT 1 OFFSET 1';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	private static void shouldSetUsage() {
		Soql soql = DatabaseLayer.Soql.newQuery(User.SObjectType)
			?.setUsage(Soql.Usage.FOR_VIEW)
			?.setRowLimit(1)
			?.toSoql();
		String expected = 'SELECT Id FROM User LIMIT 1 FOR VIEW';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	private static void shouldComposeFairlyComplexQuery() {
		Soql soql = DatabaseLayer.Soql.newQuery(User.SObjectType)
			?.addSelect(User.FirstName)
			?.addSelect(User.LastName)
			?.addSelect(User.Email)
			?.addWhere(User.IsActive, Soql.EQUALS, true)
			?.addWhere(new Soql.ParentField(User.ProfileId, Profile.Name), Soql.EQUALS, 'System Administrator')
			?.addOrderBy(User.CreatedDate, Soql.SortDirection.ASCENDING)
			?.setRowLimit(1)
			?.toSoql();
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
	private static void shouldResetQuery() {
		Soql soql = DatabaseLayer.Soql.newQuery(User.SObjectType)
			?.addSelect(User.FirstName)
			?.addSelect(User.LastName)
			?.addSelect(User.Email)
			?.addWhere(User.IsActive, Soql.EQUALS, true)
			?.addWhere(new Soql.ParentField(User.ProfileId, Profile.Name), Soql.EQUALS, 'System Administrator')
			?.addOrderBy(User.CreatedDate, Soql.SortDirection.ASCENDING)
			?.setRowLimit(1)
			?.toSoql();
		// Callers may have a need to reset the same query object
		soql?.reset()?.setRowLimit(1);
		String expected = 'SELECT Id FROM User LIMIT 1';

		Test.startTest();
		SoqlTest.validateQuery(soql, expected);
		Test.stopTest();
	}

	@IsTest
	private static void shouldGenerateInnerQuery() {
		Test.startTest();
		String result = new Soql.InnerQuery(Account.SObjectType)?.addSelect(Account.OwnerId)?.toString();
		Test.stopTest();

		String expected = '(SELECT OwnerId FROM Account)';
		Assert.areEqual(expected, result, 'Unexpected inner query output');
	}

	@IsTest
	private static void shouldGenerateSubqueryFromChildRelationship() {
		Schema.ChildRelationship rel = DatabaseLayer.Utils.ChildRelationships.getChildRelationshipFrom(Case.AccountId);

		Test.startTest();
		String result = new Soql.Subquery(rel)?.addSelect(Case.Id)?.toString();
		Test.stopTest();

		String expected = '(SELECT Id FROM Cases)';
		Assert.areEqual(expected, result, 'Unexpected inner query output');
	}

	@IsTest
	private static void shouldGenerateSubqueryFromLookupField() {
		Test.startTest();
		String result = new Soql.Subquery(Case.AccountId)?.addSelect(Case.Id)?.toString();
		Test.stopTest();

		String expected = '(SELECT Id FROM Cases)';
		Assert.areEqual(expected, result, 'Unexpected inner query output');
	}

	@IsTest
	private static void shouldOutputLogicWithSingleCondition() {
		Soql.ParentField field = new Soql.ParentField(Account.OwnerId, User.ProfileId, Profile.Name);
		Soql.Condition condition = new Soql.Condition(field, Soql.EQUALS, 'System Administrator');

		Test.startTest();
		String result = new Soql.ConditionalLogic().addCondition(condition)?.toString();
		Test.stopTest();

		// If only one condition, should just display the inner condition
		String expected = condition?.toString();
		Assert.areEqual(expected, result, 'Unexpected logic output');
	}

	@IsTest
	private static void shouldOutputLogicWithMultipleConditions() {
		Soql.ParentField ownerProfileName = new Soql.ParentField(Account.OwnerId, User.ProfileId, Profile.Name);
		Soql.Condition condition1 = new Soql.Condition(Account.Id, Soql.EQUALS, null);
		Soql.Condition condition2 = new Soql.Condition(ownerProfileName, Soql.NOT_EQUALS, 'System Administrator');

		Test.startTest();
		String result = new Soql.ConditionalLogic()?.addCondition(condition1)?.addCondition(condition2)?.toString();
		Test.stopTest();

		String expected = 'Id = null AND Owner.Profile.Name != \'System Administrator\'';
		Assert.areEqual(expected, result, 'Unexpected logic output');
	}

	@IsTest
	private static void shouldOutputOrLogicWithMultipleConditions() {
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
	private static void shouldOutputNestedConditionalLogic() {
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
	private static void shouldOutputBooleanCondition() {
		Object value = true;
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.EQUALS, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String expected = 'Id = true';
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	private static void shouldOutputBooleanListCondition() {
		Object value = new List<Boolean>{ true, false };
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String expected = 'Id IN (true, false)';
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	private static void shouldOutputBooleanSetCondition() {
		Object value = new Set<Boolean>{ true, false };
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String expected = 'Id IN (true, false)';
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	private static void shouldOutputDateCondition() {
		Object value = Date.newInstance(2024, 3, 15);
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.EQUALS, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String expected = 'Id = 2024-03-15';
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	private static void shouldOutputDateListCondition() {
		Object value = new List<Date>{ Date.newInstance(2024, 3, 15), Date.newInstance(2024, 4, 15) };
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String expected = 'Id IN (2024-03-15, 2024-04-15)';
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	private static void shouldOutputDateSetCondition() {
		Object value = new Set<Date>{ Date.newInstance(2024, 3, 15), Date.newInstance(2024, 4, 15) };
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String expected = 'Id IN (2024-03-15, 2024-04-15)';
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	private static void shouldOutputDateTimeCondition() {
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
	private static void shouldOutputDateTimeListCondition() {
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
	private static void shouldOutputDateTimeSetCondition() {
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
	private static void shouldOutputDecimalCondition() {
		Object value = 123.45;
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.EQUALS, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String expected = 'Id = 123.45';
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	private static void shouldOutputDecimalListCondition() {
		Object value = new List<Decimal>{ 123.45, 987.65 };
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String expected = 'Id IN (123.45, 987.65)';
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	private static void shouldOutputDecimalSetCondition() {
		Object value = new Set<Decimal>{ 123.45, 987.65 };
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String expected = 'Id IN (123.45, 987.65)';
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	private static void shouldOutputIdCondition() {
		Object value = UserInfo.getUserId();
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.EQUALS, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String expected = 'Id = \'' + UserInfo.getUserId() + '\'';
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	private static void shouldOutputIdListCondition() {
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
	private static void shouldOutputIdSetCondition() {
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
	private static void shouldOutputIntegerCondition() {
		Object value = 123;
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.EQUALS, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String expected = 'Id = 123';
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	private static void shouldOutputIntegerListCondition() {
		Object value = new List<Integer>{ 123, 456 };
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String expected = 'Id IN (123, 456)';
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	private static void shouldOutputIntegerSetCondition() {
		Object value = new Set<Integer>{ 123, 456 };
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String expected = 'Id IN (123, 456)';
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	private static void shouldOutputStringCondition() {
		Object value = 'foo';
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.EQUALS, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String expected = 'Id = \'foo\'';
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	private static void shouldOutputStringListCondition() {
		Object value = new List<String>{ 'foo', 'bar' };
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String expected = 'Id IN (\'foo\', \'bar\')';
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	private static void shouldOutputStringSetCondition() {
		Object value = new List<String>{ 'foo', 'bar' };
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String expected = 'Id IN (\'foo\', \'bar\')';
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	private static void shouldOutputNullCondition() {
		Object value = null;
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.EQUALS, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String expected = 'Id = null';
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	private static void shouldOutputBindCondition() {
		Object value = new Soql.Binder('myList');
		Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

		Test.startTest();
		String result = condition?.toString();
		Test.stopTest();

		String expected = 'Id IN :myList';
		Assert.areEqual(expected, result, 'Unexpected condition output');
	}

	@IsTest
	private static void shouldOutputManualBind() {
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
	private static void shouldOutputExactMatchString() {
		Soql.Operator operator = Soql.EQUALS;
		String value = 'foo';

		Test.startTest();
		String result = operator?.processStringValue(value);
		Test.stopTest();

		Assert.areEqual('\'' + value + '\'', result, 'Wrong string value');
	}

	@IsTest
	private static void shouldOuptutStartsWithString() {
		Soql.Operator operator = Soql.STARTS_WITH;
		String value = 'foo';

		Test.startTest();
		String result = operator?.processStringValue(value);
		Test.stopTest();

		Assert.areEqual('\'' + value + '%\'', result, 'Wrong string value');
	}

	@IsTest
	private static void shouldOuptutEndsWithString() {
		Soql.Operator operator = Soql.ENDS_WITH;
		String value = 'foo';

		Test.startTest();
		String result = operator?.processStringValue(value);
		Test.stopTest();

		Assert.areEqual('\'%' + value + '\'', result, 'Wrong string value');
	}

	@IsTest
	private static void shouldOuptutContainsString() {
		Soql.Operator operator = Soql.CONTAINS;
		String value = 'foo';

		Test.startTest();
		String result = operator?.processStringValue(value);
		Test.stopTest();

		Assert.areEqual('\'%' + value + '%\'', result, 'Wrong string value');
	}

	@IsTest
	private static void shouldOutputReferenceToParentFields() {
		// SOQL supports querying objects up to 5 relationships away from the FROM object
		Soql.Selectable field1 = new Soql.ParentField(OpportunityContactRole.OpportunityId, Opportunity.AccountId);
		Assert.areEqual('Opportunity.AccountId', field1?.toString(), 'Wrong ParentField value');
		Soql.Selectable field2 = new Soql.ParentField(
			OpportunityContactRole.OpportunityId,
			Opportunity.AccountId,
			Account.OwnerId
		);
		Assert.areEqual('Opportunity.Account.OwnerId', field2?.toString(), 'Wrong ParentField value');
		Soql.Selectable field3 = new Soql.ParentField(
			OpportunityContactRole.OpportunityId,
			Opportunity.AccountId,
			Account.OwnerId,
			User.ProfileId
		);
		Assert.areEqual('Opportunity.Account.Owner.ProfileId', field3?.toString(), 'Wrong ParentField value');
		Soql.Selectable field4 = new Soql.ParentField(
			OpportunityContactRole.OpportunityId,
			Opportunity.AccountId,
			Account.OwnerId,
			User.ProfileId,
			Profile.UserLicenseId
		);
		Assert.areEqual(
			'Opportunity.Account.Owner.Profile.UserLicenseId',
			field4?.toString(),
			'Wrong ParentField value'
		);
		Soql.Selectable field5 = new Soql.ParentField(
			OpportunityContactRole.OpportunityId,
			Opportunity.AccountId,
			Account.OwnerId,
			User.ProfileId,
			Profile.UserLicenseId,
			UserLicense.Name
		);
		Assert.areEqual(
			'Opportunity.Account.Owner.Profile.UserLicense.Name',
			field5?.toString(),
			'Wrong ParentField value'
		);
	}

	@IsTest
	private static void shouldCreateAggregateClause() {
		String value = new Soql.Aggregation(Soql.Function.COUNT, Account.Id)?.toString();
		Assert.areEqual('COUNT(Id)', value, 'Wrong toString() value');
	}

	@IsTest
	private static void shouldCreateAggregateClauseWithAlias() {
		String value = new Soql.Aggregation(Soql.Function.COUNT, Account.Id)?.withAlias('num')?.toString();
		Assert.areEqual('COUNT(Id) num', value, 'Wrong toString() value');
	}

	@IsTest
	private static void shouldCreateAggregateClauseWithoutInnerField() {
		String value = new Soql.Aggregation(Soql.Function.COUNT)?.toString();
		Assert.areEqual('COUNT()', value, 'Wrong toString() value');
	}

	@IsTest
	private static void shouldCreateBinderObject() {
		String key = 'ownerIds';
		List<Id> ownerIds = new List<Id>{ UserInfo.getUserId() };

		Test.startTest();
		Soql.Binder binder = new Soql.Binder(key, ownerIds);
		Test.stopTest();

		Assert.areEqual(key, binder?.getKey(), 'Wrong key');
		Assert.areEqual(':' + key, binder?.toString(), 'Wrong toString() value');
		Assert.isTrue(binder?.getValue() instanceof List<Id>, 'Wrong bind value type');
		List<Id> bindValues = (List<Id>) binder?.getValue();
		Assert.areEqual(1, bindValues?.size(), 'Wrong # of values');
	}

	@IsTest
	private static void shouldCreateEmptyBinder() {
		String key = 'ownerIds';

		Test.startTest();
		Soql.Binder binder = new Soql.Binder(key);
		Test.stopTest();

		Assert.areEqual(key, binder?.getKey(), 'Wrong key');
		Assert.areEqual(':' + key, binder?.toString(), 'Wrong toString() value');
		Assert.areEqual(null, binder?.getValue(), 'Wrong bind value');
	}

	@IsTest
	private static void shouldAddInnerQueryBindsToParent() {
		Soql.Binder owner = new Soql.Binder('ownerId', UserInfo.getUserId());
		Soql.InnerQuery innerQuery = new Soql.InnerQuery(Case.SObjectType)
			?.addSelect(Case.AccountId)
			?.addWhere(Case.OwnerId, Soql.EQUALS, owner)
			?.toInnerQuery();
		// Add the inner query to a Soql object, without explicitly adding the bind to the parent query:
		Soql testQuery = DatabaseLayer.Soql.newQuery(Account.SObjectType)
			?.addWhere(Account.Id, Soql.IN_COLLECTION, innerQuery)
			?.toSoql();
		String expected = 'SELECT Id FROM Account WHERE Id IN (SELECT AccountId FROM Case WHERE OwnerId = :ownerId)';

		Test.startTest();
		SoqlTest.validateQuery(testQuery, expected);
		Test.stopTest();

		String key = owner?.getKey();
		Assert.isTrue(testQuery?.binds?.containsKey(key), 'Did not add InnerQuery binds to Soql');
		Assert.areEqual(owner?.getValue(), testQuery?.binds?.get(key), 'Wrong `owner` bind value');
	}

	@IsTest
	private static void shouldAddSubqueryBindsToParent() {
		Soql.Binder owner = new Soql.Binder('ownerId', UserInfo.getUserId());
		Soql.Subquery subquery = new Soql.Subquery(Opportunity.AccountId)
			?.addWhere(Opportunity.OwnerId, Soql.EQUALS, owner)
			?.toSubquery();
		Soql testQuery = DatabaseLayer.Soql.newQuery(Account.SObjectType)?.addSelect(subquery)?.toSoql();
		String expected = 'SELECT Id, (SELECT Id FROM Opportunities WHERE OwnerId = :ownerId) FROM Account';

		Test.startTest();
		SoqlTest.validateQuery(testQuery, expected);
		Test.stopTest();

		String key = owner?.getKey();
		Assert.isTrue(testQuery?.binds?.containsKey(owner?.getKey()), 'Did not add Subquery binds to Soql');
		Assert.areEqual(owner?.getValue(), testQuery?.binds?.get(key), 'Wrong `owner` bind value');
	}

	@IsTest
	private static void shouldOrderByField() {
		String value = new Soql.SortOrder(Account.CreatedDate, Soql.SortDirection.ASCENDING)?.toString();
		Assert.areEqual('CreatedDate ASC NULLS LAST', value, 'Wrong value');
	}

	@IsTest
	private static void shouldOrderByParentField() {
		Soql.ParentField field = new Soql.ParentField(Opportunity.AccountId, Account.CreatedDate);
		String value = new Soql.SortOrder(field, Soql.SortDirection.ASCENDING)?.toString();
		Assert.areEqual('Account.CreatedDate ASC NULLS LAST', value, 'Wrong value');
	}

	@IsTest
	private static void shouldSpecifyNullOrder() {
		String value = new Soql.SortOrder(Account.CreatedDate, Soql.SortDirection.DESCENDING)
			?.setNullOrder(Soql.NullOrder.NULLS_FIRST)
			?.toString();
		Assert.areEqual('CreatedDate DESC NULLS FIRST', value, 'Wrong value');
	}

	@IsTest
	private static void shouldSetQueryIdentifier() {
		String identifier = 'My account query';
		Soql theQuery = DatabaseLayer.Soql.newQuery(Account.SObjectType)?.toSoql();

		Test.startTest();
		theQuery?.setQueryIdentifier(identifier);
		Test.stopTest();

		Assert.areEqual(identifier, theQuery?.identifier, 'Wrong query identifier');
	}

	@IsTest
	private static void shouldCastToInnerQuery() {
		Soql.Builder builder = new Soql.InnerQuery(Case.SObjectType)?.addSelect(Case.AccountId);

		Test.startTest();
		Soql.InnerQuery result = builder?.toInnerQuery();
		Test.stopTest();

		Assert.areEqual(builder?.toString(), result?.toString(), 'Wrong query string');
	}

	@IsTest
	private static void shouldCastToSoql() {
		Soql.Builder builder = DatabaseLayer.Soql.newQuery(Case.SObjectType)?.addSelect(Case.AccountId);

		Test.startTest();
		Soql result = builder?.toSoql();
		Test.stopTest();

		Assert.areEqual(builder?.toString(), result?.toString(), 'Wrong query string');
	}

	@IsTest
	private static void shouldCastToSubquery() {
		Soql.Builder builder = new Soql.Subquery(Case.AccountId)?.addSelect(Case.Status);

		Test.startTest();
		Soql.Subquery result = builder?.toSubquery();
		Test.stopTest();

		Assert.areEqual(builder?.toString(), result?.toString(), 'Wrong query string');
	}

	@IsTest
	private static void shouldThrowExceptionIfInvalidCasting() {
		Soql.Builder builder = new Soql.Subquery(Case.AccountId)?.addSelect(Case.Status);

		Test.startTest();
		// Subquery is never an instance of Soql!
		Exception caughtError;
		try {
			builder?.toSoql();
			Assert.fail('Did not throw a System.TypeException');
		} catch (System.TypeException error) {
			// As expected...
			caughtError = error;
		}
		Test.stopTest();
	}

	@IsTest
	private static void shouldRunPreAndPostProcessorPluginLogic() {
		DatabaseLayerTestUtils.initDmlAndSoqlPlugins(DatabaseLayerTestUtils.SamplePlugin.class.getName());

		Test.startTest();
		DatabaseLayer.Soql.newQuery(User.SObjectType)?.setRowLimit(1)?.toSoql()?.query();
		Test.stopTest();

		Assert.areEqual(1, DatabaseLayerTestUtils.SoqlPluginSpy?.numPreCalls, 'Wrong number of pre-soql plugin calls');
		Assert.areEqual(
			0,
			DatabaseLayerTestUtils.SoqlPluginSpy?.numErrorCalls,
			'Wrong number of soql error plugin calls'
		);
		Assert.areEqual(
			1,
			DatabaseLayerTestUtils.SoqlPluginSpy?.numPostCalls,
			'Wrong number of post-soql plugin calls'
		);
	}

	@IsTest
	private static void shouldRunPluginErrorLogic() {
		DatabaseLayerTestUtils.initDmlAndSoqlPlugins(DatabaseLayerTestUtils.SamplePlugin.class.getName());

		Test.startTest();
		Exception caughtError;
		try {
			// Can't query w/a null FROM object:
			DatabaseLayer.Soql.newQuery((SObjectType) null)?.toSoql()?.query();
			Assert.fail('Did not throw an Exception');
		} catch (Exception error) {
			// As expected...
			caughtError = error;
		}
		Test.stopTest();

		Assert.areEqual(1, DatabaseLayerTestUtils.SoqlPluginSpy?.numPreCalls, 'Wrong number of pre-soql plugin calls');
		Assert.areEqual(
			1,
			DatabaseLayerTestUtils.SoqlPluginSpy?.numErrorCalls,
			'Wrong number of soql error plugin calls'
		);
		Assert.areEqual(
			0,
			DatabaseLayerTestUtils.SoqlPluginSpy?.numPostCalls,
			'Wrong number of post-soql plugin calls'
		);
	}

	@IsTest
	private static void shouldNotRunProcessorLogicIfInvalidApexClassDefined() {
		DatabaseLayerTestUtils.initDmlAndSoqlPlugins('an obviously invalid apex class name');

		Test.startTest();
		DatabaseLayer.Soql.newQuery(User.SObjectType)?.setRowLimit(1)?.toSoql()?.query();
		Test.stopTest();

		Assert.areEqual(0, DatabaseLayerTestUtils.SoqlPluginSpy?.numPreCalls, 'Wrong number of pre-soql plugin calls');
		Assert.areEqual(
			0,
			DatabaseLayerTestUtils.SoqlPluginSpy?.numErrorCalls,
			'Wrong number of soql error plugin calls'
		);
		Assert.areEqual(
			0,
			DatabaseLayerTestUtils.SoqlPluginSpy?.numPostCalls,
			'Wrong number of post-soql plugin calls'
		);
	}

	@IsTest
	private static void shouldNotRunProcessorLogicIfNoValueDefined() {
		DatabaseLayerTestUtils.initDmlAndSoqlPlugins(null);

		Test.startTest();
		DatabaseLayer.Soql.newQuery(User.SObjectType)?.setRowLimit(1)?.toSoql()?.query();
		Test.stopTest();

		Assert.areEqual(0, DatabaseLayerTestUtils.SoqlPluginSpy?.numPreCalls, 'Wrong number of pre-soql plugin calls');
		Assert.areEqual(
			0,
			DatabaseLayerTestUtils.SoqlPluginSpy?.numErrorCalls,
			'Wrong number of soql error plugin calls'
		);
		Assert.areEqual(
			0,
			DatabaseLayerTestUtils.SoqlPluginSpy?.numPostCalls,
			'Wrong number of post-soql plugin calls'
		);
	}

	@IsTest
	private static void shouldNotRunProcessorLogicIfNoSettingsDefined() {
		MockCmdt.mock(DatabaseLayerParameter__mdt.SObjectType);
		DatabaseLayer.Utils.Plugins.init();

		Test.startTest();
		DatabaseLayer.Soql.newQuery(User.SObjectType)?.setRowLimit(1)?.toSoql()?.query();
		Test.stopTest();

		Assert.areEqual(0, DatabaseLayerTestUtils.SoqlPluginSpy?.numPreCalls, 'Wrong number of pre-soql plugin calls');
		Assert.areEqual(
			0,
			DatabaseLayerTestUtils.SoqlPluginSpy?.numErrorCalls,
			'Wrong number of soql error plugin calls'
		);
		Assert.areEqual(
			0,
			DatabaseLayerTestUtils.SoqlPluginSpy?.numPostCalls,
			'Wrong number of post-soql plugin calls'
		);
	}

	// **** HELPER **** //

	private static Object validateQuery(Soql soql, String expected) {
		Assert.areEqual('"' + expected + '"', '"' + soql + '"', 'Unexpected SOQL output');
		// This test will always run the queries in system mode to prevent FLS/CRUD errors
		// when the test is run by non-admin users (ex., CICD integrations w/minimal object access)
		soql?.setAccessLevel(System.AccessLevel.SYSTEM_MODE);
		return soql?.query();
	}

	@IsTest
	private static void shouldBuildTypeOfQuery() {
		Soql.TypeOf typeOfClause = new Soql.TypeOf(Task.WhatId)
			.when(Account.SObjectType)
			.thenSelect(Account.Name, Account.Phone)
			.when(Opportunity.SObjectType)
			.thenSelect(Opportunity.Name, Opportunity.StageName)
			.elseSelect('Name');

		Test.startTest();
		String result = typeOfClause?.toString();
		Test.stopTest();

		String expected = 'TYPEOF What WHEN Account THEN Name, Phone WHEN Opportunity THEN Name, StageName ELSE Name END';
		Assert.areEqual(expected, result, 'TypeOf query not formatted correctly');
	}

	@IsTest
	private static void shouldBuildTypeOfQueryWithSObjectField() {
		Soql.TypeOf typeOfClause = new Soql.TypeOf(Task.WhatId)
			.when(Account.SObjectType)
			.thenSelect(Account.Name)
			.elseSelect('Name');

		Test.startTest();
		String result = typeOfClause?.toString();
		Test.stopTest();

		String expected = 'TYPEOF What WHEN Account THEN Name ELSE Name END';
		Assert.areEqual(expected, result, 'TypeOf query with SObjectField not formatted correctly');
	}

	@IsTest
	private static void shouldBuildTypeOfQueryWithParentField() {
		Soql.Selectable parentField = new Soql.ParentField(Account.OwnerId, User.Name);
		Soql.TypeOf typeOfClause = new Soql.TypeOf(Task.WhatId)
			.when(Account.SObjectType)
			.thenSelect(parentField)
			.elseSelect('Name');

		Test.startTest();
		String result = typeOfClause?.toString();
		Test.stopTest();

		String expected = 'TYPEOF What WHEN Account THEN Owner.Name ELSE Name END';
		Assert.areEqual(expected, result, 'TypeOf query with SObjectField not formatted correctly');
	}

	@IsTest
	private static void shouldBuildTypeOfQueryWithMultipleFields() {
		Soql.TypeOf typeOfClause = new Soql.TypeOf(Task.WhatId)
			.when(Account.SObjectType)
			.thenSelect(new List<SObjectField>{ Account.Name, Account.Phone, Account.Type })
			.elseSelect('Name', 'Phone');

		Test.startTest();
		String result = typeOfClause?.toString();
		Test.stopTest();

		String expected = 'TYPEOF What WHEN Account THEN Name, Phone, Type ELSE Name, Phone END';
		Assert.areEqual(expected, result, 'TypeOf query with multiple fields not formatted correctly');
	}

	@IsTest
	private static void shouldBuildTypeOfQueryWithoutElse() {
		Soql.TypeOf typeOfClause = new Soql.TypeOf(Task.WhatId)
			.when(Account.SObjectType)
			.thenSelect(Account.Name)
			.when(Opportunity.SObjectType)
			.thenSelect(Opportunity.Name);

		Test.startTest();
		String result = typeOfClause?.toString();
		Test.stopTest();

		String expected = 'TYPEOF What WHEN Account THEN Name WHEN Opportunity THEN Name END';
		Assert.areEqual(expected, result, 'TypeOf query without ELSE not formatted correctly');
	}

	@IsTest
	private static void shouldUseTypeOfInSoqlQuery() {
		Soql.TypeOf typeOfClause = new Soql.TypeOf(Task.WhatId)
			.when(Case.SObjectType)
			.thenSelect(Case.CaseNumber)
			.elseSelect('Name');

		Soql soql = DatabaseLayer.Soql.newQuery(Task.SObjectType)?.addSelect(typeOfClause)?.toSoql();

		Test.startTest();
		String result = soql?.toString();
		Test.stopTest();

		String expected = 'SELECT Id, TYPEOF What WHEN Case THEN CaseNumber ELSE Name END FROM Task';
		Assert.areEqual(expected, result, 'SOQL query with TypeOf not formatted correctly');
	}

	@IsTest
	private static void shouldBuildTypeOfWithStringConstructor() {
		Soql.TypeOf typeOfClause = new Soql.TypeOf('What').when(Account.SObjectType).thenSelect(Account.Name);

		Test.startTest();
		String result = typeOfClause?.toString();
		Test.stopTest();

		String expected = 'TYPEOF What WHEN Account THEN Name END';
		Assert.areEqual(expected, result, 'TypeOf with string constructor not formatted correctly');
	}

	@IsTest
	private static void shouldBuildTypeOfWithParentField() {
		Soql.ParentField parentField = new Soql.ParentField(Case.ContactId, Contact.OwnerId);
		Soql.TypeOf typeOfClause = new Soql.TypeOf(parentField).when(User.SObjectType).thenSelect(User.Name);

		Test.startTest();
		String result = typeOfClause?.toString();
		Test.stopTest();

		String expected = 'TYPEOF Contact.Owner WHEN User THEN Name END';
		Assert.areEqual(expected, result, 'TypeOf with parent field not formatted correctly');
	}

	@IsTest
	private static void shouldTestAllThenSelectOverloads() {
		Soql.TypeOf typeOfClause = new Soql.TypeOf(Task.WhatId);

		Test.startTest();
		typeOfClause.when(Account.SObjectType).thenSelect(Account.Name);
		typeOfClause.when(Contact.SObjectType).thenSelect(Contact.FirstName, Contact.LastName);
		typeOfClause.when(Lead.SObjectType).thenSelect(Lead.FirstName, Lead.LastName, Lead.Company);
		typeOfClause.when(Opportunity.SObjectType)
			.thenSelect(Opportunity.Name, Opportunity.StageName, Opportunity.Amount, Opportunity.CloseDate);
		typeOfClause.when(Case.SObjectType)
			.thenSelect(Case.Subject, Case.Status, Case.Priority, Case.Origin, Case.Type);
		String result = typeOfClause?.toString();
		Test.stopTest();

		// Should contain all WHEN clauses
		Assert.isTrue(result?.contains('WHEN Account THEN Name'), 'Missing Account WHEN clause');
		Assert.isTrue(result?.contains('WHEN Contact THEN FirstName, LastName'), 'Missing Contact WHEN clause');
		Assert.isTrue(result?.contains('WHEN Lead THEN FirstName, LastName, Company'), 'Missing Lead WHEN clause');
		Assert.isTrue(
			result?.contains('WHEN Opportunity THEN Name, StageName, Amount, CloseDate'),
			'Missing Opportunity WHEN clause'
		);
		Assert.isTrue(
			result?.contains('WHEN Case THEN Subject, Status, Priority, Origin, Type'),
			'Missing Case WHEN clause'
		);
	}

	@IsTest
	private static void shouldTestAllElseSelectOverloads() {
		Test.startTest();
		Soql.TypeOf typeOf1 = new Soql.TypeOf(Task.WhatId).elseSelect('Name');
		Assert.isTrue(typeOf1?.toString()?.contains('ELSE Name'), 'Missing single field ELSE');
		Soql.TypeOf typeOf2 = new Soql.TypeOf(Task.WhatId).elseSelect('Name', 'Type');
		Assert.isTrue(typeOf2?.toString()?.contains('ELSE Name, Type'), 'Missing 2 field ELSE');
		Soql.TypeOf typeOf3 = new Soql.TypeOf(Task.WhatId).elseSelect('Name', 'Type', 'Status');
		Assert.isTrue(typeOf3?.toString()?.contains('ELSE Name, Type, Status'), 'Missing 3 field ELSE');
		Soql.TypeOf typeOf4 = new Soql.TypeOf(Task.WhatId).elseSelect('Name', 'Type', 'Status', 'Id');
		Assert.isTrue(typeOf4?.toString()?.contains('ELSE Name, Type, Status, Id'), 'Missing 4 field ELSE');
		Soql.TypeOf typeOf5 = new Soql.TypeOf(Task.WhatId).elseSelect('Name', 'Type', 'Status', 'Id', 'CreatedDate');
		Assert.isTrue(
			typeOf5?.toString()?.contains('ELSE Name, Type, Status, Id, CreatedDate'),
			'Missing 5 field ELSE'
		);
		List<String> fields = new List<String>{ 'Name', 'Description' };
		Soql.TypeOf typeOfList = new Soql.TypeOf(Task.WhatId).elseSelect(fields);
		Assert.isTrue(typeOfList?.toString()?.contains('ELSE Name, Description'), 'Missing List<String> ELSE');
		Test.stopTest();
	}

	@IsTest
	private static void shouldHandleNullFieldsInOverloads() {
		Test.startTest();
		// Test with some null fields in 5-field overload
		Soql.TypeOf typeOfClause = new Soql.TypeOf(Task.WhatId)
			.when(Account.SObjectType)
			.thenSelect(Account.Name, Account.Type, null, null, null);
		String result = typeOfClause?.toString();
		Assert.isTrue(result?.contains('WHEN Account THEN Name, Type'), 'Should handle null fields in thenSelect');

		// Test elseSelect with null fields
		Soql.TypeOf typeOfElse = new Soql.TypeOf(Task.WhatId).elseSelect('Name', 'Type', null, null, null);
		String elseResult = typeOfElse?.toString();
		Assert.isTrue(elseResult?.contains('ELSE Name, Type'), 'Should handle null fields in elseSelect');
		Test.stopTest();
	}

	// **** INNER **** //
	private class SampleWrapper {
		public Integer numRecords;
		public String profileName;
	}
}
