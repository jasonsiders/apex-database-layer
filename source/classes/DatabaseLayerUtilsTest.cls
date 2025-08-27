@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class DatabaseLayerUtilsTest {
	@SuppressWarnings('PMD.UnusedLocalVariable')
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
