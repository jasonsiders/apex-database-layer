@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class DatabaseLayerUtilsTest {
	@IsTest
	static void shouldReturnWhateverMetadataIsDefinedInOrg() {
		// A validation rule enforces that at most, 1 settings record will exist in an org
		// This ensures the get() method will return the 1st (and only) record, if one is defined:
		DatabaseLayerSetting__mdt defaultSetting = DatabaseLayerSetting__mdt.getInstance('Default');
		DatabaseLayerUtils utils = DatabaseLayer.Utils;

		Test.startTest();
		DatabaseLayerSetting__mdt results = utils?.Settings;
		Assert.areEqual(0, Limits.getQueries(), 'Should not retrieve CMDT via SOQL');
		Test.stopTest();

		Assert.areEqual(defaultSetting?.DeveloperName, results?.DeveloperName, 'Wrong DatabaseLayerSetting__mdt value');
	}

	@IsTest
	static void shouldReturnMockedMetadata() {
		// To force your test to use a specific DatabaseLayerSetting__mdt record, add ito the `settings` list:
		DatabaseLayerSetting__mdt mockSetting = new DatabaseLayerSetting__mdt(DeveloperName = 'Test_123');
		MockCmdt.mock(DatabaseLayerSetting__mdt.SObjectType)?.add(mockSetting);

		Test.startTest();
		DatabaseLayerSetting__mdt results = DatabaseLayer.Utils.Settings;
		Assert.areEqual(0, Limits.getQueries(), 'Should not retrieve CMDT via SOQL');
		Test.stopTest();

		Assert.areEqual(mockSetting?.DeveloperName, results?.DeveloperName, 'Wrong DatabaseLayerSetting__mdt value');
	}

	@IsTest
	static void shouldReturnNullIfMockedEmtpyList() {
		// Define `settings` as an empty list to ignore any defined DatabaseLayerSetting__mdt records in an org:
		MockCmdt.mock(DatabaseLayerSetting__mdt.SObjectType);

		Test.startTest();
		DatabaseLayerSetting__mdt results = DatabaseLayer.Utils.Settings;
		Assert.areEqual(0, Limits.getQueries(), 'Should not retrieve CMDT via SOQL');
		Test.stopTest();

		Assert.isNull(results, 'Should not have returned a CMDT value');
	}

	@IsTest
	static void shouldInitPluginObjectFromCustomMetadata() {
		DatabaseLayerSetting__mdt mockSetting = new DatabaseLayerSetting__mdt(
			DeveloperName = 'Test_123',
			DmlPreAndPostProcessor__c = DatabaseLayerTestUtils.SamplePlugin.class.getName()
		);
		MockCmdt.mock(DatabaseLayerSetting__mdt.SObjectType)?.add(mockSetting);
		SObjectField field = DatabaseLayerSetting__mdt.DmlPreAndPostProcessor__c;

		Test.startTest();
		Dml.PreAndPostProcessor example = (Dml.PreAndPostProcessor) DatabaseLayer.Utils.Plugins.initPlugin(field);
		Test.stopTest();

		Assert.isNotNull(example, 'Did not generate an object from CMDT');
	}

	@IsTest
	static void shouldReturnNullPluginIfPluginInvalid() {
		DatabaseLayerSetting__mdt mockSetting = new DatabaseLayerSetting__mdt(
			DeveloperName = 'Test_123',
			DmlPreAndPostProcessor__c = 'not a real object name'
		);
		MockCmdt.mock(DatabaseLayerSetting__mdt.SObjectType)?.add(mockSetting);
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
		MockCmdt.mock(DatabaseLayerSetting__mdt.SObjectType)?.add(mockSetting);
		SObjectField field = DatabaseLayerSetting__mdt.DmlPreAndPostProcessor__c;

		Test.startTest();
		Object plugin = DatabaseLayer.Utils.Plugins.initPlugin(field);
		Test.stopTest();

		Assert.isNull(plugin, 'Did not return null plugin');
	}

	@IsTest
	static void shouldReturnNullPluginIfMissingSettingsRecords() {
		MockCmdt.mock(DatabaseLayerSetting__mdt.SObjectType);
		SObjectField field = DatabaseLayerSetting__mdt.DmlPreAndPostProcessor__c;

		Test.startTest();
		Object plugin = DatabaseLayer.Utils.Plugins.initPlugin(field);
		Test.stopTest();

		Assert.isNull(plugin, 'Did not return null plugin');
	}
}
