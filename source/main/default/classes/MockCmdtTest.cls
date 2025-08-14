@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest 
private class MockCmdtTest {
    @IsTest 
    static void shouldMockCmdt() {
        SObjectType objectType = DatabaseLayerSetting__mdt.SObjectType;
        DatabaseLayerSetting__mdt setting = new DatabaseLayerSetting__mdt(DeveloperName = 'Test_Record');
        // TODO: Think about how to solve this
        MockCmdt.Repository repository = DatabaseLayer.Cmdt?.mock(objectType)?.add(setting);

        Test.startTest();
        Map<String, SObject> results = DatabaseLayer.Cmdt.ofType(objectType)?.getAll();
        Test.stopTest();

        Assert.areEqual(1, results?.size(), 'Wrong # of results');
        Assert.isTrue(results?.containsKey(setting?.DeveloperName), 'Test record was not injected');
    }

    @IsTest 
    static void shouldMockEmptyListByDefault() {
        Assert.fail('You still need to build this test');
    }

    @IsTest 
    static void shouldRemoveAndClearMetadatas() {
        Assert.fail('You still need to build this test');
    }

    @IsTest 
    static void shouldUseRegularCmdtLogicIfNoMocksSpecified() {
        Assert.fail('You still need to build this test');
    }
}