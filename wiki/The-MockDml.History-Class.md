This class stores records that were submitted for a particular DML operation while using mocks. It contains methods that allow callers to inspect what changes were made during the course of a test.

---

### Methods

#### `eraseAllHistories`

Clears all `MockDml.History` objects in the current [mock Database](./The-MockDml.Database-Class.md).

- `static void eraseAllHistories()`

```apex
DatabaseLayer.useMocks();
DatabaseLayer.Dml.doInsert(account);
MockDml.INSERTED.eraseHistory();
Assert.isFalse(MockDml.INSERTED.wasProcessed(account));
```

#### `get`

Returns a specific record that was processed by the current DML operation. Returns `null` if no such record was processed.

- `get(SObjectType objectType, String idOrUuid)`
- `get(Id recordId)`
- `get(SObject record)`

```apex
DatabaseLayer.useMocks();
DatabaseLayer.Dml.doInsert(account);
Account insertedAcc = (Account) MockDml.INSERTED.get(account);
```

#### `getAll`

Retrieves a map of records that were processed by the current DML operation, grouped by their `SObjectType`:

- `Map<SObjectType, List<SObject>> getAll()`

```apex
DatabaseLayer.useMocks();
DatabaseLayer.Dml.doInsert(account);
Assert.isFalse(MockDml.INSERTED.getAll()?.isEmpty(), 'Did not insert any records');
```

#### `getRecords`

Retrieves a list of all records of the provided `SObjectType` that were processed by the current DML operation.

- `List<SObject> getRecords(SObjectType objectType)`

```apex
DatabaseLayer.useMocks();
DatabaseLayer.Dml.doInsert(account);
Assert.isFalse(MockDml.INSERTED.getRecords(Account.SObjectType)?.isEmpty(), 'Did not insert accounts');
```

#### `wasProcessed`

Determines if a specific record was processed by the current DML operation.

- `wasProcessed(SObjectType objectType, String idOrUuid)`
- `wasProcessed(Id recordId)`
- `wasProcessed(SObject record)`

```apex
DatabaseLayer.useMocks();
DatabaseLayer.Dml.doInsert(account);
Assert.isTrue(MockDml.INSERTED.wasProcessed(account), 'Did not insert account');
```
