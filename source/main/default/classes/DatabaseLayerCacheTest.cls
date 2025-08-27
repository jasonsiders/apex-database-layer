@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest 
private class DatabaseLayerCacheTest {
    @IsTest 
	static void shouldRetrieveCachedItems() {
		String key = 'Foo';
		Object value = 'Bar';

		Test.startTest();
		DatabaseLayer.Utils.Cache.put(key, value);
		Test.stopTest();

		Object result = DatabaseLayer.Utils.Cache.get(key);
		Assert.areEqual(value, result, 'Unexpected cache value for ' + key);
	}

	@IsTest 
	static void shouldReturnNullIfNoItemsCached() {
		String key = 'Foo2';

		Test.startTest();
		Boolean wasCached = DatabaseLayer.Utils.Cache.contains(key);
		Object result = DatabaseLayer.Utils.Cache.get(key);
		Test.stopTest();

		Assert.isFalse(wasCached, 'Uncached key was found anyways');
		Assert.isNull(result, 'Uncached key did not return null');
	}
}