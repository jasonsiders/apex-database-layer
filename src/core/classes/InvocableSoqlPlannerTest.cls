@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class InvocableSoqlPlannerTest {
	static {
		// Custom metadata actually defined in the org should not interfere with this test:
		MockCmdt.mock(DatabaseLayerParameter__mdt.SObjectType);
	}

	// **** TESTS **** //
	@IsTest
	private static void shouldShareOneQueryForIdenticalInterviews() {
		insert new Account(Name = 'Acme');
		InvocableSoqlQuery query = InvocableSoqlPlannerTest.initQuery('Name', 'EQUALS', 'text1');
		List<InvocableSoql.Input> inputs = new List<InvocableSoql.Input>{};
		for (Integer i = 0; i < 200; i++) {
			inputs.add(InvocableSoqlPlannerTest.initInput(query, 'Acme'));
		}

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(inputs);
		Integer queries = Limits.getQueries();
		Test.stopTest();

		Assert.areEqual(1, queries, 'Wrong # of queries');
		Assert.areEqual(200, outputs.size(), 'Wrong # of outputs');
		for (InvocableSoql.Output output : outputs) {
			Assert.areEqual('Acme', output.record?.get('Name'), 'Wrong record');
		}
	}

	@IsTest
	private static void shouldMergeVaryingEquals() {
		InvocableSoqlPlannerTest.insertAccounts();
		InvocableSoqlQuery query = InvocableSoqlPlannerTest.initQuery('Name', 'EQUALS', 'text1');
		List<InvocableSoql.Input> inputs = new List<InvocableSoql.Input>{};
		// Text compares case-insensitively, like SOQL:
		for (String name : new List<String>{ 'acme', 'Beta', 'Nope', 'ACME' }) {
			inputs.add(InvocableSoqlPlannerTest.initInput(query, name));
		}

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(inputs);
		Integer queries = Limits.getQueries();
		Test.stopTest();

		Assert.areEqual(1, queries, 'Wrong # of queries');
		Assert.areEqual(new List<String>{ 'Acme' }, InvocableSoqlPlannerTest.getNames(outputs[0]), 'Wrong 1st output');
		Assert.areEqual(new List<String>{ 'Beta' }, InvocableSoqlPlannerTest.getNames(outputs[1]), 'Wrong 2nd output');
		Assert.areEqual(new List<String>{}, InvocableSoqlPlannerTest.getNames(outputs[2]), 'Wrong 3rd output');
		Assert.areEqual(new List<String>{ 'Acme' }, InvocableSoqlPlannerTest.getNames(outputs[3]), 'Wrong 4th output');
		// Each interview's query string shows its own value, not the merged ones:
		Assert.isTrue(outputs[1].queryString?.endsWith('WHERE Name = \'Beta\''), outputs[1].queryString);
	}

	@IsTest
	private static void shouldMergeVaryingCollections() {
		InvocableSoqlPlannerTest.insertAccounts();
		InvocableSoqlQuery query = InvocableSoqlPlannerTest.initQuery('Name', 'IN', 'textCollection1');
		InvocableSoql.Input first = InvocableSoqlPlannerTest.initInput(query, null);
		// A duplicate value doesn't duplicate its record:
		first.textCollection1 = new List<String>{ 'Acme', 'Beta', 'acme' };
		InvocableSoql.Input second = InvocableSoqlPlannerTest.initInput(query, null);
		second.textCollection1 = new List<String>{ 'Beta', 'Gamma' };

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ first, second });
		Integer queries = Limits.getQueries();
		Test.stopTest();

		Assert.areEqual(1, queries, 'Wrong # of queries');
		List<String> firstNames = InvocableSoqlPlannerTest.getNames(outputs[0]);
		firstNames.sort();
		List<String> secondNames = InvocableSoqlPlannerTest.getNames(outputs[1]);
		secondNames.sort();
		Assert.areEqual(new List<String>{ 'Acme', 'Beta' }, firstNames, 'Wrong 1st output');
		Assert.areEqual(new List<String>{ 'Beta', 'Gamma' }, secondNames, 'Wrong 2nd output');
	}

	@IsTest
	private static void shouldMergeVaryingRecordCollections() {
		List<Account> accounts = InvocableSoqlPlannerTest.insertAccounts();
		insert new List<Contact>{
			new Contact(AccountId = accounts[0].Id, LastName = 'Acme Contact'),
			new Contact(AccountId = accounts[1].Id, LastName = 'Beta Contact')
		};
		InvocableSoqlQuery query = InvocableSoqlPlannerTest.initQuery('AccountId', 'IN', 'recordCollection1');
		query.objectApiName = 'Contact';
		query.fields = new List<String>{ 'LastName' };
		InvocableSoql.Input first = InvocableSoqlPlannerTest.initInput(query, null);
		first.recordCollection1 = new List<Account>{ accounts[0] };
		InvocableSoql.Input second = InvocableSoqlPlannerTest.initInput(query, null);
		second.recordCollection1 = new List<Account>{ accounts[1], accounts[2] };

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ first, second });
		Integer queries = Limits.getQueries();
		Test.stopTest();

		Assert.areEqual(1, queries, 'Wrong # of queries');
		Assert.areEqual('Acme Contact', outputs[0].record?.get('LastName'), 'Wrong 1st output');
		Assert.areEqual(1, outputs[1].records?.size(), 'Wrong 2nd output: ' + outputs[1].records);
		Assert.areEqual('Beta Contact', outputs[1].record?.get('LastName'), 'Wrong 2nd output');
	}

	@IsTest
	private static void shouldMergeVaryingParentFields() {
		List<Account> accounts = InvocableSoqlPlannerTest.insertAccounts();
		insert new List<Contact>{
			new Contact(AccountId = accounts[0].Id, LastName = 'Acme Contact'),
			new Contact(AccountId = accounts[1].Id, LastName = 'Beta Contact'),
			new Contact(LastName = 'Orphan')
		};
		InvocableSoqlQuery query = InvocableSoqlPlannerTest.initQuery('Account.Name', 'EQUALS', 'text1');
		query.objectApiName = 'Contact';
		query.fields = new List<String>{ 'LastName' };
		List<InvocableSoql.Input> inputs = new List<InvocableSoql.Input>{
			InvocableSoqlPlannerTest.initInput(query, 'Acme'),
			InvocableSoqlPlannerTest.initInput(query, 'Beta')
		};

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(inputs);
		Integer queries = Limits.getQueries();
		Test.stopTest();

		Assert.areEqual(1, queries, 'Wrong # of queries');
		Assert.areEqual('Acme Contact', outputs[0].record?.get('LastName'), 'Wrong 1st output');
		Assert.areEqual('Beta Contact', outputs[1].record?.get('LastName'), 'Wrong 2nd output');
	}

	@IsTest
	private static void shouldMergeSimpleLikePatterns() {
		InvocableSoqlPlannerTest.insertAccounts();
		InvocableSoqlQuery likeQuery = InvocableSoqlPlannerTest.initQuery('Name', 'LIKE', 'text1');
		List<InvocableSoql.Input> likeInputs = new List<InvocableSoql.Input>{};
		for (String pattern : new List<String>{ '%CME', 'be%', '%amm%', 'gamma', '%' }) {
			likeInputs.add(InvocableSoqlPlannerTest.initInput(likeQuery, pattern));
		}
		InvocableSoqlQuery containsQuery = InvocableSoqlPlannerTest.initQuery('Name', 'CONTAINS', 'text1');
		List<InvocableSoql.Input> containsInputs = new List<InvocableSoql.Input>{
			InvocableSoqlPlannerTest.initInput(containsQuery, 'et'),
			InvocableSoqlPlannerTest.initInput(containsQuery, 'a_'),
			InvocableSoqlPlannerTest.initInput(containsQuery, 'A')
		};

		Test.startTest();
		List<InvocableSoql.Output> likeOutputs = InvocableSoql.invoke(likeInputs);
		Integer likeQueries = Limits.getQueries();
		List<InvocableSoql.Output> containsOutputs = InvocableSoql.invoke(containsInputs);
		Integer containsQueries = Limits.getQueries() - likeQueries;
		Test.stopTest();

		Assert.areEqual(1, likeQueries, 'Wrong # of LIKE queries');
		Assert.areEqual(
			new List<String>{ 'Acme' },
			InvocableSoqlPlannerTest.getNames(likeOutputs[0]),
			'Wrong ends with'
		);
		Assert.areEqual(
			new List<String>{ 'Beta' },
			InvocableSoqlPlannerTest.getNames(likeOutputs[1]),
			'Wrong starts with'
		);
		Assert.areEqual(
			new List<String>{ 'Gamma' },
			InvocableSoqlPlannerTest.getNames(likeOutputs[2]),
			'Wrong contains'
		);
		Assert.areEqual(new List<String>{ 'Gamma' }, InvocableSoqlPlannerTest.getNames(likeOutputs[3]), 'Wrong exact');
		Assert.areEqual(3, likeOutputs[4].records?.size(), 'Wrong match-all: ' + likeOutputs[4].records);
		Assert.areEqual(1, containsQueries, 'Wrong # of CONTAINS queries');
		Assert.areEqual(new List<String>{ 'Beta' }, InvocableSoqlPlannerTest.getNames(containsOutputs[0]), 'Wrong 1st');
		// Escaped wildcards match literally, in SOQL and in the split:
		Assert.areEqual(new List<String>{}, InvocableSoqlPlannerTest.getNames(containsOutputs[1]), 'Wrong 2nd');
		Assert.areEqual(3, containsOutputs[2].records?.size(), 'Wrong 3rd: ' + containsOutputs[2].records);
	}

	@IsTest
	private static void shouldRunComplexLikePatternsSeparately() {
		InvocableSoqlPlannerTest.insertAccounts();
		InvocableSoqlQuery query = InvocableSoqlPlannerTest.initQuery('Name', 'LIKE', 'text1');
		List<InvocableSoql.Input> inputs = new List<InvocableSoql.Input>{
			InvocableSoqlPlannerTest.initInput(query, 'A%e'),
			InvocableSoqlPlannerTest.initInput(query, 'B_ta'),
			InvocableSoqlPlannerTest.initInput(query, 'Gam\\%'),
			InvocableSoqlPlannerTest.initInput(query, 'gamma')
		};

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(inputs);
		Integer queries = Limits.getQueries();
		Test.stopTest();

		// The two patterns with inner wildcards run alone; an escaped wildcard is literal, so 'Gam\\%' merges with 'gamma':
		Assert.areEqual(3, queries, 'Wrong # of queries');
		Assert.areEqual(new List<String>{ 'Acme' }, InvocableSoqlPlannerTest.getNames(outputs[0]), 'Wrong 1st output');
		Assert.areEqual(new List<String>{ 'Beta' }, InvocableSoqlPlannerTest.getNames(outputs[1]), 'Wrong 2nd output');
		Assert.areEqual(new List<String>{}, InvocableSoqlPlannerTest.getNames(outputs[2]), 'Wrong 3rd output');
	}

	@IsTest
	private static void shouldRunSeparatelyWhenSeveralConditionsVary() {
		InvocableSoqlPlannerTest.insertAccounts();
		InvocableSoqlQuery query = InvocableSoqlPlannerTest.initQuery('Name', 'EQUALS', 'text1');
		query.conditions.add(InvocableSoqlPlannerTest.initCondition('Site', 'EQUALS', 'text2'));
		InvocableSoql.Input first = InvocableSoqlPlannerTest.initInput(query, 'Acme');
		first.text2 = 'East';
		InvocableSoql.Input second = InvocableSoqlPlannerTest.initInput(query, 'Beta');
		second.text2 = 'West';

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ first, second });
		Integer queries = Limits.getQueries();
		Test.stopTest();

		Assert.areEqual(2, queries, 'Wrong # of queries');
		Assert.areEqual(new List<String>{ 'Acme' }, InvocableSoqlPlannerTest.getNames(outputs[0]), 'Wrong 1st output');
		Assert.areEqual(new List<String>{ 'Beta' }, InvocableSoqlPlannerTest.getNames(outputs[1]), 'Wrong 2nd output');
	}

	@IsTest
	private static void shouldRunSeparatelyWithLimit() {
		InvocableSoqlPlannerTest.insertAccounts();
		InvocableSoqlQuery query = InvocableSoqlPlannerTest.initQuery('Name', 'IN', 'textCollection1');
		query.rowLimit = 1;
		InvocableSoql.Input first = InvocableSoqlPlannerTest.initInput(query, null);
		first.textCollection1 = new List<String>{ 'Acme' };
		InvocableSoql.Input second = InvocableSoqlPlannerTest.initInput(query, null);
		second.textCollection1 = new List<String>{ 'Beta' };

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ first, second });
		Integer queries = Limits.getQueries();
		Test.stopTest();

		// Merged, LIMIT 1 would cut one interview's row:
		Assert.areEqual(2, queries, 'Wrong # of queries');
		Assert.areEqual(new List<String>{ 'Acme' }, InvocableSoqlPlannerTest.getNames(outputs[0]), 'Wrong 1st output');
		Assert.areEqual(new List<String>{ 'Beta' }, InvocableSoqlPlannerTest.getNames(outputs[1]), 'Wrong 2nd output');
	}

	@IsTest
	private static void shouldRunSeparatelyWithAnyConditionLogic() {
		InvocableSoqlPlannerTest.insertAccounts();
		InvocableSoqlQuery query = InvocableSoqlPlannerTest.initQuery('Name', 'EQUALS', 'text1');
		query.conditions.add(InvocableSoqlPlannerTest.initCondition('Site', 'EQUALS', 'text2'));
		query.conditionLogic = 'OR';
		InvocableSoql.Input first = InvocableSoqlPlannerTest.initInput(query, 'Acme');
		first.text2 = 'West';
		InvocableSoql.Input second = InvocableSoqlPlannerTest.initInput(query, 'Beta');
		second.text2 = 'West';

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ first, second });
		Integer queries = Limits.getQueries();
		Test.stopTest();

		Assert.areEqual(2, queries, 'Wrong # of queries');
		Assert.areEqual(2, outputs[0].records?.size(), 'Wrong 1st output: ' + outputs[0].records);
		Assert.areEqual(1, outputs[1].records?.size(), 'Wrong 2nd output: ' + outputs[1].records);
	}

	@IsTest
	private static void shouldRunNullValuesSeparately() {
		InvocableSoqlPlannerTest.insertAccounts();
		InvocableSoqlQuery query = InvocableSoqlPlannerTest.initQuery('Site', 'EQUALS', 'text1');
		List<InvocableSoql.Input> inputs = new List<InvocableSoql.Input>{
			InvocableSoqlPlannerTest.initInput(query, 'East'),
			InvocableSoqlPlannerTest.initInput(query, 'West'),
			InvocableSoqlPlannerTest.initInput(query, null)
		};

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(inputs);
		Integer queries = Limits.getQueries();
		Test.stopTest();

		Assert.areEqual(2, queries, 'Wrong # of queries');
		Assert.areEqual(new List<String>{ 'Acme' }, InvocableSoqlPlannerTest.getNames(outputs[0]), 'Wrong 1st output');
		Assert.areEqual(new List<String>{ 'Beta' }, InvocableSoqlPlannerTest.getNames(outputs[1]), 'Wrong 2nd output');
		Assert.areEqual(new List<String>{ 'Gamma' }, InvocableSoqlPlannerTest.getNames(outputs[2]), 'Wrong 3rd output');
	}

	@IsTest
	private static void shouldMatchNumbersRegardlessOfScale() {
		insert new List<Account>{
			new Account(AnnualRevenue = 100, Name = 'Hundred'),
			new Account(AnnualRevenue = 200.5, Name = 'Two Hundred')
		};
		InvocableSoqlQuery query = InvocableSoqlPlannerTest.initQuery('AnnualRevenue', 'EQUALS', 'number1');
		InvocableSoql.Input first = InvocableSoqlPlannerTest.initInput(query, null);
		first.number1 = 100.00;
		InvocableSoql.Input second = InvocableSoqlPlannerTest.initInput(query, null);
		second.number1 = 200.50;

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ first, second });
		Integer queries = Limits.getQueries();
		Test.stopTest();

		Assert.areEqual(1, queries, 'Wrong # of queries');
		Assert.areEqual(new List<String>{ 'Hundred' }, InvocableSoqlPlannerTest.getNames(outputs[0]), 'Wrong 1st');
		Assert.areEqual(new List<String>{ 'Two Hundred' }, InvocableSoqlPlannerTest.getNames(outputs[1]), 'Wrong 2nd');
	}

	@IsTest
	private static void shouldMatchFifteenCharacterIds() {
		List<Account> accounts = InvocableSoqlPlannerTest.insertAccounts();
		InvocableSoqlQuery query = InvocableSoqlPlannerTest.initQuery('Id', 'EQUALS', 'text1');
		List<InvocableSoql.Input> inputs = new List<InvocableSoql.Input>{
			InvocableSoqlPlannerTest.initInput(query, String.valueOf(accounts[0].Id).left(15)),
			InvocableSoqlPlannerTest.initInput(query, String.valueOf(accounts[1].Id))
		};

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(inputs);
		Integer queries = Limits.getQueries();
		Test.stopTest();

		Assert.areEqual(1, queries, 'Wrong # of queries');
		Assert.areEqual(accounts[0].Id, outputs[0].record?.Id, 'Wrong 1st output');
		Assert.areEqual(accounts[1].Id, outputs[1].record?.Id, 'Wrong 2nd output');
	}

	@IsTest
	private static void shouldKeepQueryOrderWhenSplitting() {
		insert new List<Account>{
			new Account(Name = 'A1', Site = 'East'),
			new Account(Name = 'A2', Site = 'East'),
			new Account(Name = 'A3', Site = 'West')
		};
		InvocableSoqlQuery query = InvocableSoqlPlannerTest.initQuery('Site', 'EQUALS', 'text1');
		InvocableSoqlQuery.SortOrder byName = new InvocableSoqlQuery.SortOrder();
		byName.field = 'Name';
		byName.direction = 'DESCENDING';
		query.orderBy = new List<InvocableSoqlQuery.SortOrder>{ byName };
		List<InvocableSoql.Input> inputs = new List<InvocableSoql.Input>{
			InvocableSoqlPlannerTest.initInput(query, 'East'),
			InvocableSoqlPlannerTest.initInput(query, 'West')
		};

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(inputs);
		Test.stopTest();

		Assert.areEqual(new List<String>{ 'A2', 'A1' }, InvocableSoqlPlannerTest.getNames(outputs[0]), 'Wrong order');
		Assert.areEqual(new List<String>{ 'A3' }, InvocableSoqlPlannerTest.getNames(outputs[1]), 'Wrong 2nd output');
	}

	@IsTest
	private static void shouldRunEachDefinitionAndAccessLevelSeparately() {
		InvocableSoqlPlannerTest.insertAccounts();
		InvocableSoqlQuery byName = InvocableSoqlPlannerTest.initQuery('Name', 'EQUALS', 'text1');
		InvocableSoqlQuery bySite = InvocableSoqlPlannerTest.initQuery('Site', 'EQUALS', 'text1');
		InvocableSoql.Input systemMode = InvocableSoqlPlannerTest.initInput(byName, 'Beta');
		systemMode.accessLevel = 'SYSTEM_MODE';
		List<InvocableSoql.Input> inputs = new List<InvocableSoql.Input>{
			InvocableSoqlPlannerTest.initInput(byName, 'Acme'),
			InvocableSoqlPlannerTest.initInput(bySite, 'West'),
			systemMode
		};

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(inputs);
		Integer queries = Limits.getQueries();
		Test.stopTest();

		Assert.areEqual(3, queries, 'Wrong # of queries');
		Assert.areEqual(new List<String>{ 'Acme' }, InvocableSoqlPlannerTest.getNames(outputs[0]), 'Wrong 1st output');
		Assert.areEqual(new List<String>{ 'Beta' }, InvocableSoqlPlannerTest.getNames(outputs[1]), 'Wrong 2nd output');
		Assert.areEqual(new List<String>{ 'Beta' }, InvocableSoqlPlannerTest.getNames(outputs[2]), 'Wrong 3rd output');
	}

	@IsTest
	private static void shouldCompareCaseSensitiveFieldsExactly() {
		Test.startTest();
		String insensitive = InvocableSoqlPlanner.toKey('ABC', false);
		String sensitive = InvocableSoqlPlanner.toKey('ABC', true);
		Boolean isInsensitiveMatch = InvocableSoqlPlanner.isLikeMatch('%bc', 'xABC', false);
		Boolean isSensitiveMatch = InvocableSoqlPlanner.isLikeMatch('%bc', 'xABC', true);
		Test.stopTest();

		Assert.areEqual('abc', insensitive, 'Wrong case-insensitive key');
		Assert.areEqual('ABC', sensitive, 'Wrong case-sensitive key');
		Assert.isTrue(isInsensitiveMatch, 'Case-insensitive pattern did not match');
		Assert.isFalse(isSensitiveMatch, 'Case-sensitive pattern matched the wrong case');
	}

	// **** HELPERS **** //
	private static InvocableSoqlQuery.Condition initCondition(String field, String operator, String slot) {
		InvocableSoqlQuery.Condition condition = new InvocableSoqlQuery.Condition();
		condition.field = field;
		condition.operator = operator;
		condition.slot = slot;
		return condition;
	}

	private static InvocableSoql.Input initInput(InvocableSoqlQuery query, String text1) {
		InvocableSoql.Input input = new InvocableSoql.Input();
		input.queryDefinition = JSON.serialize(query);
		input.text1 = text1;
		return input;
	}

	private static InvocableSoqlQuery initQuery(String field, String operator, String slot) {
		InvocableSoqlQuery query = new InvocableSoqlQuery();
		query.conditions = new List<InvocableSoqlQuery.Condition>{
			InvocableSoqlPlannerTest.initCondition(field, operator, slot)
		};
		query.fields = new List<String>{ 'Name' };
		query.objectApiName = 'Account';
		return query;
	}

	private static List<String> getNames(InvocableSoql.Output output) {
		List<String> names = new List<String>{};
		for (SObject record : output?.records) {
			names.add((String) record.get('Name'));
		}
		return names;
	}

	private static List<Account> insertAccounts() {
		List<Account> accounts = new List<Account>{
			new Account(Name = 'Acme', Site = 'East'),
			new Account(Name = 'Beta', Site = 'West'),
			new Account(Name = 'Gamma')
		};
		insert accounts;
		return accounts;
	}
}
