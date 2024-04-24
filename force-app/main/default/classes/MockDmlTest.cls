@IsTest 
private class MockDmlTest {
    @IsTest 
    static void shouldMockLeadConvert() {
        Lead lead = new Lead(Id = SObjectUtils.generateMockId(Lead.SObjectType));
        Database.LeadConvert leadToConvert = new Database.LeadConvert();
        leadToConvert?.setLeadId(lead?.Id);

        Test.startTest();
        Database.LeadConvertResult result = new MockDml()?.doConvert(leadToConvert);
        Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'Mock DML did not succeed');
        // TODO: Add more asserts?
    }
}