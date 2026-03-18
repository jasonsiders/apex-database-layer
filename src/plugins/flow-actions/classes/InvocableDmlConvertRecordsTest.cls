@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class InvocableDmlConvertRecordsTest {
    static {
        DatabaseLayer.useMocks();
    }

    @IsTest
    private static void shouldConvertSingleLead() {
        Id leadId = MockRecord.initRecordId(Lead.SObjectType);
        InvocableDmlConvertRecords.Input input = new InvocableDmlConvertRecords.Input();
        input.leadId = leadId;
        input.convertedStatus = 'Converted';
        List<InvocableDmlConvertRecords.Input> inputs = new List<InvocableDmlConvertRecords.Input>{ input };

        Test.startTest();
        List<InvocableDmlConvertRecords.Output> outputs = InvocableDmlConvertRecords.invoke(inputs);
        Test.stopTest();

        Assert.areEqual(1, MockDml.CONVERTED.getAll().size(), 'Wrong # of converted leads');
        Assert.isTrue(MockDml.CONVERTED.wasProcessed(leadId), 'Test lead was not processed');
    }

    @IsTest
    private static void shouldConvertMultipleLeads() {
        List<Id> leadIds = new List<Id>{};
        List<InvocableDmlConvertRecords.Input> inputs = new List<InvocableDmlConvertRecords.Input>{};
        for (Integer i = 0; i < 3; i++) {
            Id leadId = MockRecord.initRecordId(Lead.SObjectType);
            leadIds.add(leadId);
            InvocableDmlConvertRecords.Input input = new InvocableDmlConvertRecords.Input();
            input.leadId = leadId;
            input.convertedStatus = 'Converted';
            inputs.add(input);
        }

        Test.startTest();
        List<InvocableDmlConvertRecords.Output> outputs = InvocableDmlConvertRecords.invoke(inputs);
        Test.stopTest();

        Assert.areEqual(3, MockDml.CONVERTED.getAll().size(), 'Wrong # of converted leads');
        for (Id leadId : leadIds) {
            Assert.isTrue(MockDml.CONVERTED.wasProcessed(leadId), 'Test lead was not processed');
        }
    }

    @IsTest
    private static void shouldSplitDifferentConfigurationsIntoDifferentDmlStatements() {
        // 3 different input configurations --> 3 different DML statements
        InvocableDmlConvertRecords.Input input1 = new InvocableDmlConvertRecords.Input();
        input1.leadId = MockRecord.initRecordId(Lead.SObjectType);
        input1.convertedStatus = 'Converted';
        input1.accessLevelName = System.AccessLevel.USER_MODE.toString();
        input1.allOrNone = false;
        InvocableDmlConvertRecords.Input input2 = new InvocableDmlConvertRecords.Input();
        input2.leadId = MockRecord.initRecordId(Lead.SObjectType);
        input2.convertedStatus = 'Converted';
        input2.accessLevelName = System.AccessLevel.USER_MODE.toString();
        input2.allOrNone = true;
        InvocableDmlConvertRecords.Input input3 = new InvocableDmlConvertRecords.Input();
        input3.leadId = MockRecord.initRecordId(Lead.SObjectType);
        input3.convertedStatus = 'Converted';
        input3.accessLevelName = System.AccessLevel.SYSTEM_MODE.toString();
        input3.allOrNone = true;
        List<InvocableDmlConvertRecords.Input> inputs = new List<InvocableDmlConvertRecords.Input>{ input1, input2, input3 };

        Test.startTest();
        List<InvocableDmlConvertRecords.Output> outputs = InvocableDmlConvertRecords.invoke(inputs);
        Test.stopTest();

        Assert.areEqual(3, MockDml.CONVERTED.numDmlStatements, 'Wrong # of convert calls');
        Assert.areEqual(3, MockDml.CONVERTED.getAll().size(), 'Wrong # of converted leads');
        for (InvocableDmlConvertRecords.Input input : inputs) {
            Assert.isTrue(MockDml.CONVERTED.wasProcessed(input?.leadId), 'Test lead was not processed');
        }
    }

    @SuppressWarnings('PMD.EmptyCatchBlock')
    @IsTest
    private static void shouldHandleAndRethrowErrors() {
        MockDml.shouldFail();
        InvocableDmlConvertRecords.Input input = new InvocableDmlConvertRecords.Input();
        input.leadId = MockRecord.initRecordId(Lead.SObjectType);
        input.convertedStatus = 'Converted';
        List<InvocableDmlConvertRecords.Input> inputs = new List<InvocableDmlConvertRecords.Input>{ input };

        Test.startTest();
        try {
            InvocableDmlConvertRecords.invoke(inputs);
            Assert.fail('Did not throw a System.DmlException');
        } catch (System.DmlException error) {
            // As expected...
        }
        Test.stopTest();
    }

    @SuppressWarnings('PMD.EmptyCatchBlock')
    @IsTest
    private static void shouldThrowErrorIfLeadIdNotProvided() {
        InvocableDmlConvertRecords.Input input = new InvocableDmlConvertRecords.Input();
        input.convertedStatus = 'Converted';
        List<InvocableDmlConvertRecords.Input> inputs = new List<InvocableDmlConvertRecords.Input>{ input };

        Test.startTest();
        try {
            InvocableDmlConvertRecords.invoke(inputs);
            Assert.fail('Did not throw a System.DmlException');
        } catch (System.DmlException error) {
            // As expected...
        }
        Test.stopTest();
    }

    @SuppressWarnings('PMD.EmptyCatchBlock')
    @IsTest
    private static void shouldThrowErrorIfConvertedStatusNotProvided() {
        InvocableDmlConvertRecords.Input input = new InvocableDmlConvertRecords.Input();
        input.leadId = MockRecord.initRecordId(Lead.SObjectType);
        List<InvocableDmlConvertRecords.Input> inputs = new List<InvocableDmlConvertRecords.Input>{ input };

        Test.startTest();
        try {
            InvocableDmlConvertRecords.invoke(inputs);
            Assert.fail('Did not throw a System.DmlException');
        } catch (System.DmlException error) {
            // As expected...
        }
        Test.stopTest();
    }
}
