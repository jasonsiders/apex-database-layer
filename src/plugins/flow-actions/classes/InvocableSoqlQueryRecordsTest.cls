@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class InvocableSoqlQueryRecordsTest {
	private static final String QUERY_BY_NAME = 'SELECT Id, Name FROM Account WHERE Name = :name';
	private static final String QUERY_BY_NAME_AND_PHONE = 'SELECT Id, Name FROM Account WHERE Name = :name AND Phone = :phone';
	private static final String QUERY_NESTED_WHERE = 'SELECT Id, Name FROM Account WHERE (Name = :name OR Status__c = :status) AND IsActive = :active';
	private static final String QUERY_PARENT_FIELD = 'SELECT Id, Name FROM Account WHERE Parent.Name = :name';
	private static final String QUERY_WITH_LITERAL = 'SELECT Id, Name FROM Account WHERE Name = :name AND Phone = \'555-1234\'';
	private static final String QUERY_NO_WHERE = 'SELECT Id, Name FROM Account';

	static {
		DatabaseLayer.useMocks();
	}

	private static FlowUntypedVariable createStringVariable(String key, String value) {
		FlowUntypedVariable var = new FlowUntypedVariable();
		var.key = key;
		var.typeName = 'String';
		var.textValue = value;
		return var;
	}

	private static FlowUntypedVariable createBooleanVariable(String key, Boolean value) {
		FlowUntypedVariable var = new FlowUntypedVariable();
		var.key = key;
		var.typeName = 'Boolean';
		var.textValue = String.valueOf(value);
		return var;
	}

	private static InvocableSoqlQueryRecords.Input createInput(String query, List<FlowUntypedVariable> binds) {
		InvocableSoqlQueryRecords.Input input = new InvocableSoqlQueryRecords.Input();
		input.query = query;
		input.binds = binds ?? new List<FlowUntypedVariable>{};
		return input;
	}

	@IsTest
	private static void shouldReturnResultsForSingleInput() {
		Account mockAccount = new Account(Name = 'Acme');
		MockSoql.setGlobalMock().withResults(new List<SObject>{ mockAccount });

		InvocableSoqlQueryRecords.Input input = InvocableSoqlQueryRecordsTest.createInput(
			QUERY_BY_NAME,
			new List<FlowUntypedVariable>{ InvocableSoqlQueryRecordsTest.createStringVariable('name', '"Acme"') }
		);

		Test.startTest();
		List<InvocableSoqlQueryRecords.Output> outputs = InvocableSoqlQueryRecords.invoke(
			new List<InvocableSoqlQueryRecords.Input>{ input }
		);
		Test.stopTest();

		Assert.areEqual(1, outputs.size(), 'Should return 1 output');
		Assert.areEqual(1, outputs[0].allResults.size(), 'Should have 1 result');
		Assert.isNotNull(outputs[0].firstResult, 'firstResult should be populated');
		Assert.areEqual('Acme', outputs[0].firstResult.get('Name'), 'Result name should match');
	}

	@IsTest
	private static void shouldReturnEmptyOutputForEmptyInputs() {
		Test.startTest();
		List<InvocableSoqlQueryRecords.Output> outputs = InvocableSoqlQueryRecords.invoke(
			new List<InvocableSoqlQueryRecords.Input>{}
		);
		Test.stopTest();

		Assert.areEqual(0, outputs.size(), 'Should return empty list for empty inputs');
	}

	@IsTest
	private static void shouldReturnEmptyResultsWhenQueryReturnsNothing() {
		MockSoql.setGlobalMock().withResults(new List<SObject>{});

		InvocableSoqlQueryRecords.Input input = InvocableSoqlQueryRecordsTest.createInput(
			QUERY_BY_NAME,
			new List<FlowUntypedVariable>{ InvocableSoqlQueryRecordsTest.createStringVariable('name', '"NoMatch"') }
		);

		Test.startTest();
		List<InvocableSoqlQueryRecords.Output> outputs = InvocableSoqlQueryRecords.invoke(
			new List<InvocableSoqlQueryRecords.Input>{ input }
		);
		Test.stopTest();

		Assert.areEqual(0, outputs[0].allResults.size(), 'allResults should be empty');
		Assert.isNull(outputs[0].firstResult, 'firstResult should be null when no results');
	}

	@IsTest
	private static void shouldPopulateFirstResultFromAllResults() {
		Account account1 = new Account(Name = 'Account1');
		Account account2 = new Account(Name = 'Account2');
		MockSoql.setGlobalMock().withResults(new List<SObject>{ account1, account2 });

		InvocableSoqlQueryRecords.Input input = InvocableSoqlQueryRecordsTest.createInput(QUERY_NO_WHERE, null);

		Test.startTest();
		List<InvocableSoqlQueryRecords.Output> outputs = InvocableSoqlQueryRecords.invoke(
			new List<InvocableSoqlQueryRecords.Input>{ input }
		);
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

		InvocableSoqlQueryRecords.Input input = InvocableSoqlQueryRecordsTest.createInput(
			QUERY_BY_NAME_AND_PHONE,
			new List<FlowUntypedVariable>{
				InvocableSoqlQueryRecordsTest.createStringVariable('name', '"TestAccount"'),
				InvocableSoqlQueryRecordsTest.createStringVariable('phone', '"555-1234"')
			}
		);

		Test.startTest();
		List<InvocableSoqlQueryRecords.Output> outputs = InvocableSoqlQueryRecords.invoke(
			new List<InvocableSoqlQueryRecords.Input>{ input }
		);
		Test.stopTest();

		Assert.isTrue(outputs[0].query.contains(':name'), 'Query should contain :name');
		Assert.isTrue(outputs[0].query.contains(':phone'), 'Query should contain :phone');
	}

	@IsTest
	private static void shouldExecuteOnceForIdenticalBindValues() {
		Account acmeAccount = new Account(Name = 'Acme');
		MockSoql.setGlobalMock().withResults(new List<SObject>{ acmeAccount });

		List<FlowUntypedVariable> binds = new List<FlowUntypedVariable>{
			InvocableSoqlQueryRecordsTest.createStringVariable('name', '"Acme"')
		};
		InvocableSoqlQueryRecords.Input input1 = InvocableSoqlQueryRecordsTest.createInput(QUERY_BY_NAME, binds);
		InvocableSoqlQueryRecords.Input input2 = InvocableSoqlQueryRecordsTest.createInput(QUERY_BY_NAME, binds);

		Test.startTest();
		List<InvocableSoqlQueryRecords.Output> outputs = InvocableSoqlQueryRecords.invoke(
			new List<InvocableSoqlQueryRecords.Input>{ input1, input2 }
		);
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

		InvocableSoqlQueryRecords.Input input1 = InvocableSoqlQueryRecordsTest.createInput(
			QUERY_BY_NAME,
			new List<FlowUntypedVariable>{ InvocableSoqlQueryRecordsTest.createStringVariable('name', '"Acme"') }
		);
		InvocableSoqlQueryRecords.Input input2 = InvocableSoqlQueryRecordsTest.createInput(
			QUERY_BY_NAME,
			new List<FlowUntypedVariable>{ InvocableSoqlQueryRecordsTest.createStringVariable('name', '"Beta"') }
		);

		Test.startTest();
		List<InvocableSoqlQueryRecords.Output> outputs = InvocableSoqlQueryRecords.invoke(
			new List<InvocableSoqlQueryRecords.Input>{ input1, input2 }
		);
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

		InvocableSoqlQueryRecords.Input input1 = InvocableSoqlQueryRecordsTest.createInput(
			QUERY_BY_NAME,
			new List<FlowUntypedVariable>{ InvocableSoqlQueryRecordsTest.createStringVariable('name', '"Acme"') }
		);
		InvocableSoqlQueryRecords.Input input2 = InvocableSoqlQueryRecordsTest.createInput(
			QUERY_BY_NAME,
			new List<FlowUntypedVariable>{ InvocableSoqlQueryRecordsTest.createStringVariable('name', '"NoMatch"') }
		);

		Test.startTest();
		List<InvocableSoqlQueryRecords.Output> outputs = InvocableSoqlQueryRecords.invoke(
			new List<InvocableSoqlQueryRecords.Input>{ input1, input2 }
		);
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

		InvocableSoqlQueryRecords.Input input1 = InvocableSoqlQueryRecordsTest.createInput(
			QUERY_NESTED_WHERE,
			new List<FlowUntypedVariable>{
				InvocableSoqlQueryRecordsTest.createStringVariable('name', '"Acme"'),
				InvocableSoqlQueryRecordsTest.createStringVariable('status', '"Active"'),
				InvocableSoqlQueryRecordsTest.createBooleanVariable('active', true)
			}
		);
		InvocableSoqlQueryRecords.Input input2 = InvocableSoqlQueryRecordsTest.createInput(
			QUERY_NESTED_WHERE,
			new List<FlowUntypedVariable>{
				InvocableSoqlQueryRecordsTest.createStringVariable('name', '"Beta"'),
				InvocableSoqlQueryRecordsTest.createStringVariable('status', '"Active"'),
				InvocableSoqlQueryRecordsTest.createBooleanVariable('active', true)
			}
		);

		Test.startTest();
		List<InvocableSoqlQueryRecords.Output> outputs = InvocableSoqlQueryRecords.invoke(
			new List<InvocableSoqlQueryRecords.Input>{ input1, input2 }
		);
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

		InvocableSoqlQueryRecords.Input input1 = InvocableSoqlQueryRecordsTest.createInput(
			QUERY_PARENT_FIELD,
			new List<FlowUntypedVariable>{ InvocableSoqlQueryRecordsTest.createStringVariable('name', '"Acme"') }
		);
		InvocableSoqlQueryRecords.Input input2 = InvocableSoqlQueryRecordsTest.createInput(
			QUERY_PARENT_FIELD,
			new List<FlowUntypedVariable>{ InvocableSoqlQueryRecordsTest.createStringVariable('name', '"Beta"') }
		);

		Test.startTest();
		List<InvocableSoqlQueryRecords.Output> outputs = InvocableSoqlQueryRecords.invoke(
			new List<InvocableSoqlQueryRecords.Input>{ input1, input2 }
		);
		Test.stopTest();

		Assert.areEqual(2, outputs.size(), 'Should return 2 outputs');
	}

	@IsTest
	private static void shouldExecutePerInputForNoWhereClause() {
		Account account1 = new Account(Name = 'Account1');
		Account account2 = new Account(Name = 'Account2');
		MockSoql.setGlobalMock().withResults(new List<SObject>{ account1, account2 });

		InvocableSoqlQueryRecords.Input input1 = InvocableSoqlQueryRecordsTest.createInput(QUERY_NO_WHERE, null);
		InvocableSoqlQueryRecords.Input input2 = InvocableSoqlQueryRecordsTest.createInput(QUERY_NO_WHERE, null);

		Test.startTest();
		List<InvocableSoqlQueryRecords.Output> outputs = InvocableSoqlQueryRecords.invoke(
			new List<InvocableSoqlQueryRecords.Input>{ input1, input2 }
		);
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

		InvocableSoqlQueryRecords.Input input1 = InvocableSoqlQueryRecordsTest.createInput(
			QUERY_WITH_LITERAL,
			new List<FlowUntypedVariable>{ InvocableSoqlQueryRecordsTest.createStringVariable('name', '"Acme"') }
		);
		InvocableSoqlQueryRecords.Input input2 = InvocableSoqlQueryRecordsTest.createInput(
			QUERY_WITH_LITERAL,
			new List<FlowUntypedVariable>{ InvocableSoqlQueryRecordsTest.createStringVariable('name', '"Beta"') }
		);

		Test.startTest();
		List<InvocableSoqlQueryRecords.Output> outputs = InvocableSoqlQueryRecords.invoke(
			new List<InvocableSoqlQueryRecords.Input>{ input1, input2 }
		);
		Test.stopTest();

		Assert.areEqual(2, outputs.size(), 'Should return 2 outputs');
		Assert.isNotNull(outputs[0].allResults, 'First output allResults should not be null');
		Assert.isNotNull(outputs[1].allResults, 'Second output allResults should not be null');
	}
}
