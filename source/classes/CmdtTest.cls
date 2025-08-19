@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class CmdtTest {
	private static final SObjectType CMDT_OBJECT = DatabaseLayerSetting__mdt.SObjectType;

	@IsTest
	static void shouldQueryWhatIsInOrg() {
		Cmdt.Repository repository = DatabaseLayer.Cmdt?.ofType(CMDT_OBJECT);

		Test.startTest();
		List<DatabaseLayerSetting__mdt> results = (List<DatabaseLayerSetting__mdt>) repository?.getAll()?.values();
		Assert.areEqual(0, Limits.getQueries(), 'Should not count towards query limits');
		Test.stopTest();

		Integer numSettings = DatabaseLayerSetting__mdt.getAll()?.size();
		Assert.areEqual(numSettings, results?.size(), 'Did not query what is in org');
	}

	@IsTest
	static void shouldReturnSpecifiedInstance() {
		DatabaseLayerSetting__mdt setting = CmdtTest.initMockSetting();
		String key = setting?.DeveloperName;

		Test.startTest();
		DatabaseLayerSetting__mdt result = (DatabaseLayerSetting__mdt) DatabaseLayer.Cmdt
			?.ofType(CMDT_OBJECT)
			?.getInstance(key);
		Assert.areEqual(0, Limits.getQueries(), 'Should not have used SOQL');
		Test.stopTest();

		Assert.areEqual(key, result?.DeveloperName, 'Wrong instance returned');
	}

	@IsTest
	static void shouldCacheQueryResultsIfCmdtIncludesLongTextAreaField() {
		String objectApiName = CMDT_OBJECT.toString();
		Cmdt.objectsToCache = new Set<String>{ objectApiName };

		Test.startTest();
		List<DatabaseLayerSetting__mdt> results = (List<DatabaseLayerSetting__mdt>) DatabaseLayer.Cmdt
			?.ofType(CMDT_OBJECT)
			?.getAll()
			?.values();
		Test.stopTest();

		Integer numSettings = DatabaseLayerSetting__mdt.getAll()?.size();
		Assert.areEqual(numSettings, results?.size(), 'Did not query what is in org');
	}

	@IsTest
	static void shouldAlwaysQueryIfCmdtDoesNotIncludeLongTextAreaField() {
		Cmdt.objectsToCache = new Set<String>{};

		Test.startTest();
		List<DatabaseLayerSetting__mdt> results = (List<DatabaseLayerSetting__mdt>) DatabaseLayer.Cmdt
			?.ofType(CMDT_OBJECT)
			?.getAll()
			?.values();
		Test.stopTest();

		Integer numSettings = DatabaseLayerSetting__mdt.getAll()?.size();
		Assert.areEqual(numSettings, results?.size(), 'Did not query what is in org');
	}

	@IsTest
	static void shouldMockCmdtRecords() {
		DatabaseLayerSetting__mdt settings = new DatabaseLayerSetting__mdt(DeveloperName = 'Test_Record');
		MockCmdt.mock(CMDT_OBJECT)?.add(settings);
		Cmdt.Repository repo = DatabaseLayer.Cmdt.ofType(CMDT_OBJECT);

		Test.startTest();
		Map<String, SObject> records = repo?.getAll();
		DatabaseLayerSetting__mdt matching = (DatabaseLayerSetting__mdt) repo?.getInstance(settings?.DeveloperName);
		Assert.areEqual(0, Limits.getQueries(), 'Should not have used SOQL');
		Test.stopTest();

		Assert.areEqual(1, records?.size(), 'Wrong # of records');
		Assert.isNotNull(matching, 'Mock Record was not mapped');
		Assert.areEqual(settings?.DeveloperName, matching?.DeveloperName, 'Wrong DeveloperName');
	}

	@IsTest
	static void shouldMockEmptyListOfRecords() {
		MockCmdt.mock(CMDT_OBJECT);
		// No further calls - `get` calls should return empty

		Test.startTest();
		Map<String, SObject> records = DatabaseLayer.Cmdt.ofType(CMDT_OBJECT)?.getAll();
		Assert.areEqual(0, Limits.getQueries(), 'Should not have used SOQL');
		Test.stopTest();

		Assert.areEqual(0, records?.size(), 'Wrong # of records');
	}

	@IsTest
	static void shouldRemoveSpecificMockRecordsByKey() {
		DatabaseLayerSetting__mdt setting1 = new DatabaseLayerSetting__mdt(DeveloperName = 'Test_Record_1');
		DatabaseLayerSetting__mdt setting2 = new DatabaseLayerSetting__mdt(DeveloperName = 'Test_Record_2');
		MockCmdt.Repository repo = MockCmdt.mock(CMDT_OBJECT)?.add(setting1)?.add(setting2);
		String key = setting1?.DeveloperName;

		Test.startTest();
		repo?.remove(key);
		Test.stopTest();

		Assert.isFalse(repo?.getAll()?.containsKey(key), 'Did not remove ' + key);
	}

	@IsTest
	static void shouldRemoveSpecificMockRecordByItsValue() {
		DatabaseLayerSetting__mdt setting1 = new DatabaseLayerSetting__mdt(DeveloperName = 'Test_Record_1');
		DatabaseLayerSetting__mdt setting2 = new DatabaseLayerSetting__mdt(DeveloperName = 'Test_Record_2');
		MockCmdt.Repository repo = MockCmdt.mock(CMDT_OBJECT)?.add(setting1)?.add(setting2);

		Test.startTest();
		repo?.remove(setting1);
		Test.stopTest();

		String key = setting1?.DeveloperName;
		Assert.isFalse(repo?.getAll()?.containsKey(key), 'Did not remove ' + key);
	}

	@IsTest
	static void shouldClearMockRecords() {
		DatabaseLayerSetting__mdt setting1 = new DatabaseLayerSetting__mdt(DeveloperName = 'Test_Record_1');
		DatabaseLayerSetting__mdt setting2 = new DatabaseLayerSetting__mdt(DeveloperName = 'Test_Record_2');
		MockCmdt.Repository repo = MockCmdt.mock(CMDT_OBJECT)?.add(setting1)?.add(setting2);

		Test.startTest();
		repo?.clear();
		Test.stopTest();

		Assert.areEqual(0, repo?.getAll()?.size(), 'Did not clear mock records');
	}

	@IsTest
	static void shouldMapNamespacedRecordsByFullyQualifiedApiName() {
		DatabaseLayerSetting__mdt settings = (DatabaseLayerSetting__mdt) new MockRecord(CMDT_OBJECT)
			?.setField(DatabaseLayerSetting__mdt.NamespacePrefix, 'somenamespace')
			?.setField(DatabaseLayerSetting__mdt.DeveloperName, 'Test_Record')
			?.toSObject();
		MockCmdt.mock(CMDT_OBJECT)?.add(settings);
		String key = settings?.NamespacePrefix + '__' + settings?.DeveloperName;

		Test.startTest();
		DatabaseLayerSetting__mdt matching = (DatabaseLayerSetting__mdt) DatabaseLayer.Cmdt
			?.ofType(CMDT_OBJECT)
			?.getInstance(key);
		Test.stopTest();

		Assert.isNotNull(matching, 'Did not return matching record');
		Assert.areEqual(settings?.NamespacePrefix, matching?.NamespacePrefix, 'Wrong NamespacePrefix');
		Assert.areEqual(settings?.DeveloperName, matching?.DeveloperName, 'Wrong DeveloperName');
	}

	@IsTest
	static void shouldClearRealRecordsWhenMockIsInstantiated() {
		DatabaseLayerSetting__mdt setting = CmdtTest.initMockSetting();
		String key = setting?.DeveloperName;
		SObject before = DatabaseLayer.Cmdt.ofType(CMDT_OBJECT)?.getInstance(key);
		Assert.isNotNull(before, 'Before: Did not find record');
		// Now instantiate the mocks:
		MockCmdt.mock(CMDT_OBJECT);

		Test.startTest();
		SObject after = DatabaseLayer.Cmdt.ofType(CMDT_OBJECT)?.getInstance(key);
		Test.stopTest();

		Assert.isNull(after, 'After: Did not clear mocked records');
	}

	@IsTest
	static void shouldReturnNullInstanceIfOneDoesntExist() {
		// Mostly for coverage -- since we can't test with real CMDT records
		Cmdt.objectsToCache = new Set<String>{ CMDT_OBJECT?.toString() };
		String key = 'There\'s no way this is a real key';

		Test.startTest();
		DatabaseLayerSetting__mdt instance = (DatabaseLayerSetting__mdt) DatabaseLayer.Cmdt
			?.ofType(CMDT_OBJECT)
			?.getInstance(key);
		Test.stopTest();

		Assert.isNull(instance, 'Invalid key returned an instance anyways?');
	}

	@IsTest
	static void shouldHandleSuccessiveMockCallsToSameObject() {
		// Multiple mock() calls should *not* reset the mocked records:
		Test.startTest();
		for (Integer i = 1; i < 4; i++) {
			String name = 'Test_Record_' + i;
			DatabaseLayerSetting__mdt settings = new DatabaseLayerSetting__mdt(DeveloperName = name);
			MockCmdt.mock(CMDT_OBJECT)?.add(settings);
			Set<String> mocked = DatabaseLayer.Cmdt.ofType(CMDT_OBJECT)?.getAll()?.keySet();
			Assert.areEqual(i, mocked?.size(), 'Wrong # of mocked records');
			Assert.isTrue(mocked?.contains(name), 'Did not mock ' + i);
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldExtractListOfEntityDefinitionsByName() {
		// This is purely for coverage, in orgs that don't contain CMDTs w/long text fields
		String objectApiName = CMDT_OBJECT.toString();
		EntityDefinition entity = (EntityDefinition) new MockRecord(EntityDefinition.SObjectType)
			?.setField(EntityDefinition.QualifiedApiName, objectApiName)
			?.toSObject();
		List<EntityDefinition> entities = new List<EntityDefinition>{ entity };

		Test.startTest();
		Set<String> results = Cmdt.extractEntityNames(entities);
		Test.stopTest();

		Assert.areEqual(entities?.size(), results?.size(), 'Wrong # of results');
		Assert.isTrue(results?.contains(objectApiName), 'Did not extract ' + objectApiName);
	}

	@IsTest
	static void shouldResetMetadataRetrieval() {
		DatabaseLayerSetting__mdt mockSetting1 = new DatabaseLayerSetting__mdt(DeveloperName = 'Test_Record_1');
		DatabaseLayerSetting__mdt mockSetting2 = new DatabaseLayerSetting__mdt(DeveloperName = 'Test_Record_2');
		MockCmdt.mock(CMDT_OBJECT)?.add(mockSetting1)?.add(mockSetting2);

		Test.startTest();
		MockCmdt.reset(CMDT_OBJECT);
		// After the reset, mock again, but with a new 3rd setting object:
		DatabaseLayerSetting__mdt mockSetting3 = new DatabaseLayerSetting__mdt(DeveloperName = 'Test_Record_3');
		MockCmdt.mock(CMDT_OBJECT)?.add(mockSetting3);
		Test.stopTest();

		List<DatabaseLayerSetting__mdt> results = (List<DatabaseLayerSetting__mdt>) DatabaseLayer.Cmdt.ofType(
				CMDT_OBJECT
			)
			?.getAll()
			?.values();
		Assert.areEqual(1, results?.size(), 'Wrong # of results');
		Assert.areEqual(mockSetting3?.DeveloperName, results?.get(0)?.DeveloperName, 'Did not reset');
	}

	// **** HELPER **** //
	private static DatabaseLayerSetting__mdt initMockSetting() {
		// Override the guardrails that discourage query mocking
		// Callers won't normally mock CMDT queries in this way, this is just for framework testing only
		Cmdt.soqlProvider = DatabaseLayer.Soql;
		DatabaseLayer.useMocks();
		DatabaseLayerSetting__mdt setting = new DatabaseLayerSetting__mdt(DeveloperName = 'Test_Record');
		MockSoql.setGlobalMock().withResults(new List<DatabaseLayerSetting__mdt>{ setting });
		return setting;
	}
}
