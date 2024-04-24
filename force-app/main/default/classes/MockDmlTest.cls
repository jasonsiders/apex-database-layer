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
        Assert.areEqual(numResults, MockDml.Converted?.getAll()?.size(), 'Wrong # of Converted leads');
        for (Database.LeadConvertResult result : results) {
            Assert.isTrue(result?.isSuccess(), 'Did not succeed'); 
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
        Dml dml = new MockDml()?.injectException();

        Test.startTest();
        try {
            dml?.doConvert(leadsToConvert);
            Assert.fail('Did not throw an error');
        } catch (Exception error) {
            // ...as expected...
            Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
            Assert.areEqual(0, MockDml.Converted?.getAll()?.size(), 'Wrong # of Converted leads'); 
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
        Dml dml = new MockDml()?.injectException()?.setAllOrNone(false);

        Test.startTest();
        List<Database.LeadConvertResult> results = dml?.doConvert(leadsToConvert);
        Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
        Test.stopTest();

        Assert.areEqual(leadsToConvert?.size(), results?.size(), 'Wrong # of results'); 
        Assert.areEqual(0, MockDml.Converted?.getAll()?.size(), 'Wrong # of Converted leads'); 
        for (Database.LeadConvertResult result : results) {
            Assert.isFalse(result?.isSuccess(), 'Should not have succeeded'); 
        }
    }

    // **** HELPER **** // 
    static final Integer TEST_SIZE = 200; 
}