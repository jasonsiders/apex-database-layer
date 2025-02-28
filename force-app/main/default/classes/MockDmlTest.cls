@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.EmptyCatchBlock')
@IsTest
private class MockDmlTest {
	// **** CONSTANTS **** //
	private static final Integer TEST_SIZE = 20;

	// **** TESTS **** //
	@IsTest
	static void shouldMockLeadConvert() {
		DatabaseLayer.useMockDml();
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
		DatabaseLayer.useMockDml();
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
		DatabaseLayer.useMockDml();
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
			DatabaseLayer.Dml?.doConvert(leadsToConvert);
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
		DatabaseLayer.useMockDml();
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
			DatabaseLayer.Dml?.doConvert(leadsToConvert);
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
		DatabaseLayer.useMockDml()?.fail();

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
		DatabaseLayer.useMockDml()?.fail();

		Test.startTest();
		List<Database.LeadConvertResult> results = DatabaseLayer.Dml.doConvert(leadsToConvert, false);
		Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		Test.stopTest();

		Assert.areEqual(leadsToConvert?.size(), results?.size(), 'Wrong # of results');
		Assert.areEqual(0, MockDml.CONVERTED?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of converted records');
		for (Database.LeadConvertResult result : results) {
			Assert.areEqual(false, result?.isSuccess(), 'Should not have succeeded');
		}
	}

	@IsTest
	static void shouldMockDelete() {
		DatabaseLayer.useMockDml();
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
			Assert.areEqual(true, result?.isSuccess(), 'Should not have succeeded');
		}
	}

	@IsTest
	static void shouldMockDeleteAsync() {
		DatabaseLayer.useMockDml();
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
			Assert.areEqual(true, result?.isSuccess(), 'Should not have succeeded');
		}
	}

	@IsTest
	static void shouldMockDeleteImmediate() {
		DatabaseLayer.useMockDml();
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
			Assert.areEqual(true, result?.isSuccess(), 'Should not have succeeded');
		}
	}

	@IsTest
	static void shouldMockEmptyRecycleBin() {
		DatabaseLayer.useMockDml();
		List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);
		DatabaseLayer.Dml?.doDelete(leads);

		Test.startTest();
		List<Database.EmptyRecycleBinResult> results = DatabaseLayer.Dml?.emptyRecycleBin(leads);
		Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		Test.stopTest();

		Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results');
		Assert.areEqual(results?.size(), MockDml.PURGED?.getRecords(Lead.SObjectType)?.size(), 'Wrong # purged');
		for (Database.EmptyRecycleBinResult result : results) {
			Assert.areEqual(true, result?.isSuccess(), 'Should not have succeeded');
		}
	}

	@IsTest
	static void shouldThrowExceptionIfErrorOnDelete() {
		List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);
		DatabaseLayer.useMockDml()?.fail();

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
		DatabaseLayer.useMockDml()?.fail();

		Test.startTest();
		List<Database.DeleteResult> results = DatabaseLayer.Dml.doDelete(leads, false);
		Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		Test.stopTest();

		Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results');
		Assert.areEqual(0, MockDml.DELETED?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of deleted records');
		for (Database.DeleteResult result : results) {
			Assert.areEqual(false, result?.isSuccess(), 'Should not have succeeded');
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
		}
	}

	@IsTest
	static void shouldMockInsert() {
		DatabaseLayer.useMockDml();
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
			Assert.areEqual(true, result?.isSuccess(), 'Did not succeed: ' + result?.getErrors());
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
		}
	}

	@IsTest
	static void shouldMockInsertAsync() {
		DatabaseLayer.useMockDml();
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
			Assert.areEqual(true, result?.isSuccess(), 'Did not succeed: ' + result?.getErrors());
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
		}
	}

	@IsTest
	static void shouldMockInsertImmediate() {
		DatabaseLayer.useMockDml();
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
			Assert.areEqual(true, result?.isSuccess(), 'Did not succeed: ' + result?.getErrors());
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
		}
	}

	@IsTest
	static void shouldThrowExceptionIfErrorOnInsert() {
		List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType);
		DatabaseLayer.useMockDml()?.fail();

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
		DatabaseLayer.useMockDml()?.fail();

		Test.startTest();
		List<Database.SaveResult> results = DatabaseLayer.Dml.doInsert(leads, false);
		Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		Test.stopTest();

		Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results');
		Assert.areEqual(0, MockDml.INSERTED?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of inserted records');
		for (Database.SaveResult result : results) {
			Assert.areEqual(false, result?.isSuccess(), 'Should not have succeeded');
			Assert.areEqual(null, result?.getId(), 'Insert failed, but has an Id?');
		}
	}

	@IsTest
	static void shouldMockPublish() {
		DatabaseLayer.useMockDml();
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
			Assert.areEqual(true, result?.isSuccess(), 'Did not succeed: ' + result?.getErrors());
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
		}
	}

	@IsTest
	static void shouldThrowExceptionIfErrorOnPublish() {
		List<BatchApexErrorEvent> events = MockDmlTest.initRecords(BatchApexErrorEvent.SObjectType);
		DatabaseLayer.useMockDml()?.fail();

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
		DatabaseLayer.useMockDml()?.fail();

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
			Assert.areEqual(false, result?.isSuccess(), 'Should not have succeeded');
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
		}
	}

	@IsTest
	static void shouldMockUndelete() {
		DatabaseLayer.useMockDml();
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
			Assert.areEqual(true, result?.isSuccess(), 'Did not succeed: ' + result?.getErrors());
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
		}
	}

	@IsTest
	static void shouldThrowExceptionIfErrorOnUndelete() {
		DatabaseLayer.useMockDml()?.fail();
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
		DatabaseLayer.useMockDml()?.fail();

		Test.startTest();
		List<Database.UndeleteResult> results = DatabaseLayer.Dml.doUndelete(leads, false);
		Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		Test.stopTest();

		Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results');
		Assert.areEqual(0, MockDml.UNDELETED?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of undeleted records');
		for (Database.UndeleteResult result : results) {
			Assert.areEqual(false, result?.isSuccess(), 'Should not have succeeded');
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
		}
	}

	@IsTest
	static void shouldMockUpdate() {
		DatabaseLayer.useMockDml();
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
			Assert.areEqual(true, result?.isSuccess(), 'Did not succeed: ' + result?.getErrors());
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
		}
	}

	@IsTest
	static void shouldMockUpdateAsync() {
		DatabaseLayer.useMockDml();
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
			Assert.areEqual(true, result?.isSuccess(), 'Did not succeed: ' + result?.getErrors());
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
		}
	}

	@IsTest
	static void shouldMockUpdateImmediate() {
		DatabaseLayer.useMockDml();
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
			Assert.areEqual(true, result?.isSuccess(), 'Did not succeed: ' + result?.getErrors());
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
		}
	}

	@IsTest
	static void shouldThrowExceptionIfErrorOnUpdate() {
		DatabaseLayer.useMockDml()?.fail();
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
		DatabaseLayer.useMockDml()?.fail();
		List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);

		Test.startTest();
		List<Database.SaveResult> results = DatabaseLayer.Dml.doUpdate(leads, false);
		Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		Test.stopTest();

		Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results');
		Assert.areEqual(0, MockDml.UPDATED?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of updated records');
		for (Database.SaveResult result : results) {
			Assert.areEqual(false, result?.isSuccess(), 'Should not have succeeded');
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
		}
	}

	@IsTest
	static void shouldMockUpsert() {
		DatabaseLayer.useMockDml();
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
			Assert.areEqual(true, result?.isSuccess(), 'Did not succeed: ' + result?.getErrors());
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
		}
	}

	@IsTest
	static void shouldThrowExceptionIfErrorOnUpsert() {
		DatabaseLayer.useMockDml()?.fail();
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
		DatabaseLayer.useMockDml()?.fail();
		List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);

		Test.startTest();
		List<Database.UpsertResult> results = DatabaseLayer.Dml.doUpsert(leads, false);
		Assert.areEqual(0, Limits.getDmlStatements(), 'Performed actual DML');
		Test.stopTest();

		Assert.areEqual(leads?.size(), results?.size(), 'Wrong # of results');
		Assert.areEqual(0, MockDml.UPSERTED?.getRecords(Lead.SObjectType)?.size(), 'Wrong # of upserted records');
		for (Database.UpsertResult result : results) {
			Assert.areEqual(false, result?.isSuccess(), 'Should not have succeeded');
			Assert.areNotEqual(null, result?.getId(), 'Missing Id');
		}
	}

	@IsTest
	static void shouldProvideUsefulInformationAboutProcessedRecords() {
		DatabaseLayer.useMockDml();
		Lead testLead = (Lead) new MockRecord(Lead.SObjectType)?.withId()?.toSObject();
		// Pre-test asserts
		Assert.areEqual(false, MockDml.UPDATED.wasProcessed(testLead), 'Pre-test: Should not have been processed');
		Assert.areEqual(null, MockDml.UPDATED.getRecord(testLead), 'Pre-test: Lead was processed');
		Assert.areEqual(0, MockDml.UPDATED.getRecords(Lead.SObjectType)?.size(), 'Pre-test: Wrong # of lead updates');
		Assert.areEqual(0, MockDml.UPDATED.getRecords(Lead.SObjectType)?.size(), 'Pre-test: Wrong # of total updates');
		testLead.Company = 'Credicor Inc.';

		Test.startTest();
		DatabaseLayer.Dml?.doUpdate(testLead);
		Test.stopTest();

		// Post-test asserts
		Assert.areEqual(true, MockDml.UPDATED.wasProcessed(testLead), 'Lead was not processed');
		Lead updatedLead = (Lead) MockDml.UPDATED.getRecord(testLead);
		Assert.areNotEqual(null, updatedLead, 'Lead was not updated');
		Assert.areEqual(testLead?.Company, updatedLead?.Company, 'Did not update Company');
		Assert.areEqual(1, MockDml.UPDATED.getRecords(Lead.SObjectType)?.size(), 'Wrong # of lead updates');
		Assert.areEqual(1, MockDml.UPDATED.getRecords(Lead.SObjectType)?.size(), 'Wrong # of total updates');

		// Callers can also call this method to erase the current history:
		MockDml.eraseAllHistories();
		Assert.areEqual(true, MockDml.UPDATED.getAll()?.isEmpty(), 'Did not reset history');
	}

	@IsTest
	static void shouldInjectCustomFailureLogic() {
		List<Account> accounts = MockDmlTest.initRecords(Account.SObjectType, false);
		MockDml.ConditionalFailure failure = new MockDmlTest.ExampleFailure(
			MockDml.Operation.DO_UPDATE,
			Account.SObjectType
		);
		DatabaseLayer.useMockDml().failIf(failure);

		Test.startTest();
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
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldClearFailures() {
		// The MockDml class provides a way to clear failures from an object
		List<Lead> leads = MockDmlTest.initRecords(Lead.SObjectType, true);
		MockDml mockDml = DatabaseLayer.useMockDml()?.fail();

		Test.startTest();
		// Since the DML object has a failure, it will throw an error when run:
		try {
			mockDml?.doUpdate(leads);
			Assert.fail('Did not throw an error');
		} catch (System.DmlException error) {
			// As expected...
		}

		// Now clear the failure and try again - an error should NOT be thrown
		mockDml?.clearFailures();
		try {
			mockDml?.doUpdate(leads);
		} catch (System.DmlException error) {
			Assert.fail('An error was thrown; failures were not cleared');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldGetAllRecordsFromHistory() {
		DatabaseLayer.useMockDml();
		List<Account> accounts = MockDmlTest.initRecords(Account.SObjectType, false);
		DatabaseLayer.Dml.doInsert(accounts);

		Test.startTest();
		Map<SObjectType, List<SObject>> results = MockDml.INSERTED.getAll();
		Test.stopTest();

		Assert.areEqual(true, results?.containsKey(Account.SObjectType), 'No Accounts inserted');
		Assert.areEqual(accounts?.size(), results?.get(Account.SObjectType)?.size(), 'Wrong # of Accounts inserted');
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
		private MockDml.Operation failingOperation;
		private SObjectType failingSObjectType;

		public ExampleFailure(MockDml.Operation operation, SObjectType objectType) {
			this.failingOperation = operation;
			this.failingSObjectType = objectType;
		}

		public Exception checkFailure(MockDml.Operation operation, SObject record) {
			// Only throw an error if updating an Account
			Boolean shouldFail =
				operation == this.failingOperation &&
				record?.getSObjectType() == this.failingSObjectType;
			return (shouldFail) ? new System.DmlException() : null;
		}
	}
}
