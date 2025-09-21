This class extends the `Dml` class, and simulates operations performed `Dml` objects in `@IsTest` context when the framework is configured to use mocks.

The framework automatically uses to a `MockDml` instance for DML operations whenever `DatabaseLayer.Dml` is called after `DatabaseLayer.useMocks()` or `DatabaseLayer.useMockDml()` is called.

Unlike `Dml`, `Dml` objects do not interact with the Salesforce database. Their operations "simulates" a successful DML operation by default, though it's possible to configure DML failures.

Since DML operations do not interact with the Salesforce database, changes processed via `MockDml` cannot be retrieved from the Database using traditional SOQL queries. Instead, callers can refer to a "mock database" via static `MockDml` properties to access records that were inserted, updated, etc.

Here is an example apex test that uses `MockDml`:

```apex
@IsTest
static void someTest() {
  DatabaseLayer.useMocks();
  Account account = new Account();

  Test.startTest();
  DatabaseLayer.Dml.doInsert(account);
  Test.stopTest();

  // The Account wasn't actually inserted, but it appears to be!
  Assert.isNotNull(account?.Id, 'Missing Account Id');
  Assert.isTrue(MockDml.INSERTED.wasProcessed(account?.Id, 'Account was not inserted');
}
```

---

## Properties

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
      <td>CONVERTED</td>
      <td><a href="./The-MockDml.History-Class">MockDml.History</a></td>
      <td>History object that records all <code>Database.LeadConvert</code> objects converted via <code>Dml.convertLead</code>. Getter property which retrieves an object of the same name from the <code>MockDml.MockDatabase</code>.</td>
    </tr>
    <tr>
      <td>DELETED</td>
      <td><a href="./The-MockDml.History-Class">MockDml.History</a></td>
      <td>History object that records all <code>SObject</code> records deleted via <code>Dml.doDelete</code>. Getter property which retrieves an object of the same name from the <code>MockDml.MockDatabase</code>.</td>
    </tr>
    <tr>
      <td>FAILURES</td>
      <td>List&lt;<a href="./The-MockDml.ConditionalFailure-Interface">MockDml.ConditionalFailure</a>&gt;</td>
      <td>Contains logic that runs on each DML operation to determine if a record should result in a DML failure.</td>
    </tr>
    <tr>
      <td>INSERTED</td>
      <td><a href="./The-MockDml.History-Class">MockDml.History</a></td>
      <td>History object that records all <code>SObject</code> records inserted via <code>Dml.doInsert</code>. Getter property which retrieves an object of the same name from the <code>MockDml.MockDatabase</code>.</td>
    </tr>
    <tr>
      <td>MockDatabase</td>
      <td><a href="./The-MockDml.Database-Class">MockDml.Database</a></td>
      <td>Simulates a Salesforce database; comprised of history objects, plus some special logic which simulates rollbacks.</td>
    </tr>
    <tr>
      <td>PUBLISHED</td>
      <td><a href="./The-MockDml.History-Class">MockDml.History</a></td>
      <td>History object that records all platform events inserted via <code>Dml.doPublished</code>. Getter property which retrieves an object of the same name from the <code>MockDml.MockDatabase</code>.</td>
    </tr>
    <tr>
      <td>PURGED</td>
      <td><a href="./The-MockDml.History-Class">MockDml.History</a></td>
      <td>History object that records all <code>SObject</code> records purged from the recycle bin, via <code>Dml.emptyRecycleBin</code>. Getter property which retrieves an object of the same name from the <code>MockDml.MockDatabase</code>.</td>
    </tr>
    <tr>
      <td>SAVEPOINTS</td>
      <td><a href="./The-MockDml.SavepointHistory-Class">MockDml.SavepointHistory</a></td>
      <td>History object that records all <code>System.Savepoint</code> records generated via <code>Dml.setSavepoint</code>.</td>
    </tr>
    <tr>
      <td>UNDELETED</td>
      <td><a href="./The-MockDml.History-Class">MockDml.History</a></td>
      <td>History object that records all <code>SObject</code> records undeleted via <code>Dml.doUndelete</code>. Getter property which retrieves an object of the same name from the <code>MockDml.MockDatabase</code>.</td>
    </tr>
    <tr>
      <td>UPDATED</td>
      <td><a href="./The-MockDml.History-Class">MockDml.History</a></td>
      <td>History object that records all <code>SObject</code> records upserted via <code>Dml.doUpsert</code>. Getter property which retrieves an object of the same name from the <code>MockDml.MockDatabase</code>.</td>
    </tr>
    <tr>
      <td>UPSERTED</td>
      <td><a href="./The-MockDml.History-Class">MockDml.History</a></td>
      <td>History object that records all <code>SObject</code> records updated via <code>Dml.doUpdate</code>. Getter property which retrieves an object of the same name from the <code>MockDml.MockDatabase</code>.</td>
    </tr>
  </tbody>
</table>

## Methods

💡 **Important:** `MockDml` inherits all of the same methods as its parent `Dml` class, documented [here](./The-Dml-Class#Methods). However, these methods do **not** interact with the database.

### `eraseAllHistories`

This static method the [MockDml.Database](./The-MockDml.Database-Class) to its original state. All [MockDml.History](./The-MockDml.History-Class) objects will be empty.

- `static void eraseAllHistories()`

```apex
DatabaseLayer.useMocks();
DatabaseLayer.doInsert(new Account());
// Reset the mock database:
MockDml.eraseAllHistories();
Assert.isTrue(MockDml.INSERTED.isEmpty());
```

### `shouldFail`

This static method causes all subsuquent DML operations to fail.

- `static void shouldFail()`

```apex
DatabaseLayer.useMocks();
MockDml.shouldFail();
DatabaseLayer.doInsert(new Account());
// ! Exception thrown: System.DmlException
```

### `shouldFailIf`

This static method injects a [MockDml.ConditionalFailure](./The-MockDml.ConditionalFailure-Class) object, which determines if subsuquent DML operation(s) should fail.

- `static void shouldFailIf(MockDml.Simulator simulator)`

```apex
DatabaseLayer.useMocks();
// Let's say this object fails whenever an Account is updated:
MockDml.ConditionalFailure logic = new SomeConditionalLogic();
MockDml.shouldFailIf(logic);
// Perform some DML:
Account account = new Account();
Contact contact = new Contact();
// This succeeds, since it's not a DML update:
DatabaseLayer.Dml.doInsert(account);
// This succeeds, since it's not an Account:
DatabaseLayer.Dml.doUpdate(contact);
// This fails, since it's an Account update:
DatabaseLayer.Dml.doUpdate(account);
```

### `shouldSucceed`

This static method clears the current list of [MockDml.ConditionalLogic](./The-MockDml.ConditionalLogic-Interface) failures. All subsuquent DML operation(s) should succeed.

- `static void shouldSucceed()`

```apex
DatabaseLayer.useMocks();
MockDml.shouldFail();
// This should fail:
Database.SaveResult result1 = DatabaseLayer.Dml.doInsert(new Account(), false);
// Now, remove the failure - this should succeed:
MockDml.shouldSucceed();
Database.SaveResult result2 = DatabaseLayer.Dml.doInsert(new Account(), false);
```
