@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class DatabaseLayerUtilsTest {
	@IsTest
	static void shouldGetChildRelationshipFromLookupField() {
		SObjectField field = Contact.AccountId;

		Test.startTest();
		Schema.ChildRelationship relationship = DatabaseLayer.Utils.ChildRelationships.getChildRelationshipFrom(field);
		Test.stopTest();

		Assert.areEqual(field, relationship?.getField(), 'Relationship does not point to ' + field);
	}

	@IsTest
	static void shouldGetChildRelationshipFromPolymorphicLookupField() {
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
	static void shouldReturnChildRelationshipsUnderHighStress() {
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
	static void shouldReturnNullChildRelationshipIfNotLookupField() {
		SObjectField field = Contact.CreatedDate;

		Test.startTest();
		Schema.ChildRelationship relationship = DatabaseLayer.Utils.ChildRelationships.getChildRelationshipFrom(field);
		Test.stopTest();

		Assert.areEqual(null, relationship, 'Non-lookup field returned a relationship anyways');
	}

	@IsTest
	static void shouldReturnWhateverMetadataIsDefinedInOrg() {
		// A validation rule enforces that at most, 1 settings record will exist in an org
		// This ensures the get() method will return the 1st (and only) record, if one is defined:
		Map<String, DatabaseLayerSetting__mdt> all = DatabaseLayerSetting__mdt.getAll();
		DatabaseLayerSetting__mdt firstSetting = (all?.isEmpty() == false) ? all?.values()?.get(0) : null;

		Test.startTest();
		DatabaseLayerSetting__mdt results = DatabaseLayer.Utils.MetadataSelector.get();
		Assert.areEqual(0, Limits.getQueries(), 'Should not retrieve CMDT via SOQL');
		Test.stopTest();

		Assert.areEqual(firstSetting?.DeveloperName, results?.DeveloperName, 'Wrong DatabaseLayerSetting__mdt value');
	}

	@IsTest
	static void shouldReturnMockedMetadata() {
		// To force your test to use a specific DatabaseLayerSetting__mdt record, add ito the `settings` list:
		DatabaseLayerSetting__mdt mockSetting = new DatabaseLayerSetting__mdt(DeveloperName = 'Test_123');
		DatabaseLayer.Utils.MetadataSelector.settings = new List<DatabaseLayerSetting__mdt>{ mockSetting };

		Test.startTest();
		DatabaseLayerSetting__mdt results = DatabaseLayer.Utils.MetadataSelector.get();
		Assert.areEqual(0, Limits.getQueries(), 'Should not retrieve CMDT via SOQL');
		Test.stopTest();

		Assert.areEqual(mockSetting?.DeveloperName, results?.DeveloperName, 'Wrong DatabaseLayerSetting__mdt value');
	}

	@IsTest
	static void shouldReturnNullIfMockedEmtpyList() {
		// Define `settings` as an empty list to ignore any defined DatabaseLayerSetting__mdt records in an org:
		DatabaseLayer.Utils.MetadataSelector.settings = new List<DatabaseLayerSetting__mdt>{};

		Test.startTest();
		DatabaseLayerSetting__mdt results = DatabaseLayer.Utils.MetadataSelector.get();
		Assert.areEqual(0, Limits.getQueries(), 'Should not retrieve CMDT via SOQL');
		Test.stopTest();

		Assert.isNull(results, 'Should not have returned a CMDT value');
	}

	@IsTest
	static void shouldInitPluginObjectFromCustomMetadata() {
		DatabaseLayerSetting__mdt mockSetting = new DatabaseLayerSetting__mdt(
			DeveloperName = 'Test_123',
			DmlPreAndPostProcessor__c = 'Schema.Account' // For example...
		);
		DatabaseLayer.Utils.MetadataSelector.settings = new List<DatabaseLayerSetting__mdt>{ mockSetting };
		SObjectField field = DatabaseLayerSetting__mdt.DmlPreAndPostProcessor__c;

		Test.startTest();
		// Account would never *actually* be a plugin; this is just an example:
		Account example = (Account) DatabaseLayer.Utils.Plugins.initPlugin(field);
		Test.stopTest();

		Assert.isNotNull(example, 'Did not generate an object from CMDT');
	}

	@IsTest
	static void shouldReturnNullPluginIfPluginInvalid() {
		DatabaseLayerSetting__mdt mockSetting = new DatabaseLayerSetting__mdt(
			DeveloperName = 'Test_123',
			DmlPreAndPostProcessor__c = 'not a real object name'
		);
		DatabaseLayer.Utils.MetadataSelector.settings = new List<DatabaseLayerSetting__mdt>{ mockSetting };
		SObjectField field = DatabaseLayerSetting__mdt.DmlPreAndPostProcessor__c;

		Test.startTest();
		Object plugin = DatabaseLayer.Utils.Plugins.initPlugin(field);
		Test.stopTest();

		Assert.isNull(plugin, 'Did not return null plugin');
	}

	@IsTest
	static void shouldReturnNullPluginIfMissingPluginName() {
		DatabaseLayerSetting__mdt mockSetting = new DatabaseLayerSetting__mdt(
			DeveloperName = 'Test_123',
			DmlPreAndPostProcessor__c = null
		);
		DatabaseLayer.Utils.MetadataSelector.settings = new List<DatabaseLayerSetting__mdt>{ mockSetting };
		SObjectField field = DatabaseLayerSetting__mdt.DmlPreAndPostProcessor__c;

		Test.startTest();
		Object plugin = DatabaseLayer.Utils.Plugins.initPlugin(field);
		Test.stopTest();

		Assert.isNull(plugin, 'Did not return null plugin');
	}

	@IsTest
	static void shouldReturnNullPluginIfMissingSettingsRecords() {
		DatabaseLayer.Utils.MetadataSelector.settings = new List<DatabaseLayerSetting__mdt>{};
		SObjectField field = DatabaseLayerSetting__mdt.DmlPreAndPostProcessor__c;

		Test.startTest();
		Object plugin = DatabaseLayer.Utils.Plugins.initPlugin(field);
		Test.stopTest();

		Assert.isNull(plugin, 'Did not return null plugin');
	}
}
