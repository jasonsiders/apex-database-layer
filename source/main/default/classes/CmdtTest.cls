@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class CmdtTest {
	@IsTest
	static void shouldQueryWhatIsInOrg() {
		List<DatabaseLayerSetting__mdt> allSettings = DatabaseLayerSetting__mdt.getAll()?.values();

		Test.startTest();
		List<DatabaseLayerSetting__mdt> results = (List<DatabaseLayerSetting__mdt>) DatabaseLayer.Cmdt
			?.ofType(DatabaseLayerSetting__mdt.SObjectType)
			?.getAll()
			?.values();
		Assert.areEqual(0, Limits.getQueries(), 'Should not count towards query limits');
		Test.stopTest();

		Assert.areEqual(allSettings?.size(), results?.size(), 'Did not query what is in org');
	}
}
