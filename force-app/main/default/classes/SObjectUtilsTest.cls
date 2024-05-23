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

    @IsTest 
    static void shouldSetMultipleReadOnlyFields() {
        Map<String, Object> readOnlyFields = new Map<String, Object>{
            Account.CreatedDate.toString() => DateTime.now()?.addDays(-10),
            Account.SystemModStamp.toString() => DateTime.now()?.addDays(-1)
        };
        
        Test.startTest();
        Account account = (Account) SObjectUtils.mockReadOnlyFields(new Account(), readOnlyFields);
        Test.stopTest();

        for (String fieldName : readOnlyFields?.keySet()) {
            Object expected = readOnlyFields?.get(fieldName);
            Assert.areEqual(expected, account?.get(fieldName), 'Wrong read-only value for ' + fieldName);
        }
    }

    @IsTest 
    static void shouldmockReadOnlyFields() {
        DateTime expected = DateTime.now()?.addDays(-3); 

        Test.startTest();
        Account account = (Account) SObjectUtils.mockReadOnlyFields(new Account(), Account.CreatedDate, expected);
        Test.stopTest();

        Assert.areEqual(expected, account?.CreatedDate, 'Wrong read-only value');
    }

    @IsTest 
    static void shouldSetParentLookup() {
        Account account = new Account(Id = SObjectUtils.mockRecordId(Account.SObjectType));

        Test.startTest();
        Contact contact = (Contact) SObjectUtils.mockLookup(new Contact(), Contact.AccountId, account);
        Test.stopTest();

        Assert.areEqual(account?.Id, contact?.AccountId, 'Did not set lookup field');
        Assert.areEqual(account?.Id, contact?.Account?.Id, 'Did not set parent relationship');
    }

    @IsTest 
    static void shouldSetChildLookup() {
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 3; i++) {
            Contact contact = new Contact();
            contacts?.add(contact); 
        }

        Test.startTest();
        Account account = (Account) SObjectUtils.mockRelatedList(new Account(), Contact.AccountId, contacts);
        Test.stopTest();

        Assert.areEqual(contacts?.size(), account?.Contacts?.size(), 'Did not set child relationship');
    }

    @IsTest 
    static void shouldGetChildRelationshipFromLookupField() {
        SObjectField field = Contact.AccountId;

        Test.startTest();
        Schema.ChildRelationship relationship = SObjectUtils.getChildRelationshipFrom(field);
        Test.stopTest();

        Assert.areEqual(field, relationship?.getField(), 'Relationship does not point to ' + field);
    }

    @IsTest 
    static void shouldReturnNullChildRelationshipIfNotLookupField() {
        SObjectField field = Contact.CreatedDate;

        Test.startTest();
        Schema.ChildRelationship relationship = SObjectUtils.getChildRelationshipFrom(field);
        Test.stopTest();

        Assert.isNull(relationship, 'Non-lookup field returned a relationship anyways');
    }
}