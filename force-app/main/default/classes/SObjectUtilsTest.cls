@IsTest
private class SObjectUtilsTest {
    @IsTest 
    static void shouldMockRecordIds() {
        Set<Id> mockIds = new Set<Id>();
        Integer numIterations = 200; 
        SObjectType objectType = Account.SObjectType;

        Test.startTest();
        for (Integer i = 0; i < numIterations; i++) {
            Id mockId = SObjectUtils.mockRecordId(objectType);
            Assert.isNotNull(mockId, 'Did not return Id');
            Assert.areEqual(objectType, mockId?.getSObjectType(), 'Wrong SObjectType');
            Assert.isTrue(mockId?.toString()?.endsWith(i?.toString()), 'Unexpected Id suffix');
            mockIds?.add(mockId);
        }
        Test.stopTest();

        Assert.areEqual(numIterations, mockIds?.size(), 'Wrong # of unique Ids');
    }

    @IsTest
    static void shouldMockPlatformEventIds() {
        Set<Id> mockIds = new Set<Id>();
        Integer numIterations = 200; 
        SObjectType objectType = BatchApexErrorEvent.SObjectType;

        Test.startTest();
        for (Integer i = 0; i < numIterations; i++) {
            Id mockId = SObjectUtils.mockPlatformEventId(objectType);
            Assert.isNotNull(mockId, 'Did not return Id');
            Assert.areEqual(objectType, mockId?.getSObjectType(), 'Wrong SObjectType');
            mockIds?.add(mockId);
        }
        Test.stopTest();

        Assert.areEqual(1, mockIds?.size(), 'Wrong # of unique Ids');
    }
}