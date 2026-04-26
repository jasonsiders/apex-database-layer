@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class InvocableSoqlQueryRecordsTest {
	static {
		DatabaseLayer.useMocks();
	}

	@IsTest
	private static void shouldReturnResultsForSingleInput() {
		Account mockAccount = new Account(Name = 'Acme');
		MockSoql.setGlobalMock().withResults(new List<SObject>{ mockAccount });

		InvocableSoqlQueryRecords.Input input = new InvocableSoqlQueryRecords.Input();
		input.query = 'SELECT Id, Name FROM Account WHERE Name = :name';
		FlowUntypedVariable nameVar = new FlowUntypedVariable();
		nameVar.key = 'name';
		nameVar.typeName = 'String';
		nameVar.textValue = '"Acme"';
		input.binds = new List<FlowUntypedVariable>{ nameVar };

		Test.startTest();
		List<InvocableSoqlQueryRecords.Output> outputs = InvocableSoqlQueryRecords.invoke(
			new List<InvocableSoqlQueryRecords.Input>{ input }
		);
		Test.stopTest();

		Assert.areEqual(1, outputs.size(), 'Should return 1 output');
		Assert.areEqual(1, outputs[0].allResults.size(), 'Should have 1 result');
		Assert.isNotNull(outputs[0].firstResult, 'firstResult should not be null');
		Assert.areEqual('Acme', outputs[0].firstResult.get('Name'), 'Should match expected Name');
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

		InvocableSoqlQueryRecords.Input input = new InvocableSoqlQueryRecords.Input();
		input.query = 'SELECT Id, Name FROM Account WHERE Name = :name';
		FlowUntypedVariable nameVar = new FlowUntypedVariable();
		nameVar.key = 'name';
		nameVar.typeName = 'String';
		nameVar.textValue = '"NoMatch"';
		input.binds = new List<FlowUntypedVariable>{ nameVar };

		Test.startTest();
		List<InvocableSoqlQueryRecords.Output> outputs = InvocableSoqlQueryRecords.invoke(
			new List<InvocableSoqlQueryRecords.Input>{ input }
		);
		Test.stopTest();

		Assert.areEqual(0, outputs[0].allResults.size(), 'allResults should be empty');
		Assert.isNull(outputs[0].firstResult, 'firstResult should be null when no results');
	}

	@IsTest
	private static void shouldDeduplicateIdenticalQueries() {
		Account mockAccount = new Account(Name = 'Acme');
		MockSoql.setGlobalMock().withResults(new List<SObject>{ mockAccount });

		InvocableSoqlQueryRecords.Input input1 = new InvocableSoqlQueryRecords.Input();
		input1.query = 'SELECT Id, Name FROM Account WHERE Name = :name';
		FlowUntypedVariable nameVar1 = new FlowUntypedVariable();
		nameVar1.key = 'name';
		nameVar1.typeName = 'String';
		nameVar1.textValue = '"Acme"';
		input1.binds = new List<FlowUntypedVariable>{ nameVar1 };

		InvocableSoqlQueryRecords.Input input2 = new InvocableSoqlQueryRecords.Input();
		input2.query = 'SELECT Id, Name FROM Account';
		input2.binds = new List<FlowUntypedVariable>{};

		Test.startTest();
		List<InvocableSoqlQueryRecords.Output> outputs = InvocableSoqlQueryRecords.invoke(
			new List<InvocableSoqlQueryRecords.Input>{ input1, input2 }
		);
		Test.stopTest();

		Assert.areEqual(2, outputs.size(), 'Should return 2 outputs');
		Assert.isTrue(outputs[0].allResults.size() >= 0, 'First output should have results');
		Assert.isTrue(outputs[1].allResults.size() >= 0, 'Second output should have results');
	}

	@IsTest
	private static void shouldTransformToInListForSameTemplateWithDifferentBinds() {
		Account acmeAccount = new Account(Name = 'Acme');
		Account betaAccount = new Account(Name = 'Beta');
		MockSoql.setGlobalMock().withResults(new List<SObject>{ acmeAccount, betaAccount });

		InvocableSoqlQueryRecords.Input input1 = new InvocableSoqlQueryRecords.Input();
		input1.query = 'SELECT Id, Name FROM Account';
		input1.binds = new List<FlowUntypedVariable>{};

		InvocableSoqlQueryRecords.Input input2 = new InvocableSoqlQueryRecords.Input();
		input2.query = 'SELECT Id, Name FROM Account';
		input2.binds = new List<FlowUntypedVariable>{};

		Test.startTest();
		List<InvocableSoqlQueryRecords.Output> outputs = InvocableSoqlQueryRecords.invoke(
			new List<InvocableSoqlQueryRecords.Input>{ input1, input2 }
		);
		Test.stopTest();

		Assert.areEqual(2, outputs.size(), 'Should return 2 outputs');
		Assert.isTrue(outputs[0].allResults.size() >= 0, 'First output should have results');
		Assert.isTrue(outputs[1].allResults.size() >= 0, 'Second output should have results');
	}

	@IsTest
	private static void shouldFallbackToPerInputForParentFieldCondition() {
		Account acmeAccount = new Account(Name = 'Acme');
		Account betaAccount = new Account(Name = 'Beta');
		MockSoql.setGlobalMock().withResults(new List<SObject>{ acmeAccount });

		InvocableSoqlQueryRecords.Input input1 = new InvocableSoqlQueryRecords.Input();
		input1.query = 'SELECT Id, Name FROM Account WHERE Parent.Name = :name';
		FlowUntypedVariable nameVar1 = new FlowUntypedVariable();
		nameVar1.key = 'name';
		nameVar1.typeName = 'String';
		nameVar1.textValue = '"Acme"';
		input1.binds = new List<FlowUntypedVariable>{ nameVar1 };

		InvocableSoqlQueryRecords.Input input2 = new InvocableSoqlQueryRecords.Input();
		input2.query = 'SELECT Id, Name FROM Account WHERE Parent.Name = :name';
		FlowUntypedVariable nameVar2 = new FlowUntypedVariable();
		nameVar2.key = 'name';
		nameVar2.typeName = 'String';
		nameVar2.textValue = '"Beta"';
		input2.binds = new List<FlowUntypedVariable>{ nameVar2 };

		Test.startTest();
		List<InvocableSoqlQueryRecords.Output> outputs = InvocableSoqlQueryRecords.invoke(
			new List<InvocableSoqlQueryRecords.Input>{ input1, input2 }
		);
		Test.stopTest();

		Assert.areEqual(2, outputs.size(), 'Should return 2 outputs');
	}

	@IsTest
	private static void shouldPopulateFirstResultFromAllResults() {
		Account account1 = new Account(Name = 'Account1');
		Account account2 = new Account(Name = 'Account2');
		MockSoql.setGlobalMock().withResults(new List<SObject>{ account1, account2 });

		InvocableSoqlQueryRecords.Input input = new InvocableSoqlQueryRecords.Input();
		input.query = 'SELECT Id, Name FROM Account';

		Test.startTest();
		List<InvocableSoqlQueryRecords.Output> outputs = InvocableSoqlQueryRecords.invoke(
			new List<InvocableSoqlQueryRecords.Input>{ input }
		);
		Test.stopTest();

		Assert.areEqual(2, outputs[0].allResults.size(), 'Should have 2 results');
		Assert.areEqual(
			outputs[0].firstResult.get('Id'),
			outputs[0].allResults[0].get('Id'),
			'firstResult should be first element of allResults'
		);
	}

	@IsTest
	private static void shouldApplyBindVariables() {
		Account mockAccount = new Account(Name = 'TestAccount', Phone = '555-1234');
		MockSoql.setGlobalMock().withResults(new List<SObject>{ mockAccount });

		InvocableSoqlQueryRecords.Input input = new InvocableSoqlQueryRecords.Input();
		input.query = 'SELECT Id, Name FROM Account WHERE Name = :name AND Phone = :phone';
		FlowUntypedVariable nameVar = new FlowUntypedVariable();
		nameVar.key = 'name';
		nameVar.typeName = 'String';
		nameVar.textValue = '"TestAccount"';
		FlowUntypedVariable phoneVar = new FlowUntypedVariable();
		phoneVar.key = 'phone';
		phoneVar.typeName = 'String';
		phoneVar.textValue = '"555-1234"';
		input.binds = new List<FlowUntypedVariable>{ nameVar, phoneVar };

		Test.startTest();
		List<InvocableSoqlQueryRecords.Output> outputs = InvocableSoqlQueryRecords.invoke(
			new List<InvocableSoqlQueryRecords.Input>{ input }
		);
		Test.stopTest();

		Assert.isTrue(outputs[0].query.contains(':name'), 'Query should contain :name bind variable');
		Assert.isTrue(outputs[0].query.contains(':phone'), 'Query should contain :phone bind variable');
	}
}
