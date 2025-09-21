This class stores all `MockDml.Savepoint` objects generated throughout a transction. You can interact with this class's methods to retrieve a specific savepoint, or all savepoints.

```apex
DatabaseLayer.useMocks();
System.Savepoint sp1 = DatabaseLayer.Dml.setSavepoint();
System.Savepoint sp2 = DatabaseLayer.Dml.setSavepoint();
// Get all savepoints:
List<MockDml.Savepoint> all = MockDml.SAVEPOINTS?.getAll();
// Get a specific savepoint:
MockDml.Savepoint first = MockDml.SAVEPOINTS?.get(0);
MockDml.Savepoint second = MockDml.SAVEPOINTS?.get(sp2);
```

---

### Methods

#### `getAll`

Returns all `MockDml.Savepoint` objects generated in a transaction, via `DatabaseLayer.Dml.setSavepoint()`.

- `List<MockDml.Savepoint> getAll()`

#### `get`

Returns a specific `MockDml.Savepoint` object, by the specified index or `System.Savepoint` object.

- `MockDml.Savepoint get(Integer index)`
- `MockDml.Savepoint get(System.Savepoint)`
