@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class InvocableDmlUndeleteRecordsTest {
	static {
		// Custom metadata actually defined in the org should not interfere with this test:
		MockCmdt.mock(DatabaseLayerParameter__mdt.SObjectType);
	}

	// **** TESTS **** //
	@IsTest
	private static void shouldUndeleteRecordsAndReportErrors() {
		List<Account> accounts = new List<Account>{ new Account(Name = 'Deleted'), new Account(Name = 'Live') };
		insert accounts;
		// The 2nd record isn't in the Recycle Bin, so undeleting it will fail:
		delete accounts?.get(0);
		InvocableDml.Input input = new InvocableDml.Input();
		input.allOrNone = false;
		input.recordCollection = accounts;

		Test.startTest();
		InvocableDml.Output output = InvocableDmlUndeleteRecordsTest.invoke(input);
		Test.stopTest();

		InvocableDmlResult success = output?.resultCollection?.get(0);
		InvocableDmlResult failure = output?.resultCollection?.get(1);
		Assert.isTrue(success?.isSuccess, 'Valid record failed: ' + success?.errors);
		Assert.areEqual(accounts?.get(0)?.Id, success?.id, 'Result does not match its record');
		Assert.isFalse(failure?.isSuccess, 'Invalid record succeeded');
		Assert.isFalse(failure?.errors?.isEmpty(), 'Failure has no errors');
		Assert.areEqual(2, [SELECT COUNT() FROM Account], 'Valid record was not undeleted');
	}

	@IsTest
	private static void shouldApplySettings() {
		DatabaseLayer.useMockDml();
		DatabaseLayerTestUtils.initDmlAndSoqlPlugins(DatabaseLayerTestUtils.SamplePlugin.class.getName());
		InvocableDml.Input input = new InvocableDml.Input();
		input.accessLevel = 'SYSTEM_MODE';
		input.allOrNone = false;
		input.record = new Account(Id = MockRecord.initRecordId(Account.SObjectType));

		Test.startTest();
		InvocableDmlUndeleteRecordsTest.invoke(input);
		Test.stopTest();

		Dml.Request request = DatabaseLayerTestUtils.DmlPluginSpy?.lastDmlRequest;
		Assert.areEqual(Dml.Operation.DO_UNDELETE, request?.operation, 'Wrong operation');
		Assert.areEqual(System.AccessLevel.SYSTEM_MODE, request?.accessLevel, 'Wrong access level');
		Assert.isFalse(request?.allOrNone, 'Wrong allOrNone');
		Assert.areEqual(1, MockDml.UNDELETED?.getRecords(Account.SObjectType)?.size(), 'Wrong # of undeleted records');
	}

	// **** HELPER **** //
	private static InvocableDml.Output invoke(InvocableDml.Input input) {
		List<InvocableDml.Input> inputs = new List<InvocableDml.Input>{ input };
		return InvocableDmlUndeleteRecords.invoke(inputs)?.get(0);
	}
}
