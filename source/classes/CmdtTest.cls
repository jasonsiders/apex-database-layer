@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class CmdtTest {
	@IsTest
	static void shouldQueryWhatIsInOrg() {
		Cmdt.Repository repository = DatabaseLayer.Cmdt?.ofType(DatabaseLayerSetting__mdt.SObjectType);

		Test.startTest();
		List<DatabaseLayerSetting__mdt> results = (List<DatabaseLayerSetting__mdt>) repository?.getAll()?.values();
		Assert.areEqual(0, Limits.getQueries(), 'Should not count towards query limits');
		Test.stopTest();

		Integer numSettings = DatabaseLayerSetting__mdt.getAll()?.size();
		Assert.areEqual(numSettings, results?.size(), 'Did not query what is in org');
	}

	@IsTest
	static void shouldReturnSpecifiedInstance() {
		// Note: Callers won't normally mock CMDT queries in this way,
		// but there's no way to reliably do this and ensure test coverage otherwise
		Cmdt.Soql = DatabaseLayer.Soql;
		DatabaseLayer.useMocks();
		String key = 'Test_Record';
		SObjectType objectType = DatabaseLayerSetting__mdt.SObjectType;
		DatabaseLayerSetting__mdt setting = (DatabaseLayerSetting__mdt) new MockRecord(objectType)
			?.setField(DatabaseLayerSetting__mdt.DeveloperName, key)
			?.toSObject();
		MockSoql.setGlobalMock().withResults(new List<DatabaseLayerSetting__mdt>{ setting });

		Test.startTest();
		DatabaseLayerSetting__mdt result = (DatabaseLayerSetting__mdt) DatabaseLayer.Cmdt
			?.ofType(objectType)
			?.getInstance(key);
		Test.stopTest();

		Assert.areEqual(key, result?.DeveloperName, 'Wrong instance returned');
	}

	@IsTest
	static void shouldCacheQueryResultsIfCmdtIncludesLongTextAreaField() {
		String objectApiName = DatabaseLayerSetting__mdt.SObjectType.toString();
		DatabaseLayer.Cmdt.cacheObjectApiNames = new Set<String>{ objectApiName };

		Test.startTest();
		List<DatabaseLayerSetting__mdt> results = (List<DatabaseLayerSetting__mdt>) DatabaseLayer.Cmdt
			?.ofType(DatabaseLayerSetting__mdt.SObjectType)
			?.getAll()
			?.values();
		Test.stopTest();

		Integer numSettings = DatabaseLayerSetting__mdt.getAll()?.size();
		Assert.areEqual(numSettings, results?.size(), 'Did not query what is in org');
	}

	@IsTest
	static void shouldAlwaysQueryIfCmdtDoesNotIncludeLongTextAreaField() {
		DatabaseLayer.Cmdt.cacheObjectApiNames = new Set<String>{};

		Test.startTest();
		List<DatabaseLayerSetting__mdt> results = (List<DatabaseLayerSetting__mdt>) DatabaseLayer.Cmdt
			?.ofType(DatabaseLayerSetting__mdt.SObjectType)
			?.getAll()
			?.values();
		Test.stopTest();

		Integer numSettings = DatabaseLayerSetting__mdt.getAll()?.size();
		Assert.areEqual(numSettings, results?.size(), 'Did not query what is in org');
	}
}
