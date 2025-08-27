@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class DatabaseLayerUtilsTest {
	@IsTest
	static void shouldReturnWhateverMetadataIsDefinedInOrg() {
		// A validation rule enforces that at most, 1 settings record will exist in an org
		// This ensures the get() method will return the 1st (and only) record, if one is defined:
		DatabaseLayerSetting__mdt defaultSetting = DatabaseLayerSetting__mdt.getInstance('Default');

		Test.startTest();
		DatabaseLayerSetting__mdt results = DatabaseLayer.Utils?.Settings;
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
	static void shouldInitializeUtilities() {
		DatabaseLayerTestUtils.initSettings();

		Test.startTest();
		DatabaseLayerUtils utils = DatabaseLayer.Utils;
		Test.stopTest();

		Assert.isNotNull(DatabaseLayer.Utils.Cache, 'Cache utility not initialized');
		Assert.isNotNull(DatabaseLayer.Utils.ChildRelationships, 'ChildRelationships utility not initialized');
		Assert.isNotNull(DatabaseLayer.Utils.Plugins, 'Plugins utility not initialized');
		Assert.isNotNull(DatabaseLayer.Utils.Settings, 'Settings not initialized');
	}
}
