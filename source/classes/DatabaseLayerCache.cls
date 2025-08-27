/**
 * @description Cache utility class for managing platform cache operations within the DatabaseLayer framework.
 * Provides a unified interface for both org cache and local map caching with null value handling.
 */
public class DatabaseLayerCache {
	private static final String CACHE_PARTITION_NAME;
	private static final String CACHE_SAFE_NULL_VALUE;
	@SuppressWarnings('PMD.FieldNamingConventions')
	@TestVisible
	private static DatabaseLayerCache.Provider Provider;

	private Map<String, Object> cacheMap;
	private Cache.Partition partition;

	static {
		CACHE_PARTITION_NAME = 'DatabaseLayer';
		CACHE_SAFE_NULL_VALUE = '<<NULL_CACHE_VALUE>>';
		Provider = new DatabaseLayerCache.Provider();
	}

	/**
	 * @description Constructor that initializes the cache instance with a local map and platform cache partition.
	 * @param factory The DatabaseLayer factory instance
	 */
	public DatabaseLayerCache(DatabaseLayer factory) {
		this.cacheMap = new Map<String, Object>{};
		this.partition = this.getPartition();
	}

	/**
	 * @description Checks if a key exists in either the platform cache or local map cache.
	 * @param key The cache key to check for
	 * @return True if the key exists, false otherwise
	 */
	public Boolean contains(String key) {
		return (this.partition?.contains(key) ?? this.cacheMap?.containsKey(key)) == true;
	}

	/**
	 * @description Retrieves a value from cache, checking platform cache first then local map.
	 * @param key The cache key to retrieve
	 * @return The cached value, or null if not found or if the cached value was null
	 */
	public Object get(String key) {
		Object value = this.partition?.get(key) ?? this.cacheMap?.get(key);
		return (value != CACHE_SAFE_NULL_VALUE) ? value : null;
	}

	/**
	 * @description Stores a value in both local map and platform cache with null value handling.
	 * @param key The cache key
	 * @param value The value to cache (null values are converted to a safe placeholder)
	 * @return This DatabaseLayerCache instance for method chaining
	 */
	public DatabaseLayerCache put(String key, Object value) {
		value = value ?? CACHE_SAFE_NULL_VALUE;
		this.cacheMap?.put(key, value);
		this.partition?.put(key, value);
		return this;
	}

	@TestVisible
	private Cache.Partition getPartition() {
		try {
			return DatabaseLayerCache.Provider?.getPartition();
		} catch (Cache.CacheException error) {
			// Platform cache is not enabled -- the framework will continue to use the cacheMap as a fallback
			return null;
		}
	}

	@TestVisible
	private virtual class Provider {
		/**
		 * @description Retrieves the platform cache partition for DatabaseLayer operations.
		 * @return The Cache.Partition instance for the DatabaseLayer partition
		 */
		public virtual Cache.Partition getPartition() {
			return Cache.Org.getPartition(CACHE_PARTITION_NAME);
		}
	}
}
