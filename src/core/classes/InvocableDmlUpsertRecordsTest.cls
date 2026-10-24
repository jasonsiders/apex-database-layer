@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class InvocableDmlUpsertRecordsTest {
	static {
		// Custom metadata actually defined in the org should not interfere with this test:
		MockCmdt.mock(DatabaseLayerParameter__mdt.SObjectType);
	}

	// **** TESTS **** //
	@IsTest
	private static void shouldUpsertRecords() {
		Account existing = new Account(Name = 'Before');
		insert existing;
		existing.Name = 'After';
		InvocableDml.Input input = new InvocableDml.Input();
		input.recordCollection = new List<Account>{ existing, new Account(Name = 'New') };

		Test.startTest();
		InvocableDml.Output output = InvocableDmlUpsertRecordsTest.invoke(input);
		Test.stopTest();

		InvocableDmlResult updated = output?.resultCollection?.get(0);
		InvocableDmlResult created = output?.resultCollection?.get(1);
		Assert.isTrue(updated?.isSuccess, 'Existing record failed: ' + updated?.errors);
		Assert.isFalse(updated?.isCreated, 'Existing record was created');
		Assert.areEqual(existing?.Id, updated?.id, 'Result does not match its record');
		Assert.isTrue(created?.isSuccess, 'New record failed: ' + created?.errors);
		Assert.isTrue(created?.isCreated, 'New record was not created');
		Assert.isNotNull(output?.recordCollection?.get(1)?.Id, 'New record was not assigned an Id');
		Assert.areEqual(2, [SELECT COUNT() FROM Account WHERE Name IN ('After', 'New')], 'Wrong # of upserted records');
	}

	@IsTest
	private static void shouldApplySettingsAndExternalIdField() {
		DatabaseLayer.useMockDml();
		DatabaseLayerTestUtils.initDmlAndSoqlPlugins(DatabaseLayerTestUtils.SamplePlugin.class.getName());
		InvocableDml.Input input = new InvocableDml.Input();
		input.accessLevel = 'SYSTEM_MODE';
		input.allOrNone = false;
		// Field names are trimmed and case-insensitive:
		input.externalIdField = ' id ';
		input.record = new Account(Name = 'Test');

		Test.startTest();
		InvocableDmlUpsertRecordsTest.invoke(input);
		Test.stopTest();

		Dml.Request request = DatabaseLayerTestUtils.DmlPluginSpy?.lastDmlRequest;
		Assert.areEqual(Dml.Operation.DO_UPSERT, request?.operation, 'Wrong operation');
		Assert.areEqual(System.AccessLevel.SYSTEM_MODE, request?.accessLevel, 'Wrong access level');
		Assert.isFalse(request?.allOrNone, 'Wrong allOrNone');
		Assert.areEqual(Account.Id, request?.externalIdField, 'Wrong external ID field');
	}

	@IsTest
	private static void shouldThrowOnUnknownExternalIdField() {
		DatabaseLayer.useMockDml();
		InvocableDml.Input input = new InvocableDml.Input();
		input.externalIdField = 'Not_A_Real_Field__c';
		input.record = new Account(Name = 'Test');

		Test.startTest();
		Exception caughtError;
		try {
			InvocableDmlUpsertRecordsTest.invoke(input);
		} catch (System.IllegalArgumentException error) {
			caughtError = error;
		}
		Test.stopTest();

		Assert.isNotNull(caughtError, 'Did not throw a System.IllegalArgumentException');
		Assert.isTrue(MockDml.UPSERTED?.getRecords(Account.SObjectType)?.isEmpty(), 'Upserted on the wrong field');
	}

	@IsTest
	private static void shouldListMatchFields() {
		Test.startTest();
		List<InvocableDmlUpsertRecords.MatchField> matchFields = InvocableDmlUpsertRecords.getMatchFields('Contact');
		Test.stopTest();

		Map<String, InvocableDmlUpsertRecords.MatchField> fieldsByName = new Map<String, InvocableDmlUpsertRecords.MatchField>{};
		for (InvocableDmlUpsertRecords.MatchField matchField : matchFields) {
			fieldsByName?.put(matchField?.apiName, matchField);
		}
		// Contact.Email is a standard ID lookup field in every org:
		InvocableDmlUpsertRecords.MatchField email = fieldsByName?.get('Email');
		Assert.areEqual(Contact.Email.getDescribe().getLabel(), email?.label, 'Wrong label for Email');
		Assert.isFalse(email?.isExternalId, 'Email is not an external ID');
		Assert.isFalse(fieldsByName?.containsKey('Id'), 'Listed Id, which the editor offers separately');
		Assert.isFalse(fieldsByName?.containsKey('LastName'), 'Listed a field that upserts cannot match on');
	}

	@IsTest
	private static void shouldThrowAuraHandledExceptionForUnknownObject() {
		Test.startTest();
		Exception caughtError;
		try {
			InvocableDmlUpsertRecords.getMatchFields('Not_A_Real_Object__c');
		} catch (System.AuraHandledException error) {
			caughtError = error;
		}
		Test.stopTest();

		Assert.isNotNull(caughtError, 'Did not throw a System.AuraHandledException');
	}

	// **** HELPER **** //
	private static InvocableDml.Output invoke(InvocableDml.Input input) {
		List<InvocableDml.Input> inputs = new List<InvocableDml.Input>{ input };
		return InvocableDmlUpsertRecords.invoke(inputs)?.get(0);
	}
}
