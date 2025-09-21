The `Cmdt.CacheBasedRepository` class implements the [`Cmdt.Repository`](./The-Cmdt.Repository-Interface) interface and provides cached access to Custom Metadata Type (CMDT) records to minimize SOQL governor limit consumption.

This repository implementation is automatically selected by `DatabaseLayer.Cmdt.ofType()` when the Custom Metadata Type contains Long Text Area fields. Since SOQL queries against Custom Metadata Types with Long Text Area fields count towards Salesforce governor limits, this repository caches all records in a static map after the first database query to ensure at most one query is ever executed.

```apex
// For a CMDT type with Long Text Area fields, this returns a CacheBasedRepository
Cmdt.Repository repository = DatabaseLayer.Cmdt.ofType(MySetting__mdt.SObjectType);

// First call queries the database and caches the results in a static map
List<MySetting__mdt> allSettings = (List<MySetting__mdt>) repository.getAll();

// Subsequent calls return cached data from the static map without additional queries
MySetting__mdt specificSetting = (MySetting__mdt) repository.getInstance('Default');
```

The caching strategy represents a tradeoff between SOQL query limits and heap memory consumption. By storing results in a static map, the repository ensures that multiple accesses to the same CMDT type will never exceed one SOQL query, even across different execution contexts. This design prioritizes staying within SOQL governor limits at the expense of increased heap memory usage from caching potentially large numbers of records.

The cache is populated lazily on the first `getAll()` or `getInstance()` call and persists in static memory beyond the current transaction, ensuring optimal query limit management.

---

## Methods

This class inherits all methods from [`Cmdt.Repository`](./The-Cmdt.Repository-Interface):

### `getAll`

Returns all records of the Custom Metadata Type. On the first call, queries the database and caches the results in a static map. Subsequent calls return the cached data without additional SOQL queries.

- `List<SObject> getAll()`

### `getInstance`

Returns a specific Custom Metadata Type record by its developer name. Uses cached data when available, falling back to database query if the cache hasn't been populated yet. Returns `null` if no record with the specified developer name exists.

- `SObject getInstance(String key)`
