@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs,PMD.CyclomaticComplexity')
@IsTest
private class MockDmlTest {
	// **** VARIABLES **** //
	private static final Integer TEST_SIZE;

	static {
		TEST_SIZE = 20;
		// Custom metadata actually defined in the org should not interfere with this test:
		DatabaseLayer.Utils.MetadataSelector.settings = new List<DatabaseLayerSetting__mdt>{};
		// Use Mock DML:
		DatabaseLayer.useMockDml();
		// Initialize plugins:
		MockDmlTest.initPlugins(DatabaseLayerTestUtils.SamplePlugin.class.getName());
	}

	// **** TESTS **** //
	@IsTest
	static void shouldMockLeadConvert() {
		Map<Id, Lead> leads = new Map<Id, Lead>();
		List<Database.LeadConvert> leadsToConvert = new List<Database.LeadConvert>();
		for (Integer i = 0; i < TEST_SIZE; i++) {
			Lead lead = (Lead) new MockRecord(Lead.SObjectType)?.withId()?.toSObject();
			leads?.put(lead?.Id, lead);
			Database.LeadConvert leadToConvert = new Database.LeadConvert();
			leadToConvert?.setLeadId(lead?.Id);
			leadToConvert?.setConvertedStatus('Foo!');
			leadsToConvert?.add(leadToConvert);
		}

		Test.startTest();
		List<Database.LeadConvertResult> results = DatabaseLayer.Dml?.doConvert(leadsToConvert);
		Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		Test.stopTest();

		Assert.areEqual(leadsToConvert?.size(), results?.size(), 'Wrong # of results');
		Assert.areEqual(
			results?.size(),
			MockDml.CONVERTED?.getRecords(Lead.SObjectType)?.size(),
			'Wrong # of converted records'
		);
		for (Database.LeadConvertResult result : results) {
			Assert.isTrue(result?.isSuccess(), 'Did not succeed: ' + result?.getErrors());
			Id leadId = result?.getLeadId();
			Lead lead = leads?.get(leadId);
			Assert.areNotEqual(null, lead, 'No lead w/matching Id: ' + leadId);
			Assert.areNotEqual(null, result?.getAccountId(), 'Missing ConvertedAccountId');
			Assert.areNotEqual(null, result?.getContactId(), 'Missing ConvertedContactId');
			Assert.areNotEqual(null, result?.getOpportunityId(), 'Missing ConvertedOpportunityId');
		}
	}

	@IsTest
	static void shouldMockLeadConvertWithExistingRecords() {
		Account account = (Account) new MockRecord(Account.SObjectType)?.withId()?.toSObject();
		Map<Id, Lead> leads = new Map<Id, Lead>();
		List<Database.LeadConvert> leadsToConvert = new List<Database.LeadConvert>();
		for (Integer i = 0; i < TEST_SIZE; i++) {
			Lead lead = (Lead) new MockRecord(Lead.SObjectType)?.withId()?.toSObject();
			leads?.put(lead?.Id, lead);
			Database.LeadConvert leadToConvert = new Database.LeadConvert();
			leadToConvert?.setLeadId(lead?.Id);
			leadToConvert?.setAccountId(account?.Id);
			leadToConvert?.setConvertedStatus('Foo!');
			leadsToConvert?.add(leadToConvert);
		}

		Test.startTest();
		List<Database.LeadConvertResult> results = DatabaseLayer.Dml?.doConvert(leadsToConvert);
		Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		Test.stopTest();

		Assert.areEqual(leadsToConvert?.size(), results?.size(), 'Wrong # of results');
		Assert.areEqual(
			results?.size(),
			MockDml.CONVERTED?.getRecords(Lead.SObjectType)?.size(),
			'Wrong # of converted records'
		);
		for (Database.LeadConvertResult result : results) {
			Assert.isTrue(result?.isSuccess(), 'Did not succeed: ' + result?.getErrors());
			Id leadId = result?.getLeadId();
			Lead lead = leads?.get(leadId);
			Assert.areNotEqual(null, lead, 'No lead w/matching Id: ' + leadId);
			Assert.areEqual(account?.Id, result?.getAccountId(), 'Did not use existing AccountId');
			Assert.areNotEqual(null, result?.getContactId(), 'Missing ConvertedContactId');
			Assert.areNotEqual(null, result?.getOpportunityId(), 'Missing ConvertedOpportunityId');
		}
	}

	@IsTest
	static void shouldThrowExceptionIfMissingLeadIdOnConvert() {
		List<Database.LeadConvert> leadsToConvert = new List<Database.LeadConvert>();
		for (Integer i = 0; i < TEST_SIZE; i++) {
			Lead lead = (Lead) new MockRecord(Lead.SObjectType)?.withId()?.toSObject();
			Database.LeadConvert leadToConvert = new Database.LeadConvert();
			// ! Missing lead id -- will cause an error
			leadToConvert?.setConvertedStatus('Foo!');
			leadsToConvert?.add(leadToConvert);
		}

		Test.startTest();
		Exception caughtError;
		try {
			DatabaseLayer.Dml?.doConvert(leadsToConvert);
			Assert.fail('An error was not thrown for missing Lead Id');
		} catch (System.DmlException error) {
			// As expected...
			caughtError = error;
		} finally {
			Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldThrowExceptionIfMissingLeadStatusConvert() {
		List<Database.LeadConvert> leadsToConvert = new List<Database.LeadConvert>();
		for (Integer i = 0; i < TEST_SIZE; i++) {
			Lead lead = (Lead) new MockRecord(Lead.SObjectType)?.withId()?.toSObject();
			Database.LeadConvert leadToConvert = new Database.LeadConvert();
			leadToConvert?.setLeadId(lead?.Id);
			// ! Missing converted status -- will cause an error
			leadsToConvert?.add(leadToConvert);
		}

		Test.startTest();
		Exception caughtError;
		try {
			DatabaseLayer.Dml?.doConvert(leadsToConvert);
			Assert.fail('An error was not thrown for missing converted status');
		} catch (System.DmlException error) {
			// As expected...
			caughtError = error;
		} finally {
			Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldThrowExceptionIfErrorInjectedOnConvert() {
		DatabaseLayer.useMockDml();
		MockDml.shouldFail();
		List<Database.LeadConvert> leadsToConvert = new List<Database.LeadConvert>();
		for (Integer i = 0; i < TEST_SIZE; i++) {
			Lead lead = (Lead) new MockRecord(Lead.SObjectType)?.withId()?.toSObject();
			Database.LeadConvert leadToConvert = new Database.LeadConvert();
			leadToConvert?.setLeadId(lead?.Id);
			leadToConvert?.setConvertedStatus('Some Status');
			leadsToConvert?.add(leadToConvert);
		}

		Test.startTest();
		try {
			DatabaseLayer.Dml?.doConvert(leadsToConvert);
			Assert.fail('Did not throw an error');
		} catch (Exception error) {
			// ...as expected...
			Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
			Assert.areEqual(0, MockDml.CONVERTED?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of converted records');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldFailSilentlyIfErrorAndNotAllOrNoneOnConvert() {
		List<Database.LeadConvert> leadsToConvert = new List<Database.LeadConvert>();
		for (Integer i = 0; i < TEST_SIZE; i++) {
			Lead lead = (Lead) new MockRecord(Lead.SObjectType)?.withId()?.toSObject();
			Database.LeadConvert leadToConvert = new Database.LeadConvert();
			leadToConvert?.setLeadId(lead?.Id);
			leadToConvert?.setConvertedStatus('Some Status');
			leadsToConvert?.add(leadToConvert);
		}
		DatabaseLayer.useMockDml();
		MockDml.shouldFail();

		Test.startTest();
		List<Database.LeadConvertResult> results = DatabaseLayer.Dml.doConvert(leadsToConvert, false);
		Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		Test.stopTest();

		Assert.areEqual(leadsToConvert?.size(), results?.size(), 'Wrong # of results');
		Assert.areEqual(0, MockDml.CONVERTED?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of converted records');
		for (Database.LeadConvertResult result : results) {
			Assert.isFalse(result?.isSuccess(), 'Should not have succeeded');
		}
	}

	@IsTest
	static void shouldMockDelete() {
		List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);

		Test.startTest();
		List<Database.DeleteResult> results = DatabaseLayer.Dml?.doDelete(leads);
		Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		Test.stopTest();

		Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results');
		Assert.areEqual(
			leads?.size(),
			MockDml.DELETED?.getRecords(Lead.SObjectType)?.size(),
			'Wrong # of deleted records'
		);
		for (Database.DeleteResult result : results) {
			Assert.isTrue(result?.isSuccess(), 'Should not have succeeded');
		}
	}

	@IsTest
	static void shouldMockDeleteAsync() {
		List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);

		Test.startTest();
		List<Database.DeleteResult> results = DatabaseLayer.Dml?.doDeleteAsync(leads);
		Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		Test.stopTest();

		Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results');
		Assert.areEqual(
			leads?.size(),
			MockDml.DELETED?.getRecords(Lead.SObjectType)?.size(),
			'Wrong # of deleted records'
		);
		for (Database.DeleteResult result : results) {
			Assert.isTrue(result?.isSuccess(), 'Should not have succeeded');
		}
	}

	@IsTest
	static void shouldMockDeleteImmediate() {
		List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);

		Test.startTest();
		List<Database.DeleteResult> results = DatabaseLayer.Dml?.doDeleteImmediate(leads);
		Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		Test.stopTest();

		Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results');
		Assert.areEqual(
			leads?.size(),
			MockDml.DELETED?.getRecords(Lead.SObjectType)?.size(),
			'Wrong # of deleted records'
		);
		for (Database.DeleteResult result : results) {
			Assert.isTrue(result?.isSuccess(), 'Should not have succeeded');
		}
	}

	@IsTest
	static void shouldMockEmptyRecycleBin() {
		List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);
		DatabaseLayer.Dml?.doDelete(leads);

		Test.startTest();
		List<Database.EmptyRecycleBinResult> results = DatabaseLayer.Dml?.emptyRecycleBin(leads);
		Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		Test.stopTest();

		Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results');
		Assert.areEqual(results?.size(), MockDml.PURGED?.getRecords(Lead.SObjectType)?.size(), 'Wrong # purged');
		for (Database.EmptyRecycleBinResult result : results) {
			Assert.isTrue(result?.isSuccess(), 'Should not have succeeded');
		}
	}

	@IsTest
	static void shouldThrowExceptionIfErrorOnDelete() {
		List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);
		DatabaseLayer.useMockDml();
		MockDml.shouldFail();

		Test.startTest();
		try {
			DatabaseLayer.Dml.doDelete(leads);
			Assert.fail('Did not throw an error');
		} catch (Exception error) {
			// ...as expected...
			Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
			Assert.areEqual(0, MockDml.DELETED?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of deleted records');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldFailSilentlyIfErrorAndNotAllOrNoneOnDelete() {
		List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);
		DatabaseLayer.useMockDml();
		MockDml.shouldFail();

		Test.startTest();
		List<Database.DeleteResult> results = DatabaseLayer.Dml.doDelete(leads, false);
		Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		Test.stopTest();

		Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results');
		Assert.areEqual(0, MockDml.DELETED?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of deleted records');
		for (Database.DeleteResult result : results) {
			Assert.isFalse(result?.isSuccess(), 'Should not have succeeded');
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
		}
	}

	@IsTest
	static void shouldMockInsert() {
		List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType);

		Test.startTest();
		List<Database.SaveResult> results = DatabaseLayer.Dml?.doInsert(leads);
		Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		Test.stopTest();

		Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results');
		Assert.areEqual(
			leads?.size(),
			MockDml.INSERTED?.getRecords(Lead.SObjectType)?.size(),
			'Wrong # of inserted records'
		);
		for (Database.SaveResult result : results) {
			Assert.isTrue(result?.isSuccess(), 'Did not succeed: ' + result?.getErrors());
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
		}
	}

	@IsTest
	static void shouldMockInsertAsync() {
		List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType);

		Test.startTest();
		List<Database.SaveResult> results = DatabaseLayer.Dml?.doInsertAsync(leads);
		Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		Test.stopTest();

		Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results');
		Assert.areEqual(
			leads?.size(),
			MockDml.INSERTED?.getRecords(Lead.SObjectType)?.size(),
			'Wrong # of inserted records'
		);
		for (Database.SaveResult result : results) {
			Assert.isTrue(result?.isSuccess(), 'Did not succeed: ' + result?.getErrors());
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
		}
	}

	@IsTest
	static void shouldMockInsertImmediate() {
		List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType);

		Test.startTest();
		List<Database.SaveResult> results = DatabaseLayer.Dml?.doInsertImmediate(leads);
		Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		Test.stopTest();

		Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results');
		Assert.areEqual(
			leads?.size(),
			MockDml.INSERTED?.getRecords(Lead.SObjectType)?.size(),
			'Wrong # of inserted records'
		);
		for (Database.SaveResult result : results) {
			Assert.isTrue(result?.isSuccess(), 'Did not succeed: ' + result?.getErrors());
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
		}
	}

	@IsTest
	static void shouldThrowExceptionIfErrorOnInsert() {
		List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType);
		DatabaseLayer.useMockDml();
		MockDml.shouldFail();

		Test.startTest();
		try {
			DatabaseLayer.Dml.doInsert(leads);
			Assert.fail('Did not throw an error');
		} catch (Exception error) {
			// ...as expected...
			Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
			Assert.areEqual(0, MockDml.INSERTED?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of inserted records');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldFailSilentlyIfErrorAndNotAllOrNoneOnInsert() {
		List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType);
		DatabaseLayer.useMockDml();
		MockDml.shouldFail();

		Test.startTest();
		List<Database.SaveResult> results = DatabaseLayer.Dml.doInsert(leads, false);
		Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		Test.stopTest();

		Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results');
		Assert.areEqual(0, MockDml.INSERTED?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of inserted records');
		for (Database.SaveResult result : results) {
			Assert.isFalse(result?.isSuccess(), 'Should not have succeeded');
			Assert.areEqual(null, result?.getId(), 'Insert failed, but has an Id?');
		}
	}

	@IsTest
	static void shouldMockPublish() {
		List<BatchApexErrorEvent> events = MockDmlTest.initRecords(BatchApexErrorEvent.SObjectType);

		Test.startTest();
		List<Database.SaveResult> results = DatabaseLayer.Dml?.doPublish(events);
		Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		Test.stopTest();

		Assert.areEqual(events?.size(), results?.size(), 'Wrong # of results');
		Assert.areEqual(
			events?.size(),
			MockDml.PUBLISHED?.getRecords(BatchApexErrorEvent.SObjectType)?.size(),
			'Wrong # of published records'
		);
		for (Database.SaveResult result : results) {
			Assert.isTrue(result?.isSuccess(), 'Did not succeed: ' + result?.getErrors());
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
		}
	}

	@IsTest
	static void shouldThrowExceptionIfErrorOnPublish() {
		List<BatchApexErrorEvent> events = MockDmlTest.initRecords(BatchApexErrorEvent.SObjectType);
		DatabaseLayer.useMockDml();
		MockDml.shouldFail();

		Test.startTest();
		DatabaseLayer.Dml.doPublish(events);
		Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		Test.stopTest();

		Assert.areEqual(
			0,
			MockDml.PUBLISHED?.getRecords(BatchApexErrorEvent.SObjectType)?.size(),
			'Wrong # of published records'
		);
	}

	@IsTest
	static void shouldFailSilentlyIfErrorOnPublish() {
		List<BatchApexErrorEvent> events = MockDmlTest.initRecords(BatchApexErrorEvent.SObjectType);
		DatabaseLayer.useMockDml();
		MockDml.shouldFail();

		Test.startTest();
		List<Database.SaveResult> results = DatabaseLayer.Dml.doPublish(events);
		Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		Test.stopTest();

		Assert.areEqual(events?.size(), results?.size(), 'Wrong # of results');
		Assert.areEqual(
			0,
			MockDml.PUBLISHED?.getRecords(BatchApexErrorEvent.SObjectType)?.size(),
			'Wrong # of published records'
		);
		for (Database.SaveResult result : results) {
			Assert.isFalse(result?.isSuccess(), 'Should not have succeeded');
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
		}
	}

	@IsTest
	static void shouldMockUndelete() {
		List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);

		Test.startTest();
		List<Database.UndeleteResult> results = DatabaseLayer.Dml?.doUndelete(leads);
		Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		Test.stopTest();

		Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results');
		Assert.areEqual(
			leads?.size(),
			MockDml.UNDELETED?.getRecords(Lead.SObjectType)?.size(),
			'Wrong # of undeleted records'
		);
		for (Database.UndeleteResult result : results) {
			Assert.isTrue(result?.isSuccess(), 'Did not succeed: ' + result?.getErrors());
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
		}
	}

	@IsTest
	static void shouldThrowExceptionIfErrorOnUndelete() {
		DatabaseLayer.useMockDml();
		MockDml.shouldFail();
		List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);

		Test.startTest();
		try {
			DatabaseLayer.Dml.doUndelete(leads);
			Assert.fail('Did not throw an error');
		} catch (Exception error) {
			// ...as expected...
			Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
			Assert.areEqual(0, MockDml.UNDELETED?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of undeleted records');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldFailSilentlyIfErrorAndNotAllOrNoneOnUndelete() {
		List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);
		DatabaseLayer.useMockDml();
		MockDml.shouldFail();

		Test.startTest();
		List<Database.UndeleteResult> results = DatabaseLayer.Dml.doUndelete(leads, false);
		Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		Test.stopTest();

		Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results');
		Assert.areEqual(0, MockDml.UNDELETED?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of undeleted records');
		for (Database.UndeleteResult result : results) {
			Assert.isFalse(result?.isSuccess(), 'Should not have succeeded');
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
		}
	}

	@IsTest
	static void shouldMockUpdate() {
		List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);

		Test.startTest();
		List<Database.SaveResult> results = DatabaseLayer.Dml?.doUpdate(leads);
		Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		Test.stopTest();

		Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results');
		Assert.areEqual(
			leads?.size(),
			MockDml.UPDATED?.getRecords(Lead.SObjectType)?.size(),
			'Wrong # of updated records'
		);
		for (Database.SaveResult result : results) {
			Assert.isTrue(result?.isSuccess(), 'Did not succeed: ' + result?.getErrors());
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
		}
	}

	@IsTest
	static void shouldMockUpdateAsync() {
		List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);

		Test.startTest();
		List<Database.SaveResult> results = DatabaseLayer.Dml?.doUpdateAsync(leads);
		Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		Test.stopTest();

		Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results');
		Assert.areEqual(
			leads?.size(),
			MockDml.UPDATED?.getRecords(Lead.SObjectType)?.size(),
			'Wrong # of updated records'
		);
		for (Database.SaveResult result : results) {
			Assert.isTrue(result?.isSuccess(), 'Did not succeed: ' + result?.getErrors());
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
		}
	}

	@IsTest
	static void shouldMockUpdateImmediate() {
		List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);

		Test.startTest();
		List<Database.SaveResult> results = DatabaseLayer.Dml?.doUpdateImmediate(leads);
		Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		Test.stopTest();

		Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results');
		Assert.areEqual(
			leads?.size(),
			MockDml.UPDATED?.getRecords(Lead.SObjectType)?.size(),
			'Wrong # of updated records'
		);
		for (Database.SaveResult result : results) {
			Assert.isTrue(result?.isSuccess(), 'Did not succeed: ' + result?.getErrors());
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
		}
	}

	@IsTest
	static void shouldThrowExceptionIfErrorOnUpdate() {
		DatabaseLayer.useMockDml();
		MockDml.shouldFail();
		List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);

		Test.startTest();
		try {
			DatabaseLayer.Dml.doUpdate(leads);
			Assert.fail('Did not throw an error');
		} catch (Exception error) {
			// ...as expected...
			Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
			Assert.areEqual(0, MockDml.UPDATED?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of updated records');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldFailSilentlyIfErrorAndNotAllOrNoneOnUpdate() {
		DatabaseLayer.useMockDml();
		MockDml.shouldFail();
		List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);

		Test.startTest();
		List<Database.SaveResult> results = DatabaseLayer.Dml.doUpdate(leads, false);
		Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		Test.stopTest();

		Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results');
		Assert.areEqual(0, MockDml.UPDATED?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of updated records');
		for (Database.SaveResult result : results) {
			Assert.isFalse(result?.isSuccess(), 'Should not have succeeded');
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
		}
	}

	@IsTest
	static void shouldMockUpsert() {
		List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);

		Test.startTest();
		List<Database.UpsertResult> results = DatabaseLayer.Dml?.doUpsert(leads);
		Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		Test.stopTest();

		Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results');
		Assert.areEqual(
			leads?.size(),
			MockDml.UPSERTED?.getRecords(Lead.SObjectType)?.size(),
			'Wrong # of upserted records'
		);
		for (Database.UpsertResult result : results) {
			Assert.isTrue(result?.isSuccess(), 'Did not succeed: ' + result?.getErrors());
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
		}
	}

	@IsTest
	static void shouldThrowExceptionIfErrorOnUpsert() {
		DatabaseLayer.useMockDml();
		MockDml.shouldFail();
		List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);

		Test.startTest();
		try {
			DatabaseLayer.Dml.doUpsert(leads);
			Assert.fail('Did not throw an error');
		} catch (Exception error) {
			// ...as expected...
			Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
			Assert.areEqual(0, MockDml.UPSERTED?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of upserted records');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldFailSilentlyIfErrorAndNotAllOrNoneOnUpsert() {
		DatabaseLayer.useMockDml();
		MockDml.shouldFail();
		List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);

		Test.startTest();
		List<Database.UpsertResult> results = DatabaseLayer.Dml.doUpsert(leads, false);
		Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		Test.stopTest();

		Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results');
		Assert.areEqual(0, MockDml.UPSERTED?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of upserted records');
		for (Database.UpsertResult result : results) {
			Assert.isFalse(result?.isSuccess(), 'Should not have succeeded');
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
		}
	}

	@IsTest
	static void shouldProvideUsefulInformationAboutProcessedRecords() {
		Lead testLead = (Lead) new MockRecord(Lead.SObjectType)?.withId()?.toSObject();
		// Pre-test asserts
		Assert.isFalse(MockDml.UPDATED.wasProcessed(testLead), 'Pre-test: Should not have been processed');
		Assert.areEqual(null, MockDml.UPDATED.get(testLead), 'Pre-test: Lead was processed');
		Assert.areEqual(0, MockDml.UPDATED.getRecords(Lead.SObjectType)?.size(), 'Pre-test: Wrong # of lead updates');
		Assert.areEqual(0, MockDml.UPDATED.getRecords(Lead.SObjectType)?.size(), 'Pre-test: Wrong # of total updates');
		testLead.Company = 'Credicor Inc.';

		Test.startTest();
		DatabaseLayer.Dml?.doUpdate(testLead);
		Test.stopTest();

		// Post-test asserts
		Assert.isTrue(MockDml.UPDATED.wasProcessed(testLead), 'Lead was not processed');
		Lead updatedLead = (Lead) MockDml.UPDATED.get(testLead);
		Assert.areNotEqual(null, updatedLead, 'Lead was not updated');
		Assert.areEqual(testLead?.Company, updatedLead?.Company, 'Did not update Company');
		Assert.areEqual(1, MockDml.UPDATED.getRecords(Lead.SObjectType)?.size(), 'Wrong # of lead updates');
		Assert.areEqual(1, MockDml.UPDATED.getRecords(Lead.SObjectType)?.size(), 'Wrong # of total updates');

		// Callers can also call this method to erase the current history:
		MockDml.eraseAllHistories();
		Assert.isTrue(MockDml.UPDATED.getAll()?.isEmpty(), 'Did not reset history');
	}

	@IsTest
	static void shouldInjectCustomFailureLogic() {
		List<Account> accounts = MockDmlTest.initRecords(Account.SObjectType, false);
		MockDml.ConditionalFailure failure = new MockDmlTest.ExampleFailure(
			Dml.Operation.DO_UPDATE,
			Account.SObjectType
		);
		DatabaseLayer.useMockDml();
		MockDml.shouldFailIf(failure);

		Test.startTest();
		Exception caughtError;
		// Inserts should succeed
		try {
			DatabaseLayer.Dml.doInsert(accounts);
		} catch (System.DmlException error) {
			Assert.fail('An error was thrown');
		}
		// Updates should throw an error
		try {
			DatabaseLayer.Dml.doUpdate(accounts);
			Assert.fail('Did not throw an error');
		} catch (System.DmlException error) {
			// As expected...
			caughtError = error;
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldClearFailures() {
		// The MockDml class provides a way to clear failures from an object
		List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);
		DatabaseLayer.useMockDml();
		MockDml.shouldFail();

		Test.startTest();
		// Since the DML object has a failure, it will throw an error when run:
		Exception caughtError;
		try {
			DatabaseLayer.Dml?.doUpdate(leads);
			Assert.fail('Did not throw an error');
		} catch (System.DmlException error) {
			// As expected...
			caughtError = error;
		}

		// Now clear the failure and try again - an error should NOT be thrown
		MockDml.shouldSucceed();
		try {
			DatabaseLayer.Dml?.doUpdate(leads);
		} catch (System.DmlException error) {
			Assert.fail('An error was thrown; failures were not cleared');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldGetAllRecordsFromHistory() {
		List<Account> accounts = MockDmlTest.initRecords(Account.SObjectType, false);
		DatabaseLayer.Dml.doInsert(accounts);

		Test.startTest();
		Map<SObjectType, List<SObject>> results = MockDml.INSERTED.getAll();
		Test.stopTest();

		List<Account> insertedAccounts = results?.get(Account.SObjectType);
		Assert.areEqual(accounts?.size(), insertedAccounts?.size(), 'Wrong # of Accounts inserted');
	}

	@IsTest
	static void shouldGetSpecificRecordFromHistory() {
		List<Account> accounts = MockDmlTest.initRecords(Account.SObjectType, false);
		Account firstAccount = accounts?.get(0);
		DatabaseLayer.Dml.doInsert(accounts);

		Test.startTest();
		DatabaseLayer.Dml.doInsert(accounts);
		Test.stopTest();

		Assert.isTrue(MockDml.INSERTED?.wasProcessed(firstAccount), 'Account was not inserted');
		Assert.isFalse(MockDml.UPDATED?.wasProcessed(firstAccount), 'Account should not have updated');
		Account insertedAccount = (Account) MockDml.INSERTED?.get(firstAccount);
		Assert.areEqual(firstAccount?.Id, insertedAccount?.Id, 'Wrong Account retrieved');
	}

	@IsTest
	static void shouldCreateSnapshotOfMockDatabase() {
		List<Account> accounts = MockDmlTest.initRecords(Account.SObjectType, false);
		DatabaseLayer.Dml.doInsert(accounts);

		Test.startTest();
		// Take a snapshot
		MockDml.Database snapshot = MockDml.MockDatabase?.snapshot();
		Test.stopTest();

		// Now simulate deleting the records:
		DatabaseLayer.Dml.doDelete(accounts);
		// Both the current MockDatabase & the snapshot should be aware Inserted records:
		Assert.isFalse(MockDml.INSERTED?.getAll()?.isEmpty(), 'MockDatabase: Should have inserted records');
		Assert.isFalse(snapshot?.inserted?.getAll()?.isEmpty(), 'Snapshot: Should have inserted records');
		// Only the MockDatabase is aware of the deleted records:
		Assert.isFalse(MockDml.DELETED?.getAll()?.isEmpty(), 'MockDatabase: Should have deleted records');
		Assert.isTrue(snapshot?.deleted?.getAll()?.isEmpty(), 'Snapshot: Should not have deleted records');
	}

	@IsTest
	static void shouldHandleSetSavepoints() {
		Test.startTest();
		System.Savepoint savepoint = DatabaseLayer.Dml.setSavepoint();
		Test.stopTest();

		Assert.isNotNull(savepoint, 'Did not return a System.Savepoint');
		List<MockDml.Savepoint> savepointInfos = MockDml.SAVEPOINTS?.getAll();
		Assert.areEqual(1, savepointInfos?.size(), 'Wrong # of Savepoints');
		MockDml.Savepoint savepointInfo = savepointInfos?.get(0);
		Assert.isFalse(savepointInfo?.wasReleased, 'Should not have been released');
		Assert.isFalse(savepointInfo?.wasRolledBack, 'Should not have been rolled back');
	}

	@IsTest
	static void shouldHandleReleasedSavepoints() {
		Test.startTest();
		System.Savepoint savepoint = DatabaseLayer.Dml.setSavepoint();
		DatabaseLayer.Dml.releaseSavepoint(savepoint);
		Test.stopTest();

		Assert.isNotNull(savepoint, 'Did not return a System.Savepoint');
		List<MockDml.Savepoint> savepointInfos = MockDml.SAVEPOINTS.getAll();
		Assert.areEqual(1, savepointInfos?.size(), 'Wrong # of Savepoints');
		MockDml.Savepoint savepointInfo = savepointInfos?.get(0);
		Assert.isTrue(savepointInfo?.wasReleased, 'Was not released');
		Assert.isFalse(savepointInfo?.wasRolledBack, 'Should not have been rolled back');
	}

	@IsTest
	static void shouldHandleRolledBackSavepoints() {
		MockDml.MockDatabase.resetOnRollback = true;

		Test.startTest();
		System.Savepoint savepoint = DatabaseLayer.Dml.setSavepoint();
		DatabaseLayer.Dml.doInsert(new Account());
		DatabaseLayer.Dml.rollback(savepoint);
		Test.stopTest();

		Assert.isTrue(MockDml.INSERTED.getAll()?.isEmpty(), 'Did not roll back DML operation');
		Assert.isNotNull(savepoint, 'Did not return a System.Savepoint');
		List<MockDml.Savepoint> savepointInfos = MockDml.SAVEPOINTS.getAll();
		Assert.areEqual(1, savepointInfos?.size(), 'Wrong # of Savepoints');
		MockDml.Savepoint savepointInfo = savepointInfos?.get(0);
		Assert.isFalse(savepointInfo?.wasReleased, 'Should not have been released');
		Assert.isTrue(savepointInfo?.wasRolledBack, 'Was not rolled back');
	}

	@IsTest
	static void shouldHandleRolledBackSavepointsWithoutResettingMockDatabase() {
		MockDml.MockDatabase.resetOnRollback = false;

		Test.startTest();
		System.Savepoint savepoint = DatabaseLayer.Dml.setSavepoint();
		DatabaseLayer.Dml.doInsert(new Account());
		DatabaseLayer.Dml.rollback(savepoint);
		Test.stopTest();

		Assert.isFalse(MockDml.INSERTED.getAll()?.isEmpty(), 'Savepoint should not have reset DML history');
		Assert.isNotNull(savepoint, 'Did not return a System.Savepoint');
		List<MockDml.Savepoint> savepointInfos = MockDml.SAVEPOINTS.getAll();
		Assert.areEqual(1, savepointInfos?.size(), 'Wrong # of Savepoints');
		MockDml.Savepoint savepointInfo = savepointInfos?.get(0);
		Assert.isFalse(savepointInfo?.wasReleased, 'Should not have been released');
		Assert.isTrue(savepointInfo?.wasRolledBack, 'Was not rolled back');
	}

	@IsTest
	static void shouldGetASpecificSavepoint() {
		System.Savepoint sp1 = DatabaseLayer.Dml.setSavepoint();
		System.Savepoint sp2 = DatabaseLayer.Dml.setSavepoint();
		// Roll back the second savepoint, to distinguish the two:
		DatabaseLayer.Dml.rollback(sp2);

		Test.startTest();
		MockDml.Savepoint spInfo1 = MockDml.SAVEPOINTS.get(sp1);
		MockDml.Savepoint spInfo2 = MockDml.SAVEPOINTS.get(sp2);
		Test.stopTest();

		// The first savepoint should not be rolled back:
		Assert.isNotNull(spInfo1, 'Did not return a Savepoint');
		Assert.isFalse(spInfo1?.wasRolledBack, 'Should not have been rolled back');
		Assert.isNotNull(MockDml.Savepoints.get(spInfo1?.index), 'No Savepoint matching ' + spInfo1?.index);
		// The second savepoint should be rolled back:
		Assert.isNotNull(spInfo2, 'Did not return a Savepoint');
		Assert.isTrue(spInfo2?.wasRolledBack, 'Was not rolled back');
		Assert.isNotNull(MockDml.Savepoints.get(spInfo2?.index), 'No Savepoint matching ' + spInfo2?.index);
	}

	@IsTest
	static void shouldRunPreAndPostProcessorPluginLogic() {
		MockDmlTest.initPlugins(DatabaseLayerTestUtils.SamplePlugin.class.getName());
		List<Account> accounts = MockDmlTest.initRecords(Account.SObjectType, false);

		Test.startTest();
		Database.SaveResult result = DatabaseLayer.Dml.doInsert(accounts)?.get(0);
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
		MockDmlTest.initPlugins(DatabaseLayerTestUtils.SamplePlugin.class.getName());
		List<Account> accounts = MockDmlTest.initRecords(Account.SObjectType, false);
		MockDml.shouldFail();

		Test.startTest();
		Exception caughtError;
		try {
			// Updates will fail, since there isn't an Id set:
			DatabaseLayer.Dml.doUpdate(accounts);
			Assert.fail('Did not throw a System.DmlException');
		} catch (System.DmlException error) {
			// As expected...
			caughtError = error;
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
		MockDmlTest.initPlugins('An obviously invalid apex class name');
		List<Account> accounts = MockDmlTest.initRecords(Account.SObjectType, false);

		Test.startTest();
		Database.SaveResult result = DatabaseLayer.Dml.doInsert(accounts)?.get(0);
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
		MockDmlTest.initPlugins(null);
		List<Account> accounts = MockDmlTest.initRecords(Account.SObjectType, false);

		Test.startTest();
		Database.SaveResult result = DatabaseLayer.Dml.doInsert(accounts)?.get(0);
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
		List<Account> accounts = MockDmlTest.initRecords(Account.SObjectType, false);

		Test.startTest();
		Database.SaveResult result = DatabaseLayer.Dml.doInsert(accounts)?.get(0);
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

	// **** HELPER **** //
	private static void initPlugins(String dmlPluginName) {
		DatabaseLayerSetting__mdt settings = DatabaseLayerTestUtils.initSettings();
		settings.DmlPreAndPostProcessor__c = dmlPluginName;
		DatabaseLayerTestUtils.initSettings(settings);
	}

	private static List<SObject> initRecords(SObjectType objectType, Boolean withId) {
		List<SObject> records = new List<SObject>();
		for (Integer i = 0; i < TEST_SIZE; i++) {
			MockRecord mock = new MockRecord(objectType);
			if (withId == true) {
				mock?.withId();
			}
			SObject record = mock?.toSObject();
			records?.add(record);
		}
		return records;
	}

	private static List<SObject> initRecords(SObjectType objectType) {
		return MockDmlTest.initRecords(objectType, false);
	}

	private static DatabaseLayerSetting__mdt initSettings() {
		DatabaseLayerSetting__mdt settings = new DatabaseLayerSetting__mdt();
		DatabaseLayer.Utils.MetadataSelector.settings?.add(settings);
		return settings;
	}

	// **** INNER **** //
	/**
	 * @description Example implementation of ConditionalFailure interface for testing DML operation failures
	 */
	public class ExampleFailure implements MockDml.ConditionalFailure {
		private Dml.Operation failingOperation;
		private SObjectType failingSObjectType;

		/**
		 * @description Constructor that configures which operation and SObject type should trigger a failure
		 * @param operation The DML operation that should trigger a failure
		 * @param objectType The SObject type that should trigger a failure
		 */
		public ExampleFailure(Dml.Operation operation, SObjectType objectType) {
			this.failingOperation = operation;
			this.failingSObjectType = objectType;
		}

		/**
		 * @description Checks if the given operation and record should trigger a failure exception
		 * @param operation The DML operation being performed
		 * @param record The SObject record being operated on
		 * @return Exception to throw if conditions match, null otherwise
		 */
		public Exception checkFailure(Dml.Operation operation, SObject record) {
			// Only throw an error if updating an Account
			Boolean shouldFail =
				operation == this.failingOperation &&
				record?.getSObjectType() == this.failingSObjectType;
			return (shouldFail) ? new System.DmlException() : null;
		}
	}
}
