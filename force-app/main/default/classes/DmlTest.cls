@SuppressWarnings('PMD.ApexDoc,PMD.CyclomaticComplexity')
@IsTest
private class DmlTest {
	// **** VARIABLES **** //
	private static final LeadStatus CONVERTED_STATUS;
	private static List<Database.DeleteResult> deleteCallbacksMade;
	private static List<Database.SaveResult> saveCallbacksMade;

	static {
		CONVERTED_STATUS = DmlTest.getConvertedStatus();
		deleteCallbacksMade = new List<Database.DeleteResult>();
		saveCallbacksMade = new List<Database.SaveResult>();
		// Custom metadata actually defined in the org should not interfere with this test:
		DatabaseLayer.Utils.MetadataSelector.settings = new List<DatabaseLayerSetting__mdt>{};
		// Initialize plugins
		DatabaseLayerSetting__mdt settings = DatabaseLayerTestUtils.initSettings();
		settings.DmlPreAndPostProcessor__c = DatabaseLayerTestUtils.SamplePlugin.class.getName();
		DatabaseLayer.Dml.initPlugins();
	}

	// **** TESTS **** //
	@IsTest
	static void shouldDoInsert() {
		Account account = DmlTest.initAccount();

		Test.startTest();
		Database.SaveResult result = DatabaseLayer.Dml.doInsert(account);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@Istest
	static void shouldDoInsertWithAccessLevel() {
		Account account = DmlTest.initAccount();

		Test.startTest();
		Database.SaveResult result = DatabaseLayer.Dml.doInsert(account, System.AccessLevel.SYSTEM_MODE);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoInsertWithAllOrNone() {
		Account account = DmlTest.initAccount();

		Test.startTest();
		Database.SaveResult result = DatabaseLayer.Dml.doInsert(account, true);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoInsertWithDmlOptions() {
		Account account = DmlTest.initAccount();
		Database.DmlOptions options = new Database.DmlOptions();
		options.OptAllOrNone = true;

		Test.startTest();
		Database.SaveResult result = DatabaseLayer.Dml.doInsert(account, options);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoInsertWithAllOrNoneAndAccessLevel() {
		Account account = DmlTest.initAccount();

		Test.startTest();
		Database.SaveResult result = DatabaseLayer.Dml.doInsert(account, true, System.AccessLevel.SYSTEM_MODE);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoInsertWithDmlOptionsAndAccessLevel() {
		Account account = DmlTest.initAccount();
		Database.DmlOptions options = new Database.DmlOptions();
		options.OptAllOrNone = true;

		Test.startTest();
		Database.SaveResult result = DatabaseLayer.Dml.doInsert(account, options, System.AccessLevel.SYSTEM_MODE);
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
		Database.Error error = result?.getErrors()?.get(0) ?? null;
		System.StatusCode expected = System.StatusCode.CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY;
		Assert.areEqual(expected, error?.getStatusCode(), 'Wrong Error Code');
	}

	@IsTest
	static void shouldDoInsertAsyncWithAccessLevel() {
		Account account = DmlTest.initAccount();

		Test.startTest();
		Database.SaveResult result = DatabaseLayer.Dml.doInsertAsync(account, System.AccessLevel.SYSTEM_MODE);
		Test.stopTest();

		// Note: This should fail, since Account isn't an external object.
		// This doesn't seem to happen for updateAsync() or deleteAsync() - not sure why.
		// Without defining a custom external object, not possible to test the happy path for this
		Assert.areEqual(false, result?.isSuccess(), 'InsertAsync succeeded on non-external object');
		Database.Error error = result?.getErrors()?.get(0) ?? null;
		System.StatusCode expected = System.StatusCode.CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY;
		Assert.areEqual(expected, error?.getStatusCode(), 'Wrong Error Code');
	}

	@IsTest
	static void shouldDoInsertAsyncWithCallback() {
		Account account = DmlTest.initAccount();
		DataSource.AsyncSaveCallback callback = new DmlTest.SaveCallback();

		Test.startTest();
		Database.SaveResult result = DatabaseLayer.Dml.doInsertAsync(account, callback);
		Test.stopTest();

		// Note: This should fail, since Account isn't an external object.
		// This doesn't seem to happen for updateAsync() or deleteAsync() - not sure why.
		// Without defining a custom external object, not possible to test the happy path for this
		Assert.areEqual(false, result?.isSuccess(), 'InsertAsync succeeded on non-external object');
		Database.Error error = result?.getErrors()?.get(0) ?? null;
		System.StatusCode expected = System.StatusCode.CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY;
		Assert.areEqual(expected, error?.getStatusCode(), 'Wrong Error Code');
	}

	@IsTest
	static void shouldDoInsertAsyncWithCallbackAndAccessLevel() {
		Account account = DmlTest.initAccount();
		DataSource.AsyncSaveCallback callback = new DmlTest.SaveCallback();

		Test.startTest();
		Database.SaveResult result = DatabaseLayer.Dml.doInsertAsync(account, callback, System.AccessLevel.SYSTEM_MODE);
		Test.stopTest();

		// Note: This should fail, since Account isn't an external object.
		// This doesn't seem to happen for updateAsync() or deleteAsync() - not sure why.
		// Without defining a custom external object, not possible to test the happy path for this
		Assert.areEqual(false, result?.isSuccess(), 'InsertAsync succeeded on non-external object');
		Database.Error error = result?.getErrors()?.get(0) ?? null;
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
	static void shouldInsertImmediateWithAccessLevel() {
		Account account = DmlTest.initAccount();

		Test.startTest();
		Database.SaveResult result = DatabaseLayer.Dml.doInsertImmediate(account, System.AccessLevel.SYSTEM_MODE);
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
	static void shouldDoUpdateWithAccessLevel() {
		Account account = DmlTest.initAccount();
		insert account;

		Test.startTest();
		Database.SaveResult result = DatabaseLayer.Dml.doUpdate(account, System.AccessLevel.SYSTEM_MODE);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoUpdateWithAllOrNone() {
		Account account = DmlTest.initAccount();
		insert account;

		Test.startTest();
		Database.SaveResult result = DatabaseLayer.Dml.doUpdate(account, true);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoUpdateWithDmlOptions() {
		Account account = DmlTest.initAccount();
		insert account;
		Database.DmlOptions options = new Database.DmlOptions();
		options.OptAllOrNone = true;

		Test.startTest();
		Database.SaveResult result = DatabaseLayer.Dml.doUpdate(account, options);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoUpdateWithAllOrNoneAndAccessLevel() {
		Account account = DmlTest.initAccount();
		insert account;

		Test.startTest();
		Database.SaveResult result = DatabaseLayer.Dml.doUpdate(account, true, System.AccessLevel.SYSTEM_MODE);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoUpdateWithDmlOptionsAndAccessLevel() {
		Account account = DmlTest.initAccount();
		insert account;
		Database.DmlOptions options = new Database.DmlOptions();
		options.OptAllOrNone = true;

		Test.startTest();
		Database.SaveResult result = DatabaseLayer.Dml.doUpdate(account, options, System.AccessLevel.SYSTEM_MODE);
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
	static void shouldDoUpdateAsyncWithAccessLevel() {
		Account account = DmlTest.initAccount();
		insert account;

		Test.startTest();
		Database.SaveResult result = DatabaseLayer.Dml.doUpdateAsync(account, System.AccessLevel.SYSTEM_MODE);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoUpdateAsyncWithCallback() {
		Account account = DmlTest.initAccount();
		insert account;
		DataSource.AsyncSaveCallback callback = new DmlTest.SaveCallback();

		Test.startTest();
		Database.SaveResult result = DatabaseLayer.Dml.doUpdateAsync(account, callback);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoUpdateAsyncWithCallbackAndAccessLevel() {
		Account account = DmlTest.initAccount();
		insert account;
		DataSource.AsyncSaveCallback callback = new DmlTest.SaveCallback();

		Test.startTest();
		Database.SaveResult result = DatabaseLayer.Dml.doUpdateAsync(account, callback, System.AccessLevel.SYSTEM_MODE);
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
	static void shouldDoUpdateImmediateWithAccessLevel() {
		Account account = DmlTest.initAccount();
		insert account;

		Test.startTest();
		Database.SaveResult result = DatabaseLayer.Dml.doUpdateImmediate(account, System.AccessLevel.SYSTEM_MODE);
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
	static void shouldDoUpsertWithAccessLevel() {
		Account account = DmlTest.initAccount();

		Test.startTest();
		Database.UpsertResult result = DatabaseLayer.Dml.doUpsert(account, System.AccessLevel.SYSTEM_MODE);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoUpsertWithAllOrNone() {
		Account account = DmlTest.initAccount();

		Test.startTest();
		Database.UpsertResult result = DatabaseLayer.Dml.doUpsert(account, true);
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
	static void shouldDoUpsertWithAllOrNoneAndAccessLevel() {
		Account account = DmlTest.initAccount();

		Test.startTest();
		Database.UpsertResult result = DatabaseLayer.Dml.doUpsert(account, true, System.AccessLevel.SYSTEM_MODE);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoUpsertWithExternalIdFieldAndAccessLevel() {
		Account acc = DmlTest.initAccount();
		SObjectField externalIdField = Account.Id;

		Test.startTest();
		Database.UpsertResult result = DatabaseLayer.Dml.doUpsert(acc, externalIdField, System.AccessLevel.SYSTEM_MODE);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoUpsertWithExternalIdFieldAndAllOrNone() {
		Account acc = DmlTest.initAccount();
		SObjectField externalIdField = Account.Id;

		Test.startTest();
		Database.UpsertResult result = DatabaseLayer.Dml.doUpsert(acc, externalIdField, true);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoUpsertWithExternalIdFieldAndAllOrNoneAndAccessLevel() {
		Account acc = DmlTest.initAccount();
		SObjectField externalIdField = Account.Id;

		Test.startTest();
		Database.UpsertResult result = DatabaseLayer.Dml.doUpsert(
			acc,
			externalIdField,
			true,
			System.AccessLevel.SYSTEM_MODE
		);
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
	static void shouldDoDeleteWithAccessLevel() {
		Account account = DmlTest.initAccount();
		insert account;

		Test.startTest();
		Database.DeleteResult result = DatabaseLayer.Dml.doDelete(account, System.AccessLevel.SYSTEM_MODE);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoDeleteWithAllOrNone() {
		Account account = DmlTest.initAccount();
		insert account;

		Test.startTest();
		Database.DeleteResult result = DatabaseLayer.Dml.doDelete(account, true);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoDeleteWithAllOrNoneAndAccessLevel() {
		Account account = DmlTest.initAccount();
		insert account;

		Test.startTest();
		Database.DeleteResult result = DatabaseLayer.Dml.doDelete(account, true, System.AccessLevel.SYSTEM_MODE);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoDeleteWithId() {
		Account account = DmlTest.initAccount();
		insert account;

		Test.startTest();
		Database.DeleteResult result = DatabaseLayer.Dml.doDelete(account?.Id);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoDeleteWithIdAndAccessLevel() {
		Account account = DmlTest.initAccount();
		insert account;

		Test.startTest();
		Database.DeleteResult result = DatabaseLayer.Dml.doDelete(account?.Id, System.AccessLevel.SYSTEM_MODE);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoDeleteWithIdAndAllOrNone() {
		Account account = DmlTest.initAccount();
		insert account;

		Test.startTest();
		Database.DeleteResult result = DatabaseLayer.Dml.doDelete(account?.Id, true);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoDeleteWithIdAndAllOrNoneAndAccessLevel() {
		Account account = DmlTest.initAccount();
		insert account;

		Test.startTest();
		Database.DeleteResult result = DatabaseLayer.Dml.doDelete(account?.Id, true, System.AccessLevel.SYSTEM_MODE);
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
	static void shouldDoDeleteAsyncWithAccessLevel() {
		Account account = DmlTest.initAccount();
		insert account;

		Test.startTest();
		Database.DeleteResult result = DatabaseLayer.Dml.doDeleteAsync(account, System.AccessLevel.SYSTEM_MODE);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoDeleteAsyncWithCallback() {
		Account account = DmlTest.initAccount();
		insert account;
		DataSource.AsyncDeleteCallback callback = new DmlTest.DeleteCallback();

		Test.startTest();
		Database.DeleteResult result = DatabaseLayer.Dml.doDeleteAsync(account, callback);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoDeleteAsyncWithCallbackAndAccessLevel() {
		Account account = DmlTest.initAccount();
		insert account;
		DataSource.AsyncDeleteCallback callback = new DmlTest.DeleteCallback();

		Test.startTest();
		Database.DeleteResult result = DatabaseLayer.Dml.doDeleteAsync(
			account,
			callback,
			System.AccessLevel.SYSTEM_MODE
		);
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
	static void shouldDoDeleteImmediateWithAccessLevel() {
		Account account = DmlTest.initAccount();
		insert account;

		Test.startTest();
		Database.DeleteResult result = DatabaseLayer.Dml.doDeleteImmediate(account, System.AccessLevel.SYSTEM_MODE);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldEmptyRecycleBin() {
		Account account = DmlTest.initAccount();
		insert account;
		delete account;

		Test.startTest();
		Database.EmptyRecycleBinResult result = DatabaseLayer.Dml.emptyRecycleBin(account);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldEmptyRecycleBinWithId() {
		Account account = DmlTest.initAccount();
		insert account;
		delete account;

		Test.startTest();
		Database.EmptyRecycleBinResult result = DatabaseLayer.Dml.emptyRecycleBin(account?.Id);
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
	static void shouldDoUndeleteWithAccessLevel() {
		Account account = DmlTest.initAccount();
		insert account;
		delete account;

		Test.startTest();
		Database.UndeleteResult result = DatabaseLayer.Dml.doUndelete(account, System.AccessLevel.SYSTEM_MODE);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoUndeleteWithAllOrNone() {
		Account account = DmlTest.initAccount();
		insert account;
		delete account;

		Test.startTest();
		Database.UndeleteResult result = DatabaseLayer.Dml.doUndelete(account, true);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoUndeleteWithAllOrNoneAndAccessLevel() {
		Account account = DmlTest.initAccount();
		insert account;
		delete account;

		Test.startTest();
		Database.UndeleteResult result = DatabaseLayer.Dml.doUndelete(account, true, System.AccessLevel.SYSTEM_MODE);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoUndeleteWithId() {
		Account account = DmlTest.initAccount();
		insert account;
		delete account;

		Test.startTest();
		Database.UndeleteResult result = DatabaseLayer.Dml.doUndelete(account?.Id);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoUndeleteWithIdAndAccessLevel() {
		Account account = DmlTest.initAccount();
		insert account;
		delete account;

		Test.startTest();
		Database.UndeleteResult result = DatabaseLayer.Dml.doUndelete(account?.Id, System.AccessLevel.SYSTEM_MODE);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoUndeleteWithIdAndAllOrNone() {
		Account account = DmlTest.initAccount();
		insert account;
		delete account;

		Test.startTest();
		Database.UndeleteResult result = DatabaseLayer.Dml.doUndelete(account?.Id, true);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoUndeleteWithIdAndAllOrNoneAndAccessLevel() {
		Account account = DmlTest.initAccount();
		insert account;
		delete account;

		Test.startTest();
		Database.UndeleteResult result = DatabaseLayer.Dml.doUndelete(
			account?.Id,
			true,
			System.AccessLevel.SYSTEM_MODE
		);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
	}

	@IsTest
	static void shouldDoPublish() {
		BatchApexErrorEvent event = new BatchApexErrorEvent();

		Test.startTest();
		Database.SaveResult result = DatabaseLayer.Dml.doPublish(event);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'Publish failed');
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

	@IsTest
	static void shouldProcessEmptyDeleteCallback() {
		// Purely for code coverage -- run the default Async DML Callbacks
		try {
			Test.startTest();
			new Dml.EmptyDeleteCallback()?.processDelete(null);
			new Dml.EmptySaveCallback()?.processSave(null);
			Test.stopTest();
		} catch (Exception error) {
			Assert.fail('Failed to run Empty Callbacks');
		}
	}

	@IsTest
	static void shouldHandleSavepoints() {
		Account account = DmlTest.initAccount();

		Test.startTest();
		try {
			// Set a savepoint:
			System.Savepoint savepoint = DatabaseLayer.Dml.setSavepoint();
			Assert.isNotNull(savepoint, 'Did not set a savepoint');
			// Perform some DML:
			insert account;
			// Roll back that DML & release the savepoint:
			DatabaseLayer.Dml.rollback(savepoint);
			DatabaseLayer.Dml.releaseSavepoint(savepoint);
		} catch (Exception error) {
			Assert.fail(error?.toString());
		}
		Test.stopTest();

		Assert.areEqual(0, [SELECT COUNT() FROM Account], 'DML operation was not rolled back');
	}

	@IsTest
	static void shouldRunPreAndPostProcessorPluginLogic() {
		DatabaseLayerSetting__mdt settings = DatabaseLayerTestUtils.initSettings();
		settings.DmlPreAndPostProcessor__c = DatabaseLayerTestUtils.SamplePlugin.class.getName();
		// Re-initialize the plugins, now that the field has been set:
		DatabaseLayer.Dml.initPlugins();
		Account account = DmlTest.initAccount();

		Test.startTest();
		Database.SaveResult result = DatabaseLayer.Dml.doInsert(account);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
		Assert.areEqual(1, DatabaseLayerTestUtils.DmlPluginSpy?.numPreCalls, 'Wrong number of pre-dml plugin calls');
		Assert.areEqual(
			0,
			DatabaseLayerTestUtils.DmlPluginSpy?.numErrorCalls,
			'Wrong number of dml error plugin calls'
		);
		Assert.areEqual(1, DatabaseLayerTestUtils.DmlPluginSpy?.numPostCalls, 'Wrong number of post-dml plugin calls');
	}

	@IsTest
	static void shouldRunPluginErrorLogic() {
		DatabaseLayerSetting__mdt settings = DatabaseLayerTestUtils.initSettings();
		settings.DmlPreAndPostProcessor__c = DatabaseLayerTestUtils.SamplePlugin.class.getName();
		// Re-initialize the plugins, now that the field has been set:
		DatabaseLayer.Dml.initPlugins();
		Account account = DmlTest.initAccount();

		Test.startTest();
		try {
			// Updates will fail, since there isn't an Id set:
			DatabaseLayer.Dml.doUpdate(account);
			Assert.fail('Did not throw a System.DmlException');
		} catch (System.DmlException error) {
			// As expected...
		}
		Test.stopTest();

		Assert.areEqual(1, DatabaseLayerTestUtils.DmlPluginSpy?.numPreCalls, 'Wrong number of pre-dml plugin calls');
		Assert.areEqual(
			1,
			DatabaseLayerTestUtils.DmlPluginSpy?.numErrorCalls,
			'Wrong number of dml error plugin calls'
		);
		Assert.areEqual(0, DatabaseLayerTestUtils.DmlPluginSpy?.numPostCalls, 'Wrong number of post-dml plugin calls');
	}

	@IsTest
	static void shouldNotRunProcessorLogicIfInvalidApexClassDefined() {
		DatabaseLayerSetting__mdt settings = DatabaseLayerTestUtils.initSettings();
		settings.DmlPreAndPostProcessor__c = 'an obviously invalid apex class name';
		// Re-initialize the plugins, now that the field has been set:
		DatabaseLayer.Dml.initPlugins();
		Account account = DmlTest.initAccount();

		Test.startTest();
		Database.SaveResult result = DatabaseLayer.Dml.doInsert(account);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
		Assert.areEqual(0, DatabaseLayerTestUtils.DmlPluginSpy?.numPreCalls, 'Wrong number of pre-dml plugin calls');
		Assert.areEqual(
			0,
			DatabaseLayerTestUtils.DmlPluginSpy?.numErrorCalls,
			'Wrong number of dml error plugin calls'
		);
		Assert.areEqual(0, DatabaseLayerTestUtils.DmlPluginSpy?.numPostCalls, 'Wrong number of post-dml plugin calls');
	}

	@IsTest
	static void shouldNotRunProcessorLogicIfNoValueDefined() {
		DatabaseLayerSetting__mdt settings = DatabaseLayerTestUtils.initSettings();
		settings.DmlPreAndPostProcessor__c = null;
		DatabaseLayer.Dml.initPlugins();
		Account account = DmlTest.initAccount();

		Test.startTest();
		Database.SaveResult result = DatabaseLayer.Dml.doInsert(account);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
		Assert.areEqual(0, DatabaseLayerTestUtils.DmlPluginSpy?.numPreCalls, 'Wrong number of pre-dml plugin calls');
		Assert.areEqual(
			0,
			DatabaseLayerTestUtils.DmlPluginSpy?.numErrorCalls,
			'Wrong number of dml error plugin calls'
		);
		Assert.areEqual(0, DatabaseLayerTestUtils.DmlPluginSpy?.numPostCalls, 'Wrong number of post-dml plugin calls');
	}

	@IsTest
	static void shouldNotRunProcessorLogicIfNoSettingsDefined() {
		DatabaseLayer.Utils.MetadataSelector.settings = new List<DatabaseLayerSetting__mdt>{};
		DatabaseLayer.Dml.initPlugins();
		Account account = DmlTest.initAccount();

		Test.startTest();
		Database.SaveResult result = DatabaseLayer.Dml.doInsert(account);
		Test.stopTest();

		Assert.areEqual(true, result?.isSuccess(), 'DML failed: ' + result?.getErrors());
		Assert.areEqual(0, DatabaseLayerTestUtils.DmlPluginSpy?.numPreCalls, 'Wrong number of pre-dml plugin calls');
		Assert.areEqual(
			0,
			DatabaseLayerTestUtils.DmlPluginSpy?.numErrorCalls,
			'Wrong number of dml error plugin calls'
		);
		Assert.areEqual(0, DatabaseLayerTestUtils.DmlPluginSpy?.numPostCalls, 'Wrong number of post-dml plugin calls');
	}

	@IsTest
	static void shouldSerializeDmlRequestForRecords() {
		// The Dml.Request may be used in plugins for a variety of purposes, including logging
		// For this reason, we should make sure the request is JSON-serializable,
		// despite containing several fields that are not typically allowed in JSON
		Lead lead = DmlTest.initLead();
		List<Lead> leads = new List<Lead>{ lead };
		Dml.Request request = DatabaseLayer.Dml.initRequest(Dml.Operation.DO_INSERT, leads);

		Test.startTest();
		String requestJson = JSON.serialize(request);
		Test.stopTest();

		Assert.isNotNull(requestJson, 'Is not JSON serializable');
	}

	@IsTest
	static void shouldSerializeDmlRequestForLeadConverts() {
		// The Dml.Request may be used in plugins for a variety of purposes, including logging
		// For this reason, we should make sure the request is JSON-serializable,
		// despite containing several fields that are not typically allowed in JSON
		Lead lead = (Lead) new MockRecord(Lead.SObjectType)?.withId()?.toSObject();
		Database.LeadConvert leadToConvert = DmlTest.initLeadConvert(lead);
		List<Database.LeadConvert> leadsToConvert = new List<Database.LeadConvert>{ leadToConvert };
		Dml.Request request = DatabaseLayer.Dml.initRequest(Dml.Operation.DO_CONVERT, leadsToConvert);

		Test.startTest();
		String requestJson = JSON.serialize(request);
		Test.stopTest();

		Assert.isNotNull(requestJson, 'Is not JSON serializable');
	}

	// **** HELPER **** //
	private static LeadStatus getConvertedStatus() {
		return [SELECT ApiName FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1] ?? null;
	}

	private static Account initAccount() {
		return new Account(Name = 'Robinson Industries');
	}

	private static List<Account> initAccountList() {
		Account account = DmlTest.initAccount();
		return new List<Account>{ account };
	}

	private static Lead initLead() {
		return new Lead(Company = 'Tharsis Inc.', FirstName = 'John', LastName = 'Doe');
	}

	private static Database.LeadConvert initLeadConvert(Lead lead) {
		Database.LeadConvert leadToConvert = new Database.LeadConvert();
		leadToConvert?.setLeadId(lead?.Id);
		leadToConvert?.setConvertedStatus(CONVERTED_STATUS?.ApiName);
		return leadToConvert;
	}

	private static DatabaseLayerSetting__mdt initSettings() {
		DatabaseLayerSetting__mdt settings = new DatabaseLayerSetting__mdt();
		DatabaseLayer.Utils.MetadataSelector.settings?.add(settings);
		return settings;
	}

	// **** INNER **** //
	private class DeleteCallback extends DataSource.AsyncDeleteCallback {
		public override void processDelete(Database.DeleteResult result) {
			DmlTest.deleteCallbacksMade?.add(result);
		}
	}

	private class SaveCallback extends DataSource.AsyncSaveCallback {
		public override void processSave(Database.SaveResult result) {
			DmlTest.saveCallbacksMade?.add(result);
		}
	}
}
