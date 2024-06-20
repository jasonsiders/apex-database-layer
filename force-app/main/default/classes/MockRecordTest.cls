@IsTest 
private class MockRecordTest {
    @IsTest 
    static void shouldMockNewRecords() {
        String accountName = 'John Doe Enterprises';
        DateTime now = DateTime.now();
        Contact mockContact = (Contact) new MockRecord(Contact.SObjectType)?.toSObject();
        MockRecord accountMock = new MockRecord(Account.SObjectType)
            ?.setField(Account.Name, accountName)
            ?.setField(Account.CreatedDate, now)
            ?.setLookup(Account.OwnerId, new User(Id = UserInfo.getUserId()))
            ?.setRelatedList(Contact.AccountId, new List<Contact>{ mockContact })
            ?.withId();
        
        Test.startTest();
        Account mockAccount = (Account) accountMock?.toSObject();
        Test.stopTest();

        Assert.areEqual(accountName, mockAccount?.Name, 'Did not set ordinary field');
        Assert.areEqual(now, mockAccount?.CreatedDate, 'Did not set read-only field'); 
        Assert.areEqual(UserInfo.getUserId(), mockAccount?.OwnerId, 'Did not set lookup field');
        Assert.areNotEqual(null, mockAccount.Owner, 'Did not set lookup relationship');
        Assert.areEqual(1, mockAccount?.Contacts?.size(), 'Did not set related list');
    }

    @IsTest 
    static void shouldMockExistingRecord() {
        Account existingAccount = new Account(
            BillingCountry = 'US',
            Name = 'John Doe Enterprises'
        );

        Test.startTest();
        Account mockedAccount = (Account) new MockRecord(existingAccount)
            ?.setField(Account.BillingCountry, 'UK')
            ?.withId()
            ?.toSObject();
        Test.stopTest();

        Assert.areEqual(existingAccount?.Name, mockedAccount?.Name, 'Did not retain existing value');
        Assert.areEqual('UK', mockedAccount?.BillingCountry, 'Did not overwrite existing value');
        Assert.areNotEqual(null, mockedAccount?.Id, 'Did not set Id');
    }
}