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

    public DatabaseLayerCache(DatabaseLayer factory) {
        this.cacheMap = new Map<String, Object>{};
        this.partition = this.getPartition();
    }

    public Boolean contains(String key) {
        return (this.partition?.contains(key) ?? this.cacheMap?.containsKey(key)) == true;
    }

    public Object get(String key) {
        Object value = this.partition?.get(key) ?? this.cacheMap?.get(key);
        return (value != CACHE_SAFE_NULL_VALUE) ? value : null;
    }

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
            System.debug(error + '\n' + error.getStackTraceString());
            return null;
        }
    }

    @TestVisible
    private virtual class Provider {
        public virtual Cache.Partition getPartition() {
            return Cache.Org.getPartition(CACHE_PARTITION_NAME);
        }
    }
}