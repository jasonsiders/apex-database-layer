@IsTest
@SuppressWarnings('PMD.EmptyCatchBlock')
private class MockDmlTest {
	// **** CONSTANTS **** //
	private static final Integer TEST_SIZE = 20;

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
		List<Database.LeadConvertResult> results = new MockDml()?.doConvert(leadsToConvert);
		Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		Test.stopTest();

		Assert.areEqual(leadsToConvert?.size(), results?.size(), 'Wrong # of results');
		Assert.areEqual(results?.size(), MockDml.Converted?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of converted records');
		for (Database.LeadConvertResult result : results) {
			Assert.areEqual(true, result?.isSuccess(), 'Did not succeed: ' + result?.getErrors());
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
		List<Database.LeadConvertResult> results = new MockDml()?.doConvert(leadsToConvert);
		Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		Test.stopTest();

		Assert.areEqual(leadsToConvert?.size(), results?.size(), 'Wrong # of results');
		Assert.areEqual(results?.size(), MockDml.Converted?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of converted records');
		for (Database.LeadConvertResult result : results) {
			Assert.areEqual(true, result?.isSuccess(), 'Did not succeed: ' + result?.getErrors());
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
		try {
			new MockDml()?.doConvert(leadsToConvert);
			Assert.fail('An error was not thrown for missing Lead Id');
		} catch (System.DmlException error) {
			// As expected
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
		try {
			new MockDml()?.doConvert(leadsToConvert);
			Assert.fail('An error was not thrown for missing converted status');
		} catch (System.DmlException error) {
			// As expected
		} finally {
			Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldThrowExceptionIfErrorInjectedOnConvert() {
		List<Database.LeadConvert> leadsToConvert = new List<Database.LeadConvert>();
		for (Integer i = 0; i < TEST_SIZE; i++) {
			Lead lead = (Lead) new MockRecord(Lead.SObjectType)?.withId()?.toSObject();
			Database.LeadConvert leadToConvert = new Database.LeadConvert();
			leadToConvert?.setLeadId(lead?.Id);
			leadToConvert?.setConvertedStatus('Some Status');
			leadsToConvert?.add(leadToConvert);
		}
		Dml dml = new MockDml()?.fail();

		Test.startTest();
		try {
			dml?.doConvert(leadsToConvert);
			Assert.fail('Did not throw an error');
		} catch (Exception error) {
			// ...as expected...
			Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
			Assert.areEqual(0, MockDml.Converted?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of converted records');
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
		Dml dml = new MockDml()?.fail()?.setAllOrNone(false);

		Test.startTest();
		List<Database.LeadConvertResult> results = dml?.doConvert(leadsToConvert);
		Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		Test.stopTest();

		Assert.areEqual(leadsToConvert?.size(), results?.size(), 'Wrong # of results');
		Assert.areEqual(0, MockDml.Converted?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of converted records');
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
		Assert.areEqual(leads?.size(), MockDml.Deleted?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of deleted records');
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
		Assert.areEqual(leads?.size(), MockDml.Deleted?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of deleted records');
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
		Assert.areEqual(leads?.size(), MockDml.Deleted?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of deleted records');
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
		Assert.areEqual(leads?.size(), MockDml.Deleted?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of deleted records');
		for (Database.DeleteResult result : results) {
			Assert.areEqual(true, result?.isSuccess(), 'Should not have succeeded');
		}
	}

	@IsTest
	static void shouldThrowExceptionIfErrorOnDelete() {
		List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);
		Dml dml = new MockDml()?.fail();

		Test.startTest();
		try {
			dml?.doDelete(leads);
			Assert.fail('Did not throw an error');
		} catch (Exception error) {
			// ...as expected...
			Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
			Assert.areEqual(0, MockDml.Deleted?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of deleted records');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldFailSilentlyIfErrorAndNotAllOrNoneOnDelete() {
		List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);
		Dml dml = new MockDml()?.fail()?.setAllOrNone(false);

		Test.startTest();
		List<Database.DeleteResult> results = dml?.doDelete(leads);
		Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		Test.stopTest();

		Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results');
		Assert.areEqual(0, MockDml.Deleted?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of deleted records');
		for (Database.DeleteResult result : results) {
			Assert.areEqual(false, result?.isSuccess(), 'Should not have succeeded');
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
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
		Assert.areEqual(leads?.size(), MockDml.Inserted?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of inserted records');
		for (Database.SaveResult result : results) {
			Assert.areEqual(true, result?.isSuccess(), 'Did not succeed: ' + result?.getErrors());
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
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
		Assert.areEqual(leads?.size(), MockDml.Inserted?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of inserted records');
		for (Database.SaveResult result : results) {
			Assert.areEqual(true, result?.isSuccess(), 'Did not succeed: ' + result?.getErrors());
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
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
		Assert.areEqual(leads?.size(), MockDml.Inserted?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of inserted records');
		for (Database.SaveResult result : results) {
			Assert.areEqual(true, result?.isSuccess(), 'Did not succeed: ' + result?.getErrors());
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
		}
	}

	@IsTest
	static void shouldThrowExceptionIfErrorOnInsert() {
		List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType);
		Dml dml = new MockDml()?.fail();

		Test.startTest();
		try {
			dml?.doInsert(leads);
			Assert.fail('Did not throw an error');
		} catch (Exception error) {
			// ...as expected...
			Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
			Assert.areEqual(0, MockDml.Inserted?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of inserted records');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldFailSilentlyIfErrorAndNotAllOrNoneOnInsert() {
		List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType);
		Dml dml = new MockDml()?.fail()?.setAllOrNone(false);

		Test.startTest();
		List<Database.SaveResult> results = dml?.doInsert(leads);
		Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		Test.stopTest();

		Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results');
		Assert.areEqual(0, MockDml.Inserted?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of inserted records');
		for (Database.SaveResult result : results) {
			Assert.areEqual(false, result?.isSuccess(), 'Should not have succeeded');
			Assert.areEqual(null, result?.getId(), 'Insert failed, but has an Id?');
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
		Assert.areEqual(events?.size(), MockDml.Published?.getRecords(BatchApexErrorEvent.SObjectType)?.size(), 'Wrong # of published records');
		for (Database.SaveResult result : results) {
			Assert.areEqual(true, result?.isSuccess(), 'Did not succeed: ' + result?.getErrors());
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
		}
	}

	@IsTest
	static void shouldThrowExceptionIfErrorOnPublish() {
		List<BatchApexErrorEvent> events = MockDmlTest.initRecords(BatchApexErrorEvent.SObjectType);
		Dml dml = new MockDml()?.fail();

		Test.startTest();
		try {
			dml?.doPublish(events);
			Assert.fail('Did not throw an error');
		} catch (Exception error) {
			// ...as expected...
			Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
			Assert.areEqual(0, MockDml.Published?.getRecords(BatchApexErrorEvent.SObjectType)?.size(), 'Wrong # of published records');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldFailSilentlyIfErrorAndNotAllOrNoneOnPublish() {
		List<BatchApexErrorEvent> events = MockDmlTest.initRecords(BatchApexErrorEvent.SObjectType);
		Dml dml = new MockDml()?.fail()?.setAllOrNone(false);

		Test.startTest();
		List<Database.SaveResult> results = dml?.doPublish(events);
		Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		Test.stopTest();

		Assert.areEqual(events?.size(), results?.size(), 'Wrong # of results');
		Assert.areEqual(0, MockDml.Published?.getRecords(BatchApexErrorEvent.SObjectType)?.size(), 'Wrong # of published records');
		for (Database.SaveResult result : results) {
			Assert.areEqual(false, result?.isSuccess(), 'Should not have succeeded');
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
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
		Assert.areEqual(leads?.size(), MockDml.Undeleted?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of undeleted records');
		for (Database.UndeleteResult result : results) {
			Assert.areEqual(true, result?.isSuccess(), 'Did not succeed: ' + result?.getErrors());
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
		}
	}

	@IsTest
	static void shouldThrowExceptionIfErrorOnUndelete() {
		List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);
		Dml dml = new MockDml()?.fail();

		Test.startTest();
		try {
			dml?.doUndelete(leads);
			Assert.fail('Did not throw an error');
		} catch (Exception error) {
			// ...as expected...
			Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
			Assert.areEqual(0, MockDml.Undeleted?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of undeleted records');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldFailSilentlyIfErrorAndNotAllOrNoneOnUndelete() {
		List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);
		Dml dml = new MockDml()?.fail()?.setAllOrNone(false);

		Test.startTest();
		List<Database.UndeleteResult> results = dml?.doUndelete(leads);
		Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		Test.stopTest();

		Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results');
		Assert.areEqual(0, MockDml.Undeleted?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of undeleted records');
		for (Database.UndeleteResult result : results) {
			Assert.areEqual(false, result?.isSuccess(), 'Should not have succeeded');
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
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
		Assert.areEqual(leads?.size(), MockDml.Updated?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of updated records');
		for (Database.SaveResult result : results) {
			Assert.areEqual(true, result?.isSuccess(), 'Did not succeed: ' + result?.getErrors());
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
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
		Assert.areEqual(leads?.size(), MockDml.Updated?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of updated records');
		for (Database.SaveResult result : results) {
			Assert.areEqual(true, result?.isSuccess(), 'Did not succeed: ' + result?.getErrors());
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
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
		Assert.areEqual(leads?.size(), MockDml.Updated?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of updated records');
		for (Database.SaveResult result : results) {
			Assert.areEqual(true, result?.isSuccess(), 'Did not succeed: ' + result?.getErrors());
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
		}
	}

	@IsTest
	static void shouldThrowExceptionIfErrorOnUpdate() {
		List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);
		Dml dml = new MockDml()?.fail();

		Test.startTest();
		try {
			dml?.doUpdate(leads);
			Assert.fail('Did not throw an error');
		} catch (Exception error) {
			// ...as expected...
			Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
			Assert.areEqual(0, MockDml.Updated?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of updated records');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldFailSilentlyIfErrorAndNotAllOrNoneOnUpdate() {
		List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);
		Dml dml = new MockDml()?.fail()?.setAllOrNone(false);

		Test.startTest();
		List<Database.SaveResult> results = dml?.doUpdate(leads);
		Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		Test.stopTest();

		Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results');
		Assert.areEqual(0, MockDml.Updated?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of updated records');
		for (Database.SaveResult result : results) {
			Assert.areEqual(false, result?.isSuccess(), 'Should not have succeeded');
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
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
		Assert.areEqual(leads?.size(), MockDml.Upserted?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of upserted records');
		for (Database.UpsertResult result : results) {
			Assert.areEqual(true, result?.isSuccess(), 'Did not succeed: ' + result?.getErrors());
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
		}
	}

	@IsTest
	static void shouldThrowExceptionIfErrorOnUpsert() {
		List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);
		Dml dml = new MockDml()?.fail();

		Test.startTest();
		try {
			dml?.doUpsert(leads);
			Assert.fail('Did not throw an error');
		} catch (Exception error) {
			// ...as expected...
			Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
			Assert.areEqual(0, MockDml.Upserted?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of upserted records');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldFailSilentlyIfErrorAndNotAllOrNoneOnUpsert() {
		List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);
		Dml dml = new MockDml()?.fail()?.setAllOrNone(false);

		Test.startTest();
		List<Database.UpsertResult> results = dml?.doUpsert(leads);
		Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		Test.stopTest();

		Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results');
		Assert.areEqual(0, MockDml.Upserted?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of upserted records');
		for (Database.UpsertResult result : results) {
			Assert.areEqual(false, result?.isSuccess(), 'Should not have succeeded');
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
		}
	}

	@IsTest
	static void shouldProvideUsefulInformationAboutProcessedRecords() {
		Lead testLead = (Lead) new MockRecord(Lead.SObjectType)?.withId()?.toSObject();
		// Pre-test asserts
		Assert.areEqual(false, MockDml.Updated.wasProcessed(testLead), 'Pre-test: Should not have been processed');
		Assert.areEqual(null, MockDml.Updated.getRecord(testLead), 'Pre-test: Lead was processed');
		Assert.areEqual(0, MockDml.Updated.getRecords(Lead.SObjectType)?.size(), 'Pre-test: Wrong # of lead updates');
		Assert.areEqual(0, MockDml.Updated.getRecords(Lead.SObjectType)?.size(), 'Pre-test: Wrong # of total updates');
		testLead.Company = 'Credicor Inc.';

		Test.startTest();
		new MockDml()?.doUpdate(testLead);
		Test.stopTest();

		// Post-test asserts
		Assert.areEqual(true, MockDml.Updated.wasProcessed(testLead), 'Lead was not processed');
		Lead updatedLead = (Lead) MockDml.Updated.getRecord(testLead);
		Assert.areNotEqual(null, updatedLead, 'Lead was not updated');
		Assert.areEqual(testLead?.Company, updatedLead?.Company, 'Did not update Company');
		Assert.areEqual(1, MockDml.Updated.getRecords(Lead.SObjectType)?.size(), 'Wrong # of lead updates');
		Assert.areEqual(1, MockDml.Updated.getRecords(Lead.SObjectType)?.size(), 'Wrong # of total updates');

		// Callers can also call this method to erase the current history:
		MockDml.eraseAllHistories();
		Assert.areEqual(true, MockDml.Updated.getAll()?.isEmpty(), 'Did not reset history');
	}

	@IsTest
	static void shouldInjectCustomFailureLogic() {
		List<Account> accounts = MockDmlTest.initRecords(Account.SObjectType, false);
		MockDml.ConditionalFailure failure = new MockDmlTest.ExampleFailure();
		Dml dml = new MockDml()?.failIf(failure);

		Test.startTest();
		// Inserts should succeed
		try {
			dml?.doInsert(accounts);
		} catch (System.DmlException error) {
			Assert.fail('An error was thrown');
		}
		// Updates should throw an error
		try {
			dml?.doUpdate(accounts);
			Assert.fail('Did not throw an error');
		} catch (System.DmlException error) {
			// As expected...
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldClearFailures() {
		// The MockDml class provides a way to clear failures from an object
		List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);
		MockDml dml = new MockDml()?.fail();

		Test.startTest();
		// Since the DML object has a failure, it will throw an error when run:
		try {
			dml?.doUpdate(leads);
			Assert.fail('Did not throw an error');
		} catch (System.DmlException error) {
			// As expected...
		}

		// Now clear the failure and try again - an error should NOT be thrown
		dml?.clearFailures();
		try {
			dml?.doUpdate(leads);
		} catch (System.DmlException error) {
			Assert.fail('An error was thrown; failures were not cleared');
		}
		Test.stopTest();
	}

	// **** HELPER **** //
	static List<SObject> initRecords(SObjectType objectType, Boolean withId) {
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

	static List<SObject> initRecords(SObjectType objectType) {
		return MockDmlTest.initRecords(objectType, false);
	}

	// **** INNER **** //
	public class ExampleFailure implements MockDml.ConditionalFailure {
		public Exception checkFailure(Dml.Operation operation, SObject record) {
			// Only throw an error if updating an Account
			Boolean shouldFail =
				operation == Dml.Operation.DO_UPDATE &&
				record?.getSObjectType() == Account.SObjectType;
			return shouldFail ? new System.DmlException() : null;
		}
	}
}
