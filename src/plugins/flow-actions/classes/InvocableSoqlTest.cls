@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class InvocableSoqlTest {
	private static final String QUERY_BY_NAME = 'SELECT Id, Name FROM Account WHERE Name = :name';
	private static final String QUERY_BY_NAME_AND_PHONE = 'SELECT Id, Name FROM Account WHERE Name = :name AND Phone = :phone';
	private static final String QUERY_NESTED_WHERE = 'SELECT Id, Name FROM Account WHERE (Name = :name OR Status__c = :status) AND IsActive = :active';
	private static final String QUERY_PARENT_FIELD = 'SELECT Id, Name FROM Account WHERE Parent.Name = :name';
	private static final String QUERY_WITH_LITERAL = 'SELECT Id, Name FROM Account WHERE Name = :name AND Phone = \'555-1234\'';
	private static final String QUERY_NO_WHERE = 'SELECT Id, Name FROM Account';
	private static final String QUERY_MULTIPLE_PIVOTS = 'SELECT Id, Name FROM Account WHERE Name = :name AND Phone = :phone';
	private static final String QUERY_WITH_COMPARISON = 'SELECT Id, Name FROM Account WHERE NumberOfEmployees > :count';

	static {
		DatabaseLayer.useMocks();
	}

	@IsTest
	private static void shouldReturnResultsForSingleInput() {
		Account mockAccount = new Account(Name = 'Acme');
		MockSoql.setGlobalMock().withResults(new List<SObject>{ mockAccount });
		BindVariable nameBind = new BindVariable();
		nameBind.key = 'name';
		nameBind.textValue = 'Acme';
		nameBind.typeName = 'String';
		nameBind.isCollection = false;

		InvocableSoql.Input input = InvocableSoqlTest.createInput(QUERY_BY_NAME, new List<BindVariable>{ nameBind });

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ input });
		Test.stopTest();

		Assert.areEqual(1, outputs.size(), 'Should return 1 output');
		Assert.areEqual(1, outputs[0].allResults.size(), 'Should have 1 result');
		Assert.isNotNull(outputs[0].firstResult, 'firstResult should be populated');
		Assert.areEqual('Acme', outputs[0].firstResult.get('Name'), 'Result name should match');
	}

	@IsTest
	private static void shouldReturnEmptyOutputForEmptyInputs() {
		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{});
		Test.stopTest();

		Assert.areEqual(0, outputs.size(), 'Should return empty list for empty inputs');
	}

	@IsTest
	private static void shouldReturnEmptyResultsWhenQueryReturnsNothing() {
		MockSoql.setGlobalMock().withResults(new List<SObject>{});
		BindVariable nameBind = new BindVariable();
		nameBind.key = 'name';
		nameBind.textValue = 'NoMatch';
		nameBind.typeName = 'String';
		nameBind.isCollection = false;

		InvocableSoql.Input input = InvocableSoqlTest.createInput(QUERY_BY_NAME, new List<BindVariable>{ nameBind });

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ input });
		Test.stopTest();

		Assert.areEqual(0, outputs[0].allResults.size(), 'allResults should be empty');
		Assert.isNull(outputs[0].firstResult, 'firstResult should be null when no results');
	}

	@IsTest
	private static void shouldPopulateFirstResultFromAllResults() {
		Account account1 = new Account(Name = 'Account1');
		Account account2 = new Account(Name = 'Account2');
		MockSoql.setGlobalMock().withResults(new List<SObject>{ account1, account2 });

		InvocableSoql.Input input = InvocableSoqlTest.createInput(QUERY_NO_WHERE, null);

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ input });
		Test.stopTest();

		Assert.areEqual(2, outputs[0].allResults.size(), 'Should have 2 results');
		Assert.areEqual(
			outputs[0].firstResult.get('Id'),
			outputs[0].allResults[0].get('Id'),
			'firstResult should be first element'
		);
	}

	@IsTest
	private static void shouldApplyBindVariables() {
		Account mockAccount = new Account(Name = 'TestAccount', Phone = '555-1234');
		MockSoql.setGlobalMock().withResults(new List<SObject>{ mockAccount });
		BindVariable nameBind = new BindVariable();
		nameBind.key = 'name';
		nameBind.textValue = 'TestAccount';
		nameBind.typeName = 'String';
		nameBind.isCollection = false;
		BindVariable phoneBind = new BindVariable();
		phoneBind.key = 'phone';
		phoneBind.textValue = '555-1234';
		phoneBind.typeName = 'String';
		phoneBind.isCollection = false;

		InvocableSoql.Input input = InvocableSoqlTest.createInput(
			QUERY_BY_NAME_AND_PHONE,
			new List<BindVariable>{ nameBind, phoneBind }
		);

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ input });
		Test.stopTest();

		Assert.isTrue(outputs[0].query.contains(':name'), 'Query should contain :name');
		Assert.isTrue(outputs[0].query.contains(':phone'), 'Query should contain :phone');
	}

	@IsTest
	private static void shouldApplySerializedBindVariables() {
		Account mockAccount = new Account(Name = 'JsonAccount');
		MockSoql.setGlobalMock().withResults(new List<SObject>{ mockAccount });
		BindVariable nameBind = new BindVariable();
		nameBind.key = 'name';
		nameBind.textValue = 'JsonAccount';
		nameBind.typeName = 'String';
		nameBind.isCollection = false;

		InvocableSoql.Input input = InvocableSoqlTest.createInput(QUERY_BY_NAME, new List<BindVariable>{ nameBind });

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ input });
		Test.stopTest();

		InvocableSoql.Output output = outputs?.get(0);
		Assert.areEqual(QUERY_BY_NAME, output?.query, 'Wrong query');
	}

	@IsTest
	private static void shouldExecuteOnceForIdenticalBindValues() {
		Account acmeAccount = new Account(Name = 'Acme');
		MockSoql.setGlobalMock().withResults(new List<SObject>{ acmeAccount });
		BindVariable nameBind = new BindVariable();
		nameBind.key = 'name';
		nameBind.textValue = 'Acme';
		nameBind.typeName = 'String';
		nameBind.isCollection = false;

		List<BindVariable> binds = new List<BindVariable>{ nameBind };
		InvocableSoql.Input input1 = InvocableSoqlTest.createInput(QUERY_BY_NAME, binds);
		InvocableSoql.Input input2 = InvocableSoqlTest.createInput(QUERY_BY_NAME, binds);

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ input1, input2 });
		Test.stopTest();

		Assert.areEqual(2, outputs.size(), 'Should return 2 outputs');
		Assert.areEqual(1, outputs[0].allResults.size(), 'First output should have 1 result');
		Assert.areEqual(1, outputs[1].allResults.size(), 'Second output should have 1 result');
		Assert.areEqual(outputs[0].allResults, outputs[1].allResults, 'Outputs should share results');
	}

	@IsTest
	private static void shouldTransformToInListForSameTemplateWithDifferentBinds() {
		Account acmeAccount = new Account(Name = 'Acme');
		Account betaAccount = new Account(Name = 'Beta');
		MockSoql.setGlobalMock().withResults(new List<SObject>{ acmeAccount, betaAccount });
		BindVariable firstNameBind = new BindVariable();
		firstNameBind.key = 'name';
		firstNameBind.textValue = 'Acme';
		firstNameBind.typeName = 'String';
		firstNameBind.isCollection = false;
		BindVariable secondNameBind = new BindVariable();
		secondNameBind.key = 'name';
		secondNameBind.textValue = 'Beta';
		secondNameBind.typeName = 'String';
		secondNameBind.isCollection = false;

		InvocableSoql.Input input1 = InvocableSoqlTest.createInput(
			QUERY_BY_NAME,
			new List<BindVariable>{ firstNameBind }
		);
		InvocableSoql.Input input2 = InvocableSoqlTest.createInput(
			QUERY_BY_NAME,
			new List<BindVariable>{ secondNameBind }
		);

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ input1, input2 });
		Test.stopTest();

		Assert.areEqual(2, outputs.size(), 'Should return 2 outputs');
		Assert.areEqual(1, outputs[0].allResults.size(), 'First output should have 1 result');
		Assert.areEqual('Acme', outputs[0].allResults[0].get('Name'), 'First output should be Acme');
		Assert.areEqual(1, outputs[1].allResults.size(), 'Second output should have 1 result');
		Assert.areEqual('Beta', outputs[1].allResults[0].get('Name'), 'Second output should be Beta');
	}

	@IsTest
	private static void shouldReturnEmptyResultsForUnmatchedBindValue() {
		Account acmeAccount = new Account(Name = 'Acme');
		MockSoql.setGlobalMock().withResults(new List<SObject>{ acmeAccount });
		BindVariable matchedNameBind = new BindVariable();
		matchedNameBind.key = 'name';
		matchedNameBind.textValue = 'Acme';
		matchedNameBind.typeName = 'String';
		matchedNameBind.isCollection = false;
		BindVariable unmatchedNameBind = new BindVariable();
		unmatchedNameBind.key = 'name';
		unmatchedNameBind.textValue = 'NoMatch';
		unmatchedNameBind.typeName = 'String';
		unmatchedNameBind.isCollection = false;

		InvocableSoql.Input input1 = InvocableSoqlTest.createInput(
			QUERY_BY_NAME,
			new List<BindVariable>{ matchedNameBind }
		);
		InvocableSoql.Input input2 = InvocableSoqlTest.createInput(
			QUERY_BY_NAME,
			new List<BindVariable>{ unmatchedNameBind }
		);

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ input1, input2 });
		Test.stopTest();

		Assert.areEqual(1, outputs[0].allResults.size(), 'Matched input should have 1 result');
		Assert.areEqual(0, outputs[1].allResults.size(), 'Unmatched input should have 0 results');
		Assert.isNull(outputs[1].firstResult, 'firstResult should be null for unmatched');
	}

	@IsTest
	private static void shouldFallbackToPerInputForNestedWhereLogic() {
		Account account1 = new Account(Name = 'Acme');
		Account account2 = new Account(Name = 'Beta');
		MockSoql.setGlobalMock().withResults(new List<SObject>{ account1, account2 });
		BindVariable firstNameBind = new BindVariable();
		firstNameBind.key = 'name';
		firstNameBind.textValue = 'Acme';
		firstNameBind.typeName = 'String';
		firstNameBind.isCollection = false;
		BindVariable firstStatusBind = new BindVariable();
		firstStatusBind.key = 'status';
		firstStatusBind.textValue = 'Active';
		firstStatusBind.typeName = 'String';
		firstStatusBind.isCollection = false;
		BindVariable firstActiveBind = new BindVariable();
		firstActiveBind.key = 'active';
		firstActiveBind.textValue = String.valueOf(true);
		firstActiveBind.typeName = 'Boolean';
		firstActiveBind.isCollection = false;
		BindVariable secondNameBind = new BindVariable();
		secondNameBind.key = 'name';
		secondNameBind.textValue = 'Beta';
		secondNameBind.typeName = 'String';
		secondNameBind.isCollection = false;
		BindVariable secondStatusBind = new BindVariable();
		secondStatusBind.key = 'status';
		secondStatusBind.textValue = 'Active';
		secondStatusBind.typeName = 'String';
		secondStatusBind.isCollection = false;
		BindVariable secondActiveBind = new BindVariable();
		secondActiveBind.key = 'active';
		secondActiveBind.textValue = String.valueOf(true);
		secondActiveBind.typeName = 'Boolean';
		secondActiveBind.isCollection = false;

		InvocableSoql.Input input1 = InvocableSoqlTest.createInput(
			QUERY_NESTED_WHERE,
			new List<BindVariable>{ firstNameBind, firstStatusBind, firstActiveBind }
		);
		InvocableSoql.Input input2 = InvocableSoqlTest.createInput(
			QUERY_NESTED_WHERE,
			new List<BindVariable>{ secondNameBind, secondStatusBind, secondActiveBind }
		);

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ input1, input2 });
		Test.stopTest();

		Assert.areEqual(2, outputs.size(), 'Should return 2 outputs');
		Assert.isNotNull(outputs[0].allResults, 'First output allResults should not be null');
		Assert.isNotNull(outputs[1].allResults, 'Second output allResults should not be null');
	}

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
	@IsTest
	private static void shouldFallbackToPerInputForParentFieldCondition() {
		Account acmeAccount = new Account(Name = 'Acme');
		MockSoql.setGlobalMock().withResults(new List<SObject>{ acmeAccount });
		BindVariable firstNameBind = new BindVariable();
		firstNameBind.key = 'name';
		firstNameBind.textValue = 'Acme';
		firstNameBind.typeName = 'String';
		firstNameBind.isCollection = false;
		BindVariable secondNameBind = new BindVariable();
		secondNameBind.key = 'name';
		secondNameBind.textValue = 'Beta';
		secondNameBind.typeName = 'String';
		secondNameBind.isCollection = false;

		InvocableSoql.Input input1 = InvocableSoqlTest.createInput(
			QUERY_PARENT_FIELD,
			new List<BindVariable>{ firstNameBind }
		);
		InvocableSoql.Input input2 = InvocableSoqlTest.createInput(
			QUERY_PARENT_FIELD,
			new List<BindVariable>{ secondNameBind }
		);

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ input1, input2 });
		Test.stopTest();

		Assert.areEqual(2, outputs.size(), 'Should return 2 outputs');
	}

	@IsTest
	private static void shouldExecutePerInputForNoWhereClause() {
		Account account1 = new Account(Name = 'Account1');
		Account account2 = new Account(Name = 'Account2');
		MockSoql.setGlobalMock().withResults(new List<SObject>{ account1, account2 });

		InvocableSoql.Input input1 = InvocableSoqlTest.createInput(QUERY_NO_WHERE, null);
		InvocableSoql.Input input2 = InvocableSoqlTest.createInput(QUERY_NO_WHERE, null);

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ input1, input2 });
		Test.stopTest();

		Assert.areEqual(2, outputs.size(), 'Should return 2 outputs');
		Assert.areEqual(2, outputs[0].allResults.size(), 'First output should have 2 results');
		Assert.areEqual(2, outputs[1].allResults.size(), 'Second output should have 2 results');
	}

	@IsTest
	private static void shouldAddNonPivotConditionsToInListTransformation() {
		Account acmeAccount = new Account(Name = 'Acme', Phone = '555-1234');
		Account betaAccount = new Account(Name = 'Beta', Phone = '555-1234');
		MockSoql.setGlobalMock().withResults(new List<SObject>{ acmeAccount, betaAccount });
		BindVariable firstNameBind = new BindVariable();
		firstNameBind.key = 'name';
		firstNameBind.textValue = 'Acme';
		firstNameBind.typeName = 'String';
		firstNameBind.isCollection = false;
		BindVariable secondNameBind = new BindVariable();
		secondNameBind.key = 'name';
		secondNameBind.textValue = 'Beta';
		secondNameBind.typeName = 'String';
		secondNameBind.isCollection = false;

		InvocableSoql.Input input1 = InvocableSoqlTest.createInput(
			QUERY_WITH_LITERAL,
			new List<BindVariable>{ firstNameBind }
		);
		InvocableSoql.Input input2 = InvocableSoqlTest.createInput(
			QUERY_WITH_LITERAL,
			new List<BindVariable>{ secondNameBind }
		);

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ input1, input2 });
		Test.stopTest();

		Assert.areEqual(2, outputs.size(), 'Should return 2 outputs');
		Assert.isNotNull(outputs[0].allResults, 'First output allResults should not be null');
		Assert.isNotNull(outputs[1].allResults, 'Second output allResults should not be null');
	}

	@IsTest
	private static void shouldFallbackToPerInputForMultiplePivotConditions() {
		Account acmeAccount = new Account(Name = 'Acme', Phone = '555-1234');
		Account betaAccount = new Account(Name = 'Beta', Phone = '555-5678');
		MockSoql.setGlobalMock().withResults(new List<SObject>{ acmeAccount, betaAccount });
		BindVariable firstNameBind = new BindVariable();
		firstNameBind.key = 'name';
		firstNameBind.textValue = 'Acme';
		firstNameBind.typeName = 'String';
		firstNameBind.isCollection = false;
		BindVariable firstPhoneBind = new BindVariable();
		firstPhoneBind.key = 'phone';
		firstPhoneBind.textValue = '555-1234';
		firstPhoneBind.typeName = 'String';
		firstPhoneBind.isCollection = false;
		BindVariable secondNameBind = new BindVariable();
		secondNameBind.key = 'name';
		secondNameBind.textValue = 'Beta';
		secondNameBind.typeName = 'String';
		secondNameBind.isCollection = false;
		BindVariable secondPhoneBind = new BindVariable();
		secondPhoneBind.key = 'phone';
		secondPhoneBind.textValue = '555-5678';
		secondPhoneBind.typeName = 'String';
		secondPhoneBind.isCollection = false;

		InvocableSoql.Input input1 = InvocableSoqlTest.createInput(
			QUERY_MULTIPLE_PIVOTS,
			new List<BindVariable>{ firstNameBind, firstPhoneBind }
		);
		InvocableSoql.Input input2 = InvocableSoqlTest.createInput(
			QUERY_MULTIPLE_PIVOTS,
			new List<BindVariable>{ secondNameBind, secondPhoneBind }
		);

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ input1, input2 });
		Test.stopTest();

		Assert.areEqual(2, outputs.size(), 'Should return 2 outputs');
		Assert.isNotNull(outputs[0].allResults, 'First output should have results');
		Assert.isNotNull(outputs[1].allResults, 'Second output should have results');
	}

	@IsTest
	private static void shouldFallbackToPerInputForComparisonOperator() {
		Account account = new Account(Name = 'Test', NumberOfEmployees = 100);
		MockSoql.setGlobalMock().withResults(new List<SObject>{ account });
		BindVariable firstCountBind = new BindVariable();
		firstCountBind.key = 'count';
		firstCountBind.textValue = '50';
		firstCountBind.typeName = 'String';
		firstCountBind.isCollection = false;
		BindVariable secondCountBind = new BindVariable();
		secondCountBind.key = 'count';
		secondCountBind.textValue = '150';
		secondCountBind.typeName = 'String';
		secondCountBind.isCollection = false;

		InvocableSoql.Input input1 = InvocableSoqlTest.createInput(
			QUERY_WITH_COMPARISON,
			new List<BindVariable>{ firstCountBind }
		);
		InvocableSoql.Input input2 = InvocableSoqlTest.createInput(
			QUERY_WITH_COMPARISON,
			new List<BindVariable>{ secondCountBind }
		);

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ input1, input2 });
		Test.stopTest();

		Assert.areEqual(2, outputs.size(), 'Should return 2 outputs');
		Assert.isNotNull(outputs[0].allResults, 'First output should have results');
		Assert.isNotNull(outputs[1].allResults, 'Second output should have results');
	}

	@IsTest
	private static void shouldFireOneQueryForSingleInput() {
		MockSoql.setGlobalMock().withResults(new List<SObject>{ new Account(Name = 'Acme') });
		BindVariable nameBind = new BindVariable();
		nameBind.key = 'name';
		nameBind.textValue = 'Acme';
		nameBind.typeName = 'String';
		nameBind.isCollection = false;

		InvocableSoql.Input input = InvocableSoqlTest.createInput(QUERY_BY_NAME, new List<BindVariable>{ nameBind });
		Test.startTest();
		InvocableSoql.invoke(new List<InvocableSoql.Input>{ input });
		Test.stopTest();
		Assert.areEqual(1, MockSoql.MockDatabase?.getNumQueries(), 'Single input should fire exactly 1 query');
	}

	@IsTest
	private static void shouldFireOneQueryForIdenticalBindValues() {
		MockSoql.setGlobalMock().withResults(new List<SObject>{ new Account(Name = 'Acme') });
		BindVariable nameBind = new BindVariable();
		nameBind.key = 'name';
		nameBind.textValue = 'Acme';
		nameBind.typeName = 'String';
		nameBind.isCollection = false;
		List<BindVariable> binds = new List<BindVariable>{ nameBind };
		InvocableSoql.Input input1 = InvocableSoqlTest.createInput(QUERY_BY_NAME, binds);
		InvocableSoql.Input input2 = InvocableSoqlTest.createInput(QUERY_BY_NAME, binds);
		Test.startTest();
		InvocableSoql.invoke(new List<InvocableSoql.Input>{ input1, input2 });
		Test.stopTest();
		// executeOnceAndCopy: query fires once, results are copied to the second output
		Assert.areEqual(1, MockSoql.MockDatabase?.getNumQueries(), 'Identical bind values should fire only 1 query');
	}

	@IsTest
	private static void shouldFireOneQueryForDifferentBindValuesViaInList() {
		MockSoql.setGlobalMock()
			.withResults(new List<SObject>{ new Account(Name = 'Acme'), new Account(Name = 'Beta') });
		BindVariable firstNameBind = new BindVariable();
		firstNameBind.key = 'name';
		firstNameBind.textValue = 'Acme';
		firstNameBind.typeName = 'String';
		firstNameBind.isCollection = false;
		BindVariable secondNameBind = new BindVariable();
		secondNameBind.key = 'name';
		secondNameBind.textValue = 'Beta';
		secondNameBind.typeName = 'String';
		secondNameBind.isCollection = false;

		InvocableSoql.Input input1 = InvocableSoqlTest.createInput(
			QUERY_BY_NAME,
			new List<BindVariable>{ firstNameBind }
		);
		InvocableSoql.Input input2 = InvocableSoqlTest.createInput(
			QUERY_BY_NAME,
			new List<BindVariable>{ secondNameBind }
		);
		Test.startTest();
		InvocableSoql.invoke(new List<InvocableSoql.Input>{ input1, input2 });
		Test.stopTest();
		// executeWithInList: bind values are merged into one IN-list query
		Assert.areEqual(
			1,
			MockSoql.MockDatabase?.getNumQueries(),
			'Different bind values should merge into 1 IN-list query'
		);
	}

	@IsTest
	private static void shouldFireOneQueryPerInputForFallbackGroup() {
		MockSoql.setGlobalMock()
			.withResults(new List<SObject>{ new Account(Name = 'Acme'), new Account(Name = 'Beta') });
		BindVariable firstNameBind = new BindVariable();
		firstNameBind.key = 'name';
		firstNameBind.textValue = 'Acme';
		firstNameBind.typeName = 'String';
		firstNameBind.isCollection = false;
		BindVariable firstStatusBind = new BindVariable();
		firstStatusBind.key = 'status';
		firstStatusBind.textValue = 'Active';
		firstStatusBind.typeName = 'String';
		firstStatusBind.isCollection = false;
		BindVariable firstActiveBind = new BindVariable();
		firstActiveBind.key = 'active';
		firstActiveBind.textValue = String.valueOf(true);
		firstActiveBind.typeName = 'Boolean';
		firstActiveBind.isCollection = false;
		BindVariable secondNameBind = new BindVariable();
		secondNameBind.key = 'name';
		secondNameBind.textValue = 'Beta';
		secondNameBind.typeName = 'String';
		secondNameBind.isCollection = false;
		BindVariable secondStatusBind = new BindVariable();
		secondStatusBind.key = 'status';
		secondStatusBind.textValue = 'Active';
		secondStatusBind.typeName = 'String';
		secondStatusBind.isCollection = false;
		BindVariable secondActiveBind = new BindVariable();
		secondActiveBind.key = 'active';
		secondActiveBind.textValue = String.valueOf(true);
		secondActiveBind.typeName = 'Boolean';
		secondActiveBind.isCollection = false;

		InvocableSoql.Input input1 = InvocableSoqlTest.createInput(
			QUERY_NESTED_WHERE,
			new List<BindVariable>{ firstNameBind, firstStatusBind, firstActiveBind }
		);
		InvocableSoql.Input input2 = InvocableSoqlTest.createInput(
			QUERY_NESTED_WHERE,
			new List<BindVariable>{ secondNameBind, secondStatusBind, secondActiveBind }
		);
		Test.startTest();
		InvocableSoql.invoke(new List<InvocableSoql.Input>{ input1, input2 });
		Test.stopTest();
		// executePerInput: nested WHERE blocks IN-list optimization, each input fires its own query
		Assert.areEqual(
			2,
			MockSoql.MockDatabase?.getNumQueries(),
			'Nested WHERE fallback should fire 1 query per input'
		);
	}

	@IsTest
	private static void shouldValidateSimpleQuery() {
		DatabaseLayer.useRealData();
		String query = 'SELECT Id FROM Account ORDER BY CreatedDate DESC LIMIT 1';

		Test.startTest();
		try {
			InvocableSoql.validateQuery(query, null);
		} catch (Exception anyError) {
			Assert.fail('Should not have thrown an exception');
		}
		Test.stopTest();
	}

	@IsTest
	private static void shouldValidateQueryWithBinds() {
		DatabaseLayer.useRealData();
		String query = 'SELECT Id FROM Account WHERE Name = :name';
		BindVariable nameBind = new BindVariable();
		nameBind.key = 'name';
		nameBind.textValue = null;
		nameBind.typeName = 'String';
		nameBind.isCollection = false;
		List<BindVariable> binds = new List<BindVariable>{ nameBind };

		Test.startTest();
		try {
			InvocableSoql.validateQuery(query, binds);
		} catch (Exception anyError) {
			Assert.fail('Should not have thrown an exception');
		}
		Test.stopTest();
	}

	@SuppressWarnings('PMD.EmptyCatchBlock')
	@IsTest
	private static void shouldThrowExceptionIfInvalidQueryString() {
		DatabaseLayer.useRealData();
		String query = 'asdf';

		Test.startTest();
		try {
			InvocableSoql.validateQuery(query, null);
			Assert.fail('Should have thrown an exception');
		} catch (Exception anyError) {
			// As expected...
		}
		Test.stopTest();
	}

	@SuppressWarnings('PMD.EmptyCatchBlock')
	@IsTest
	private static void shouldThrowExceptionIfMissingBinds() {
		DatabaseLayer.useRealData();
		String query = 'SELECT Id FROM Account WHERE Name = :name';
		BindVariable nameBind = new BindVariable();
		nameBind.key = 'someOtherBind';
		nameBind.textValue = null;
		nameBind.typeName = 'String';
		nameBind.isCollection = false;
		List<BindVariable> binds = new List<BindVariable>{ nameBind };

		Test.startTest();
		try {
			InvocableSoql.validateQuery(query, binds);
			Assert.fail('Should have thrown an exception');
		} catch (Exception anyError) {
			// As expected...
		}
		Test.stopTest();
	}

	@IsTest
	private static void shouldHandleNullBinds() {
		MockSoql.setGlobalMock().withResults(new List<SObject>{ new Account(Name = 'Acme') });
		InvocableSoql.Input input = new InvocableSoql.Input();
		input.query = QUERY_NO_WHERE;

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ input });
		Test.stopTest();

		Assert.areEqual(1, outputs.size(), 'Should return 1 output when binds is null');
	}

	@IsTest
	private static void shouldResolveTypedScalarBindValues() {
		Date dateValue = Date.newInstance(2026, 5, 3);
		Datetime datetimeValue = Datetime.newInstance(2026, 5, 3, 12, 30, 0);
		Time timeValue = Time.newInstance(12, 30, 0, 0);

		BindVariable booleanBind = new BindVariable();
		booleanBind.key = 'active';
		booleanBind.booleanValue = true;
		booleanBind.typeName = 'Boolean';
		booleanBind.isCollection = false;
		BindVariable dateBind = new BindVariable();
		dateBind.key = 'closeDate';
		dateBind.dateValue = dateValue;
		dateBind.typeName = 'Date';
		dateBind.isCollection = false;
		BindVariable datetimeBind = new BindVariable();
		datetimeBind.key = 'createdDate';
		datetimeBind.datetimeValue = datetimeValue;
		datetimeBind.typeName = 'Datetime';
		datetimeBind.isCollection = false;
		BindVariable decimalBind = new BindVariable();
		decimalBind.key = 'amount';
		decimalBind.decimalValue = 10.5;
		decimalBind.typeName = 'Decimal';
		decimalBind.isCollection = false;
		BindVariable timeBind = new BindVariable();
		timeBind.key = 'startTime';
		timeBind.timeValue = timeValue;
		timeBind.typeName = 'Time';
		timeBind.isCollection = false;

		Assert.areEqual(true, booleanBind.toSoqlBinder().getValue(), 'Boolean bind should use typed value');
		Assert.areEqual(dateValue, dateBind.toSoqlBinder().getValue(), 'Date bind should use typed value');
		Assert.areEqual(datetimeValue, datetimeBind.toSoqlBinder().getValue(), 'Datetime bind should use typed value');
		Assert.areEqual(10.5, decimalBind.toSoqlBinder().getValue(), 'Decimal bind should use typed value');
		Assert.areEqual(timeValue, timeBind.toSoqlBinder().getValue(), 'Time bind should use typed value');
	}

	@IsTest
	private static void shouldResolveTypedCollectionBindValues() {
		List<Boolean> booleanValues = new List<Boolean>{ true, false };
		List<Date> dateValues = new List<Date>{ Date.newInstance(2026, 5, 3) };
		List<Datetime> datetimeValues = new List<Datetime>{ Datetime.newInstance(2026, 5, 3, 12, 30, 0) };
		List<Decimal> decimalValues = new List<Decimal>{ 10.5, 20.25 };
		List<String> textValues = new List<String>{ 'Acme', 'Beta' };
		List<Time> timeValues = new List<Time>{ Time.newInstance(12, 30, 0, 0) };

		BindVariable booleanBind = new BindVariable();
		booleanBind.key = 'active';
		booleanBind.booleanValues = booleanValues;
		booleanBind.typeName = 'Boolean';
		booleanBind.isCollection = true;
		BindVariable dateBind = new BindVariable();
		dateBind.key = 'closeDates';
		dateBind.dateValues = dateValues;
		dateBind.typeName = 'Date';
		dateBind.isCollection = true;
		BindVariable datetimeBind = new BindVariable();
		datetimeBind.key = 'createdDates';
		datetimeBind.datetimeValues = datetimeValues;
		datetimeBind.typeName = 'Datetime';
		datetimeBind.isCollection = true;
		BindVariable decimalBind = new BindVariable();
		decimalBind.key = 'amounts';
		decimalBind.decimalValues = decimalValues;
		decimalBind.typeName = 'Decimal';
		decimalBind.isCollection = true;
		BindVariable textBind = new BindVariable();
		textBind.key = 'names';
		textBind.textValues = textValues;
		textBind.typeName = 'String';
		textBind.isCollection = true;
		BindVariable timeBind = new BindVariable();
		timeBind.key = 'startTimes';
		timeBind.timeValues = timeValues;
		timeBind.typeName = 'Time';
		timeBind.isCollection = true;

		Assert.areEqual(
			booleanValues,
			booleanBind.toSoqlBinder().getValue(),
			'Boolean collection should use typed value'
		);
		Assert.areEqual(dateValues, dateBind.toSoqlBinder().getValue(), 'Date collection should use typed value');
		Assert.areEqual(
			datetimeValues,
			datetimeBind.toSoqlBinder().getValue(),
			'Datetime collection should use typed value'
		);
		Assert.areEqual(
			decimalValues,
			decimalBind.toSoqlBinder().getValue(),
			'Decimal collection should use typed value'
		);
		Assert.areEqual(textValues, textBind.toSoqlBinder().getValue(), 'Text collection should use typed value');
		Assert.areEqual(timeValues, timeBind.toSoqlBinder().getValue(), 'Time collection should use typed value');
	}

	@SuppressWarnings('PMD.EmptyCatchBlock')
	@IsTest
	private static void shouldThrowForUndeserializableBindValue() {
		BindVariable nameBind = new BindVariable();
		nameBind.key = 'name';
		nameBind.textValue = 'NotABoolean';
		nameBind.typeName = 'Boolean';
		nameBind.isCollection = false;

		InvocableSoql.Input input = InvocableSoqlTest.createInput(QUERY_BY_NAME, new List<BindVariable>{ nameBind });

		Test.startTest();
		try {
			InvocableSoql.invoke(new List<InvocableSoql.Input>{ input });
			Assert.fail('Should have thrown an exception');
		} catch (Exception anyError) {
			// As expected
		}
		Test.stopTest();
	}

	@SuppressWarnings('PMD.EmptyCatchBlock')
	@IsTest
	private static void shouldThrowForUnknownBindType() {
		BindVariable nameBind = new BindVariable();
		nameBind.key = 'name';
		nameBind.textValue = 'Acme';
		nameBind.typeName = 'UnknownType123';
		nameBind.isCollection = false;

		InvocableSoql.Input input = InvocableSoqlTest.createInput(QUERY_BY_NAME, new List<BindVariable>{ nameBind });

		Test.startTest();
		try {
			InvocableSoql.invoke(new List<InvocableSoql.Input>{ input });
			Assert.fail('Should have thrown an exception');
		} catch (Exception anyError) {
			// As expected
		}
		Test.stopTest();
	}

	private static InvocableSoql.Input createInput(String query, List<BindVariable> binds) {
		InvocableSoql.Input input = new InvocableSoql.Input();
		input.query = query;
		input.binds = binds ?? new List<BindVariable>{};
		return input;
	}
}
