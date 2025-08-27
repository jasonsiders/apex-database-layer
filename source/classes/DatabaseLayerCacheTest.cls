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

		Boolean wasCached = DatabaseLayer.Utils.Cache.contains(key);
		Assert.isTrue(wasCached, key + ' was not cached');
		Object result = DatabaseLayer.Utils.Cache.get(key);
		Assert.areEqual(value, result, 'Unexpected cache value for ' + key);
	}

	@IsTest
	static void shouldReturnNullIfNoItemsCached() {
		String key = 'Foo2';

		Test.startTest();
		Object result = DatabaseLayer.Utils.Cache.get(key);
		Test.stopTest();

		Boolean wasCached = DatabaseLayer.Utils.Cache.contains(key);
		Assert.isFalse(wasCached, key + ' should not be cached');
		Assert.isNull(result, 'Uncached key did not return null');
	}

	@IsTest
	static void shouldCacheNullValue() {
		String key = 'Foo3';
		DatabaseLayer.Utils.Cache.put(key, null);

		Test.startTest();
		Object result = DatabaseLayer.Utils.Cache.get(key);
		Test.stopTest();

		Boolean wasCached = DatabaseLayer.Utils.Cache.contains(key);
		Assert.isTrue(wasCached, key + ' was not cached');
		Assert.isNull(result, 'Uncached key did not return null');
	}

	@IsTest
	static void shouldHandleCacheInitializationErrors() {
		DatabaseLayerCache.Provider = new DatabaseLayerCacheTest.ErrorProvider();

		Test.startTest();
		try {
			Cache.Partition result = DatabaseLayer.Utils.Cache.getPartition();
			Assert.isNull(result, 'Should not have returned a value');
		} catch (Cache.CacheException error) {
			Assert.fail('Should not have thrown an exception');
		}
		Test.stopTest();
	}

	// **** INNER **** //
	private class ErrorProvider extends DatabaseLayerCache.Provider {
		public override Cache.Partition getPartition() {
			throw new Cache.CacheException();
		}
	}
}
