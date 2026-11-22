@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class InvocableSoqlTest {
	static {
		// Custom metadata actually defined in the org should not interfere with this test:
		MockCmdt.mock(DatabaseLayerParameter__mdt.SObjectType);
	}

	// **** TESTS **** //
	@IsTest
	private static void shouldQueryWithStaticCondition() {
		insert new List<Account>{ new Account(Name = 'Acme'), new Account(Name = 'Beta') };
		InvocableSoqlQuery query = InvocableSoqlTest.initQuery('Account', new List<String>{ 'Name' });
		query.conditions.add(InvocableSoqlTest.initCondition('Name', 'EQUALS', 'Acme'));

		Test.startTest();
		InvocableSoql.Output output = InvocableSoqlTest.invoke(InvocableSoqlTest.initInput(query));
		Test.stopTest();

		Assert.areEqual(1, output?.records?.size(), 'Wrong # of records');
		Assert.areEqual('Acme', output?.record?.get('Name'), 'Wrong record');
		Assert.areEqual('SELECT Id, Name FROM Account WHERE Name = \'Acme\'', output?.queryString, 'Wrong query');
	}

	@IsTest
	private static void shouldReturnEmptyResults() {
		InvocableSoqlQuery query = InvocableSoqlTest.initQuery('Account', null);

		Test.startTest();
		InvocableSoql.Output output = InvocableSoqlTest.invoke(InvocableSoqlTest.initInput(query));
		Test.stopTest();

		Assert.isTrue(output?.records?.isEmpty(), 'Wrong records: ' + output?.records);
		Assert.isNull(output?.record, 'Wrong single record');
		Assert.areEqual('SELECT Id FROM Account', output?.queryString, 'Wrong query');
	}

	@IsTest
	private static void shouldBindSlotValues() {
		Account account = new Account(Name = 'Acme', NumberOfEmployees = 50);
		insert account;
		Date birthdate = Date.newInstance(2000, 1, 15);
		insert new List<Contact>{
			new Contact(AccountId = account.Id, Birthdate = birthdate, LastName = 'Match'),
			new Contact(AccountId = account.Id, Birthdate = birthdate, LastName = 'Other')
		};
		InvocableSoqlQuery query = InvocableSoqlTest.initQuery('Contact', new List<String>{ 'LastName' });
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

		Test.startTest();
		InvocableSoql.Output output = InvocableSoqlTest.invoke(input);
		Test.stopTest();

		Assert.areEqual(1, output?.records?.size(), 'Wrong # of records');
		String expected =
			'SELECT Id, LastName, Birthdate, IsDeleted, Account.NumberOfEmployees, LastModifiedDate FROM Contact ' +
			'WHERE LastName = \'Match\' AND Birthdate = 2000-01-15 AND IsDeleted = false AND ' +
			'Account.NumberOfEmployees = 50 AND LastModifiedDate > 2000-01-01T12:30:00Z';
		Assert.areEqual(expected, output?.queryString, 'Wrong query');
	}

	@IsTest
	private static void shouldBindTimes() {
		InvocableSoqlQuery query = InvocableSoqlTest.initQuery('BusinessHours', null);
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
		List<Account> accounts = new List<Account>{ new Account(Name = 'Acme'), new Account(Name = 'Beta') };
		insert accounts;
		insert new List<Contact>{
			new Contact(AccountId = accounts[0].Id, LastName = 'Acme Contact'),
			new Contact(AccountId = accounts[1].Id, LastName = 'Beta Contact')
		};
		InvocableSoqlQuery query = InvocableSoqlTest.initQuery('Contact', new List<String>{ 'LastName' });
		query.conditions.add(InvocableSoqlTest.initSlotCondition('AccountId', 'IN', 'recordCollection1'));
		InvocableSoql.Input input = InvocableSoqlTest.initInput(query);
		// Duplicates collapse, like they would in IN:
		input.recordCollection1 = new List<Account>{ accounts[0], accounts[0] };

		Test.startTest();
		InvocableSoql.Output output = InvocableSoqlTest.invoke(input);
		Test.stopTest();

		Assert.areEqual(1, output?.records?.size(), 'Wrong # of records');
		Assert.areEqual('Acme Contact', output?.record?.get('LastName'), 'Wrong record');
		Assert.isTrue(
			output?.queryString?.endsWith('WHERE AccountId IN (\'' + accounts[0].Id + '\')'),
			output?.queryString
		);
	}

	@IsTest
	private static void shouldThrowForRecordWithoutId() {
		InvocableSoqlQuery query = InvocableSoqlTest.initQuery('Contact', null);
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
		insert new Account(Name = 'Acme');
		InvocableSoqlQuery query = InvocableSoqlTest.initQuery('Account', null);
		query.conditions.add(InvocableSoqlTest.initSlotCondition('Name', 'IN', 'textCollection1'));

		Test.startTest();
		InvocableSoql.Output output = InvocableSoqlTest.invoke(InvocableSoqlTest.initInput(query));
		Test.stopTest();

		Assert.isTrue(output?.records?.isEmpty(), 'Wrong records: ' + output?.records);
		Assert.areEqual('SELECT Id, Name FROM Account WHERE Name IN ()', output?.queryString, 'Wrong query');
	}

	@IsTest
	private static void shouldMatchWildcardCharactersLiterally() {
		insert new List<Account>{
			new Account(Name = 'Save 50% Now'),
			new Account(Name = 'Save 500 Now'),
			new Account(Name = 'a_b'),
			new Account(Name = 'axb')
		};

		Test.startTest();
		InvocableSoql.Output contains = InvocableSoqlTest.invokeOnName('CONTAINS', '50%');
		InvocableSoql.Output startsWith = InvocableSoqlTest.invokeOnName('STARTS_WITH', 'a_');
		InvocableSoql.Output endsWith = InvocableSoqlTest.invokeOnName('ENDS_WITH', 'now');
		InvocableSoql.Output pattern = InvocableSoqlTest.invokeOnName('LIKE', 'a_b');
		Test.stopTest();

		Assert.areEqual(1, contains?.records?.size(), 'Wrong CONTAINS records: ' + contains?.records);
		Assert.areEqual('Save 50% Now', contains?.record?.get('Name'), 'Wrong CONTAINS record');
		Assert.areEqual(
			'SELECT Id, Name FROM Account WHERE Name LIKE \'%50\\%%\'',
			contains?.queryString,
			'Wrong query'
		);
		Assert.areEqual(1, startsWith?.records?.size(), 'Wrong STARTS_WITH records: ' + startsWith?.records);
		Assert.areEqual('a_b', startsWith?.record?.get('Name'), 'Wrong STARTS_WITH record');
		Assert.areEqual(2, endsWith?.records?.size(), 'Wrong ENDS_WITH records: ' + endsWith?.records);
		// LIKE passes its pattern through, wildcards and all:
		Assert.areEqual(2, pattern?.records?.size(), 'Wrong LIKE records: ' + pattern?.records);
	}

	@IsTest
	private static void shouldQueryParentFields() {
		Account account = new Account(Name = 'Acme');
		insert account;
		insert new Contact(AccountId = account.Id, LastName = 'Contact');
		InvocableSoqlQuery query = InvocableSoqlTest.initQuery('Contact', new List<String>{ 'Account.Name' });
		query.conditions.add(InvocableSoqlTest.initCondition('Account.Owner.IsActive', 'EQUALS', 'true'));

		Test.startTest();
		InvocableSoql.Output output = InvocableSoqlTest.invoke(InvocableSoqlTest.initInput(query));
		Test.stopTest();

		Assert.areEqual('Acme', output?.record?.getSObject('Account')?.get('Name'), 'Wrong parent field');
		String expected = 'SELECT Id, Account.Name, Account.Owner.IsActive FROM Contact WHERE Account.Owner.IsActive = true';
		Assert.areEqual(expected, output?.queryString, 'Wrong query');
	}

	@IsTest
	private static void shouldApplyConditionLogic() {
		insert new List<Account>{
			new Account(Name = 'Acme', Site = 'East'),
			new Account(Name = 'Beta', Site = 'West'),
			new Account(Name = 'Gamma', Site = 'East')
		};
		InvocableSoqlQuery query = InvocableSoqlTest.initQuery('Account', null);
		query.conditions.add(InvocableSoqlTest.initCondition('Name', 'EQUALS', 'Acme'));
		query.conditions.add(InvocableSoqlTest.initCondition('Name', 'EQUALS', 'Beta'));
		query.conditions.add(InvocableSoqlTest.initCondition('Site', 'EQUALS', 'West'));
		InvocableSoqlQuery anyQuery = (InvocableSoqlQuery) JSON.deserialize(
			JSON.serialize(query),
			InvocableSoqlQuery.class
		);
		anyQuery.conditionLogic = 'or';
		query.conditionLogic = '1 OR (2 AND NOT 3)';

		Test.startTest();
		InvocableSoql.Output customOutput = InvocableSoqlTest.invoke(InvocableSoqlTest.initInput(query));
		InvocableSoql.Output anyOutput = InvocableSoqlTest.invoke(InvocableSoqlTest.initInput(anyQuery));
		Test.stopTest();

		Assert.areEqual(1, customOutput?.records?.size(), 'Wrong custom logic records: ' + customOutput?.records);
		String expected = 'SELECT Id, Name, Site FROM Account WHERE Name = \'Acme\' OR (Name = \'Beta\' AND (NOT Site = \'West\'))';
		Assert.areEqual(expected, customOutput?.queryString, 'Wrong custom logic query');
		Assert.areEqual(2, anyOutput?.records?.size(), 'Wrong OR records: ' + anyOutput?.records);
		Assert.isTrue(
			anyOutput?.queryString?.contains('Name = \'Acme\' OR Name = \'Beta\' OR Site'),
			anyOutput?.queryString
		);
	}

	@IsTest
	private static void shouldWrapNegatedGroups() {
		insert new List<Account>{
			new Account(Name = 'Acme', Site = 'East'),
			new Account(Name = 'Beta', Site = 'East'),
			new Account(Name = 'Gamma', Site = 'East')
		};
		InvocableSoqlQuery query = InvocableSoqlTest.initQuery('Account', null);
		query.conditions.add(InvocableSoqlTest.initCondition('Name', 'EQUALS', 'Acme'));
		query.conditions.add(InvocableSoqlTest.initCondition('Name', 'EQUALS', 'Beta'));
		query.conditions.add(InvocableSoqlTest.initCondition('Site', 'EQUALS', 'East'));
		query.conditionLogic = 'not (1 or 2) and not not 3';

		Test.startTest();
		InvocableSoql.Output output = InvocableSoqlTest.invoke(InvocableSoqlTest.initInput(query));
		Test.stopTest();

		Assert.areEqual(1, output?.records?.size(), 'Wrong records: ' + output?.records);
		Assert.areEqual('Gamma', output?.record?.get('Name'), 'Wrong record');
		String expected =
			'SELECT Id, Name, Site FROM Account WHERE (NOT (Name = \'Acme\' OR Name = \'Beta\')) AND ' +
			'(NOT (NOT Site = \'East\'))';
		Assert.areEqual(expected, output?.queryString, 'Wrong query');
	}

	@IsTest
	private static void shouldRejectInvalidConditionLogic() {
		InvocableSoqlQuery query = InvocableSoqlTest.initQuery('Account', null);
		query.conditions.add(InvocableSoqlTest.initCondition('Name', 'EQUALS', 'Acme'));
		InvocableSoqlQuery outOfRange = (InvocableSoqlQuery) JSON.deserialize(
			JSON.serialize(query),
			InvocableSoqlQuery.class
		);
		outOfRange.conditionLogic = '1 AND 2';
		query.conditionLogic = '1 OR Name != null';

		Test.startTest();
		Exception injectedError = InvocableSoqlTest.invokeAndCatch(InvocableSoqlTest.initInput(query));
		Exception outOfRangeError = InvocableSoqlTest.invokeAndCatch(InvocableSoqlTest.initInput(outOfRange));
		Test.stopTest();

		Assert.isInstanceOfType(injectedError, IllegalArgumentException.class, 'Wrong error: ' + injectedError);
		Assert.isInstanceOfType(outOfRangeError, IllegalArgumentException.class, 'Wrong error: ' + outOfRangeError);
	}

	@IsTest
	private static void shouldRenderLiteralOnlyConditions() {
		// Account has no multi-select picklist, so the query is only rendered, not run:
		DatabaseLayer.useMockSoql();
		InvocableSoqlQuery query = InvocableSoqlTest.initQuery('Account', null);
		InvocableSoqlQuery.Condition includes = InvocableSoqlTest.initCondition('Name', 'INCLUDES', null);
		includes.values = new List<String>{ 'a;b', 'c' };
		InvocableSoqlQuery.Condition excludes = InvocableSoqlTest.initCondition('Site', 'EXCLUDES', null);
		excludes.values = new List<String>{ 'it\'s' };
		InvocableSoqlQuery.Condition dateLiteral = InvocableSoqlTest.initCondition('CreatedDate', 'GREATER_THAN', null);
		dateLiteral.dateLiteral = 'LAST_N_DAYS:30';
		query.conditions.addAll(
			new List<InvocableSoqlQuery.Condition>{
				includes,
				excludes,
				InvocableSoqlTest.initCondition('Phone', 'IS_NULL', null),
				InvocableSoqlTest.initCondition('Fax', 'IS_NOT_NULL', null),
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
	private static void shouldRunDateLiterals() {
		insert new Account(Name = 'Acme');
		InvocableSoqlQuery query = InvocableSoqlTest.initQuery('Account', null);
		InvocableSoqlQuery.Condition condition = InvocableSoqlTest.initCondition('CreatedDate', 'EQUALS', null);
		condition.dateLiteral = 'TODAY';
		query.conditions.add(condition);

		Test.startTest();
		InvocableSoql.Output output = InvocableSoqlTest.invoke(InvocableSoqlTest.initInput(query));
		Test.stopTest();

		Assert.areEqual(1, output?.records?.size(), 'Wrong # of records');
	}

	@IsTest
	private static void shouldRejectMalformedDateLiteral() {
		InvocableSoqlQuery query = InvocableSoqlTest.initQuery('Account', null);
		InvocableSoqlQuery.Condition condition = InvocableSoqlTest.initCondition('CreatedDate', 'EQUALS', null);
		condition.dateLiteral = 'TODAY OR Name != null';
		query.conditions.add(condition);

		Test.startTest();
		Exception caughtError = InvocableSoqlTest.invokeAndCatch(InvocableSoqlTest.initInput(query));
		Test.stopTest();

		Assert.isInstanceOfType(caughtError, IllegalArgumentException.class, 'Wrong error: ' + caughtError);
	}

	@IsTest
	private static void shouldApplyOrderByLimitAndOffset() {
		insert new List<Account>{ new Account(Name = 'A'), new Account(Name = 'B'), new Account(Name = 'C') };
		InvocableSoqlQuery query = InvocableSoqlTest.initQuery('Account', new List<String>{ 'Name' });
		InvocableSoqlQuery.SortOrder byName = new InvocableSoqlQuery.SortOrder();
		byName.field = 'Name';
		byName.direction = 'DESCENDING';
		byName.nullOrder = 'NULLS_FIRST';
		InvocableSoqlQuery.SortOrder byId = new InvocableSoqlQuery.SortOrder();
		byId.field = 'Id';
		query.orderBy = new List<InvocableSoqlQuery.SortOrder>{ byName, byId };
		query.rowLimit = 1;
		query.rowOffset = 1;

		Test.startTest();
		InvocableSoql.Output output = InvocableSoqlTest.invoke(InvocableSoqlTest.initInput(query));
		Test.stopTest();

		Assert.areEqual(1, output?.records?.size(), 'Wrong # of records');
		Assert.areEqual('B', output?.record?.get('Name'), 'Wrong record');
		String expected = 'SELECT Id, Name FROM Account ORDER BY Name DESC NULLS FIRST, Id ASC NULLS LAST LIMIT 1 OFFSET 1';
		Assert.areEqual(expected, output?.queryString, 'Wrong query');
	}

	@IsTest
	private static void shouldApplyUsage() {
		Account account = new Account(Name = 'Deleted');
		insert account;
		delete account;
		InvocableSoqlQuery query = InvocableSoqlTest.initQuery('Account', null);
		query.conditions.add(InvocableSoqlTest.initCondition('IsDeleted', 'EQUALS', 'true'));
		query.usage = 'ALL_ROWS';

		Test.startTest();
		InvocableSoql.Output output = InvocableSoqlTest.invoke(InvocableSoqlTest.initInput(query));
		Test.stopTest();

		Assert.areEqual(account.Id, output?.record?.Id, 'Did not query all rows');
		Assert.isTrue(output?.queryString?.endsWith(' ALL ROWS'), 'Wrong query: ' + output?.queryString);
	}

	@IsTest
	private static void shouldApplyAccessLevel() {
		DatabaseLayer.useMockSoql();
		InvocableSoqlTest.QuerySpy spy = new InvocableSoqlTest.QuerySpy();
		MockSoql.setGlobalMock(spy);
		InvocableSoql.Input systemMode = InvocableSoqlTest.initInput(InvocableSoqlTest.initQuery('Account', null));
		systemMode.accessLevel = 'SYSTEM_MODE';
		InvocableSoql.Input userMode = InvocableSoqlTest.initInput(InvocableSoqlTest.initQuery('Account', null));
		InvocableSoql.Input invalid = InvocableSoqlTest.initInput(InvocableSoqlTest.initQuery('Account', null));
		invalid.accessLevel = 'GOD_MODE';

		Test.startTest();
		InvocableSoqlTest.invoke(systemMode);
		System.AccessLevel systemLevel = spy.lastQuery?.accessLevel;
		InvocableSoqlTest.invoke(userMode);
		System.AccessLevel userLevel = spy.lastQuery?.accessLevel;
		Exception caughtError = InvocableSoqlTest.invokeAndCatch(invalid);
		Test.stopTest();

		Assert.areEqual(System.AccessLevel.SYSTEM_MODE, systemLevel, 'Wrong access level');
		Assert.areEqual(System.AccessLevel.USER_MODE, userLevel, 'Did not default to USER_MODE');
		Assert.isInstanceOfType(caughtError, IllegalArgumentException.class, 'Wrong error: ' + caughtError);
	}

	@IsTest
	private static void shouldRejectInvalidDefinitions() {
		InvocableSoqlQuery unknownField = InvocableSoqlTest.initQuery('Account', null);
		unknownField.conditions.add(InvocableSoqlTest.initCondition('Not_A_Field__c', 'EQUALS', 'x'));
		InvocableSoqlQuery unknownParent = InvocableSoqlTest.initQuery('Contact', null);
		unknownParent.conditions.add(InvocableSoqlTest.initCondition('Nope.Name', 'EQUALS', 'x'));
		InvocableSoqlQuery unknownOperator = InvocableSoqlTest.initQuery('Account', null);
		unknownOperator.conditions.add(InvocableSoqlTest.initCondition('Name', 'SOUNDS_LIKE', 'x'));
		InvocableSoqlQuery unknownSlot = InvocableSoqlTest.initQuery('Account', null);
		unknownSlot.conditions.add(InvocableSoqlTest.initSlotCondition('Name', 'EQUALS', 'text99'));
		InvocableSoqlQuery unknownSelectField = InvocableSoqlTest.initQuery(
			'Account',
			new List<String>{ 'Name, (SELECT Id FROM Contacts)' }
		);
		InvocableSoqlQuery unknownSortField = InvocableSoqlTest.initQuery('Account', null);
		InvocableSoqlQuery.SortOrder badSort = new InvocableSoqlQuery.SortOrder();
		badSort.field = 'Nope__c';
		unknownSortField.orderBy = new List<InvocableSoqlQuery.SortOrder>{ badSort };
		InvocableSoqlQuery malformedDateLiteral = InvocableSoqlTest.initQuery('Account', null);
		InvocableSoqlQuery.Condition fakeLiteral = InvocableSoqlTest.initCondition('CreatedDate', 'EQUALS', null);
		fakeLiteral.dateLiteral = 'FOO_BAR:3';
		malformedDateLiteral.conditions.add(fakeLiteral);
		InvocableSoqlQuery missingObject = InvocableSoqlTest.initQuery(null, null);
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
		Account account = new Account(AnnualRevenue = 1000.5, Name = 'Acme', NumberOfEmployees = 50);
		insert account;
		insert new Contact(AccountId = account.Id, Birthdate = Date.newInstance(2000, 1, 15), LastName = 'Match');
		InvocableSoqlQuery query = InvocableSoqlTest.initQuery('Contact', null);
		query.conditions.add(InvocableSoqlTest.initCondition('Birthdate', 'EQUALS', '2000-01-15'));
		query.conditions.add(InvocableSoqlTest.initCondition('Account.AnnualRevenue', 'EQUALS', '1000.50'));
		query.conditions.add(InvocableSoqlTest.initCondition('Account.NumberOfEmployees', 'LESS_OR_EQUAL', '50'));
		query.conditions.add(InvocableSoqlTest.initCondition('LastModifiedDate', 'LESS_THAN', '2999-01-01T00:00:00Z'));
		// 15-character IDs work too:
		query.conditions.add(
			InvocableSoqlTest.initCondition('AccountId', 'EQUALS', String.valueOf(account.Id).left(15))
		);
		InvocableSoqlQuery.Condition employeeCounts = InvocableSoqlTest.initCondition(
			'Account.NumberOfEmployees',
			'IN',
			null
		);
		employeeCounts.values = new List<String>{ '50', '60' };
		query.conditions.add(employeeCounts);

		Test.startTest();
		InvocableSoql.Output output = InvocableSoqlTest.invoke(InvocableSoqlTest.initInput(query));
		Test.stopTest();

		Assert.areEqual(1, output?.records?.size(), 'Wrong # of records');
		Assert.isTrue(output?.queryString?.contains('AccountId = \'' + account.Id + '\''), output?.queryString);
		Assert.isTrue(output?.queryString?.endsWith('Account.NumberOfEmployees IN (50, 60)'), output?.queryString);
	}

	@IsTest
	private static void shouldRejectFractionsForWholeNumberFields() {
		InvocableSoqlQuery query = InvocableSoqlTest.initQuery('Account', null);
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
		InvocableSoqlQuery query = InvocableSoqlTest.initQuery('Account', null);
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
		Test.stopTest();

		Assert.isTrue(taskFieldsByName.get('WhoId')?.isPolymorphic, 'WhoId looks up to Contacts and Leads');
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

	// **** HELPERS **** //
	private static InvocableSoqlQuery.Condition initCondition(String field, String operator, String value) {
		InvocableSoqlQuery.Condition condition = new InvocableSoqlQuery.Condition();
		condition.field = field;
		condition.operator = operator;
		condition.value = value;
		return condition;
	}

	private static Map<String, InvocableSoql.FieldOption> indexFields(String objectApiName) {
		Map<String, InvocableSoql.FieldOption> fieldsByName = new Map<String, InvocableSoql.FieldOption>{};
		for (InvocableSoql.FieldOption option : InvocableSoql.getFields(objectApiName)) {
			fieldsByName.put(option.apiName, option);
		}
		return fieldsByName;
	}

	private static InvocableSoql.Input initInput(InvocableSoqlQuery query) {
		InvocableSoql.Input input = new InvocableSoql.Input();
		input.queryDefinition = JSON.serialize(query);
		return input;
	}

	private static InvocableSoqlQuery initQuery(String objectApiName, List<String> fields) {
		InvocableSoqlQuery query = new InvocableSoqlQuery();
		query.conditions = new List<InvocableSoqlQuery.Condition>{};
		query.fields = fields;
		query.objectApiName = objectApiName;
		return query;
	}

	private static InvocableSoqlQuery.Condition initSlotCondition(String field, String operator, String slot) {
		InvocableSoqlQuery.Condition condition = InvocableSoqlTest.initCondition(field, operator, null);
		condition.slot = slot;
		return condition;
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
		InvocableSoqlQuery query = InvocableSoqlTest.initQuery('Account', new List<String>{ 'Name' });
		query.conditions.add(InvocableSoqlTest.initCondition('Name', operator, value));
		return InvocableSoqlTest.invoke(InvocableSoqlTest.initInput(query));
	}

	// **** INNER **** //
	/** @description Records the last mocked query, so tests can check how it was built **/
	private class QuerySpy implements MockSoql.Simulator {
		private Soql lastQuery;

		/**
		 * @description Records the query, returning no rows
		 * @param queryToMock The query the action ran
		 * @return No rows
		 */
		public List<Object> simulateQuery(Soql queryToMock) {
			this.lastQuery = queryToMock;
			return new List<SObject>{};
		}
	}
}
