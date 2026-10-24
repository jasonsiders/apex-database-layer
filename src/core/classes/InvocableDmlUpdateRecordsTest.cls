@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class InvocableDmlUpdateRecordsTest {
	static {
		// Custom metadata actually defined in the org should not interfere with this test:
		MockCmdt.mock(DatabaseLayerParameter__mdt.SObjectType);
	}

	// **** TESTS **** //
	@IsTest
	private static void shouldUpdateRecordsAndReportErrors() {
		Account valid = new Account(Name = 'Before');
		Account invalid = new Account(Name = 'Before');
		List<Account> accounts = new List<Account>{ valid, invalid };
		insert accounts;
		valid.Name = 'After';
		// Account.Name is required, so the 2nd record will fail:
		invalid.Name = null;
		InvocableDml.Input input = new InvocableDml.Input();
		input.allOrNone = false;
		input.recordCollection = accounts;

		Test.startTest();
		InvocableDml.Output output = InvocableDmlUpdateRecordsTest.invoke(input);
		Test.stopTest();

		InvocableDmlResult success = output?.resultCollection?.get(0);
		InvocableDmlResult failure = output?.resultCollection?.get(1);
		Assert.isTrue(success?.isSuccess, 'Valid record failed: ' + success?.errors);
		Assert.areEqual(accounts?.get(0)?.Id, success?.id, 'Result does not match its record');
		Assert.isFalse(failure?.isSuccess, 'Invalid record succeeded');
		Assert.isTrue(
			failure?.errors?.get(0)?.startsWith('REQUIRED_FIELD_MISSING: '),
			'Wrong error: ' + failure?.errors
		);
		Assert.areEqual(1, [SELECT COUNT() FROM Account WHERE Name = 'After'], 'Valid record was not updated');
	}

	@IsTest
	private static void shouldMergeRecordsSharedByInputs() {
		Account parent = new Account(Name = 'Before');
		insert parent;
		InvocableDml.Input nameInput = new InvocableDml.Input();
		nameInput.record = new Account(Id = parent?.Id, Name = 'After');
		InvocableDml.Input phoneInput = new InvocableDml.Input();
		phoneInput.record = new Account(Id = parent?.Id, Phone = '555-0100');
		List<InvocableDml.Input> inputs = new List<InvocableDml.Input>{ nameInput, phoneInput };

		Test.startTest();
		// A DML operation would throw on the duplicate Id, and fail both interviews:
		List<InvocableDml.Output> outputs = InvocableDmlUpdateRecords.invoke(inputs);
		Test.stopTest();

		for (InvocableDml.Output output : outputs) {
			Assert.isTrue(output?.result?.isSuccess, 'Shared record failed: ' + output?.result?.errors);
			Assert.areEqual(parent?.Id, output?.result?.id, 'Result does not match its record');
		}
		Account updated = [SELECT Name, Phone FROM Account WHERE Id = :parent.Id];
		Assert.areEqual('After', updated?.Name, 'Lost the 1st input\'s change');
		Assert.areEqual('555-0100', updated?.Phone, 'Lost the 2nd input\'s change');
	}

	@IsTest
	private static void shouldMergeRecordsWithReadOnlyFields() {
		Account parent = new Account(Name = 'Before');
		insert parent;
		insert new Contact(AccountId = parent?.Id, LastName = 'Test');
		Account phoneUpdate = new Account(Id = parent?.Id, Phone = '555-0100');
		// Like a Get Records result, with audit fields and child records Apex can't set
		Account nameUpdate = InvocableDmlUpdateRecordsTest.queryWithReadOnlyFields(parent?.Id);
		nameUpdate.Name = 'After';
		List<InvocableDml.Input> inputs = new List<InvocableDml.Input>{};
		for (Account record : new List<Account>{ phoneUpdate, nameUpdate }) {
			InvocableDml.Input input = new InvocableDml.Input();
			input.record = record;
			inputs?.add(input);
		}

		Test.startTest();
		List<InvocableDml.Output> outputs = InvocableDmlUpdateRecords.invoke(inputs);
		Test.stopTest();

		for (InvocableDml.Output output : outputs) {
			Assert.isTrue(output?.result?.isSuccess, 'Shared record failed: ' + output?.result?.errors);
		}
		Account updated = [SELECT Name, Phone FROM Account WHERE Id = :parent.Id];
		Assert.areEqual('After', updated?.Name, 'Lost the 1st input\'s change');
		Assert.areEqual('555-0100', updated?.Phone, 'Lost the 2nd input\'s change');
	}

	@IsTest
	private static void shouldApplyAllOptions() {
		DatabaseLayer.useMockDml();
		DatabaseLayerTestUtils.initDmlAndSoqlPlugins(DatabaseLayerTestUtils.SamplePlugin.class.getName());
		InvocableDml.Input input = new InvocableDml.Input();
		input.accessLevel = 'SYSTEM_MODE';
		input.allOrNone = false;
		input.allowFieldTruncation = true;
		input.record = new Account(Id = MockRecord.initRecordId(Account.SObjectType), Name = 'Test');

		Test.startTest();
		InvocableDmlUpdateRecordsTest.invoke(input);
		Test.stopTest();

		Dml.Request request = DatabaseLayerTestUtils.DmlPluginSpy?.lastDmlRequest;
		Assert.areEqual(Dml.Operation.DO_UPDATE, request?.operation, 'Wrong operation');
		Assert.areEqual(System.AccessLevel.SYSTEM_MODE, request?.accessLevel, 'Wrong access level');
		Assert.isFalse(request?.options?.OptAllOrNone, 'Wrong OptAllOrNone');
		Assert.isTrue(request?.options?.AllowFieldTruncation, 'Wrong AllowFieldTruncation');
		Assert.areEqual(1, MockDml.UPDATED?.getRecords(Account.SObjectType)?.size(), 'Wrong # of updated records');
	}

	// **** HELPER **** //
	private static InvocableDml.Output invoke(InvocableDml.Input input) {
		List<InvocableDml.Input> inputs = new List<InvocableDml.Input>{ input };
		return InvocableDmlUpdateRecords.invoke(inputs)?.get(0);
	}

	private static Account queryWithReadOnlyFields(Id accountId) {
		return [
			SELECT Id, Name, CreatedDate, LastModifiedDate, (SELECT Id FROM Contacts)
			FROM Account
			WHERE Id = :accountId
		];
	}
}
