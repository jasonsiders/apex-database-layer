@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class InvocableDmlInsertRecordsTest {
	// **** VARIABLES **** //
	private static final Integer TEST_SIZE = 200;

	static {
		// Custom metadata actually defined in the org should not interfere with this test:
		MockCmdt.mock(DatabaseLayerParameter__mdt.SObjectType);
	}

	// **** TESTS **** //
	@IsTest
	private static void shouldInsertRecordCollection() {
		DatabaseLayer.useMockDml();
		InvocableDml.Input input = new InvocableDml.Input();
		input.recordCollection = InvocableDmlInsertRecordsTest.initAccounts(3);

		Test.startTest();
		InvocableDml.Output output = InvocableDmlInsertRecordsTest.invoke(input);
		Test.stopTest();

		Assert.areEqual(3, output?.recordCollection?.size(), 'Wrong # of records');
		Assert.areEqual(3, output?.resultCollection?.size(), 'Wrong # of results');
		Assert.areEqual(3, MockDml.INSERTED?.getRecords(Account.SObjectType)?.size(), 'Wrong # of inserted records');
		for (Integer i = 0; i < output?.recordCollection?.size(); i++) {
			SObject record = output?.recordCollection?.get(i);
			InvocableDmlResult result = output?.resultCollection?.get(i);
			Assert.isNotNull(record?.Id, 'Record was not assigned an Id');
			Assert.areEqual(record?.Id, result?.id, 'Result does not match its record');
			Assert.isTrue(result?.isSuccess, 'Result was not successful');
			Assert.isTrue(result?.errors?.isEmpty(), 'Result has errors: ' + result?.errors);
		}
		Assert.areEqual(output?.recordCollection?.get(0), output?.record, 'Wrong single record');
		Assert.areEqual(output?.resultCollection?.get(0), output?.result, 'Wrong single result');
	}

	@IsTest
	private static void shouldInsertSingleRecord() {
		DatabaseLayer.useMockDml();
		InvocableDml.Input input = new InvocableDml.Input();
		input.record = InvocableDmlInsertRecordsTest.initAccounts(1)?.get(0);

		Test.startTest();
		InvocableDml.Output output = InvocableDmlInsertRecordsTest.invoke(input);
		Test.stopTest();

		Assert.isNotNull(output?.record?.Id, 'Record was not assigned an Id');
		Assert.areEqual(output?.record?.Id, output?.result?.id, 'Result does not match its record');
		Assert.isTrue(output?.result?.isSuccess, 'Result was not successful');
		Assert.areEqual(1, output?.recordCollection?.size(), 'Wrong # of records');
		Assert.areEqual(1, output?.resultCollection?.size(), 'Wrong # of results');
	}

	@IsTest
	private static void shouldDoNothingWithoutRecords() {
		DatabaseLayer.useMockDml();
		DatabaseLayerTestUtils.initDmlAndSoqlPlugins(DatabaseLayerTestUtils.SamplePlugin.class.getName());
		InvocableDml.Input input = new InvocableDml.Input();

		Test.startTest();
		InvocableDml.Output output = InvocableDmlInsertRecordsTest.invoke(input);
		Test.stopTest();

		Assert.areEqual(0, DatabaseLayerTestUtils.DmlPluginSpy?.numPreCalls, 'Performed DML without records');
		Assert.isNull(output?.record, 'Wrong single record');
		Assert.isNull(output?.result, 'Wrong single result');
		Assert.isTrue(output?.recordCollection?.isEmpty(), 'Wrong records: ' + output?.recordCollection);
		Assert.isTrue(output?.resultCollection?.isEmpty(), 'Wrong results: ' + output?.resultCollection);
	}

	@IsTest
	private static void shouldReportErrorsWhenNotAllOrNone() {
		InvocableDml.Input input = new InvocableDml.Input();
		input.allOrNone = false;
		// Contact.LastName is required, so the 2nd record will fail:
		input.recordCollection = new List<Contact>{ new Contact(LastName = 'Valid'), new Contact() };

		Test.startTest();
		InvocableDml.Output output = InvocableDmlInsertRecordsTest.invoke(input);
		Test.stopTest();

		InvocableDmlResult success = output?.resultCollection?.get(0);
		InvocableDmlResult failure = output?.resultCollection?.get(1);
		Assert.isTrue(success?.isSuccess, 'Valid record failed: ' + success?.errors);
		Assert.isNotNull(success?.id, 'Valid record has no Id');
		Assert.isFalse(failure?.isSuccess, 'Invalid record succeeded');
		Assert.isNull(failure?.id, 'Invalid record has an Id');
		Assert.areEqual(1, failure?.errors?.size(), 'Wrong # of errors: ' + failure?.errors);
		String error = failure?.errors?.get(0);
		Assert.isTrue(error?.startsWith('REQUIRED_FIELD_MISSING: '), 'Missing status code: ' + error);
		Assert.isTrue(error?.endsWith(' (LastName)'), 'Missing field names: ' + error);
		Assert.areEqual(1, [SELECT COUNT() FROM Contact], 'Wrong # of inserted contacts');
	}

	@IsTest
	private static void shouldThrowWhenAllOrNone() {
		DatabaseLayer.useMockDml();
		MockDml.shouldFail();
		InvocableDml.Input input = new InvocableDml.Input();
		input.recordCollection = InvocableDmlInsertRecordsTest.initAccounts(1);

		Test.startTest();
		Exception caughtError;
		try {
			InvocableDmlInsertRecordsTest.invoke(input);
		} catch (System.DmlException error) {
			caughtError = error;
		}
		Test.stopTest();

		Assert.isNotNull(caughtError, 'Did not throw a System.DmlException');
	}

	@IsTest
	private static void shouldDefaultToUserModeAndAllOrNone() {
		DatabaseLayer.useMockDml();
		DatabaseLayerTestUtils.initDmlAndSoqlPlugins(DatabaseLayerTestUtils.SamplePlugin.class.getName());
		InvocableDml.Input input = new InvocableDml.Input();
		input.recordCollection = InvocableDmlInsertRecordsTest.initAccounts(1);

		Test.startTest();
		InvocableDmlInsertRecordsTest.invoke(input);
		Test.stopTest();

		Dml.Request request = DatabaseLayerTestUtils.DmlPluginSpy?.lastDmlRequest;
		Assert.areEqual(System.AccessLevel.USER_MODE, request?.accessLevel, 'Wrong access level');
		Assert.isTrue(request?.allOrNone, 'Wrong allOrNone');
		Assert.isFalse(request?.options?.AllowFieldTruncation, 'Wrong AllowFieldTruncation');
	}

	@IsTest
	private static void shouldApplyAllOptions() {
		DatabaseLayer.useMockDml();
		DatabaseLayerTestUtils.initDmlAndSoqlPlugins(DatabaseLayerTestUtils.SamplePlugin.class.getName());
		Id assignmentRuleId = MockRecord.initRecordId(Schema.SObjectType.AssignmentRule.getSObjectType());
		InvocableDml.Input input = new InvocableDml.Input();
		input.recordCollection = InvocableDmlInsertRecordsTest.initAccounts(1);
		input.accessLevel = 'system_mode';
		input.allOrNone = false;
		input.allowDuplicates = true;
		input.allowFieldTruncation = true;
		input.assignmentRuleId = assignmentRuleId;
		input.localeOptions = 'en_US';
		input.runDuplicateRulesAsCurrentUser = true;
		input.triggerAutoResponseEmail = true;
		input.triggerOtherEmail = true;
		input.triggerUserEmail = true;
		input.useDefaultAssignmentRule = true;

		Test.startTest();
		InvocableDmlInsertRecordsTest.invoke(input);
		Test.stopTest();

		Dml.Request request = DatabaseLayerTestUtils.DmlPluginSpy?.lastDmlRequest;
		Database.DmlOptions options = request?.options;
		Assert.areEqual(System.AccessLevel.SYSTEM_MODE, request?.accessLevel, 'Wrong access level');
		Assert.isFalse(options?.OptAllOrNone, 'Wrong OptAllOrNone');
		Assert.isTrue(options?.AllowFieldTruncation, 'Wrong AllowFieldTruncation');
		Assert.areEqual('en_US', options?.LocaleOptions, 'Wrong LocaleOptions');
		Assert.areEqual(assignmentRuleId, options?.AssignmentRuleHeader?.AssignmentRuleId, 'Wrong AssignmentRuleId');
		Assert.isTrue(options?.AssignmentRuleHeader?.UseDefaultRule, 'Wrong UseDefaultRule');
		Assert.isTrue(options?.DuplicateRuleHeader?.AllowSave, 'Wrong AllowSave');
		Assert.isTrue(options?.DuplicateRuleHeader?.RunAsCurrentUser, 'Wrong RunAsCurrentUser');
		Assert.isTrue(options?.EmailHeader?.TriggerAutoResponseEmail, 'Wrong TriggerAutoResponseEmail');
		Assert.isTrue(options?.EmailHeader?.TriggerOtherEmail, 'Wrong TriggerOtherEmail');
		Assert.isTrue(options?.EmailHeader?.TriggerUserEmail, 'Wrong TriggerUserEmail');
	}

	@IsTest
	private static void shouldRunInvalidAccessLevelInUserMode() {
		DatabaseLayer.useMockDml();
		DatabaseLayerTestUtils.initDmlAndSoqlPlugins(DatabaseLayerTestUtils.SamplePlugin.class.getName());
		InvocableDml.Input input = new InvocableDml.Input();
		input.accessLevel = 'Not a real access level';
		input.recordCollection = InvocableDmlInsertRecordsTest.initAccounts(1);

		Test.startTest();
		InvocableDmlInsertRecordsTest.invoke(input);
		Test.stopTest();

		Dml.Request request = DatabaseLayerTestUtils.DmlPluginSpy?.lastDmlRequest;
		Assert.areEqual(System.AccessLevel.USER_MODE, request?.accessLevel, 'Wrong access level');
	}

	@IsTest
	private static void shouldBulkifyInputs() {
		DatabaseLayer.useMockDml();
		DatabaseLayerTestUtils.initDmlAndSoqlPlugins(DatabaseLayerTestUtils.SamplePlugin.class.getName());
		List<InvocableDml.Input> inputs = new List<InvocableDml.Input>();
		for (Account account : InvocableDmlInsertRecordsTest.initAccounts(TEST_SIZE)) {
			InvocableDml.Input input = new InvocableDml.Input();
			input.record = account;
			inputs.add(input);
		}

		Test.startTest();
		List<InvocableDml.Output> outputs = InvocableDmlInsertRecords.invoke(inputs);
		Test.stopTest();

		Assert.areEqual(1, DatabaseLayerTestUtils.DmlPluginSpy?.numPreCalls, 'Wrong # of DML operations');
		Assert.areEqual(TEST_SIZE, outputs?.size(), 'Wrong # of outputs');
		for (Integer i = 0; i < TEST_SIZE; i++) {
			InvocableDml.Output output = outputs?.get(i);
			Assert.areEqual(inputs?.get(i)?.record, output?.record, 'Output is out of order');
			Assert.areEqual(output?.record?.Id, output?.result?.id, 'Result does not match its record');
		}
	}

	@IsTest
	private static void shouldApplyFirstInputSettingsToAllInputs() {
		DatabaseLayer.useMockDml();
		DatabaseLayerTestUtils.initDmlAndSoqlPlugins(DatabaseLayerTestUtils.SamplePlugin.class.getName());
		InvocableDml.Input userMode = new InvocableDml.Input();
		userMode.recordCollection = InvocableDmlInsertRecordsTest.initAccounts(2);
		InvocableDml.Input systemMode = new InvocableDml.Input();
		systemMode.accessLevel = 'SYSTEM_MODE';
		systemMode.recordCollection = InvocableDmlInsertRecordsTest.initAccounts(3);
		List<InvocableDml.Input> inputs = new List<InvocableDml.Input>{ userMode, systemMode };

		Test.startTest();
		List<InvocableDml.Output> outputs = InvocableDmlInsertRecords.invoke(inputs);
		Test.stopTest();

		Dml.Request request = DatabaseLayerTestUtils.DmlPluginSpy?.lastDmlRequest;
		Assert.areEqual(1, DatabaseLayerTestUtils.DmlPluginSpy?.numPreCalls, 'Wrong # of DML operations');
		Assert.areEqual(System.AccessLevel.USER_MODE, request?.accessLevel, 'Did not use the first input settings');
		Assert.areEqual(2, outputs?.get(0)?.resultCollection?.size(), 'Wrong # of results for the first input');
		Assert.areEqual(3, outputs?.get(1)?.resultCollection?.size(), 'Wrong # of results for the second input');
		Assert.areEqual(
			outputs?.get(1)?.recordCollection?.get(2)?.Id,
			outputs?.get(1)?.resultCollection?.get(2)?.id,
			'Result does not match its record'
		);
	}

	// **** HELPER **** //
	private static List<Account> initAccounts(Integer numRecords) {
		List<Account> accounts = new List<Account>();
		for (Integer i = 0; i < numRecords; i++) {
			accounts.add(new Account(Name = 'Test Account #' + i));
		}
		return accounts;
	}

	private static InvocableDml.Output invoke(InvocableDml.Input input) {
		List<InvocableDml.Input> inputs = new List<InvocableDml.Input>{ input };
		return InvocableDmlInsertRecords.invoke(inputs)?.get(0);
	}
}
