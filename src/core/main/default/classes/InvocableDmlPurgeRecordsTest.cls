@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class InvocableDmlPurgeRecordsTest {
    static {
        DatabaseLayer.useMocks();
    }

    @IsTest
    private static void shouldPurgeSingleRecord() {
        Id recordId = MockRecord.initRecordId(Account.SObjectType);
        FlowDmlDeleteInput input = new FlowDmlDeleteInput();
        input.recordId = recordId;
        List<FlowDmlDeleteInput> inputs = new List<FlowDmlDeleteInput>{ input };

        Test.startTest();
        List<FlowDmlBaseOutput> outputs = InvocableDmlPurgeRecords.invoke(inputs);
        Test.stopTest();

        Assert.areEqual(1, MockDml.PURGED.getAll().size(), 'Wrong # of purged records');
        Assert.isTrue(MockDml.PURGED.wasProcessed(recordId), 'Test record was not processed');
    }

    @IsTest
    private static void shouldPurgeMultipleRecords() {
        FlowDmlDeleteInput input = new FlowDmlDeleteInput();
        input.recordIds = new List<Id>{};
        for (Integer i = 0; i < 3; i++) {
            input.recordIds?.add(MockRecord.initRecordId(Account.SObjectType));
        }
        List<FlowDmlDeleteInput> inputs = new List<FlowDmlDeleteInput>{ input };

        Test.startTest();
        List<FlowDmlBaseOutput> outputs = InvocableDmlPurgeRecords.invoke(inputs);
        Test.stopTest();

        Assert.areEqual(3, MockDml.PURGED.getAll().size(), 'Wrong # of purged records');
        for (Id recordId : input.recordIds) {
            Assert.isTrue(MockDml.PURGED.wasProcessed(recordId), 'Test record was not processed');
        }
    }

    @IsTest
    private static void shouldHandleBothInputsPopulated() {
        FlowDmlDeleteInput input = new FlowDmlDeleteInput();
        input.recordId = MockRecord.initRecordId(Account.SObjectType);
        input.recordIds = new List<Id>{};
        for (Integer i = 0; i < 3; i++) {
            input.recordIds?.add(MockRecord.initRecordId(Account.SObjectType));
        }
        List<FlowDmlDeleteInput> inputs = new List<FlowDmlDeleteInput>{ input };

        Test.startTest();
        List<FlowDmlBaseOutput> outputs = InvocableDmlPurgeRecords.invoke(inputs);
        Test.stopTest();

        Assert.areEqual(4, MockDml.PURGED.getAll().size(), 'Wrong # of purged records');
        Assert.isTrue(MockDml.PURGED.wasProcessed(input?.recordId), 'Single record was not processed');
        for (Id recordId : input.recordIds) {
            Assert.isTrue(MockDml.PURGED.wasProcessed(recordId), 'Test record was not processed');
        }
    }

    @IsTest
    private static void shouldPurgeSingleRecordViaIdInput() {
        FlowDmlDeleteInput input = new FlowDmlDeleteInput();
        input.recordId = MockRecord.initRecordId(Account.SObjectType);
        input.baseInput.records = new List<SObject>{};
        for (Integer i = 0; i < 3; i++) {
            input.baseInput.records?.add(new MockRecord(Account.SObjectType).toSObject());
        }
        List<FlowDmlDeleteInput> inputs = new List<FlowDmlDeleteInput>{ input };

        Test.startTest();
        List<FlowDmlBaseOutput> outputs = InvocableDmlPurgeRecords.invoke(inputs);
        Test.stopTest();

        Assert.areEqual(4, MockDml.PURGED.getAll().size(), 'Wrong # of purged records');
        Assert.isTrue(MockDml.PURGED.wasProcessed(input?.recordId), 'Single Id record was not processed');
        for (SObject rec : input.baseInput.records) {
            Assert.isTrue(MockDml.PURGED.wasProcessed(rec), 'SObject record was not processed');
        }
    }

    @IsTest
    private static void shouldPurgeMultipleRecordsViaIdInput() {
        FlowDmlDeleteInput input = new FlowDmlDeleteInput();
        input.recordIds = new List<Id>{};
        for (Integer i = 0; i < 3; i++) {
            input.recordIds?.add(MockRecord.initRecordId(Account.SObjectType));
        }
        input.baseInput.record = new MockRecord(Account.SObjectType).toSObject();
        List<FlowDmlDeleteInput> inputs = new List<FlowDmlDeleteInput>{ input };

        Test.startTest();
        List<FlowDmlBaseOutput> outputs = InvocableDmlPurgeRecords.invoke(inputs);
        Test.stopTest();

        Assert.areEqual(4, MockDml.PURGED.getAll().size(), 'Wrong # of purged records');
        Assert.isTrue(MockDml.PURGED.wasProcessed(input?.baseInput?.record), 'Single SObject record was not processed');
        for (Id recordId : input.recordIds) {
            Assert.isTrue(MockDml.PURGED.wasProcessed(recordId), 'Id record was not processed');
        }
    }

    @IsTest
    private static void shouldHandleAllInputTypesPopulated() {
        FlowDmlDeleteInput input = new FlowDmlDeleteInput();
        input.recordId = MockRecord.initRecordId(Account.SObjectType);
        input.baseInput.record = new MockRecord(Account.SObjectType).toSObject();
        for (Integer i = 0; i < 3; i++) {
            Id recordId = MockRecord.initRecordId(Account.SObjectType);
            input.recordIds?.add(recordId);
            SObject record = new MockRecord(Account.SObjectType).toSObject();
            input.baseInput?.records?.add(record);
        }
        List<FlowDmlDeleteInput> inputs = new List<FlowDmlDeleteInput>{ input };

        Test.startTest();
        List<FlowDmlBaseOutput> outputs = InvocableDmlPurgeRecords.invoke(inputs);
        Test.stopTest();

        Assert.areEqual(8, MockDml.PURGED.getAll().size(), 'Wrong # of purged records');
        Assert.isTrue(MockDml.PURGED.wasProcessed(input?.recordId), 'Single Id record was not processed');
        Assert.isTrue(MockDml.PURGED.wasProcessed(input?.baseInput?.record), 'Single SObject record was not processed');
        for (Id recordId : input.recordIds) {
            Assert.isTrue(MockDml.PURGED.wasProcessed(recordId), 'Id record was not processed');
        }
        for (SObject record : input.baseInput.records) {
            Assert.isTrue(MockDml.PURGED.wasProcessed(record), 'SObject record was not processed');
        }
    }

    @IsTest
    private static void shouldSplitDifferentConfigurationsIntoDifferentDmlStatements() {
        // 3 different input configurations --> 3 different DML statements
        FlowDmlDeleteInput input1 = new FlowDmlDeleteInput();
        input1.baseInput.accessLevelName = System.AccessLevel.USER_MODE.toString();
        input1.baseInput.allOrNone = false;
        input1.recordId = MockRecord.initRecordId(Account.SObjectType);
        FlowDmlDeleteInput input2 = new FlowDmlDeleteInput();
        input2.baseInput.accessLevelName = System.AccessLevel.USER_MODE.toString();
        input2.baseInput.allOrNone = true;
        input2.recordId = MockRecord.initRecordId(Account.SObjectType);
        FlowDmlDeleteInput input3 = new FlowDmlDeleteInput();
        input3.baseInput.accessLevelName = System.AccessLevel.SYSTEM_MODE.toString();
        input3.baseInput.allOrNone = true;
        input3.recordId = MockRecord.initRecordId(Account.SObjectType);
        List<FlowDmlDeleteInput> inputs = new List<FlowDmlDeleteInput>{ input1, input2, input3 };

        Test.startTest();
        List<FlowDmlBaseOutput> outputs = InvocableDmlPurgeRecords.invoke(inputs);
        Test.stopTest();

        Assert.areEqual(3, MockDml.PURGED.numDmlStatements, 'Wrong # of purge calls');
        Assert.areEqual(3, MockDml.PURGED.getAll().size(), 'Wrong # of purged records');
        for (FlowDmlDeleteInput input : inputs) {
            Assert.isTrue(MockDml.PURGED.wasProcessed(input?.recordId), 'Test record was not processed');
        }
    }

    @IsTest
    private static void shouldNoOpIfNeitherInputPopulated() {
        FlowDmlDeleteInput input = new FlowDmlDeleteInput();
        List<FlowDmlDeleteInput> inputs = new List<FlowDmlDeleteInput>{ input };

        Test.startTest();
        List<FlowDmlBaseOutput> outputs = InvocableDmlPurgeRecords.invoke(inputs);
        Test.stopTest();

        Assert.areEqual(0, MockDml.PURGED.getAll().size(), 'Wrong # of purged records');
    }

    @SuppressWarnings('PMD.EmptyCatchBlock')
    @IsTest
    private static void shouldHandleAndRethrowErrors() {
        MockDml.shouldFail();
        FlowDmlDeleteInput input = new FlowDmlDeleteInput();
        input.recordId = MockRecord.initRecordId(Account.SObjectType);
        List<FlowDmlDeleteInput> inputs = new List<FlowDmlDeleteInput>{ input };

        Test.startTest();
        try {
            InvocableDmlPurgeRecords.invoke(inputs);
            Assert.fail('Did not throw a System.DmlException');
        } catch (System.DmlException error) {
            // As expected...
        }
        Test.stopTest();
    }
}
