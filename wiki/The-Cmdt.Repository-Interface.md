The `Cmdt.Repository` interface provides the abstract base interface for retrieving Custom Metadata Type (CMDT) records. This interface serves as the foundation for both real database operations and mock implementations.

The repository is returned by the `DatabaseLayer.Cmdt.ofType()` method and provides a unified interface for accessing CMDT records regardless of whether the system is configured for real database operations or mock testing scenarios.

```apex
// Get a repository for a specific CMDT type
Cmdt.Repository repository = DatabaseLayer.Cmdt.ofType(MySetting__mdt.SObjectType);

// Retrieve all records
List<MySetting__mdt> allSettings = (List<MySetting__mdt>) repository.getAll().values();

// Retrieve a specific record by developer name
MySetting__mdt specificSetting = (MySetting__mdt) repository.getInstance('Default');
```

## Implementations

The actual implementation returned depends on the CMDT field structure to optimize performance while managing memory constraints:

- **CMDT types with Long Text Area fields**: Returns a [`Cmdt.QueryBasedRepository`](./The-Cmdt.QueryBasedRepository-Class) that queries the database on each request. This avoids caching potentially large text values that could consume significant heap memory and cause governor limit issues.
- **CMDT types without Long Text Area fields**: Returns a [`Cmdt.CacheBasedRepository`](./The-Cmdt.CacheBasedRepository-Class) that caches all records in memory for optimal performance on subsequent retrievals, since the memory footprint is predictable and manageable.

When `MockCmdt.mock()` is called for a specific Custom Metadata Type, subsequent calls to `DatabaseLayer.Cmdt.ofType()` for that same type will return a [`MockCmdt.Repository`](./The-MockCmdt.Repository-Class) instance instead.

---

## Methods

### `getAll`

Returns all records of the Custom Metadata Type managed by this repository.

- `Map<String, SObject> getAll()`

### `getInstance`

Returns a specific Custom Metadata Type record by its developer name. Returns `null` if no record with the specified developer name exists.

- `SObject getInstance(String key)`
