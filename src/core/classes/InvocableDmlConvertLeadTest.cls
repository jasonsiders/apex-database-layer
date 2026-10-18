@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class InvocableDmlConvertLeadTest {
	// **** VARIABLES **** //
	private static final Integer TEST_SIZE = 200;
	private static final String CONVERTED_STATUS = [
		SELECT MasterLabel
		FROM LeadStatus
		WHERE IsConverted = TRUE
		LIMIT 1
	]
	?.MasterLabel;

	static {
		// Custom metadata actually defined in the org should not interfere with this test:
		MockCmdt.mock(DatabaseLayerParameter__mdt.SObjectType);
	}

	// **** TESTS **** //
	@IsTest
	private static void shouldConvertLeadsAndReportErrors() {
		List<Lead> leads = new List<Lead>{
			new Lead(Company = 'Valid', LastName = 'Test'),
			new Lead(Company = 'Invalid', LastName = 'Test')
		};
		insert leads;
		InvocableDmlConvertLead.Input valid = InvocableDmlConvertLeadTest.initInput(leads?.get(0)?.Id);
		valid.allOrNone = false;
		InvocableDmlConvertLead.Input invalid = InvocableDmlConvertLeadTest.initInput(leads?.get(1)?.Id);
		invalid.convertedStatus = 'Not a real status';

		Test.startTest();
		List<InvocableDmlConvertLead.Output> outputs = InvocableDmlConvertLead.invoke(
			new List<InvocableDmlConvertLead.Input>{ valid, invalid }
		);
		Test.stopTest();

		InvocableDmlConvertLead.Output success = outputs?.get(0);
		InvocableDmlConvertLead.Output failure = outputs?.get(1);
		Assert.isTrue(success?.result?.isSuccess, 'Valid lead failed: ' + success?.result?.errors);
		Assert.areEqual(leads?.get(0)?.Id, success?.result?.id, 'Result does not match its lead');
		Assert.isNotNull(success?.accountId, 'No account Id');
		Assert.isNotNull(success?.contactId, 'No contact Id');
		Assert.isNotNull(success?.opportunityId, 'No opportunity Id');
		Assert.isFalse(failure?.result?.isSuccess, 'Invalid lead succeeded');
		Assert.isFalse(failure?.result?.errors?.isEmpty(), 'Failure has no errors');
		Assert.areEqual(1, [SELECT COUNT() FROM Lead WHERE IsConverted = TRUE], 'Wrong # of converted leads');
	}

	@IsTest
	private static void shouldApplyAllOptions() {
		DatabaseLayer.useMockDml();
		DatabaseLayerTestUtils.initDmlAndSoqlPlugins(DatabaseLayerTestUtils.SamplePlugin.class.getName());
		Id leadId = MockRecord.initRecordId(Lead.SObjectType);
		Id ownerId = UserInfo.getUserId();
		InvocableDmlConvertLead.Input input = InvocableDmlConvertLeadTest.initInput(leadId);
		input.accessLevel = 'SYSTEM_MODE';
		input.allOrNone = false;
		input.allowDuplicates = true;
		input.doNotCreateOpportunity = true;
		input.opportunityName = 'Test Opportunity';
		input.overwriteLeadSource = true;
		input.ownerId = ownerId;
		input.runDuplicateRulesAsCurrentUser = true;
		input.sendNotificationEmail = true;

		Test.startTest();
		InvocableDmlConvertLead.Output output = InvocableDmlConvertLead.invoke(
				new List<InvocableDmlConvertLead.Input>{ input }
			)
			?.get(0);
		Test.stopTest();

		Dml.Request request = DatabaseLayerTestUtils.DmlPluginSpy?.lastDmlRequest;
		Database.LeadConvert leadToConvert = request?.leadsToConvert?.get(0);
		Assert.areEqual(Dml.Operation.DO_CONVERT, request?.operation, 'Wrong operation');
		Assert.areEqual(System.AccessLevel.SYSTEM_MODE, request?.accessLevel, 'Wrong access level');
		Assert.isFalse(request?.options?.OptAllOrNone, 'Wrong OptAllOrNone');
		Assert.isTrue(request?.options?.DuplicateRuleHeader?.AllowSave, 'Wrong AllowSave');
		Assert.isTrue(request?.options?.DuplicateRuleHeader?.RunAsCurrentUser, 'Wrong RunAsCurrentUser');
		Assert.areEqual(leadId, leadToConvert?.getLeadId(), 'Wrong lead Id');
		Assert.areEqual(input?.convertedStatus, leadToConvert?.getConvertedStatus(), 'Wrong converted status');
		Assert.isTrue(leadToConvert?.isDoNotCreateOpportunity(), 'Wrong DoNotCreateOpportunity');
		Assert.areEqual('Test Opportunity', leadToConvert?.getOpportunityName(), 'Wrong opportunity name');
		Assert.isTrue(leadToConvert?.isOverwriteLeadSource(), 'Wrong OverwriteLeadSource');
		Assert.areEqual(ownerId, leadToConvert?.getOwnerId(), 'Wrong owner Id');
		Assert.isTrue(leadToConvert?.isSendNotificationEmail(), 'Wrong SendNotificationEmail');
		Assert.isNull(output?.opportunityId, 'Created an opportunity');
	}

	@IsTest
	private static void shouldBulkifyInputs() {
		DatabaseLayer.useMockDml();
		DatabaseLayerTestUtils.initDmlAndSoqlPlugins(DatabaseLayerTestUtils.SamplePlugin.class.getName());
		List<InvocableDmlConvertLead.Input> inputs = new List<InvocableDmlConvertLead.Input>{};
		for (Integer i = 0; i < TEST_SIZE; i++) {
			Id leadId = MockRecord.initRecordId(Lead.SObjectType);
			InvocableDmlConvertLead.Input input = InvocableDmlConvertLeadTest.initInput(leadId);
			inputs?.add(input);
		}

		Test.startTest();
		List<InvocableDmlConvertLead.Output> outputs = InvocableDmlConvertLead.invoke(inputs);
		Test.stopTest();

		Assert.areEqual(1, DatabaseLayerTestUtils.DmlPluginSpy?.numPreCalls, 'Wrong # of DML operations');
		Assert.areEqual(TEST_SIZE, outputs?.size(), 'Wrong # of outputs');
		for (Integer i = 0; i < TEST_SIZE; i++) {
			Assert.areEqual(inputs?.get(i)?.leadId, outputs?.get(i)?.result?.id, 'Output is out of order');
		}
	}

	@IsTest
	private static void shouldDoNothingWithoutInputs() {
		DatabaseLayer.useMockDml();
		DatabaseLayerTestUtils.initDmlAndSoqlPlugins(DatabaseLayerTestUtils.SamplePlugin.class.getName());

		Test.startTest();
		List<InvocableDmlConvertLead.Output> outputs = InvocableDmlConvertLead.invoke(
			new List<InvocableDmlConvertLead.Input>{}
		);
		Test.stopTest();

		Assert.areEqual(0, DatabaseLayerTestUtils.DmlPluginSpy?.numPreCalls, 'Performed DML without inputs');
		Assert.isTrue(outputs?.isEmpty(), 'Wrong outputs: ' + outputs);
	}

	@IsTest
	private static void shouldConstructEmptyOutput() {
		// Flow constructs outputs via their no-arg constructor
		InvocableDmlConvertLead.Output output = new InvocableDmlConvertLead.Output();

		Assert.isFalse(output?.result?.isSuccess, 'Empty output succeeded');
	}

	// **** HELPER **** //
	private static InvocableDmlConvertLead.Input initInput(Id leadId) {
		InvocableDmlConvertLead.Input input = new InvocableDmlConvertLead.Input();
		input.convertedStatus = CONVERTED_STATUS;
		input.leadId = leadId;
		return input;
	}
}
