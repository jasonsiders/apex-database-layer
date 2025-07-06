@SuppressWarnings('PMD.ApexDoc')
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
		Account existingAccount = new Account(BillingCountry = 'US', Name = 'John Doe Enterprises');

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

	@IsTest
	static void shouldGetValuesFromMockRecord() {
		String accountName = 'John Doe Enterprises';
		DateTime now = DateTime.now();
		Contact contact = (Contact) new MockRecord(Contact.SObjectType)?.withId()?.toSObject();
		MockRecord accountMock = new MockRecord(Account.SObjectType)
			?.setField(Account.Name, accountName)
			?.setField(Account.CreatedDate, now)
			?.setLookup(Account.OwnerId, new User(Id = UserInfo.getUserId()))
			?.setRelatedList(Schema.Contact.AccountId, new List<Contact>{ contact })
			?.withId();

		Test.startTest();
		Assert.areEqual(accountName, accountMock?.get(Account.Name), 'Wrong Name value');
		User owner = (User) accountMock?.getLookup(Account.OwnerId);
		Assert.areEqual(UserInfo.getUserId(), owner?.Id, 'Wrong OwnerId value');
		List<Contact> contacts = accountMock?.getRelatedList(Schema.Contact.AccountId);
		Assert.areEqual(1, contacts?.size(), 'Wrong # of Contacts');
		Assert.areEqual(contact?.Id, contacts?.get(0)?.Id, 'Wrong Contact Id');
	}

	@IsTest
	static void shouldAddToExistingRelatedList() {
		Contact contact1 = (Contact) new MockRecord(Contact.SObjectType)?.withId()?.toSObject();
		Contact contact2 = (Contact) new MockRecord(Contact.SObjectType)?.withId()?.toSObject();
		MockRecord accountMock = new MockRecord(Account.SObjectType)
			?.setRelatedList(Contact.AccountId, new List<Contact>{ contact1 })
			?.withId();

		Test.startTest();
		accountMock?.addToRelatedList(Contact.AccountId, contact2);
		Test.stopTest();

		List<Contact> contacts = accountMock?.getRelatedList(Contact.AccountId);
		Map<Id, Contact> contactMap = new Map<Id, Contact>(contacts);
		Assert.areEqual(2, contactMap?.size(), 'Wrong # of Contacts');
		Assert.areEqual(true, contactMap?.containsKey(contact2?.Id), 'Did not add Contact to related list');
	}

	@IsTest
	static void shouldAddMockAndRealRecordsToRelatedList() {
		MockRecord mockContact = new MockRecord(Contact.SObjectType)?.withId();
		Contact realContact = (Contact) new MockRecord(Contact.SObjectType)?.withId()?.toSObject();

		Test.startTest();
		Account account = (Account) new MockRecord(Account.SObjectType)
			?.addToRelatedList(Contact.AccountId, mockContact)
			?.addToRelatedList(Contact.AccountId, realContact)
			?.withId()
			?.toSObject();
		Test.stopTest();

		Map<Id, Contact> contacts = new Map<Id, Contact>(account?.Contacts);
		Assert.areEqual(2, contacts?.size(), 'Wrong # of Contacts');
		Assert.isTrue(contacts?.containsKey(mockContact?.Id), 'Did not add mock Contact to related list');
		Assert.isTrue(contacts?.containsKey(realContact?.Id), 'Did not add real Contact to related list');
	}
}
