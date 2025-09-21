This class decorates a `System.Savepoint` object, and keeps track of its usage throughout a transaction. Refer to this object's properties when you need to assert if a savepoint was rolled back or released.

You can access `MockDml.Savepoint`s via the `MockDml.SavepointHistory` class, which is acccessible via the `MockDml.SAVEPOINTS` static property. Read more about the `MockDml.SavepointHistory` class [here](./The-MockDml.SavepointHistory-Class).

Example:

```apex
DatabaseLayer.useMocks();
System.Savepoint savepoint = DatabaseLayer.Dml.setSavepoint();

Test.startTest();
DatabaseLayer.Dml.rollback(savepoint);
Test.stopTest();

MockDml.Savepoint sp = MockDml.SAVEPOINTS.get(0);
Assert.areEqual(true, sp?.wasRolledBack);
Assert.areEqual(false, sp?.wasReleased);
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
      <td>index</td>
      <td>Integer</td>
      <td>(Read-only) The Savepoint's index, corresponding with the number of savepoints generated in the transaction, starting with 0.</td>
    </tr>
    <tr>
      <td>name</td>
      <td>String</td>
      <td>(Read-only) The Savepoint's name, which is discoverable via the <code>System.Savepoint</code>'s <code>toString()</code> value.</td>
    </tr>
    <tr>
      <td>wasReleased</td>
      <td>Boolean</td>
      <td>(Read-only) Indicates whether <code>DatabaseLayer.Dml.releaseSavepoint()</code> was called for the current savepoint.</td>
    </tr>
    <tr>
      <td>wasRolledBack</td>
      <td>Boolean</td>
      <td>(Read-only) Indicates whether <code>DatabaseLayer.Dml.rollback()</code> was called for the current savepoint.</td>
    </tr>
  </tbody>
</table>
