@IsTest 
private class MockDmlTest {
    @IsTest 
    static void shouldMockLeadConvert() {
        Map<Id, Lead> leads = new Map<Id, Lead>();
        List<Database.LeadConvert> leadsToConvert = new List<Database.LeadConvert>();
        for (Integer i = 0; i < TEST_SIZE; i++) {
            Id leadId = SObjectUtils.generateMockId(Lead.SObjectType);
            Lead lead = new Lead(Id = leadId);
            leads?.put(lead?.Id, lead); 
            Database.LeadConvert leadToConvert = new Database.LeadConvert();
            leadToConvert?.setLeadId(leadId);
            leadToConvert?.setConvertedStatus('Some Status');
            leadsToConvert?.add(leadToConvert);
        }

        Test.startTest();
        List<Database.LeadConvertResult> results = new MockDml()?.doConvert(leadsToConvert);
        Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
        Test.stopTest();

        Integer numResults = results?.size();
        Assert.areEqual(leadsToConvert?.size(), numResults, 'Wrong # of results'); 
        Assert.areEqual(numResults, MockDml.Converted?.getAll()?.size(), 'Wrong # of converted records');
        for (Database.LeadConvertResult result : results) {
            Assert.areEqual(true, result?.isSuccess(), 'Did not succeed: ' + result?.getErrors()); 
            Id leadId = result?.getLeadId();
            Lead lead = leads?.get(leadId);
            Assert.isNotNull(lead, 'No lead w/matching Id: ' + leadId);
            Assert.isNotNull(lead?.ConvertedAccountId, 'Missing ConvertedAccountId');
            Assert.areEqual(result?.getAccountId(), lead?.ConvertedAccountId, 'Wrong ConvertedAccountId');
            Assert.isNotNull(lead?.ConvertedContactId, 'Missing ConvertedContactId');
            Assert.areEqual(result?.getContactId(), lead?.ConvertedContactId, 'Wrong ConvertedContactId');
            Assert.isNotNull(lead?.ConvertedOpportunityId, 'Missing ConvertedOpportunityId');
            Assert.areEqual(result?.getOpportunityId(), lead?.ConvertedOpportunityId, 'Wrong ConvertedOpportunityId');
        }
    }

    @IsTest 
    static void shouldThrowExceptionIfErrorOnConvert() {
        List<Database.LeadConvert> leadsToConvert = new List<Database.LeadConvert>();
        for (Integer i = 0; i < TEST_SIZE; i++) {
            Id leadId = SObjectUtils.generateMockId(Lead.SObjectType);
            Database.LeadConvert leadToConvert = new Database.LeadConvert();
            leadToConvert?.setLeadId(leadId);
            leadToConvert?.setConvertedStatus('Some Status');
            leadsToConvert?.add(leadToConvert);
        }
        MockDml.FailureLogic failure = new MockFailure();
        Dml dml = new MockDml()?.addFailure(failure);

        Test.startTest();
        try {
            dml?.doConvert(leadsToConvert);
            Assert.fail('Did not throw an error');
        } catch (Exception error) {
            // ...as expected...
            Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
            Assert.areEqual(0, MockDml.Converted?.getAll()?.size(), 'Wrong # of converted records'); 
        }
        Test.stopTest();
    }

    @IsTest 
    static void shouldFailSilentlyIfErrorAndNotAllOrNoneOnConvert() {
        List<Database.LeadConvert> leadsToConvert = new List<Database.LeadConvert>();
        for (Integer i = 0; i < TEST_SIZE; i++) {
            Id leadId = SObjectUtils.generateMockId(Lead.SObjectType);
            Database.LeadConvert leadToConvert = new Database.LeadConvert();
            leadToConvert?.setLeadId(leadId);
            leadToConvert?.setConvertedStatus('Some Status');
            leadsToConvert?.add(leadToConvert);
        }
        MockDml.FailureLogic failure = new MockFailure();
        Dml dml = new MockDml()?.addFailure(failure)?.setAllOrNone(false);

        Test.startTest();
        List<Database.LeadConvertResult> results = dml?.doConvert(leadsToConvert);
        Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
        Test.stopTest();

        Assert.areEqual(leadsToConvert?.size(), results?.size(), 'Wrong # of results'); 
        Assert.areEqual(0, MockDml.Converted?.getAll()?.size(), 'Wrong # of converted records'); 
        for (Database.LeadConvertResult result : results) {
            Assert.areEqual(false, result?.isSuccess(), 'Should not have succeeded'); 
        }
    }

    @IsTest 
    static void shouldMockDelete() {
        List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);
        
        Test.startTest();
        List<Database.DeleteResult> results = new MockDml()?.doDelete(leads);
        Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
        Test.stopTest();

        Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results'); 
        Assert.areEqual(leads?.size(), MockDml.Deleted?.getAll()?.size(), 'Wrong # of deleted records'); 
        for (Database.DeleteResult result : results) {
            Assert.areEqual(true, result?.isSuccess(), 'Should not have succeeded'); 
        }
    }

    @IsTest 
    static void shouldMockDeleteAsync() {
        List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);
        
        Test.startTest();
        List<Database.DeleteResult> results = new MockDml()?.doDeleteAsync(leads);
        Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
        Test.stopTest();

        Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results'); 
        Assert.areEqual(leads?.size(), MockDml.Deleted?.getAll()?.size(), 'Wrong # of deleted records'); 
        for (Database.DeleteResult result : results) {
            Assert.areEqual(true, result?.isSuccess(), 'Should not have succeeded'); 
        }
    }

    @IsTest 
    static void shouldMockDeleteImmediate() {
        List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);
        
        Test.startTest();
        List<Database.DeleteResult> results = new MockDml()?.doDeleteImmediate(leads);
        Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
        Test.stopTest();

        Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results'); 
        Assert.areEqual(leads?.size(), MockDml.Deleted?.getAll()?.size(), 'Wrong # of deleted records'); 
        for (Database.DeleteResult result : results) {
            Assert.areEqual(true, result?.isSuccess(), 'Should not have succeeded'); 
        }
    }

    @IsTest 
    static void shouldMockHardDelete() {
        List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);
        
        Test.startTest();
        List<Database.DeleteResult> results = new MockDml()?.doHardDelete(leads);
        Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
        Test.stopTest();

        Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results'); 
        Assert.areEqual(leads?.size(), MockDml.Deleted?.getAll()?.size(), 'Wrong # of deleted records'); 
        for (Database.DeleteResult result : results) {
            Assert.areEqual(true, result?.isSuccess(), 'Should not have succeeded'); 
        }
    }

    @IsTest 
    static void shouldThrowExceptionIfErrorOnDelete() {
        List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);
        MockDml.FailureLogic failure = new MockFailure();
        Dml dml = new MockDml()?.addFailure(failure);
        
        Test.startTest();
        try {
            dml?.doDelete(leads);
            Assert.fail('Did not throw an error');
        } catch (Exception error) {
            // ...as expected...
            Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
            Assert.areEqual(0, MockDml.Deleted?.getAll()?.size(), 'Wrong # of deleted records'); 
        }
        Test.stopTest();
    }

    @IsTest 
    static void shouldFailSilentlyIfErrorAndNotAllOrNoneOnDelete() {
        List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);
        MockDml.FailureLogic failure = new MockFailure();
        Dml dml = new MockDml()?.addFailure(failure)?.setAllOrNone(false);

        Test.startTest();
        List<Database.DeleteResult> results = dml?.doDelete(leads);
        Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
        Test.stopTest();

        Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results'); 
        Assert.areEqual(0, MockDml.Deleted?.getAll()?.size(), 'Wrong # of deleted records'); 
        for (Database.DeleteResult result : results) {
            Assert.areEqual(false, result?.isSuccess(), 'Should not have succeeded'); 
            Assert.isNotNull(result?.getId(), 'Missing Id');
        }
    }

    @IsTest 
    static void shouldMockInsert() {
        List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType);

        Test.startTest();
        List<Database.SaveResult> results = new MockDml()?.doInsert(leads);
        Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
        Test.stopTest();

        Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results'); 
        Assert.areEqual(leads?.size(), MockDml.Inserted?.getAll()?.size(), 'Wrong # of inserted records'); 
        for (Database.SaveResult result : results) {
            Assert.areEqual(true, result?.isSuccess(), 'Did not succeed: ' + result?.getErrors()); 
            Assert.isNotNull(result?.getId(), 'Missing Id');
        }
    }

    @IsTest 
    static void shouldMockInsertAsync() {
        List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType);

        Test.startTest();
        List<Database.SaveResult> results = new MockDml()?.doInsertAsync(leads);
        Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
        Test.stopTest();

        Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results'); 
        Assert.areEqual(leads?.size(), MockDml.Inserted?.getAll()?.size(), 'Wrong # of inserted records'); 
        for (Database.SaveResult result : results) {
            Assert.areEqual(true, result?.isSuccess(), 'Did not succeed: ' + result?.getErrors()); 
            Assert.isNotNull(result?.getId(), 'Missing Id');
        }
    }

    @IsTest 
    static void shouldMockInsertImmediate() {
        List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType);

        Test.startTest();
        List<Database.SaveResult> results = new MockDml()?.doInsertImmediate(leads);
        Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
        Test.stopTest();

        Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results'); 
        Assert.areEqual(leads?.size(), MockDml.Inserted?.getAll()?.size(), 'Wrong # of inserted records'); 
        for (Database.SaveResult result : results) {
            Assert.areEqual(true, result?.isSuccess(), 'Did not succeed: ' + result?.getErrors()); 
            Assert.isNotNull(result?.getId(), 'Missing Id');
        }
    }

    @IsTest 
    static void shouldThrowExceptionIfErrorOnInsert() {
        List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType);
        MockDml.FailureLogic failure = new MockFailure();
        Dml dml = new MockDml()?.addFailure(failure);

        Test.startTest();
        try {
            dml?.doInsert(leads);
            Assert.fail('Did not throw an error');
        } catch (Exception error) {
            // ...as expected...
            Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
            Assert.areEqual(0, MockDml.Inserted?.getAll()?.size(), 'Wrong # of inserted records'); 
        }
        Test.stopTest();
    }

    @IsTest 
    static void shouldFailSilentlyIfErrorAndNotAllOrNoneOnInsert() {
        List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType);
        MockDml.FailureLogic failure = new MockFailure();
        Dml dml = new MockDml()?.addFailure(failure)?.setAllOrNone(false);

        Test.startTest();
        List<Database.SaveResult> results = dml?.doInsert(leads);
        Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
        Test.stopTest();

        Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results'); 
        Assert.areEqual(0, MockDml.Inserted?.getAll()?.size(), 'Wrong # of inserted records'); 
        for (Database.SaveResult result : results) {
            Assert.areEqual(false, result?.isSuccess(), 'Should not have succeeded'); 
            Assert.isNull(result?.getId(), 'Insert failed, but has an Id?');
        }
    }

    @IsTest 
    static void shouldMockPublish() {
        List<BatchApexErrorEvent> events = MockDmlTest.initRecords(BatchApexErrorEvent.SObjectType);

        Test.startTest();
        List<Database.SaveResult> results = new MockDml()?.doPublish(events);
        Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
        Test.stopTest();

        Assert.areEqual(events?.size(), results?.size(), 'Wrong # of results'); 
        Assert.areEqual(events?.size(), MockDml.Published?.getAll()?.size(), 'Wrong # of published records'); 
        for (Database.SaveResult result : results) {
            Assert.areEqual(true, result?.isSuccess(), 'Did not succeed: ' + result?.getErrors()); 
            Assert.isNotNull(result?.getId(), 'Missing Id');
        }
    }

    @IsTest 
    static void shouldThrowExceptionIfErrorOnPublish() {
        List<BatchApexErrorEvent> events = MockDmlTest.initRecords(BatchApexErrorEvent.SObjectType);
        MockDml.FailureLogic failure = new MockFailure();
        Dml dml = new MockDml()?.addFailure(failure);

        Test.startTest();
        try {
            dml?.doPublish(events);
            Assert.fail('Did not throw an error');
        } catch (Exception error) {
            // ...as expected...
            Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
            Assert.areEqual(0, MockDml.Published?.getAll()?.size(), 'Wrong # of published records'); 
        }
        Test.stopTest();
    }

    @IsTest 
    static void shouldFailSilentlyIfErrorAndNotAllOrNoneOnPublish() {
        List<BatchApexErrorEvent> events = MockDmlTest.initRecords(BatchApexErrorEvent.SObjectType);
        MockDml.FailureLogic failure = new MockFailure();
        Dml dml = new MockDml()?.addFailure(failure)?.setAllOrNone(false);

        Test.startTest();
        List<Database.SaveResult> results = dml?.doPublish(events);
        Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
        Test.stopTest();

        Assert.areEqual(events?.size(), results?.size(), 'Wrong # of results'); 
        Assert.areEqual(0, MockDml.Published?.getAll()?.size(), 'Wrong # of published records'); 
        for (Database.SaveResult result : results) {
            Assert.areEqual(false, result?.isSuccess(), 'Should not have succeeded'); 
            Assert.isNotNull(result?.getId(), 'Missing Id');
        }
    }

    @IsTest 
    static void shouldMockUndelete() {
        List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);

        Test.startTest();
        List<Database.UndeleteResult> results = new MockDml()?.doUndelete(leads);
        Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
        Test.stopTest();

        Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results'); 
        Assert.areEqual(leads?.size(), MockDml.Undeleted?.getAll()?.size(), 'Wrong # of undeleted records'); 
        for (Database.UndeleteResult result : results) {
            Assert.areEqual(true, result?.isSuccess(), 'Did not succeed: ' + result?.getErrors()); 
            Assert.isNotNull(result?.getId(), 'Missing Id');
        }
    }

    @IsTest 
    static void shouldThrowExceptionIfErrorOnUndelete() {
        List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);
        MockDml.FailureLogic failure = new MockFailure();
        Dml dml = new MockDml()?.addFailure(failure);

        Test.startTest();
        try {
            dml?.doUndelete(leads);
            Assert.fail('Did not throw an error');
        } catch (Exception error) {
            // ...as expected...
            Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
            Assert.areEqual(0, MockDml.Undeleted?.getAll()?.size(), 'Wrong # of undeleted records'); 
        }
        Test.stopTest();
    }

    @IsTest 
    static void shouldFailSilentlyIfErrorAndNotAllOrNoneOnUndelete() {
        List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);
        MockDml.FailureLogic failure = new MockFailure();
        Dml dml = new MockDml()?.addFailure(failure)?.setAllOrNone(false);

        Test.startTest();
        List<Database.UndeleteResult> results = dml?.doUndelete(leads);
        Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
        Test.stopTest();

        Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results'); 
        Assert.areEqual(0, MockDml.Undeleted?.getAll()?.size(), 'Wrong # of undeleted records'); 
        for (Database.UndeleteResult result : results) {
            Assert.areEqual(false, result?.isSuccess(), 'Should not have succeeded'); 
            Assert.isNotNull(result?.getId(), 'Missing Id');
        }
    }

    @IsTest 
    static void shouldMockUpdate() {
        List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);

        Test.startTest();
        List<Database.SaveResult> results = new MockDml()?.doUpdate(leads);
        Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
        Test.stopTest();

        Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results'); 
        Assert.areEqual(leads?.size(), MockDml.Updated?.getAll()?.size(), 'Wrong # of updated records'); 
        for (Database.SaveResult result : results) {
            Assert.areEqual(true, result?.isSuccess(), 'Did not succeed: ' + result?.getErrors()); 
            Assert.isNotNull(result?.getId(), 'Missing Id');
        }
    }

    @IsTest 
    static void shouldMockUpdateAsync() {
        List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);

        Test.startTest();
        List<Database.SaveResult> results = new MockDml()?.doUpdateAsync(leads);
        Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
        Test.stopTest();

        Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results'); 
        Assert.areEqual(leads?.size(), MockDml.Updated?.getAll()?.size(), 'Wrong # of updated records'); 
        for (Database.SaveResult result : results) {
            Assert.areEqual(true, result?.isSuccess(), 'Did not succeed: ' + result?.getErrors()); 
            Assert.isNotNull(result?.getId(), 'Missing Id');
        }
    }

    @IsTest 
    static void shouldMockUpdateImmediate() {
        List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);

        Test.startTest();
        List<Database.SaveResult> results = new MockDml()?.doUpdateImmediate(leads);
        Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
        Test.stopTest();

        Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results'); 
        Assert.areEqual(leads?.size(), MockDml.Updated?.getAll()?.size(), 'Wrong # of updated records'); 
        for (Database.SaveResult result : results) {
            Assert.areEqual(true, result?.isSuccess(), 'Did not succeed: ' + result?.getErrors()); 
            Assert.isNotNull(result?.getId(), 'Missing Id');
        }
    }

    @IsTest 
    static void shouldThrowExceptionIfErrorOnUpdate() {
        List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);
        MockDml.FailureLogic failure = new MockFailure();
        Dml dml = new MockDml()?.addFailure(failure);

        Test.startTest();
        try {
            dml?.doUpdate(leads);
            Assert.fail('Did not throw an error');
        } catch (Exception error) {
            // ...as expected...
            Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
            Assert.areEqual(0, MockDml.Updated?.getAll()?.size(), 'Wrong # of updated records'); 
        }
        Test.stopTest();
    }

    @IsTest 
    static void shouldFailSilentlyIfErrorAndNotAllOrNoneOnUpdate() {
        List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);
        MockDml.FailureLogic failure = new MockFailure();
        Dml dml = new MockDml()?.addFailure(failure)?.setAllOrNone(false);

        Test.startTest();
        List<Database.SaveResult> results = dml?.doUpdate(leads);
        Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
        Test.stopTest();

        Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results'); 
        Assert.areEqual(0, MockDml.Updated?.getAll()?.size(), 'Wrong # of updated records'); 
        for (Database.SaveResult result : results) {
            Assert.areEqual(false, result?.isSuccess(), 'Should not have succeeded'); 
            Assert.isNotNull(result?.getId(), 'Missing Id');
        }
    }

    @IsTest 
    static void shouldMockUpsert() {
        List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);

        Test.startTest();
        List<Database.UpsertResult> results = new MockDml()?.doUpsert(leads);
        Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
        Test.stopTest();

        Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results'); 
        Assert.areEqual(leads?.size(), MockDml.Upserted?.getAll()?.size(), 'Wrong # of upserted records'); 
        for (Database.UpsertResult result : results) {
            Assert.areEqual(true, result?.isSuccess(), 'Did not succeed: ' + result?.getErrors()); 
            Assert.isNotNull(result?.getId(), 'Missing Id');
        }
    }

    @IsTest 
    static void shouldThrowExceptionIfErrorOnUpsert() {
        List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);
        MockDml.FailureLogic failure = new MockFailure();
        Dml dml = new MockDml()?.addFailure(failure);

        Test.startTest();
        try {
            dml?.doUpsert(leads);
            Assert.fail('Did not throw an error');
        } catch (Exception error) {
            // ...as expected...
            Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
            Assert.areEqual(0, MockDml.Upserted?.getAll()?.size(), 'Wrong # of upserted records'); 
        }
        Test.stopTest();
    }

    @IsTest 
    static void shouldFailSilentlyIfErrorAndNotAllOrNoneOnUpsert() {
        List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);
        MockDml.FailureLogic failure = new MockFailure();
        Dml dml = new MockDml()?.addFailure(failure)?.setAllOrNone(false);

        Test.startTest();
        List<Database.UpsertResult> results = dml?.doUpsert(leads);
        Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
        Test.stopTest();

        Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results'); 
        Assert.areEqual(0, MockDml.Upserted?.getAll()?.size(), 'Wrong # of upserted records'); 
        for (Database.UpsertResult result : results) {
            Assert.areEqual(false, result?.isSuccess(), 'Should not have succeeded'); 
            Assert.isNotNull(result?.getId(), 'Missing Id');
        }
    }

    @IsTest 
    static void shouldProvideUsefulInformationAboutProcessedRecords() {
        Lead testLead = (Lead) MockDmlTest.initRecord(Lead.SObjectType, true);
        // Pre-test asserts
        Assert.areEqual(false, MockDml.Updated.wasProcessed(testLead), 'Pre-test: Should not have been processed');
        Assert.isNull(MockDml.Updated.getRecord(testLead), 'Pre-test: Lead was processed');
        Assert.areEqual(0, MockDml.Updated.getRecords(Lead.SObjectType)?.size(), 'Pre-test: Wrong # of lead updates');
        Assert.areEqual(0, MockDml.Updated.getAll()?.size(), 'Pre-test: Wrong # of total updates');
        testLead.Company = 'Credicor Inc.';

        Test.startTest();
        new MockDml()?.doUpdate(testLead);
        Test.stopTest();

        // Post-test asserts
        Assert.areEqual(true, MockDml.Updated.wasProcessed(testLead), 'Lead was not processed');
        Lead updatedLead = (Lead) MockDml.Updated.getRecord(testLead);
        Assert.isNotNull(updatedLead, 'Lead was not updated'); 
        Assert.areEqual(testLead?.Company, updatedLead?.Company, 'Did not update Company');
        Assert.areEqual(1, MockDml.Updated.getRecords(Lead.SObjectType)?.size(), 'Wrong # of lead updates');
        Assert.areEqual(1, MockDml.Updated.getAll()?.size(), 'Wrong # of total updates');

        // Callers can also call this method to erase the current history:
        new MockDml()?.eraseHistory();
        Assert.areEqual(true, MockDml.Updated.getAll()?.isEmpty(), 'Did not reset history');
    }

    // **** HELPER **** // 
    static final Integer TEST_SIZE = 200; 

    static List<SObject> initRecords(SObjectType objectType, Boolean withId) {
        List<SObject> records = new List<SObject>();
        for (Integer i = 0; i < TEST_SIZE; i++) {
            SObject record = MockDmlTest.initRecord(objectType, withId);
            records?.add(record);
        }
        return records;
    }

    static List<SObject> initRecords(SObjectType objectType) {
        return MockDmlTest.initRecords(objectType, false);
    }

    static SObject initRecord(SObjectType objectType, Boolean withId) {
        Id recordId = (withId) ? SObjectUtils.generateMockId(objectType) : null;
        return objectType?.newSObject(recordId);
    }

    static SObject initRecord(SObjectType objectType) {
        return MockDmlTest.initRecord(objectType, false);
    }
    
    // **** INNER **** //
    public class MockFailure implements MockDml.FailureLogic {
        public MockDml.Error checkFailure(Dml.Operation operation, SObject record) {
            // This class always returns an error to be thrown
            return new MockDml.Error();
        }
    }
}