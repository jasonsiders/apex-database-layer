The `Cmdt.QueryBasedRepository` class implements the [`Cmdt.Repository`](./The-Cmdt.Repository-Interface) interface and provides direct database access to Custom Metadata Type (CMDT) records.

This repository implementation is automatically selected by `DatabaseLayer.Cmdt.ofType()` when the Custom Metadata Type does not contain Long Text Area fields. Since SOQL queries against Custom Metadata Types without Long Text Area fields do not count towards Salesforce governor limits, this repository can safely execute a fresh query on each request without concern for SOQL limit consumption.

```apex
// For a CMDT type without Long Text Area fields, this returns a QueryBasedRepository
Cmdt.Repository repository = DatabaseLayer.Cmdt.ofType(MySetting__mdt.SObjectType);

// Each call executes a fresh SOQL query (but doesn't count towards limits)
List<MySetting__mdt> allSettings = (List<MySetting__mdt>) repository.getAll();

// Another query is executed, but still doesn't count towards limits
MySetting__mdt specificSetting = (MySetting__mdt) repository.getInstance('Default');
```

The query-per-request strategy takes advantage of Salesforce's SOQL limit exemption for Custom Metadata Types without Long Text Area fields. Since these queries are "free" from a governor limit perspective, the repository prioritizes memory efficiency over query optimization by avoiding any caching mechanism.

---

## Methods

This class inherits all methods from [`Cmdt.Repository`](./The-Cmdt.Repository-Interface):

### `getAll`

Returns all records of the Custom Metadata Type by executing a fresh SOQL query on each call. Since queries against CMDT types without Long Text Area fields don't count towards governor limits, this approach prioritizes memory efficiency.

- `List<SObject> getAll()`

### `getInstance`

Returns a specific Custom Metadata Type record by its developer name through a targeted SOQL query. Returns `null` if no record with the specified developer name exists. Each call results in a fresh query that doesn't count towards governor limits.

- `SObject getInstance(String key)`
