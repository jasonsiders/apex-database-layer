@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class DatabaseLayerPluginsTest {
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
	static void shouldHandleErrorsWithPluginInitialization() {
		// If a 0-arg constructor isn't publicly visible, it will fail
		DatabaseLayerSetting__mdt mockSetting = new DatabaseLayerSetting__mdt(
			DeveloperName = 'Test_123',
			DmlPreAndPostProcessor__c = DatabaseLayer.class.getName()
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
