@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class InvocableDmlInsertRecordsTest {
	static {
		DatabaseLayer.useMocks();
	}

	@IsTest
	private static void shouldInsertSingleRecord() {
		SObject record = new MockRecord(Account.SObjectType).toSObject();
		FlowDmlBaseInput input = new FlowDmlBaseInput();
		input.record = record;
		List<FlowDmlBaseInput> inputs = new List<FlowDmlBaseInput>{ input };

		Test.startTest();
		List<FlowDmlBaseOutput> outputs = InvocableDmlInsertRecords.invoke(inputs);
		Test.stopTest();

		Assert.areEqual(1, MockDml.INSERTED.getAll().size(), 'Wrong # of inserted records');
		Assert.isTrue(MockDml.INSERTED.wasProcessed(record), 'Test record was not processed');
	}

	@IsTest
	private static void shouldInsertMultipleRecords() {
		FlowDmlBaseInput input = new FlowDmlBaseInput();
		input.records = new List<SObject>{};
		for (Integer i = 0; i < 3; i++) {
			SObject record = new MockRecord(Account.SObjectType).toSObject();
			input.records?.add(record);
		}
		List<FlowDmlBaseInput> inputs = new List<FlowDmlBaseInput>{ input };

		Test.startTest();
		List<FlowDmlBaseOutput> outputs = InvocableDmlInsertRecords.invoke(inputs);
		Test.stopTest();

		Assert.areEqual(3, MockDml.INSERTED.getAll().size(), 'Wrong # of inserted records');
		for (SObject record : input.records) {
			Assert.isTrue(MockDml.INSERTED.wasProcessed(record), 'Test record was not processed');
		}
	}

	@IsTest
	private static void shouldHandleBothInputsPopulated() {
		FlowDmlBaseInput input = new FlowDmlBaseInput();
		input.record = new MockRecord(Account.SObjectType).toSObject();
		input.records = new List<SObject>{};
		for (Integer i = 0; i < 3; i++) {
			SObject record = new MockRecord(Account.SObjectType).toSObject();
			input.records?.add(record);
		}
		List<FlowDmlBaseInput> inputs = new List<FlowDmlBaseInput>{ input };

		Test.startTest();
		List<FlowDmlBaseOutput> outputs = InvocableDmlInsertRecords.invoke(inputs);
		Test.stopTest();

		Assert.areEqual(4, MockDml.INSERTED.getAll().size(), 'Wrong # of inserted records');
		Assert.isTrue(MockDml.INSERTED.wasProcessed(input?.record), 'Single record was not processed');
		for (SObject record : input.records) {
			Assert.isTrue(MockDml.INSERTED.wasProcessed(record), 'Test record was not processed');
		}
	}

	@IsTest
	private static void shouldSplitDifferentConfigurationsIntoDifferentDmlStatements() {
		// 3 different input configurations --> 3 different DML statements
		FlowDmlBaseInput input1 = new FlowDmlBaseInput();
		input1.accessLevelName = System.AccessLevel.USER_MODE.toString();
		input1.allOrNone = false;
		input1.record = new MockRecord(Account.SObjectType).toSObject();
		FlowDmlBaseInput input2 = new FlowDmlBaseInput();
		input2.accessLevelName = System.AccessLevel.USER_MODE.toString();
		input2.allOrNone = true;
		input2.record = new MockRecord(Account.SObjectType).toSObject();
		FlowDmlBaseInput input3 = new FlowDmlBaseInput();
		input3.accessLevelName = System.AccessLevel.SYSTEM_MODE.toString();
		input3.allOrNone = true;
		input3.record = new MockRecord(Account.SObjectType).toSObject();
		List<FlowDmlBaseInput> inputs = new List<FlowDmlBaseInput>{ input1, input2, input3 };

		Test.startTest();
		List<FlowDmlBaseOutput> outputs = InvocableDmlInsertRecords.invoke(inputs);
		Test.stopTest();

		Assert.areEqual(3, MockDml.INSERTED.numDmlStatements, 'Wrong # of insert calls');
		Assert.areEqual(3, MockDml.INSERTED.getAll().size(), 'Wrong # of inserted records');
		for (FlowDmlBaseInput input : inputs) {
			Assert.isTrue(MockDml.INSERTED.wasProcessed(input?.record), 'Test record was not processed');
		}
	}

	@IsTest
	private static void shouldNoOpIfNeitherInputPopulated() {
		FlowDmlBaseInput input = new FlowDmlBaseInput();
		List<FlowDmlBaseInput> inputs = new List<FlowDmlBaseInput>{ input };

		Test.startTest();
		List<FlowDmlBaseOutput> outputs = InvocableDmlInsertRecords.invoke(inputs);
		Test.stopTest();

		Assert.areEqual(0, MockDml.INSERTED.getAll().size(), 'Wrong # of inserted records');
	}

	@SuppressWarnings('PMD.EmptyCatchBlock')
	@IsTest
	private static void shouldHandleAndRethrowErrors() {
		MockDml.shouldFail();
		SObject record = new MockRecord(Account.SObjectType).toSObject();
		FlowDmlBaseInput input = new FlowDmlBaseInput();
		input.record = record;
		List<FlowDmlBaseInput> inputs = new List<FlowDmlBaseInput>{ input };

		Test.startTest();
		try {
			InvocableDmlInsertRecords.invoke(inputs);
			Assert.fail('Did not throw a System.DmlException');
		} catch (System.DmlException error) {
			// As expected...
		}
		Test.stopTest();
	}
}
