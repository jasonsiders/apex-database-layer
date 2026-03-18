@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class InvocableDmlUpsertRecordsTest {
	static {
		DatabaseLayer.useMocks();
	}

	@IsTest
	private static void shouldUpsertSingleRecord() {
		SObject record = new MockRecord(Account.SObjectType).toSObject();
		InvocableDmlUpsertRecords.Input input = new InvocableDmlUpsertRecords.Input();
		input.baseInput = new FlowDmlBaseInput();
		input.baseInput.record = record;
		List<InvocableDmlUpsertRecords.Input> inputs = new List<InvocableDmlUpsertRecords.Input>{ input };

		Test.startTest();
		List<InvocableDmlUpsertRecords.Output> outputs = InvocableDmlUpsertRecords.invoke(inputs);
		Test.stopTest();

		Assert.areEqual(1, MockDml.UPSERTED.getAll().size(), 'Wrong # of upserted records');
		Assert.isTrue(MockDml.UPSERTED.wasProcessed(record), 'Test record was not processed');
	}

	@IsTest
	private static void shouldUpsertMultipleRecords() {
		InvocableDmlUpsertRecords.Input input = new InvocableDmlUpsertRecords.Input();
		input.baseInput = new FlowDmlBaseInput();
		input.baseInput.records = new List<SObject>{};
		for (Integer i = 0; i < 3; i++) {
			SObject record = new MockRecord(Account.SObjectType).toSObject();
			input.baseInput.records?.add(record);
		}
		List<InvocableDmlUpsertRecords.Input> inputs = new List<InvocableDmlUpsertRecords.Input>{ input };

		Test.startTest();
		List<InvocableDmlUpsertRecords.Output> outputs = InvocableDmlUpsertRecords.invoke(inputs);
		Test.stopTest();

		Assert.areEqual(3, MockDml.UPSERTED.getAll().size(), 'Wrong # of upserted records');
		for (SObject record : input.baseInput.records) {
			Assert.isTrue(MockDml.UPSERTED.wasProcessed(record), 'Test record was not processed');
		}
	}

	@IsTest
	private static void shouldHandleBothInputsPopulated() {
		InvocableDmlUpsertRecords.Input input = new InvocableDmlUpsertRecords.Input();
		input.baseInput = new FlowDmlBaseInput();
		input.baseInput.record = new MockRecord(Account.SObjectType).toSObject();
		input.baseInput.records = new List<SObject>{};
		for (Integer i = 0; i < 3; i++) {
			SObject record = new MockRecord(Account.SObjectType).toSObject();
			input.baseInput.records?.add(record);
		}
		List<InvocableDmlUpsertRecords.Input> inputs = new List<InvocableDmlUpsertRecords.Input>{ input };

		Test.startTest();
		List<InvocableDmlUpsertRecords.Output> outputs = InvocableDmlUpsertRecords.invoke(inputs);
		Test.stopTest();

		Assert.areEqual(4, MockDml.UPSERTED.getAll().size(), 'Wrong # of upserted records');
		Assert.isTrue(MockDml.UPSERTED.wasProcessed(input?.baseInput?.record), 'Single record was not processed');
		for (SObject record : input.baseInput.records) {
			Assert.isTrue(MockDml.UPSERTED.wasProcessed(record), 'Test record was not processed');
		}
	}

	@IsTest
	private static void shouldSplitDifferentConfigurationsIntoDifferentDmlStatements() {
		// 3 different input configurations --> 3 different DML statements
		InvocableDmlUpsertRecords.Input input1 = new InvocableDmlUpsertRecords.Input();
		input1.baseInput = new FlowDmlBaseInput();
		input1.baseInput.accessLevelName = System.AccessLevel.USER_MODE.toString();
		input1.baseInput.allOrNone = false;
		input1.baseInput.record = new MockRecord(Account.SObjectType).toSObject();
		InvocableDmlUpsertRecords.Input input2 = new InvocableDmlUpsertRecords.Input();
		input2.baseInput = new FlowDmlBaseInput();
		input2.baseInput.accessLevelName = System.AccessLevel.USER_MODE.toString();
		input2.baseInput.allOrNone = true;
		input2.baseInput.record = new MockRecord(Account.SObjectType).toSObject();
		InvocableDmlUpsertRecords.Input input3 = new InvocableDmlUpsertRecords.Input();
		input3.baseInput = new FlowDmlBaseInput();
		input3.baseInput.accessLevelName = System.AccessLevel.SYSTEM_MODE.toString();
		input3.baseInput.allOrNone = true;
		input3.baseInput.record = new MockRecord(Account.SObjectType).toSObject();
		List<InvocableDmlUpsertRecords.Input> inputs = new List<InvocableDmlUpsertRecords.Input>{
			input1,
			input2,
			input3
		};

		Test.startTest();
		List<InvocableDmlUpsertRecords.Output> outputs = InvocableDmlUpsertRecords.invoke(inputs);
		Test.stopTest();

		Assert.areEqual(3, MockDml.UPSERTED.numDmlStatements, 'Wrong # of upsert calls');
		Assert.areEqual(3, MockDml.UPSERTED.getAll().size(), 'Wrong # of upserted records');
		for (InvocableDmlUpsertRecords.Input input : inputs) {
			Assert.isTrue(MockDml.UPSERTED.wasProcessed(input?.baseInput?.record), 'Test record was not processed');
		}
	}

	@IsTest
	private static void shouldNoOpIfNeitherInputPopulated() {
		InvocableDmlUpsertRecords.Input input = new InvocableDmlUpsertRecords.Input();
		input.baseInput = new FlowDmlBaseInput();
		List<InvocableDmlUpsertRecords.Input> inputs = new List<InvocableDmlUpsertRecords.Input>{ input };

		Test.startTest();
		List<InvocableDmlUpsertRecords.Output> outputs = InvocableDmlUpsertRecords.invoke(inputs);
		Test.stopTest();

		Assert.areEqual(0, MockDml.UPSERTED.getAll().size(), 'Wrong # of upserted records');
	}

	@SuppressWarnings('PMD.EmptyCatchBlock')
	@IsTest
	private static void shouldHandleAndRethrowErrors() {
		MockDml.shouldFail();
		SObject record = new MockRecord(Account.SObjectType).toSObject();
		InvocableDmlUpsertRecords.Input input = new InvocableDmlUpsertRecords.Input();
		input.baseInput = new FlowDmlBaseInput();
		input.baseInput.record = record;
		List<InvocableDmlUpsertRecords.Input> inputs = new List<InvocableDmlUpsertRecords.Input>{ input };

		Test.startTest();
		try {
			InvocableDmlUpsertRecords.invoke(inputs);
			Assert.fail('Did not throw a System.DmlException');
		} catch (System.DmlException error) {
			// As expected...
		}
		Test.stopTest();
	}
}
