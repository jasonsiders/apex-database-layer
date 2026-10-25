@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class InvocableDmlEmptyRecycleBinTest {
	static {
		// Custom metadata actually defined in the org should not interfere with this test:
		MockCmdt.mock(DatabaseLayerParameter__mdt.SObjectType);
	}

	// **** TESTS **** //
	@IsTest
	private static void shouldPurgeDeletedRecordsAndReportErrors() {
		List<Account> accounts = new List<Account>{ new Account(Name = 'Deleted'), new Account(Name = 'Live') };
		insert accounts;
		// The 2nd record isn't in the Recycle Bin, so purging it will fail:
		delete accounts?.get(0);
		InvocableDml.Input input = new InvocableDml.Input();
		input.recordCollection = accounts;

		Test.startTest();
		InvocableDml.Output output = InvocableDmlEmptyRecycleBinTest.invoke(input);
		Test.stopTest();

		InvocableDmlResult success = output?.resultCollection?.get(0);
		InvocableDmlResult failure = output?.resultCollection?.get(1);
		Assert.isTrue(success?.isSuccess, 'Valid record failed: ' + success?.errors);
		Assert.areEqual(accounts?.get(0)?.Id, success?.id, 'Result does not match its record');
		// Successful EmptyRecycleBinResults have null errors, unlike other results:
		Assert.isTrue(success?.errors?.isEmpty(), 'Success has errors: ' + success?.errors);
		Assert.isFalse(failure?.isSuccess, 'Invalid record succeeded');
		Assert.isTrue(failure?.errors?.get(0)?.startsWith('INVALID_ID_FIELD: '), 'Wrong error: ' + failure?.errors);
	}

	@IsTest
	private static void shouldUseDatabaseLayer() {
		DatabaseLayer.useMockDml();
		InvocableDml.Input input = new InvocableDml.Input();
		input.record = new Account(Id = MockRecord.initRecordId(Account.SObjectType));

		Test.startTest();
		InvocableDmlEmptyRecycleBinTest.invoke(input);
		Test.stopTest();

		Assert.areEqual(1, MockDml.PURGED?.getRecords(Account.SObjectType)?.size(), 'Wrong # of purged records');
	}

	// **** HELPER **** //
	private static InvocableDml.Output invoke(InvocableDml.Input input) {
		List<InvocableDml.Input> inputs = new List<InvocableDml.Input>{ input };
		return InvocableDmlEmptyRecycleBin.invoke(inputs)?.get(0);
	}
}
