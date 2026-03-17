@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class InvocableUndeleteRecordsTest {
    static {
        DatabaseLayer.useMocks();
    }

    @IsTest
    private static void shouldUndeleteSingleRecord() {
        Id recordId = MockRecord.initRecordId(Account.SObjectType);
        FlowDmlDeleteInput input = new FlowDmlDeleteInput();
        input.recordId = recordId;
        List<FlowDmlDeleteInput> inputs = new List<FlowDmlDeleteInput>{ input };

        Test.startTest();
        List<FlowDmlBaseOutput> outputs = InvocableUndeleteRecords.invoke(inputs);
        Test.stopTest();

        Assert.areEqual(1, MockDml.UNDELETED.getAll().size(), 'Wrong # of undeleted records');
        Assert.isTrue(MockDml.UNDELETED.wasProcessed(recordId), 'Test record was not processed');
    }

    @IsTest
    private static void shouldUndeleteMultipleRecords() {
        FlowDmlDeleteInput input = new FlowDmlDeleteInput();
        input.recordIds = new List<Id>{};
        for (Integer i = 0; i < 3; i++) {
            input.recordIds?.add(MockRecord.initRecordId(Account.SObjectType));
        }
        List<FlowDmlDeleteInput> inputs = new List<FlowDmlDeleteInput>{ input };

        Test.startTest();
        List<FlowDmlBaseOutput> outputs = InvocableUndeleteRecords.invoke(inputs);
        Test.stopTest();

        Assert.areEqual(3, MockDml.UNDELETED.getAll().size(), 'Wrong # of undeleted records');
        for (Id recordId : input.recordIds) {
            Assert.isTrue(MockDml.UNDELETED.wasProcessed(recordId), 'Test record was not processed');
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
        List<FlowDmlBaseOutput> outputs = InvocableUndeleteRecords.invoke(inputs);
        Test.stopTest();

        Assert.areEqual(4, MockDml.UNDELETED.getAll().size(), 'Wrong # of undeleted records');
        Assert.isTrue(MockDml.UNDELETED.wasProcessed(input?.recordId), 'Single record was not processed');
        for (Id recordId : input.recordIds) {
            Assert.isTrue(MockDml.UNDELETED.wasProcessed(recordId), 'Test record was not processed');
        }
    }

    @IsTest
    private static void shouldUndeleteSingleRecordViaIdInput() {
        FlowDmlDeleteInput input = new FlowDmlDeleteInput();
        input.recordId = MockRecord.initRecordId(Account.SObjectType);
        input.baseInput.records = new List<SObject>{};
        for (Integer i = 0; i < 3; i++) {
            input.baseInput.records?.add(new MockRecord(Account.SObjectType).toSObject());
        }
        List<FlowDmlDeleteInput> inputs = new List<FlowDmlDeleteInput>{ input };

        Test.startTest();
        List<FlowDmlBaseOutput> outputs = InvocableUndeleteRecords.invoke(inputs);
        Test.stopTest();

        Assert.areEqual(4, MockDml.UNDELETED.getAll().size(), 'Wrong # of undeleted records');
        Assert.isTrue(MockDml.UNDELETED.wasProcessed(input?.recordId), 'Single Id record was not processed');
        for (SObject rec : input.baseInput.records) {
            Assert.isTrue(MockDml.UNDELETED.wasProcessed(rec), 'SObject record was not processed');
        }
    }

    @IsTest
    private static void shouldUndeleteMultipleRecordsViaIdInput() {
        FlowDmlDeleteInput input = new FlowDmlDeleteInput();
        input.recordIds = new List<Id>{};
        for (Integer i = 0; i < 3; i++) {
            input.recordIds?.add(MockRecord.initRecordId(Account.SObjectType));
        }
        input.baseInput.record = new MockRecord(Account.SObjectType).toSObject();
        List<FlowDmlDeleteInput> inputs = new List<FlowDmlDeleteInput>{ input };

        Test.startTest();
        List<FlowDmlBaseOutput> outputs = InvocableUndeleteRecords.invoke(inputs);
        Test.stopTest();

        Assert.areEqual(4, MockDml.UNDELETED.getAll().size(), 'Wrong # of undeleted records');
        Assert.isTrue(MockDml.UNDELETED.wasProcessed(input?.baseInput?.record), 'Single SObject record was not processed');
        for (Id recordId : input.recordIds) {
            Assert.isTrue(MockDml.UNDELETED.wasProcessed(recordId), 'Id record was not processed');
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
        List<FlowDmlBaseOutput> outputs = InvocableUndeleteRecords.invoke(inputs);
        Test.stopTest();

        Assert.areEqual(8, MockDml.UNDELETED.getAll().size(), 'Wrong # of undeleted records');
        Assert.isTrue(MockDml.UNDELETED.wasProcessed(input?.recordId), 'Single Id record was not processed');
        Assert.isTrue(MockDml.UNDELETED.wasProcessed(input?.baseInput?.record), 'Single SObject record was not processed');
        for (Id recordId : input.recordIds) {
            Assert.isTrue(MockDml.UNDELETED.wasProcessed(recordId), 'Id record was not processed');
        }
        for (SObject record : input.baseInput.records) {
            Assert.isTrue(MockDml.UNDELETED.wasProcessed(record), 'SObject record was not processed');
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
        List<FlowDmlBaseOutput> outputs = InvocableUndeleteRecords.invoke(inputs);
        Test.stopTest();

        Assert.areEqual(3, MockDml.UNDELETED.numDmlStatements, 'Wrong # of undelete calls');
        Assert.areEqual(3, MockDml.UNDELETED.getAll().size(), 'Wrong # of undeleted records');
        for (FlowDmlDeleteInput input : inputs) {
            Assert.isTrue(MockDml.UNDELETED.wasProcessed(input?.recordId), 'Test record was not processed');
        }
    }

    @IsTest
    private static void shouldNoOpIfNeitherInputPopulated() {
        FlowDmlDeleteInput input = new FlowDmlDeleteInput();
        List<FlowDmlDeleteInput> inputs = new List<FlowDmlDeleteInput>{ input };

        Test.startTest();
        List<FlowDmlBaseOutput> outputs = InvocableUndeleteRecords.invoke(inputs);
        Test.stopTest();

        Assert.areEqual(0, MockDml.UNDELETED.getAll().size(), 'Wrong # of undeleted records');
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
            InvocableUndeleteRecords.invoke(inputs);
            Assert.fail('Did not throw a System.DmlException');
        } catch (System.DmlException error) {
            // As expected...
        }
        Test.stopTest();
    }
}
