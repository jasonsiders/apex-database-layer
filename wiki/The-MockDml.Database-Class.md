Simulates a Salesforce database when mocks are used. The class stores a `MockDml.History` object for each DML method, along with logic to handle savepoint/rollback behavior.

This object is available as a public static property, `MockDml.MockDatabase`. A blank database object is initialized by default. As records are submitted for mock DML over time, the records are then added to the appropriate history object.

Example:

```apex
DatabaseLayer.useMockDml();
Account acc = new Account();

Test.startTest();
DatabaseLayer.insert(acc);
Test.stopTest();

// Access the MockDml.Database's 'inserted' property:
Assert.isTrue(MockDml.MockDatabase.inserted?.wasProcessed(acc), 'Account was not inserted');
// This is functionally equivalent; INSERTED getter refers to the current MockDatabase:
Assert.isTrue(MockDml.INSERTED?.wasProcessed(acc), 'Account was not inserted');
```

---

### Properties

<table>
  <thead>
    <tr>
      <th>Property Name</th>
      <th>Data Type</th>
      <th>Details</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>converted</td>
      <td>MockDml.RecordHistory</td>
      <td>A read-only property containing a history object that stores all upserted records during a transaction. The <code>MockDml.CONVERTED</code> getter property returns this value from the current mock database.</td>
    </tr>
    <tr>
      <td>deleted</td>
      <td>MockDml.RecordHistory</td>
      <td>A read-only property containing a history object that stores all upserted records during a transaction. The <code>MockDml.DELETED</code> getter property returns this value from the current mock database.</td>
    </tr>
    <tr>
      <td>inserted</td>
      <td>MockDml.RecordHistory</td>
      <td>A read-only property containing a history object that stores all upserted records during a transaction. The <code>MockDml.INSERTED</code> getter property returns this value from the current mock database.</td>
    </tr>
    <tr>
      <td>published</td>
      <td>MockDml.PlatformEventHistory</td>
      <td>A read-only property containing a history object that stores all upserted records during a transaction. The <code>MockDml.PUBLISHED</code> getter property returns this value from the current mock database.</td>
    </tr>
    <tr>
      <td>purged</td>
      <td>MockDml.RecordHistory</td>
      <td>A read-only property containing a history object that stores all upserted records during a transaction. The <code>MockDml.PURGED</code> getter property returns this value from the current mock database.</td>
    </tr>
    <tr>
      <td>undeleted</td>
      <td>MockDml.RecordHistory</td>
      <td>A read-only property containing a history object that stores all upserted records during a transaction. The <code>MockDml.UNDELETED</code> getter property returns this value from the current mock database.</td>
    </tr>
    <tr>
      <td>updated</td>
      <td>MockDml.RecordHistory</td>
      <td>A read-only property containing a history object that stores all upserted records during a transaction. The <code>MockDml.UPDATED</code> getter property returns this value from the current mock database.</td>
    </tr>
    <tr>
      <td>upserted</td>
      <td>MockDml.RecordHistory</td>
      <td>A read-only property containing a history object that stores all upserted records during a transaction. The <code>MockDml.UPSERTED</code> getter property returns this value from the current mock database.</td>
    </tr>
    <tr>
      <td>resetOnRollback</td>
      <td>Boolean</td>
      <td>
        This property determines how the database will behave when a rollback occurs.<br><br>
        By default (<code>true</code>), savepoints will store a "snapshot" of the mock database at the time that they were initialized. Rolling back the savepoint will then cause the current <code>MockDatabase</code> to be replaced with that snapshot.<br><br>
        If set to <code>false</code>, the database will "ignore" rollbacks. You'll still be able to reference any records that were processed in the corresponding history object, even if they were rolled back. This may be desirable if you want to see what happened before the rollback occurred, or to improve performance in cases where this isn't needed.
      </td>
    </tr>
  </tbody>
</table>

---

### Methods

#### `snapshot`

- `MockDml.Database snapshot()`

This method returns a copy of the current `MockDatabase`, using JSON-serialization. Changes to this snapshot object will not mutate the database object that generated it, and vice-versa.

Example:

```apex
MockDml.Database databaseSnapshot = MockDml.MockDatabase.snapshot();
```
