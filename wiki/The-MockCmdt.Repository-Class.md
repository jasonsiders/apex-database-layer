The `MockCmdt.Repository` class provides the interface for configuring mock Custom Metadata Type records. It allows in-memory storage and manipulation of Custom Metadata Type records without database operations.

This class is returned by [`MockCmdt.mock()`](./The-MockCmdt-Class#mock) and provides fluent methods for adding, removing, and clearing mock records in test scenarios. All methods return the repository instance, enabling fluent method chaining for complex setup scenarios.

```apex
@IsTest
static void testRepositoryOperations() {
    DatabaseLayer.useMocks();

    MySetting__mdt setting1 = new MySetting__mdt(DeveloperName = 'Setting_1');
    MySetting__mdt setting2 = new MySetting__mdt(DeveloperName = 'Setting_2');

    // Fluent method chaining for setup
    MockCmdt.mock(MySetting__mdt.SObjectType)
        ?.clear()
        ?.add(setting1)
        ?.add(new List<MySetting__mdt>{ setting2 });

    List<MySetting__mdt> allSettings = (List<MySetting__mdt>) DatabaseLayer.Cmdt
        ?.ofType(MySetting__mdt.SObjectType)
        ?.getAll();

    Assert.areEqual(2, allSettings.size(), 'Should have 2 records');

    // Remove one record
    MockCmdt.mock(MySetting__mdt.SObjectType).remove(setting1);

    allSettings = (List<MySetting__mdt>) DatabaseLayer.Cmdt
        ?.ofType(MySetting__mdt.SObjectType)
        ?.getAll();

    Assert.areEqual(1, allSettings.size(), 'Should have 1 record after removal');
}
```

---

## Methods

### `add`

Adds records to the mock repository. Supports adding a list of records, or a single record.

- `MockCmdt.Repository add(List<SObject> recordList)`
- `MockCmdt.Repository add(SObject record)`

### `clear`

Removes all records from the mock repository.

- `MockCmdt.Repository clear()`

### `remove`

Removes records from the mock repository. Supports removing by record key, by record object, by list of records, or by set of keys.

- `MockCmdt.Repository remove(Set<String> keys)`
- `MockCmdt.Repository remove(List<SObject> recordList)`
- `MockCmdt.Repository remove(SObject record)`
- `MockCmdt.Repository remove(String key)`
