@IsTest
private class DmlTest {
	// **** CONSTANTS **** //
	private static final LeadStatus CONVERTED_STATUS = DmlTest.getConvertedStatus();

	// **** TESTS **** //
	@IsTest
	static void shouldDoInsert() {
		Account account = DmlTest.initAccount();

		Test.startTest();
		Database.SaveResult result = DatabaseLayer.Dml.doInsert(account);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoInsertAsync() {
		Account account = DmlTest.initAccount();

		Test.startTest();
		Database.SaveResult result = DatabaseLayer.Dml.doInsertAsync(account);
		Test.stopTest();

		// Note: This should fail, since Account isn't an external object.
		// This doesn't seem to happen for updateAsync() or deleteAsync() - not sure why.
		// Without defining a custom external object, not possible to test the happy path for this
		Assert.areEqual(false, result?.isSuccess(), 'InsertAsync succeeded on non-external object');
		Database.Error error = result?.getErrors()[0] ?? null;
		System.StatusCode expected = System.StatusCode.CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY;
		Assert.areEqual(expected, error?.getStatusCode(), 'Wrong Error Code');
	}

	@IsTest
	static void shouldDoInsertImmediate() {
		Account account = DmlTest.initAccount();

		Test.startTest();
		Database.SaveResult result = DatabaseLayer.Dml.doInsertImmediate(account);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoUpdate() {
		Account account = DmlTest.initAccount();
		insert account;

		Test.startTest();
		Database.SaveResult result = DatabaseLayer.Dml.doUpdate(account);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoUpdateAsync() {
		Account account = DmlTest.initAccount();
		insert account;

		Test.startTest();
		Database.SaveResult result = DatabaseLayer.Dml.doUpdateAsync(account);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoUpdateImmediate() {
		Account account = DmlTest.initAccount();
		insert account;

		Test.startTest();
		Database.SaveResult result = DatabaseLayer.Dml.doUpdateImmediate(account);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoUpsert() {
		Account account = DmlTest.initAccount();

		Test.startTest();
		Database.UpsertResult result = DatabaseLayer.Dml.doUpsert(account);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoUpsertWithExternalIdField() {
		Account acc = DmlTest.initAccount();
		SObjectField field = Account.Id;

		Test.startTest();
		Database.UpsertResult result = DatabaseLayer.Dml?.doUpsert(acc, field);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoDelete() {
		Account account = DmlTest.initAccount();
		insert account;

		Test.startTest();
		Database.DeleteResult result = DatabaseLayer.Dml.doDelete(account);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoDeleteAsync() {
		Account account = DmlTest.initAccount();
		insert account;

		Test.startTest();
		Database.DeleteResult result = DatabaseLayer.Dml.doDeleteAsync(account);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoDeleteImmediate() {
		Account account = DmlTest.initAccount();
		insert account;

		Test.startTest();
		Database.DeleteResult result = DatabaseLayer.Dml.doDeleteImmediate(account);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoHardDelete() {
		Account account = DmlTest.initAccount();
		insert account;
		delete account;

		Test.startTest();
		Database.EmptyRecycleBinResult result = DatabaseLayer.Dml.emptyRecycleBin(account);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoUndelete() {
		Account account = DmlTest.initAccount();
		insert account;
		delete account;

		Test.startTest();
		Database.UndeleteResult result = DatabaseLayer.Dml.doUndelete(account);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoPublish() {
		BatchApexErrorEvent event = new BatchApexErrorEvent();

		Test.startTest();
		Database.SaveResult result = DatabaseLayer.Dml.doPublish(event);
		Test.stopTest();

		// Note: Standard platform events that are available in all Salesforce orgs
		// (like BatchApexErrorEvent) can't be inserted by users; rather, generated by the system.
		// Without defining a custom platform event, not possible to test the happy path for this
		Assert.areEqual(false, result?.isSuccess(), 'Publish succeeded on standard platform event');
		Database.Error error = result?.getErrors()[0] ?? null;
		System.StatusCode expected = System.StatusCode.CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY;
		Assert.areEqual(expected, error?.getStatusCode(), 'Wrong Error Code');
	}

	@IsTest
	static void shouldDoConvert() {
		Lead lead = DmlTest.initLead();
		insert lead;
		Database.LeadConvert leadToConvert = DmlTest.initLeadConvert(lead);

		Test.startTest();
		Database.LeadConvertResult result = DatabaseLayer.Dml.doConvert(leadToConvert);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'Did not succeed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoConvertWithAllOrNone() {
		Lead lead = DmlTest.initLead();
		insert lead;
		Database.LeadConvert leadToConvert = DmlTest.initLeadConvert(lead);

		Test.startTest();
		Database.LeadConvertResult result = DatabaseLayer.Dml.doConvert(leadToConvert, true);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'Did not succeed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoConvertWithDmlOptions() {
		Lead lead = DmlTest.initLead();
		insert lead;
		Database.LeadConvert leadToConvert = DmlTest.initLeadConvert(lead);
		Database.DmlOptions options = new Database.DmlOptions();
		options.OptAllOrNone = true;

		Test.startTest();
		Database.LeadConvertResult result = DatabaseLayer.Dml.doConvert(leadToConvert, options);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'Did not succeed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoConvertWithAccessLevel() {
		Lead lead = DmlTest.initLead();
		insert lead;
		Database.LeadConvert leadToConvert = DmlTest.initLeadConvert(lead);

		Test.startTest();
		Database.LeadConvertResult result = DatabaseLayer.Dml.doConvert(leadToConvert, System.AccessLevel.SYSTEM_MODE);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'Did not succeed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoConvertWithDmlOptionsAndAccessLevel() {
		Lead lead = DmlTest.initLead();
		insert lead;
		Database.LeadConvert leadToConvert = DmlTest.initLeadConvert(lead);
		Database.DmlOptions options = new Database.DmlOptions();
		options.OptAllOrNone = true;

		Test.startTest();
		Database.LeadConvertResult result = DatabaseLayer.Dml.doConvert(
			leadToConvert,
			options,
			System.AccessLevel.SYSTEM_MODE
		);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'Did not succeed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoConvertWithAllOrNoneAndAccessLevel() {
		Lead lead = DmlTest.initLead();
		insert lead;
		Database.LeadConvert leadToConvert = DmlTest.initLeadConvert(lead);

		Test.startTest();
		Database.LeadConvertResult result = DatabaseLayer.Dml.doConvert(
			leadToConvert,
			true,
			System.AccessLevel.SYSTEM_MODE
		);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'Did not succeed: ' + result?.getErrors());
	}

	// **** HELPER **** //
	static List<Database.DeleteResult> deleteCallbacksMade = new List<Database.DeleteResult>();
	static List<Database.SaveResult> saveCallbacksMade = new List<Database.SaveResult>();

	static LeadStatus getConvertedStatus() {
		return [SELECT ApiName FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1] ?? null;
	}

	static Account initAccount() {
		return new Account(Name = 'Robinson Industries');
	}

	static List<Account> initAccountList() {
		Account account = DmlTest.initAccount();
		return new List<Account>{ account };
	}

	static Lead initLead() {
		return new Lead(Company = 'Tharsis Inc.', FirstName = 'John', LastName = 'Doe');
	}

	static Database.LeadConvert initLeadConvert(Lead lead) {
		Database.LeadConvert leadToConvert = new Database.LeadConvert();
		leadToConvert?.setLeadId(lead?.Id);
		leadToConvert?.setConvertedStatus(CONVERTED_STATUS?.ApiName);
		return leadToConvert;
	}

	private class TestDeleteCallback extends DataSource.AsyncDeleteCallback {
		public override void processDelete(Database.DeleteResult result) {
			DmlTest.deleteCallbacksMade?.add(result);
		}
	}

	private class TestSaveCallback extends DataSource.AsyncSaveCallback {
		public override void processSave(Database.SaveResult result) {
			DmlTest.saveCallbacksMade?.add(result);
		}
	}
}
