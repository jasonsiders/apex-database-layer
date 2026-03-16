@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class DatabaseLayerUtilsTest {
	@IsTest
	private static void shouldGetChildRelationshipFromLookupField() {
		SObjectField field = Contact.AccountId;

		Test.startTest();
		Schema.ChildRelationship relationship = DatabaseLayer.Utils.ChildRelationships.getChildRelationshipFrom(field);
		Test.stopTest();

		Assert.areEqual(field, relationship?.getField(), 'Relationship does not point to ' + field);
	}

	@IsTest
	private static void shouldGetChildRelationshipFromPolymorphicLookupField() {
		SObjectField field = Task.WhoId; // Polymorphic! Can be a reference to Contact.Tasks OR Lead.Tasks
		SObjectType referenceTo = Lead.SObjectType; // ...in this case, we want Lead.Tasks

		Test.startTest();
		Schema.ChildRelationship relationship = DatabaseLayer.Utils.ChildRelationships.getChildRelationshipFrom(
			field,
			referenceTo
		);
		Test.stopTest();

		Assert.areEqual(field, relationship?.getField(), 'Relationship does not point to ' + field);
	}

	@IsTest
	private static void shouldReturnChildRelationshipsUnderHighStress() {
		// The operation to retrieve Schema.ChildRelationships from an object can be expensive,
		// so the class internally caches these results via an inner class.
		// Successive calls to retrieve the same SObjectType's relationships
		// should have similar performance implications as calling it once.
		SObjectField field = Contact.AccountId;
		DatabaseLayer.Utils.ChildRelationships.getChildRelationshipFrom(field);
		Integer firstTime = Limits.getCpuTime();

		for (Integer i = 0; i < 10; i++) {
			Integer start = Limits.getCpuTime();
			DatabaseLayer.Utils.ChildRelationships.getChildRelationshipFrom(field);
			Integer thisTime = Limits.getCpuTime() - start;
			Assert.areEqual(
				true,
				thisTime < firstTime,
				'Took longer than initial call: ' + new List<Integer>{ firstTime, thisTime }
			);
		}
	}

	@IsTest
	private static void shouldReturnNullChildRelationshipIfNotLookupField() {
		SObjectField field = Contact.CreatedDate;

		Test.startTest();
		Schema.ChildRelationship relationship = DatabaseLayer.Utils.ChildRelationships.getChildRelationshipFrom(field);
		Test.stopTest();

		Assert.areEqual(null, relationship, 'Non-lookup field returned a relationship anyways');
	}

	@IsTest
	private static void shouldReturnWhateverMetadataIsDefinedInOrg() {
		// Verify that getParameter() retrieves real org data without using SOQL:
		String parameterName = 'DmlPreAndPostProcessor';
		String expected = DatabaseLayerParameter__mdt.getInstance(parameterName)?.Value__c;
		DatabaseLayerUtils utils = DatabaseLayer.Utils;

		Test.startTest();
		String result = utils?.getParameter(parameterName);
		Assert.areEqual(0, Limits.getQueries(), 'Should not retrieve CMDT via SOQL');
		Test.stopTest();

		Assert.areEqual(expected, result, 'Wrong DatabaseLayerParameter__mdt value');
	}

	@IsTest
	private static void shouldReturnMockedMetadata() {
		// To force your test to use a specific DatabaseLayerParameter__mdt record, add it to the mock:
		String parameterName = 'Test_123';
		DatabaseLayerParameter__mdt mockParam = new DatabaseLayerParameter__mdt(
			DeveloperName = parameterName,
			Value__c = 'TestValue'
		);
		MockCmdt.mock(DatabaseLayerParameter__mdt.SObjectType)?.add(mockParam);

		Test.startTest();
		String result = DatabaseLayer.Utils.getParameter(parameterName);
		Assert.areEqual(0, Limits.getQueries(), 'Should not retrieve CMDT via SOQL');
		Test.stopTest();

		Assert.areEqual(mockParam?.Value__c, result, 'Wrong parameter value');
	}

	@IsTest
	private static void shouldReturnNullIfMockedEmtpyList() {
		// Define an empty mock to ignore any defined DatabaseLayerParameter__mdt records in an org:
		MockCmdt.mock(DatabaseLayerParameter__mdt.SObjectType);

		Test.startTest();
		String result = DatabaseLayer.Utils.getParameter('DmlPreAndPostProcessor');
		Assert.areEqual(0, Limits.getQueries(), 'Should not retrieve CMDT via SOQL');
		Test.stopTest();

		Assert.isNull(result, 'Should not have returned a parameter value');
	}

	@IsTest
	private static void shouldInitPluginObjectFromCustomMetadata() {
		String parameterName = 'DmlPreAndPostProcessor';
		DatabaseLayerParameter__mdt mockParam = new DatabaseLayerParameter__mdt(
			DeveloperName = parameterName,
			Value__c = DatabaseLayerTestUtils.SamplePlugin.class.getName()
		);
		MockCmdt.mock(DatabaseLayerParameter__mdt.SObjectType)?.add(mockParam);

		Test.startTest();
		Dml.PreAndPostProcessor example = (Dml.PreAndPostProcessor) DatabaseLayer.Utils.Plugins.initPlugin(
			parameterName
		);
		Test.stopTest();

		Assert.isNotNull(example, 'Did not generate an object from CMDT');
	}

	@IsTest
	private static void shouldReturnNullPluginIfPluginNotConstructable() {
		String parameterName = 'DmlPreAndPostProcessor';
		DatabaseLayerParameter__mdt mockParam = new DatabaseLayerParameter__mdt(
			DeveloperName = parameterName,
			Value__c = 'Soql' // No public 0-arg constructor
		);
		MockCmdt.mock(DatabaseLayerParameter__mdt.SObjectType)?.add(mockParam);

		Test.startTest();
		Object plugin = DatabaseLayer.Utils.Plugins.initPlugin(parameterName);
		Test.stopTest();

		Assert.isNull(plugin, 'Did not return null plugin');
	}

	@IsTest
	private static void shouldReturnNullPluginIfPluginInvalid() {
		String parameterName = 'DmlPreAndPostProcessor';
		DatabaseLayerParameter__mdt mockParam = new DatabaseLayerParameter__mdt(
			DeveloperName = parameterName,
			Value__c = 'not a real object name'
		);
		MockCmdt.mock(DatabaseLayerParameter__mdt.SObjectType)?.add(mockParam);

		Test.startTest();
		Object plugin = DatabaseLayer.Utils.Plugins.initPlugin(parameterName);
		Test.stopTest();

		Assert.isNull(plugin, 'Did not return null plugin');
	}

	@IsTest
	private static void shouldReturnNullPluginIfMissingPluginName() {
		String parameterName = 'DmlPreAndPostProcessor';
		DatabaseLayerParameter__mdt mockParam = new DatabaseLayerParameter__mdt(
			DeveloperName = parameterName,
			Value__c = null
		);
		MockCmdt.mock(DatabaseLayerParameter__mdt.SObjectType)?.add(mockParam);

		Test.startTest();
		Object plugin = DatabaseLayer.Utils.Plugins.initPlugin(parameterName);
		Test.stopTest();

		Assert.isNull(plugin, 'Did not return null plugin');
	}

	@IsTest
	private static void shouldReturnNullPluginIfMissingSettingsRecords() {
		MockCmdt.mock(DatabaseLayerParameter__mdt.SObjectType);

		Test.startTest();
		Object plugin = DatabaseLayer.Utils.Plugins.initPlugin('DmlPreAndPostProcessor');
		Test.stopTest();

		Assert.isNull(plugin, 'Did not return null plugin');
	}

	@IsTest
	private static void shouldCreateNewSObjectsFromIds() {
		Id recordId = UserInfo.getUserId();

		Test.startTest();
		SObject record = DatabaseLayer.Utils.SObjects.newSObject(recordId);
		Test.stopTest();

		Assert.isInstanceOfType(record, User.class, 'Did not create a User');
		Assert.areEqual(record?.Id, recordId, 'Wrong Id');
	}
}
