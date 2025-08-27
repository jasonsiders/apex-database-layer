public class DatabaseLayerCache {
    private static final String CACHE_PARTITION_NAME = 'DatabaseLayer';
	private static final String CACHE_SAFE_NULL_VALUE = '<<NULL_CACHE_VALUE>>';
    private Map<String, Object> cacheMap;
    private Cache.Partition partition;

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

    private Cache.Partition getPartition() {
        try {
            return Cache.Org.getPartition(CACHE_PARTITION_NAME);
        } catch (Exception error) {
            System.debug(error + '\n' + error.getStackTraceString());
            return null;
        }
    }
}