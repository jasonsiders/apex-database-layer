@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs,PMD.CyclomaticComplexity,PMD.NcssCount')
@IsTest
private class InvocableSoqlTest {
	private static final List<Object> NO_VALUES = new List<Object>{};

	static {
		// Custom metadata actually defined in the org should not interfere with this test:
		MockCmdt.mock(DatabaseLayerParameter__mdt.SObjectType);
		DatabaseLayer.useMockSoql();
	}

	// **** TESTS **** //
	@IsTest
	private static void shouldQueryWithStaticCondition() {
		Account acme = InvocableSoqlTest.initAccount('Acme', null);
		InvocableSoqlTest.mockRows(new List<SObject>{ acme });
		InvocableSoql.Query query = InvocableSoqlTest.initQuery('Account', new List<String>{ 'Name' });
		query.conditions.add(InvocableSoqlTest.initCondition('Name', 'EQUALS', 'Acme'));

		Test.startTest();
		InvocableSoql.Output output = InvocableSoqlTest.invoke(InvocableSoqlTest.initInput(query));
		Test.stopTest();

		Assert.areEqual(1, output?.records?.size(), 'Wrong # of records');
		Assert.areEqual(acme, output?.record, 'Wrong record');
		Assert.areEqual('SELECT Id, Name FROM Account WHERE Name = \'Acme\'', output?.queryString, 'Wrong query');
	}

	@IsTest
	private static void shouldReturnEmptyResults() {
		InvocableSoql.Query query = InvocableSoqlTest.initQuery('Account', null);

		Test.startTest();
		InvocableSoql.Output output = InvocableSoqlTest.invoke(InvocableSoqlTest.initInput(query));
		Test.stopTest();

		Assert.isTrue(output?.records?.isEmpty(), 'Wrong records: ' + output?.records);
		Assert.isNull(output?.record, 'Wrong single record');
		Assert.areEqual('SELECT Id FROM Account', output?.queryString, 'Wrong query');
	}

	@IsTest
	private static void shouldBindSlotValues() {
		// One real query, since only the database rejects a bind of the wrong type, ex: a Decimal for an Integer field
		DatabaseLayer.useRealSoql();
		Account account = new Account(Name = 'Acme', NumberOfEmployees = 50);
		insert account;
		Date birthdate = Date.newInstance(2000, 1, 15);
		insert new List<Contact>{
			new Contact(AccountId = account.Id, Birthdate = birthdate, LastName = 'Match'),
			new Contact(AccountId = account.Id, Birthdate = birthdate, LastName = 'Other')
		};
		InvocableSoql.Query query = InvocableSoqlTest.initQuery('Contact', new List<String>{ 'LastName' });
		query.conditions.add(InvocableSoqlTest.initSlotCondition('LastName', 'EQUALS', 'text1'));
		query.conditions.add(InvocableSoqlTest.initSlotCondition('Birthdate', 'EQUALS', 'date1'));
		query.conditions.add(InvocableSoqlTest.initSlotCondition('IsDeleted', 'EQUALS', 'boolean1'));
		// Flow passes numbers as Decimals, which SOQL can't bind to an Integer field without coercion:
		query.conditions.add(InvocableSoqlTest.initSlotCondition('Account.NumberOfEmployees', 'EQUALS', 'number1'));
		query.conditions.add(InvocableSoqlTest.initSlotCondition('LastModifiedDate', 'GREATER_THAN', 'dateTime1'));
		InvocableSoql.Input input = InvocableSoqlTest.initInput(query);
		input.text1 = 'Match';
		input.date1 = birthdate;
		input.boolean1 = false;
		input.number1 = 50.0;
		input.dateTime1 = DateTime.newInstanceGmt(2000, 1, 1, 12, 30, 0);
		// Differing only in its number, this interview merges with the first, so the query binds a list of them:
		String inputJson = JSON.serialize(input);
		InvocableSoql.Input other = (InvocableSoql.Input) JSON.deserialize(inputJson, InvocableSoql.Input.class);
		other.number1 = 60.0;

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ input, other });
		Integer queries = Limits.getQueries();
		Test.stopTest();

		InvocableSoql.Output output = outputs?.get(0);
		Assert.areEqual(1, queries, 'Did not merge the interviews');
		Assert.areEqual(1, output?.records?.size(), 'Wrong # of records');
		Assert.isTrue(outputs?.get(1)?.records?.isEmpty(), 'Wrong records for the other number');
		String expected =
			'SELECT Id, LastName, Birthdate, IsDeleted, Account.NumberOfEmployees, LastModifiedDate FROM Contact ' +
			'WHERE LastName = \'Match\' AND Birthdate = 2000-01-15 AND IsDeleted = false AND ' +
			'Account.NumberOfEmployees = 50 AND LastModifiedDate > 2000-01-01T12:30:00Z';
		Assert.areEqual(expected, output?.queryString, 'Wrong query');
	}

	@IsTest
	private static void shouldBindTimes() {
		InvocableSoql.Query query = InvocableSoqlTest.initQuery('BusinessHours', null);
		query.conditions.add(InvocableSoqlTest.initSlotCondition('MondayStartTime', 'GREATER_OR_EQUAL', 'time1'));
		// A typed time has no zone; JSON alone would read it in the running user's time zone:
		query.conditions.add(InvocableSoqlTest.initCondition('MondayEndTime', 'LESS_THAN', '17:30'));
		InvocableSoql.Input input = InvocableSoqlTest.initInput(query);
		input.time1 = Time.newInstance(9, 30, 0, 0);

		Test.startTest();
		InvocableSoql.Output output = InvocableSoqlTest.invoke(input);
		Test.stopTest();

		String expected =
			'SELECT Id, MondayStartTime, MondayEndTime FROM BusinessHours ' +
			'WHERE MondayStartTime >= 09:30:00.000Z AND MondayEndTime < 17:30:00.000Z';
		Assert.areEqual(expected, output?.queryString, 'Wrong query');
	}

	@IsTest
	private static void shouldMatchRecordCollectionByIds() {
		InvocableSoqlTest.QuerySpy spy = InvocableSoqlTest.mockRows(new List<SObject>{});
		Account account = InvocableSoqlTest.initAccount('Acme', null);
		InvocableSoql.Query query = InvocableSoqlTest.initQuery('Contact', new List<String>{ 'LastName' });
		query.conditions.add(InvocableSoqlTest.initSlotCondition('AccountId', 'IN', 'recordCollection1'));
		InvocableSoql.Input input = InvocableSoqlTest.initInput(query);
		// Duplicates collapse, like they would in IN:
		input.recordCollection1 = new List<Account>{ account, account };

		Test.startTest();
		InvocableSoql.Output output = InvocableSoqlTest.invoke(input);
		Test.stopTest();

		Object boundIds = spy.queries?.get(0)?.binds?.get('bind0');
		Assert.areEqual(new List<Id>{ account.Id }, boundIds, 'Wrong bound IDs');
		Assert.isTrue(
			output?.queryString?.endsWith('WHERE AccountId IN (\'' + account.Id + '\')'),
			output?.queryString
		);
	}

	@IsTest
	private static void shouldThrowForRecordWithoutId() {
		InvocableSoql.Query query = InvocableSoqlTest.initQuery('Contact', null);
		query.conditions.add(InvocableSoqlTest.initSlotCondition('AccountId', 'IN', 'recordCollection1'));
		InvocableSoql.Input input = InvocableSoqlTest.initInput(query);
		input.recordCollection1 = new List<Account>{ new Account(Name = 'Unsaved') };

		Test.startTest();
		Exception caughtError = InvocableSoqlTest.invokeAndCatch(input);
		Test.stopTest();

		Assert.isInstanceOfType(caughtError, IllegalArgumentException.class, 'Wrong error: ' + caughtError);
	}

	@IsTest
	private static void shouldBindUnsetCollectionAsEmpty() {
		InvocableSoql.Query query = InvocableSoqlTest.initQuery('Account', null);
		query.conditions.add(InvocableSoqlTest.initSlotCondition('Name', 'IN', 'textCollection1'));

		Test.startTest();
		InvocableSoql.Output output = InvocableSoqlTest.invoke(InvocableSoqlTest.initInput(query));
		Test.stopTest();

		Assert.areEqual('SELECT Id, Name FROM Account WHERE Name IN ()', output?.queryString, 'Wrong query');
	}

	@IsTest
	private static void shouldMatchWildcardCharactersLiterally() {
		Test.startTest();
		InvocableSoql.Output contains = InvocableSoqlTest.invokeOnName('CONTAINS', '50%');
		InvocableSoql.Output startsWith = InvocableSoqlTest.invokeOnName('STARTS_WITH', 'a_');
		InvocableSoql.Output endsWith = InvocableSoqlTest.invokeOnName('ENDS_WITH', 'now');
		InvocableSoql.Output pattern = InvocableSoqlTest.invokeOnName('LIKE', 'a_b');
		Test.stopTest();

		String queryPrefix = 'SELECT Id, Name FROM Account WHERE Name LIKE ';
		Assert.areEqual(queryPrefix + '\'%50\\%%\'', contains?.queryString, 'Wrong CONTAINS query');
		Assert.areEqual(queryPrefix + '\'a\\_%\'', startsWith?.queryString, 'Wrong STARTS_WITH query');
		Assert.areEqual(queryPrefix + '\'%now\'', endsWith?.queryString, 'Wrong ENDS_WITH query');
		// LIKE passes its pattern through, wildcards and all:
		Assert.areEqual(queryPrefix + '\'a_b\'', pattern?.queryString, 'Wrong LIKE query');
	}

	@IsTest
	private static void shouldQueryParentFields() {
		InvocableSoql.Query query = InvocableSoqlTest.initQuery('Contact', new List<String>{ 'Account.Name' });
		query.conditions.add(InvocableSoqlTest.initCondition('Account.Owner.IsActive', 'EQUALS', 'true'));
		InvocableSoql.Query tasks = InvocableSoqlTest.initQuery('Task', new List<String>{ 'Who.Name' });
		tasks.conditions.add(InvocableSoqlTest.initCondition('Who.Type', 'EQUALS', 'Contact'));

		Test.startTest();
		InvocableSoql.Output output = InvocableSoqlTest.invoke(InvocableSoqlTest.initInput(query));
		InvocableSoql.Output taskOutput = InvocableSoqlTest.invoke(InvocableSoqlTest.initInput(tasks));
		Test.stopTest();

		String expected = 'SELECT Id, Account.Name, Account.Owner.IsActive FROM Contact WHERE Account.Owner.IsActive = true';
		Assert.areEqual(expected, output?.queryString, 'Wrong query');
		String expectedTasks = 'SELECT Id, Who.Name, Who.Type FROM Task WHERE Who.Type = \'Contact\'';
		Assert.areEqual(expectedTasks, taskOutput?.queryString, 'Wrong polymorphic query');
	}

	@IsTest
	private static void shouldApplyConditionLogic() {
		InvocableSoql.Query query = InvocableSoqlTest.initQuery('Account', null);
		query.conditions.add(InvocableSoqlTest.initCondition('Name', 'EQUALS', 'Acme'));
		query.conditions.add(InvocableSoqlTest.initCondition('Name', 'EQUALS', 'Beta'));
		query.conditions.add(InvocableSoqlTest.initCondition('Site', 'EQUALS', 'West'));
		InvocableSoql.Query anyQuery = (InvocableSoql.Query) JSON.deserialize(
			JSON.serialize(query),
			InvocableSoql.Query.class
		);
		anyQuery.conditionLogic = 'or';
		query.conditionLogic = '1 OR (2 AND NOT 3)';

		Test.startTest();
		InvocableSoql.Output customOutput = InvocableSoqlTest.invoke(InvocableSoqlTest.initInput(query));
		InvocableSoql.Output anyOutput = InvocableSoqlTest.invoke(InvocableSoqlTest.initInput(anyQuery));
		Test.stopTest();

		// Grouped, so a condition that a SOQL plugin adds applies to all of it:
		String expected = 'SELECT Id, Name, Site FROM Account WHERE (Name = \'Acme\' OR (Name = \'Beta\' AND (NOT Site = \'West\')))';
		Assert.areEqual(expected, customOutput?.queryString, 'Wrong custom logic query');
		Assert.isTrue(
			anyOutput?.queryString?.contains('Name = \'Acme\' OR Name = \'Beta\' OR Site'),
			anyOutput?.queryString
		);
	}

	@IsTest
	private static void shouldWrapNegatedGroups() {
		InvocableSoql.Query query = InvocableSoqlTest.initQuery('Account', null);
		query.conditions.add(InvocableSoqlTest.initCondition('Name', 'EQUALS', 'Acme'));
		query.conditions.add(InvocableSoqlTest.initCondition('Name', 'EQUALS', 'Beta'));
		query.conditions.add(InvocableSoqlTest.initCondition('Site', 'EQUALS', 'East'));
		query.conditionLogic = 'not (1 or 2) and not not 3';

		Test.startTest();
		InvocableSoql.Output output = InvocableSoqlTest.invoke(InvocableSoqlTest.initInput(query));
		Test.stopTest();

		String expected =
			'SELECT Id, Name, Site FROM Account WHERE (NOT (Name = \'Acme\' OR Name = \'Beta\')) AND ' +
			'(NOT (NOT Site = \'East\'))';
		Assert.areEqual(expected, output?.queryString, 'Wrong query');
	}

	@IsTest
	private static void shouldRejectInvalidConditionLogic() {
		InvocableSoql.Query query = InvocableSoqlTest.initQuery('Account', null);
		query.conditions.add(InvocableSoqlTest.initCondition('Name', 'EQUALS', 'Acme'));
		InvocableSoql.Query outOfRange = (InvocableSoql.Query) JSON.deserialize(
			JSON.serialize(query),
			InvocableSoql.Query.class
		);
		InvocableSoql.Query unbalanced = (InvocableSoql.Query) JSON.deserialize(
			JSON.serialize(query),
			InvocableSoql.Query.class
		);
		outOfRange.conditionLogic = '1 AND 2';
		// SOQL would fail every query on a syntax error, so the action fails first, naming the logic
		unbalanced.conditionLogic = 'NOT (1';
		query.conditionLogic = '1 OR Name != null';

		Test.startTest();
		Exception injectedError = InvocableSoqlTest.invokeAndCatch(InvocableSoqlTest.initInput(query));
		Exception outOfRangeError = InvocableSoqlTest.invokeAndCatch(InvocableSoqlTest.initInput(outOfRange));
		Exception unbalancedError = InvocableSoqlTest.invokeAndCatch(InvocableSoqlTest.initInput(unbalanced));
		Test.stopTest();

		Assert.isInstanceOfType(injectedError, IllegalArgumentException.class, 'Wrong error: ' + injectedError);
		Assert.isInstanceOfType(outOfRangeError, IllegalArgumentException.class, 'Wrong error: ' + outOfRangeError);
		Assert.isInstanceOfType(unbalancedError, IllegalArgumentException.class, 'Wrong error: ' + unbalancedError);
	}

	@IsTest
	private static void shouldRenderLiteralOnlyConditions() {
		InvocableSoql.Query query = InvocableSoqlTest.initQuery('Account', null);
		InvocableSoql.Condition includes = InvocableSoqlTest.initCondition('Name', 'INCLUDES', null);
		includes.values = new List<String>{ 'a;b', 'c' };
		InvocableSoql.Condition excludes = InvocableSoqlTest.initCondition('Site', 'EXCLUDES', null);
		excludes.values = new List<String>{ 'it\'s' };
		InvocableSoql.Condition dateLiteral = InvocableSoqlTest.initCondition('CreatedDate', 'GREATER_THAN', null);
		dateLiteral.dateLiteral = 'LAST_N_DAYS:30';
		query.conditions.addAll(
			new List<InvocableSoql.Condition>{
				includes,
				excludes,
				InvocableSoqlTest.initCondition('Phone', 'IS_NULL', 'true'),
				// Like Get Records, Is Null takes true or false; false finds the records with a value
				InvocableSoqlTest.initCondition('Fax', 'IS_NULL', 'false'),
				dateLiteral
			}
		);

		Test.startTest();
		InvocableSoql.Output output = InvocableSoqlTest.invoke(InvocableSoqlTest.initInput(query));
		Test.stopTest();

		String expected =
			'SELECT Id, Name, Site, Phone, Fax, CreatedDate FROM Account WHERE Name INCLUDES (\'a;b\', \'c\') AND ' +
			'Site EXCLUDES (\'it\\\'s\') AND Phone = null AND Fax != null AND CreatedDate > LAST_N_DAYS:30';
		Assert.areEqual(expected, output?.queryString, 'Wrong query');
	}

	@IsTest
	private static void shouldRejectMalformedDateLiteral() {
		InvocableSoql.Query query = InvocableSoqlTest.initQuery('Account', null);
		InvocableSoql.Condition condition = InvocableSoqlTest.initCondition('CreatedDate', 'EQUALS', null);
		condition.dateLiteral = 'TODAY OR Name != null';
		query.conditions.add(condition);

		Test.startTest();
		Exception caughtError = InvocableSoqlTest.invokeAndCatch(InvocableSoqlTest.initInput(query));
		Test.stopTest();

		Assert.isInstanceOfType(caughtError, IllegalArgumentException.class, 'Wrong error: ' + caughtError);
	}

	@IsTest
	private static void shouldApplyOrderByLimitAndOffset() {
		InvocableSoql.Query query = InvocableSoqlTest.initQuery('Account', new List<String>{ 'Name' });
		InvocableSoql.SortOrder byName = new InvocableSoql.SortOrder();
		byName.field = 'Name';
		byName.direction = 'DESCENDING';
		byName.nullOrder = 'NULLS_FIRST';
		InvocableSoql.SortOrder byId = new InvocableSoql.SortOrder();
		byId.field = 'Id';
		query.orderBy = new List<InvocableSoql.SortOrder>{ byName, byId };
		query.rowLimit = 1;
		query.rowOffset = 1;

		Test.startTest();
		InvocableSoql.Output output = InvocableSoqlTest.invoke(InvocableSoqlTest.initInput(query));
		Test.stopTest();

		String expected = 'SELECT Id, Name FROM Account ORDER BY Name DESC NULLS FIRST, Id ASC NULLS LAST LIMIT 1 OFFSET 1';
		Assert.areEqual(expected, output?.queryString, 'Wrong query');
	}

	@IsTest
	private static void shouldApplyUsage() {
		InvocableSoql.Query query = InvocableSoqlTest.initQuery('Account', null);
		query.conditions.add(InvocableSoqlTest.initCondition('IsDeleted', 'EQUALS', 'true'));
		query.usage = 'ALL_ROWS';

		Test.startTest();
		InvocableSoql.Output output = InvocableSoqlTest.invoke(InvocableSoqlTest.initInput(query));
		Test.stopTest();

		Assert.areEqual('SELECT Id, IsDeleted FROM Account WHERE IsDeleted = true ALL ROWS', output?.queryString);
	}

	@IsTest
	private static void shouldApplyAccessLevel() {
		InvocableSoqlTest.QuerySpy spy = InvocableSoqlTest.mockRows(new List<SObject>{});
		InvocableSoql.Input systemMode = InvocableSoqlTest.initInput(InvocableSoqlTest.initQuery('Account', null));
		systemMode.accessLevel = 'SYSTEM_MODE';
		InvocableSoql.Input userMode = InvocableSoqlTest.initInput(InvocableSoqlTest.initQuery('Account', null));
		InvocableSoql.Input invalid = InvocableSoqlTest.initInput(InvocableSoqlTest.initQuery('Account', null));
		invalid.accessLevel = 'GOD_MODE';

		Test.startTest();
		InvocableSoqlTest.invoke(systemMode);
		InvocableSoqlTest.invoke(userMode);
		Exception caughtError = InvocableSoqlTest.invokeAndCatch(invalid);
		Test.stopTest();

		Assert.areEqual(System.AccessLevel.SYSTEM_MODE, spy.queries?.get(0)?.accessLevel, 'Wrong access level');
		Assert.areEqual(System.AccessLevel.USER_MODE, spy.queries?.get(1)?.accessLevel, 'Did not default to USER_MODE');
		Assert.isInstanceOfType(caughtError, IllegalArgumentException.class, 'Wrong error: ' + caughtError);
	}

	@IsTest
	private static void shouldRejectInvalidDefinitions() {
		InvocableSoql.Query unknownField = InvocableSoqlTest.initQuery('Account', null);
		unknownField.conditions.add(InvocableSoqlTest.initCondition('Not_A_Field__c', 'EQUALS', 'x'));
		InvocableSoql.Query unknownParent = InvocableSoqlTest.initQuery('Contact', null);
		unknownParent.conditions.add(InvocableSoqlTest.initCondition('Nope.Name', 'EQUALS', 'x'));
		InvocableSoql.Query unknownOperator = InvocableSoqlTest.initQuery('Account', null);
		unknownOperator.conditions.add(InvocableSoqlTest.initCondition('Name', 'SOUNDS_LIKE', 'x'));
		InvocableSoql.Query unknownSlot = InvocableSoqlTest.initQuery('Account', null);
		unknownSlot.conditions.add(InvocableSoqlTest.initSlotCondition('Name', 'EQUALS', 'text99'));
		InvocableSoql.Query unknownSelectField = InvocableSoqlTest.initQuery(
			'Account',
			new List<String>{ 'Name, (SELECT Id FROM Contacts)' }
		);
		InvocableSoql.Query unknownSortField = InvocableSoqlTest.initQuery('Account', null);
		InvocableSoql.SortOrder badSort = new InvocableSoql.SortOrder();
		badSort.field = 'Nope__c';
		unknownSortField.orderBy = new List<InvocableSoql.SortOrder>{ badSort };
		InvocableSoql.Query malformedDateLiteral = InvocableSoqlTest.initQuery('Account', null);
		InvocableSoql.Condition fakeLiteral = InvocableSoqlTest.initCondition('CreatedDate', 'EQUALS', null);
		fakeLiteral.dateLiteral = 'FOO_BAR:3';
		malformedDateLiteral.conditions.add(fakeLiteral);
		// Without TYPEOF, a polymorphic relationship only allows the Name object's fields:
		InvocableSoql.Query polymorphicField = InvocableSoqlTest.initQuery('Task', new List<String>{ 'Who.Birthdate' });
		InvocableSoql.Query unknownAllFields = InvocableSoqlTest.initQuery('Contact', new List<String>{ 'Nope.*' });
		InvocableSoql.Query missingObject = InvocableSoqlTest.initQuery(null, null);
		InvocableSoql.Input missingDefinition = new InvocableSoql.Input();

		Test.startTest();
		List<Exception> errors = new List<Exception>{
			InvocableSoqlTest.invokeAndCatch(InvocableSoqlTest.initInput(unknownField)),
			InvocableSoqlTest.invokeAndCatch(InvocableSoqlTest.initInput(unknownParent)),
			InvocableSoqlTest.invokeAndCatch(InvocableSoqlTest.initInput(unknownOperator)),
			InvocableSoqlTest.invokeAndCatch(InvocableSoqlTest.initInput(unknownSlot)),
			InvocableSoqlTest.invokeAndCatch(InvocableSoqlTest.initInput(unknownSelectField)),
			InvocableSoqlTest.invokeAndCatch(InvocableSoqlTest.initInput(unknownSortField)),
			InvocableSoqlTest.invokeAndCatch(InvocableSoqlTest.initInput(malformedDateLiteral)),
			InvocableSoqlTest.invokeAndCatch(InvocableSoqlTest.initInput(polymorphicField)),
			InvocableSoqlTest.invokeAndCatch(InvocableSoqlTest.initInput(unknownAllFields)),
			InvocableSoqlTest.invokeAndCatch(InvocableSoqlTest.initInput(missingObject)),
			InvocableSoqlTest.invokeAndCatch(missingDefinition)
		};
		Test.stopTest();

		for (Exception error : errors) {
			Assert.isInstanceOfType(error, IllegalArgumentException.class, 'Wrong error: ' + error);
		}
	}

	@IsTest
	private static void shouldCoerceStaticValues() {
		InvocableSoqlTest.QuerySpy spy = InvocableSoqlTest.mockRows(new List<SObject>{});
		Id accountId = MockRecord.initRecordId(Account.SObjectType);
		InvocableSoql.Query query = InvocableSoqlTest.initQuery('Contact', null);
		query.conditions.add(InvocableSoqlTest.initCondition('Birthdate', 'EQUALS', '2000-01-15'));
		query.conditions.add(InvocableSoqlTest.initCondition('Account.AnnualRevenue', 'EQUALS', '1000.50'));
		query.conditions.add(InvocableSoqlTest.initCondition('Account.NumberOfEmployees', 'LESS_OR_EQUAL', '50'));
		query.conditions.add(InvocableSoqlTest.initCondition('LastModifiedDate', 'LESS_THAN', '2999-01-01T00:00:00Z'));
		// 15-character IDs work too:
		query.conditions.add(
			InvocableSoqlTest.initCondition('AccountId', 'EQUALS', String.valueOf(accountId).left(15))
		);
		InvocableSoql.Condition employeeCounts = InvocableSoqlTest.initCondition(
			'Account.NumberOfEmployees',
			'IN',
			null
		);
		employeeCounts.values = new List<String>{ '50', '60' };
		query.conditions.add(employeeCounts);

		Test.startTest();
		InvocableSoql.Output output = InvocableSoqlTest.invoke(InvocableSoqlTest.initInput(query));
		Test.stopTest();

		// SOQL binds are strictly typed, so each value takes its field's type:
		Map<String, Object> binds = spy.queries?.get(0)?.binds;
		Assert.areEqual(Date.newInstance(2000, 1, 15), binds?.get('bind0'), 'Wrong date');
		Assert.isInstanceOfType(binds?.get('bind1'), Decimal.class, 'Wrong currency type');
		Assert.isInstanceOfType(binds?.get('bind2'), Integer.class, 'Wrong whole number type');
		Assert.isInstanceOfType(binds?.get('bind3'), DateTime.class, 'Wrong date/time type');
		Assert.areEqual(accountId, binds?.get('bind4'), 'Wrong ID');
		Assert.isTrue(output?.queryString?.contains('AccountId = \'' + accountId + '\''), output?.queryString);
		Assert.isTrue(output?.queryString?.endsWith('Account.NumberOfEmployees IN (50, 60)'), output?.queryString);
	}

	@IsTest
	private static void shouldRejectFractionsForWholeNumberFields() {
		InvocableSoql.Query query = InvocableSoqlTest.initQuery('Account', null);
		query.conditions.add(InvocableSoqlTest.initSlotCondition('NumberOfEmployees', 'LESS_THAN', 'number1'));
		InvocableSoql.Input input = InvocableSoqlTest.initInput(query);
		input.number1 = 42.5;

		Test.startTest();
		Exception caughtError = InvocableSoqlTest.invokeAndCatch(input);
		Test.stopTest();

		Assert.isInstanceOfType(caughtError, IllegalArgumentException.class, 'Wrong error: ' + caughtError);
	}

	@IsTest
	private static void shouldEscapeQuotesInQueryString() {
		InvocableSoql.Query query = InvocableSoqlTest.initQuery('Account', null);
		query.conditions.add(InvocableSoqlTest.initCondition('Name', 'NOT_EQUALS', 'O\'Brien'));
		query.conditions.add(InvocableSoqlTest.initSlotCondition('Site', 'EQUALS', 'text1'));

		Test.startTest();
		InvocableSoql.Output output = InvocableSoqlTest.invoke(InvocableSoqlTest.initInput(query));
		Test.stopTest();

		Assert.areEqual(
			'SELECT Id, Name, Site FROM Account WHERE Name != \'O\\\'Brien\' AND Site = null',
			output?.queryString,
			'Wrong query'
		);
	}

	@IsTest
	private static void shouldListQueryableObjects() {
		Test.startTest();
		List<InvocableSoql.ObjectOption> objects = InvocableSoql.getObjects();
		Test.stopTest();

		Map<String, InvocableSoql.ObjectOption> objectsByName = new Map<String, InvocableSoql.ObjectOption>{};
		for (InvocableSoql.ObjectOption option : objects) {
			objectsByName.put(option.apiName, option);
		}
		Assert.areEqual(
			Account.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
			objectsByName.get('Account')?.label,
			'Wrong label'
		);
		Assert.isFalse(objectsByName.containsKey('AggregateResult'), 'Listed an object that cannot be queried');
	}

	@IsTest
	private static void shouldListFields() {
		Test.startTest();
		Map<String, InvocableSoql.FieldOption> fieldsByName = InvocableSoqlTest.indexFields('Contact');
		Map<String, InvocableSoql.FieldOption> taskFieldsByName = InvocableSoqlTest.indexFields('Task');
		InvocableSoql.FieldOption folderId = InvocableSoqlTest.indexFields('Document').get('FolderId');
		InvocableSoql.FieldOption createdById = InvocableSoqlTest.indexFields('AccountHistory').get('CreatedById');
		InvocableSoql.FieldOption permissionSetId = InvocableSoqlTest.indexFields('ObjectPermissions').get('ParentId');
		Test.stopTest();

		Assert.isTrue(taskFieldsByName.get('WhoId')?.isPolymorphic, 'WhoId looks up to Contacts and Leads');
		Assert.areEqual('Name', taskFieldsByName.get('WhoId')?.referenceTo, 'Polymorphic lookups drill into Name');
		Assert.areEqual('Contact', fieldsByName.get('Id')?.referenceTo, 'An ID holds its own object\'s IDs');
		// FolderId holds Folder or User IDs, but SOQL resolves it to Folder:
		Assert.isTrue(folderId?.isPolymorphic, 'FolderId looks up to Folders and Users');
		Assert.areEqual('Folder', folderId?.referenceTo, 'Wrong parent object for a multi-object lookup');
		// CreatedById only holds User IDs, but SOQL resolves it to Name:
		Assert.isTrue(createdById?.isPolymorphic, 'A name-pointing lookup takes any object\'s records');
		Assert.areEqual('Name', createdById?.referenceTo, 'Name-pointing lookups drill into Name');
		// ParentId is name-pointing too, but SOQL resolves it to PermissionSet, so it only takes permission sets:
		Assert.areEqual('PermissionSet', permissionSetId?.referenceTo, 'Wrong parent object');
		Assert.isFalse(permissionSetId?.isPolymorphic, 'ParentId only takes permission sets');
		InvocableSoql.FieldOption accountId = fieldsByName.get('AccountId');
		Assert.areEqual('Account', accountId?.relationshipName, 'Wrong relationship name');
		Assert.areEqual('Account', accountId?.referenceTo, 'Wrong parent object');
		Assert.areEqual('REFERENCE', accountId?.type, 'Wrong type');
		Assert.isFalse(accountId?.isPolymorphic, 'AccountId only looks up to Account');
		InvocableSoql.FieldOption lastName = fieldsByName.get('LastName');
		Assert.areEqual(Contact.LastName.getDescribe().getLabel(), lastName?.label, 'Wrong label');
		Assert.isTrue(lastName?.isFilterable, 'LastName is filterable');
		Assert.isTrue(lastName?.isSortable, 'LastName is sortable');
		Assert.isNull(lastName?.relationshipName, 'LastName is not a lookup');
		InvocableSoql.FieldOption leadSource = fieldsByName.get('LeadSource');
		Assert.areEqual('PICKLIST', leadSource?.type, 'Wrong type');
		Assert.isFalse(leadSource?.picklistValues?.isEmpty(), 'Missing picklist values');
		Assert.isNotNull(leadSource?.picklistValues?.get(0)?.value, 'Missing picklist value');
	}

	@IsTest
	private static void shouldThrowAuraHandledExceptionForUnknownObject() {
		Test.startTest();
		Exception caughtError;
		try {
			InvocableSoql.getFields('Not_An_Object__c');
		} catch (System.AuraHandledException error) {
			caughtError = error;
		}
		Test.stopTest();

		Assert.isNotNull(caughtError, 'Did not throw a System.AuraHandledException');
	}

	@IsTest
	private static void shouldSelectAllFieldsOfTheObjectAndItsParents() {
		List<String> fields = new List<String>{ '*', 'Account.Owner.*', 'Account.Name' };
		String definition = InvocableSoqlTest.initDefinition('Contact', fields);

		Test.startTest();
		InvocableSoql.Query query = InvocableSoql.parseQuery(definition);
		Soql soql = query?.toSoql(InvocableSoqlTest.NO_VALUES, System.AccessLevel.SYSTEM_MODE);
		String queryString = query?.toQueryString(InvocableSoqlTest.NO_VALUES, System.AccessLevel.SYSTEM_MODE);
		Test.stopTest();

		Set<String> selected = soql?.selectClauses;
		Assert.isTrue(selected?.contains('LastName'), 'Did not select all of the contact\'s fields');
		Assert.isTrue(selected?.contains('Account.Owner.Name'), 'Did not select all of the account owner\'s fields');
		Assert.isTrue(selected?.contains('Account.Name'), 'Did not keep a named parent field');
		Assert.isTrue(queryString?.contains('Account.Owner.Email'), 'Query string lacks the expanded fields');
	}

	@IsTest
	private static void shouldLetPluginsAddConditionsToQueriesWithoutAny() {
		String definition = InvocableSoqlTest.initDefinition('Account', new List<String>{ 'Name' });

		Test.startTest();
		InvocableSoql.Query query = InvocableSoql.parseQuery(definition);
		Soql builder = query?.toSoql(InvocableSoqlTest.NO_VALUES, System.AccessLevel.SYSTEM_MODE);
		// A SOQL plugin can add conditions to any query before it runs:
		builder?.addWhere(Account.Name, Soql.EQUALS, 'Acme');
		Test.stopTest();

		Assert.isTrue(builder?.toString()?.endsWith(' WHERE Name = \'Acme\''), 'Wrong query: ' + builder);
	}

	@IsTest
	private static void shouldGroupAnyConditionLogicApartFromAddedConditions() {
		InvocableSoql.Query definition = InvocableSoqlTest.initQuery('Account', null);
		definition.conditionLogic = 'OR';
		definition.conditions.add(InvocableSoqlTest.initCondition('Name', 'EQUALS', 'Acme'));
		definition.conditions.add(InvocableSoqlTest.initCondition('Name', 'EQUALS', 'Beta'));
		String json = JSON.serialize(definition);
		InvocableSoql.Input input = new InvocableSoql.Input();

		Test.startTest();
		InvocableSoql.Query query = InvocableSoql.parseQuery(json);
		List<Object> values = query?.resolveValues(input);
		Soql builder = query?.toSoql(values, System.AccessLevel.SYSTEM_MODE);
		// A SOQL plugin's condition must apply to every record the logic finds, not just its last condition's:
		builder?.addWhere(Account.Site, Soql.EQUALS, 'East');
		Test.stopTest();

		String expected = ' WHERE (Name = :bind0 OR Name = :bind1) AND Site = \'East\'';
		Assert.isTrue(builder?.toString()?.endsWith(expected), 'Wrong query: ' + builder);
	}

	@IsTest
	private static void shouldCheckNullsWithTrueOrFalseFromResources() {
		InvocableSoql.Condition condition = InvocableSoqlTest.initSlotCondition('Phone', 'IS_NULL', 'boolean1');
		InvocableSoql.Query query = InvocableSoqlTest.initQuery('Account', new List<String>{ 'Name' });
		query.conditions.add(condition);
		List<InvocableSoql.Input> inputs = new List<InvocableSoql.Input>{};
		// An unset resource checks for null, like a definition with no value
		for (Boolean isNull : new List<Boolean>{ true, false, null }) {
			InvocableSoql.Input input = InvocableSoqlTest.initInput(query);
			input.boolean1 = isNull;
			inputs.add(input);
		}

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(inputs);
		Test.stopTest();

		String queryPrefix = 'SELECT Id, Name, Phone FROM Account WHERE ';
		Assert.areEqual(queryPrefix + 'Phone = null', outputs?.get(0)?.queryString, 'Wrong query for true');
		Assert.areEqual(queryPrefix + 'Phone != null', outputs?.get(1)?.queryString, 'Wrong query for false');
		Assert.areEqual(queryPrefix + 'Phone = null', outputs?.get(2)?.queryString, 'Wrong query for no value');
	}

	@IsTest
	private static void shouldShareOneQueryForIdenticalInterviews() {
		Account acme = InvocableSoqlTest.initAccount('Acme', null);
		InvocableSoqlTest.QuerySpy spy = InvocableSoqlTest.mockRows(new List<SObject>{ acme });
		InvocableSoql.Query query = InvocableSoqlTest.initSlotQuery('Name', 'EQUALS', 'text1');
		List<InvocableSoql.Input> inputs = new List<InvocableSoql.Input>{};
		for (Integer i = 0; i < 200; i++) {
			inputs.add(InvocableSoqlTest.initTextInput(query, 'Acme'));
		}

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(inputs);
		Test.stopTest();

		Assert.areEqual(1, spy.queries?.size(), 'Wrong # of queries');
		Assert.areEqual(200, outputs.size(), 'Wrong # of outputs');
		for (InvocableSoql.Output output : outputs) {
			Assert.areEqual(acme, output.record, 'Wrong record');
		}
	}

	@IsTest
	private static void shouldMergeVaryingEquals() {
		InvocableSoqlTest.QuerySpy spy = InvocableSoqlTest.mockRows(InvocableSoqlTest.initAccounts());
		InvocableSoql.Query query = InvocableSoqlTest.initSlotQuery('Name', 'EQUALS', 'text1');
		List<InvocableSoql.Input> inputs = new List<InvocableSoql.Input>{};
		// Text compares case-insensitively, like SOQL:
		for (String name : new List<String>{ 'acme', 'Beta', 'Nope', 'ACME' }) {
			inputs.add(InvocableSoqlTest.initTextInput(query, name));
		}

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(inputs);
		Test.stopTest();

		Assert.areEqual(1, spy.queries?.size(), 'Wrong # of queries');
		List<Object> mergedNames = (List<Object>) spy.queries?.get(0)?.binds?.get('bind0');
		Set<Object> expectedNames = new Set<Object>{ 'acme', 'Beta', 'Nope', 'ACME' };
		Assert.areEqual(expectedNames, new Set<Object>(mergedNames), 'Did not query every name');
		Assert.areEqual(new List<String>{ 'Acme' }, InvocableSoqlTest.getNames(outputs[0]), 'Wrong 1st output');
		Assert.areEqual(new List<String>{ 'Beta' }, InvocableSoqlTest.getNames(outputs[1]), 'Wrong 2nd output');
		Assert.areEqual(new List<String>{}, InvocableSoqlTest.getNames(outputs[2]), 'Wrong 3rd output');
		Assert.areEqual(new List<String>{ 'Acme' }, InvocableSoqlTest.getNames(outputs[3]), 'Wrong 4th output');
		// Each interview's query string shows its own value, not the merged ones:
		Assert.isTrue(outputs[1].queryString?.endsWith('WHERE Name = \'Beta\''), outputs[1].queryString);
	}

	@IsTest
	private static void shouldMergeVaryingCollections() {
		InvocableSoqlTest.QuerySpy spy = InvocableSoqlTest.mockRows(InvocableSoqlTest.initAccounts());
		InvocableSoql.Query query = InvocableSoqlTest.initSlotQuery('Name', 'IN', 'textCollection1');
		InvocableSoql.Input first = InvocableSoqlTest.initInput(query);
		// A duplicate value doesn't duplicate its record:
		first.textCollection1 = new List<String>{ 'Acme', 'Beta', 'acme' };
		InvocableSoql.Input second = InvocableSoqlTest.initInput(query);
		second.textCollection1 = new List<String>{ 'Beta', 'Gamma' };

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ first, second });
		Test.stopTest();

		Assert.areEqual(1, spy.queries?.size(), 'Wrong # of queries');
		List<String> firstNames = InvocableSoqlTest.getNames(outputs[0]);
		firstNames.sort();
		List<String> secondNames = InvocableSoqlTest.getNames(outputs[1]);
		secondNames.sort();
		Assert.areEqual(new List<String>{ 'Acme', 'Beta' }, firstNames, 'Wrong 1st output');
		Assert.areEqual(new List<String>{ 'Beta', 'Gamma' }, secondNames, 'Wrong 2nd output');
	}

	@IsTest
	private static void shouldMergeVaryingRecordCollections() {
		List<Account> accounts = InvocableSoqlTest.initAccounts();
		List<Contact> contacts = new List<Contact>{
			new Contact(AccountId = accounts[0].Id, LastName = 'Acme Contact'),
			new Contact(AccountId = accounts[1].Id, LastName = 'Beta Contact')
		};
		InvocableSoqlTest.QuerySpy spy = InvocableSoqlTest.mockRows(contacts);
		InvocableSoql.Query query = InvocableSoqlTest.initQuery('Contact', new List<String>{ 'LastName' });
		query.conditions.add(InvocableSoqlTest.initSlotCondition('AccountId', 'IN', 'recordCollection1'));
		InvocableSoql.Input first = InvocableSoqlTest.initInput(query);
		first.recordCollection1 = new List<Account>{ accounts[0] };
		InvocableSoql.Input second = InvocableSoqlTest.initInput(query);
		second.recordCollection1 = new List<Account>{ accounts[1], accounts[2] };

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ first, second });
		Test.stopTest();

		Assert.areEqual(1, spy.queries?.size(), 'Wrong # of queries');
		List<Object> mergedIds = (List<Object>) spy.queries?.get(0)?.binds?.get('bind0');
		Set<Object> expectedIds = new Set<Object>{ accounts[0].Id, accounts[1].Id, accounts[2].Id };
		Assert.areEqual(expectedIds, new Set<Object>(mergedIds), 'Did not query every record\'s ID');
		Assert.areEqual(new List<SObject>{ contacts[0] }, outputs[0].records, 'Wrong 1st output');
		Assert.areEqual(new List<SObject>{ contacts[1] }, outputs[1].records, 'Wrong 2nd output');
	}

	@IsTest
	private static void shouldMergeVaryingParentFields() {
		List<Account> accounts = InvocableSoqlTest.initAccounts();
		List<Contact> contacts = new List<Contact>{
			new Contact(Account = accounts[0], LastName = 'Acme Contact'),
			new Contact(Account = accounts[1], LastName = 'Beta Contact'),
			new Contact(LastName = 'Orphan')
		};
		InvocableSoqlTest.QuerySpy spy = InvocableSoqlTest.mockRows(contacts);
		InvocableSoql.Query query = InvocableSoqlTest.initQuery('Contact', new List<String>{ 'LastName' });
		query.conditions.add(InvocableSoqlTest.initSlotCondition('Account.Name', 'EQUALS', 'text1'));
		List<InvocableSoql.Input> inputs = new List<InvocableSoql.Input>{
			InvocableSoqlTest.initTextInput(query, 'Acme'),
			InvocableSoqlTest.initTextInput(query, 'Beta')
		};

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(inputs);
		Test.stopTest();

		Assert.areEqual(1, spy.queries?.size(), 'Wrong # of queries');
		Assert.areEqual(new List<SObject>{ contacts[0] }, outputs[0].records, 'Wrong 1st output');
		Assert.areEqual(new List<SObject>{ contacts[1] }, outputs[1].records, 'Wrong 2nd output');
	}

	@IsTest
	private static void shouldMergeSimpleLikePatterns() {
		InvocableSoqlTest.QuerySpy spy = InvocableSoqlTest.mockRows(InvocableSoqlTest.initAccounts());
		InvocableSoql.Query likeQuery = InvocableSoqlTest.initSlotQuery('Name', 'LIKE', 'text1');
		List<InvocableSoql.Input> likeInputs = new List<InvocableSoql.Input>{};
		for (String pattern : new List<String>{ '%CME', 'be%', '%amm%', 'gamma', '%' }) {
			likeInputs.add(InvocableSoqlTest.initTextInput(likeQuery, pattern));
		}
		InvocableSoql.Query containsQuery = InvocableSoqlTest.initSlotQuery('Name', 'CONTAINS', 'text1');
		List<InvocableSoql.Input> containsInputs = new List<InvocableSoql.Input>{
			InvocableSoqlTest.initTextInput(containsQuery, 'et'),
			InvocableSoqlTest.initTextInput(containsQuery, 'a_'),
			InvocableSoqlTest.initTextInput(containsQuery, 'A')
		};

		Test.startTest();
		List<InvocableSoql.Output> likeOutputs = InvocableSoql.invoke(likeInputs);
		Integer likeQueries = spy.queries?.size();
		List<InvocableSoql.Output> containsOutputs = InvocableSoql.invoke(containsInputs);
		Integer containsQueries = spy.queries?.size() - likeQueries;
		Test.stopTest();

		Assert.areEqual(1, likeQueries, 'Wrong # of LIKE queries');
		Assert.areEqual(new List<String>{ 'Acme' }, InvocableSoqlTest.getNames(likeOutputs[0]), 'Wrong ends with');
		Assert.areEqual(new List<String>{ 'Beta' }, InvocableSoqlTest.getNames(likeOutputs[1]), 'Wrong starts with');
		Assert.areEqual(new List<String>{ 'Gamma' }, InvocableSoqlTest.getNames(likeOutputs[2]), 'Wrong contains');
		Assert.areEqual(new List<String>{ 'Gamma' }, InvocableSoqlTest.getNames(likeOutputs[3]), 'Wrong exact');
		Assert.areEqual(3, likeOutputs[4].records?.size(), 'Wrong match-all: ' + likeOutputs[4].records);
		Assert.areEqual(1, containsQueries, 'Wrong # of CONTAINS queries');
		Assert.areEqual(new List<String>{ 'Beta' }, InvocableSoqlTest.getNames(containsOutputs[0]), 'Wrong 1st');
		// Escaped wildcards match literally, in SOQL and in the split:
		Assert.areEqual(new List<String>{}, InvocableSoqlTest.getNames(containsOutputs[1]), 'Wrong 2nd');
		Assert.areEqual(3, containsOutputs[2].records?.size(), 'Wrong 3rd: ' + containsOutputs[2].records);
	}

	@IsTest
	private static void shouldRunComplexLikePatternsSeparately() {
		InvocableSoqlTest.QuerySpy spy = InvocableSoqlTest.mockRows(InvocableSoqlTest.initAccounts());
		InvocableSoql.Query query = InvocableSoqlTest.initSlotQuery('Name', 'LIKE', 'text1');
		List<InvocableSoql.Input> inputs = new List<InvocableSoql.Input>{
			InvocableSoqlTest.initTextInput(query, 'A%e'),
			InvocableSoqlTest.initTextInput(query, 'B_ta'),
			InvocableSoqlTest.initTextInput(query, 'Gam\\%'),
			InvocableSoqlTest.initTextInput(query, 'gamma')
		};

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(inputs);
		Test.stopTest();

		// The two patterns with inner wildcards run alone; an escaped wildcard is literal, so 'Gam\\%' merges with 'gamma':
		Assert.areEqual(3, spy.queries?.size(), 'Wrong # of queries');
		Assert.isTrue(outputs[0].queryString?.endsWith('WHERE Name LIKE \'A%e\''), outputs[0].queryString);
		Assert.isTrue(outputs[1].queryString?.endsWith('WHERE Name LIKE \'B_ta\''), outputs[1].queryString);
		Assert.areEqual(new List<String>{}, InvocableSoqlTest.getNames(outputs[2]), 'Wrong 3rd output');
		Assert.areEqual(new List<String>{ 'Gamma' }, InvocableSoqlTest.getNames(outputs[3]), 'Wrong 4th output');
	}

	@IsTest
	private static void shouldRunSeparatelyWhenSeveralConditionsVary() {
		InvocableSoqlTest.QuerySpy spy = InvocableSoqlTest.mockRows(new List<SObject>{});
		InvocableSoql.Query query = InvocableSoqlTest.initSlotQuery('Name', 'EQUALS', 'text1');
		query.conditions.add(InvocableSoqlTest.initSlotCondition('Site', 'EQUALS', 'text2'));
		InvocableSoql.Input first = InvocableSoqlTest.initTextInput(query, 'Acme');
		first.text2 = 'East';
		InvocableSoql.Input second = InvocableSoqlTest.initTextInput(query, 'Beta');
		second.text2 = 'West';

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ first, second });
		Test.stopTest();

		Assert.areEqual(2, spy.queries?.size(), 'Wrong # of queries');
		Assert.isTrue(outputs[0].queryString?.endsWith('Name = \'Acme\' AND Site = \'East\''), outputs[0].queryString);
		Assert.isTrue(outputs[1].queryString?.endsWith('Name = \'Beta\' AND Site = \'West\''), outputs[1].queryString);
	}

	@IsTest
	private static void shouldRunSeparatelyWithLimit() {
		InvocableSoqlTest.QuerySpy spy = InvocableSoqlTest.mockRows(new List<SObject>{});
		InvocableSoql.Query query = InvocableSoqlTest.initSlotQuery('Name', 'IN', 'textCollection1');
		query.rowLimit = 1;
		InvocableSoql.Input first = InvocableSoqlTest.initInput(query);
		first.textCollection1 = new List<String>{ 'Acme' };
		InvocableSoql.Input second = InvocableSoqlTest.initInput(query);
		second.textCollection1 = new List<String>{ 'Beta' };

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ first, second });
		Test.stopTest();

		// Merged, LIMIT 1 would cut one interview's row:
		Assert.areEqual(2, spy.queries?.size(), 'Wrong # of queries');
		Assert.isTrue(outputs[0].queryString?.endsWith('Name IN (\'Acme\') LIMIT 1'), outputs[0].queryString);
		Assert.isTrue(outputs[1].queryString?.endsWith('Name IN (\'Beta\') LIMIT 1'), outputs[1].queryString);
	}

	@IsTest
	private static void shouldRunSeparatelyWithAnyConditionLogic() {
		InvocableSoqlTest.QuerySpy spy = InvocableSoqlTest.mockRows(new List<SObject>{});
		InvocableSoql.Query query = InvocableSoqlTest.initSlotQuery('Name', 'EQUALS', 'text1');
		query.conditions.add(InvocableSoqlTest.initSlotCondition('Site', 'EQUALS', 'text2'));
		query.conditionLogic = 'OR';
		InvocableSoql.Input first = InvocableSoqlTest.initTextInput(query, 'Acme');
		first.text2 = 'West';
		InvocableSoql.Input second = InvocableSoqlTest.initTextInput(query, 'Beta');
		second.text2 = 'West';

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ first, second });
		Test.stopTest();

		// Merged, a row matching only the shared condition couldn't be split back to one interview:
		Assert.areEqual(2, spy.queries?.size(), 'Wrong # of queries');
		Assert.isTrue(outputs[0].queryString?.contains('Name = \'Acme\' OR Site = \'West\''), outputs[0].queryString);
		Assert.isTrue(outputs[1].queryString?.contains('Name = \'Beta\' OR Site = \'West\''), outputs[1].queryString);
	}

	@IsTest
	private static void shouldRunNullValuesSeparately() {
		InvocableSoqlTest.QuerySpy spy = InvocableSoqlTest.mockRows(InvocableSoqlTest.initAccounts());
		InvocableSoql.Query query = InvocableSoqlTest.initSlotQuery('Site', 'EQUALS', 'text1');
		List<InvocableSoql.Input> inputs = new List<InvocableSoql.Input>{
			InvocableSoqlTest.initTextInput(query, 'East'),
			InvocableSoqlTest.initTextInput(query, 'West'),
			InvocableSoqlTest.initInput(query)
		};

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(inputs);
		Test.stopTest();

		Assert.areEqual(2, spy.queries?.size(), 'Wrong # of queries');
		Assert.areEqual(new List<String>{ 'Acme' }, InvocableSoqlTest.getNames(outputs[0]), 'Wrong 1st output');
		Assert.areEqual(new List<String>{ 'Beta' }, InvocableSoqlTest.getNames(outputs[1]), 'Wrong 2nd output');
		Assert.isTrue(outputs[2].queryString?.endsWith('WHERE Site = null'), outputs[2].queryString);
	}

	@IsTest
	private static void shouldMatchNumbersRegardlessOfScale() {
		List<Account> accounts = new List<Account>{
			new Account(AnnualRevenue = 100, Name = 'Hundred'),
			new Account(AnnualRevenue = 200.5, Name = 'Two Hundred')
		};
		InvocableSoqlTest.QuerySpy spy = InvocableSoqlTest.mockRows(accounts);
		InvocableSoql.Query query = InvocableSoqlTest.initSlotQuery('AnnualRevenue', 'EQUALS', 'number1');
		InvocableSoql.Input first = InvocableSoqlTest.initInput(query);
		first.number1 = 100.00;
		InvocableSoql.Input second = InvocableSoqlTest.initInput(query);
		second.number1 = 200.50;

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ first, second });
		Test.stopTest();

		Assert.areEqual(1, spy.queries?.size(), 'Wrong # of queries');
		Assert.areEqual(new List<String>{ 'Hundred' }, InvocableSoqlTest.getNames(outputs[0]), 'Wrong 1st');
		Assert.areEqual(new List<String>{ 'Two Hundred' }, InvocableSoqlTest.getNames(outputs[1]), 'Wrong 2nd');
	}

	@IsTest
	private static void shouldMatchFifteenCharacterIds() {
		List<Account> accounts = InvocableSoqlTest.initAccounts();
		InvocableSoqlTest.QuerySpy spy = InvocableSoqlTest.mockRows(accounts);
		InvocableSoql.Query query = InvocableSoqlTest.initSlotQuery('Id', 'EQUALS', 'text1');
		List<InvocableSoql.Input> inputs = new List<InvocableSoql.Input>{
			InvocableSoqlTest.initTextInput(query, String.valueOf(accounts[0].Id).left(15)),
			InvocableSoqlTest.initTextInput(query, String.valueOf(accounts[1].Id))
		};

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(inputs);
		Test.stopTest();

		Assert.areEqual(1, spy.queries?.size(), 'Wrong # of queries');
		Assert.areEqual(accounts[0].Id, outputs[0].record?.Id, 'Wrong 1st output');
		Assert.areEqual(accounts[1].Id, outputs[1].record?.Id, 'Wrong 2nd output');
	}

	@IsTest
	private static void shouldKeepQueryOrderWhenSplitting() {
		// The split keeps each interview's rows in the order the query returned them:
		InvocableSoqlTest.mockRows(
			new List<SObject>{
				InvocableSoqlTest.initAccount('A2', 'East'),
				InvocableSoqlTest.initAccount('A3', 'West'),
				InvocableSoqlTest.initAccount('A1', 'East')
			}
		);
		InvocableSoql.Query query = InvocableSoqlTest.initSlotQuery('Site', 'EQUALS', 'text1');
		InvocableSoql.SortOrder byName = new InvocableSoql.SortOrder();
		byName.field = 'Name';
		byName.direction = 'DESCENDING';
		query.orderBy = new List<InvocableSoql.SortOrder>{ byName };
		List<InvocableSoql.Input> inputs = new List<InvocableSoql.Input>{
			InvocableSoqlTest.initTextInput(query, 'East'),
			InvocableSoqlTest.initTextInput(query, 'West')
		};

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(inputs);
		Test.stopTest();

		Assert.areEqual(new List<String>{ 'A2', 'A1' }, InvocableSoqlTest.getNames(outputs[0]), 'Wrong order');
		Assert.areEqual(new List<String>{ 'A3' }, InvocableSoqlTest.getNames(outputs[1]), 'Wrong 2nd output');
	}

	@IsTest
	private static void shouldRunEachDefinitionAndAccessLevelSeparately() {
		InvocableSoqlTest.QuerySpy spy = InvocableSoqlTest.mockRows(new List<SObject>{});
		InvocableSoql.Query byName = InvocableSoqlTest.initSlotQuery('Name', 'EQUALS', 'text1');
		InvocableSoql.Query bySite = InvocableSoqlTest.initSlotQuery('Site', 'EQUALS', 'text1');
		InvocableSoql.Input systemMode = InvocableSoqlTest.initTextInput(byName, 'Beta');
		systemMode.accessLevel = 'SYSTEM_MODE';
		List<InvocableSoql.Input> inputs = new List<InvocableSoql.Input>{
			InvocableSoqlTest.initTextInput(byName, 'Acme'),
			InvocableSoqlTest.initTextInput(bySite, 'West'),
			systemMode
		};

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(inputs);
		Test.stopTest();

		Assert.areEqual(3, spy.queries?.size(), 'Wrong # of queries');
		Assert.isTrue(outputs[0].queryString?.endsWith('WHERE Name = \'Acme\''), outputs[0].queryString);
		Assert.isTrue(outputs[1].queryString?.endsWith('WHERE Site = \'West\''), outputs[1].queryString);
		Assert.isTrue(outputs[2].queryString?.endsWith('WHERE Name = \'Beta\''), outputs[2].queryString);
	}

	@IsTest
	private static void shouldCompareCaseSensitiveFieldsExactly() {
		Test.startTest();
		String insensitive = InvocableSoql.toKey('ABC', false);
		String sensitive = InvocableSoql.toKey('ABC', true);
		String candidate = InvocableSoql.toKey('xABC', false);
		Boolean isInsensitiveMatch = new InvocableSoql.LikePattern('%bc', false).matches(candidate);
		Boolean isSensitiveMatch = new InvocableSoql.LikePattern('%bc', true).matches('xABC');
		Test.stopTest();

		Assert.areEqual('abc', insensitive, 'Wrong case-insensitive key');
		Assert.areEqual('ABC', sensitive, 'Wrong case-sensitive key');
		Assert.isTrue(isInsensitiveMatch, 'Case-insensitive pattern did not match');
		Assert.isFalse(isSensitiveMatch, 'Case-sensitive pattern matched the wrong case');
	}

	// **** HELPERS **** //
	private static Account initAccount(String name, String site) {
		Id accountId = MockRecord.initRecordId(Account.SObjectType);
		return new Account(Id = accountId, Name = name, Site = site);
	}

	private static List<Account> initAccounts() {
		return new List<Account>{
			InvocableSoqlTest.initAccount('Acme', 'East'),
			InvocableSoqlTest.initAccount('Beta', 'West'),
			InvocableSoqlTest.initAccount('Gamma', null)
		};
	}

	private static InvocableSoql.Condition initCondition(String field, String operator, String value) {
		InvocableSoql.Condition condition = new InvocableSoql.Condition();
		condition.field = field;
		condition.operator = operator;
		condition.value = value;
		return condition;
	}

	private static String initDefinition(String objectApiName, List<String> fields) {
		InvocableSoql.Query query = InvocableSoqlTest.initQuery(objectApiName, fields);
		return JSON.serialize(query);
	}

	private static Map<String, InvocableSoql.FieldOption> indexFields(String objectApiName) {
		Map<String, InvocableSoql.FieldOption> fieldsByName = new Map<String, InvocableSoql.FieldOption>{};
		for (InvocableSoql.FieldOption option : InvocableSoql.getFields(objectApiName)) {
			fieldsByName.put(option.apiName, option);
		}
		return fieldsByName;
	}

	private static InvocableSoql.Input initInput(InvocableSoql.Query query) {
		InvocableSoql.Input input = new InvocableSoql.Input();
		input.queryDefinition = JSON.serialize(query);
		return input;
	}

	private static InvocableSoql.Query initQuery(String objectApiName, List<String> fields) {
		InvocableSoql.Query query = new InvocableSoql.Query();
		query.conditions = new List<InvocableSoql.Condition>{};
		query.fields = fields;
		query.objectApiName = objectApiName;
		return query;
	}

	private static InvocableSoql.Condition initSlotCondition(String field, String operator, String slot) {
		InvocableSoql.Condition condition = InvocableSoqlTest.initCondition(field, operator, null);
		condition.slot = slot;
		return condition;
	}

	private static InvocableSoql.Query initSlotQuery(String field, String operator, String slot) {
		InvocableSoql.Query query = InvocableSoqlTest.initQuery('Account', new List<String>{ 'Name' });
		query.conditions.add(InvocableSoqlTest.initSlotCondition(field, operator, slot));
		return query;
	}

	private static InvocableSoql.Input initTextInput(InvocableSoql.Query query, String text1) {
		InvocableSoql.Input input = InvocableSoqlTest.initInput(query);
		input.text1 = text1;
		return input;
	}

	private static List<String> getNames(InvocableSoql.Output output) {
		List<String> names = new List<String>{};
		for (SObject record : output?.records) {
			names.add((String) record.get('Name'));
		}
		return names;
	}

	private static InvocableSoql.Output invoke(InvocableSoql.Input input) {
		List<InvocableSoql.Input> inputs = new List<InvocableSoql.Input>{ input };
		return InvocableSoql.invoke(inputs)?.get(0);
	}

	private static Exception invokeAndCatch(InvocableSoql.Input input) {
		Exception caughtError;
		try {
			InvocableSoqlTest.invoke(input);
		} catch (Exception error) {
			caughtError = error;
		}
		return caughtError;
	}

	private static InvocableSoql.Output invokeOnName(String operator, String value) {
		InvocableSoql.Query query = InvocableSoqlTest.initQuery('Account', new List<String>{ 'Name' });
		query.conditions.add(InvocableSoqlTest.initCondition('Name', operator, value));
		return InvocableSoqlTest.invoke(InvocableSoqlTest.initInput(query));
	}

	private static InvocableSoqlTest.QuerySpy mockRows(List<SObject> rows) {
		InvocableSoqlTest.QuerySpy spy = new InvocableSoqlTest.QuerySpy(rows);
		MockSoql.setGlobalMock(spy);
		return spy;
	}

	// **** INNER **** //
	/** @description Answers every query with the same rows, and records each one so tests can check how it was built **/
	private class QuerySpy implements MockSoql.Simulator {
		private List<Soql> queries = new List<Soql>{};
		private List<SObject> rows;

		/**
		 * @description Sets the rows every query returns
		 * @param rows The rows, in the order the database would return them
		 */
		private QuerySpy(List<SObject> rows) {
			this.rows = rows;
		}

		/**
		 * @description Records the query, returning the rows
		 * @param queryToMock The query the action ran
		 * @return The rows
		 */
		public List<Object> simulateQuery(Soql queryToMock) {
			this.queries?.add(queryToMock);
			return this.rows;
		}
	}
}
