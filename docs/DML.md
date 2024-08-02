# The `Dml` Class

- ! TODO ! Add some general information about the class

## Public Methods

### Performing DML
#### `doConvert`
#### `doDelete`
#### `doDeleteAsync`
#### `doDeleteImmediate`
#### `doDml`
#### `doHardDelete`
#### `doInsert`
#### `doInsertAsync`
#### `doInsertImmediate`
#### `doPublish`
#### `doUndelete`
#### `doUpdate`
#### `doUpdateAsync`
#### `doUpdateImmediate`
#### `doUpsert`

### Configuring DML Settings
#### `getAccessLevel`
#### `getAllOrNone`
#### `getDeleteCallback`
#### `getSaveCallback`
#### `getDmlOptions`
#### `getExternalIdField`
#### `reset`
#### `setAccessLevel`
#### `setAllOrNone`
#### `setCallback`
#### `setDmlOptions`
#### `setExternalIdField`

## Public Inner Types

### `Dml.Operation`

## Mocking DML Operations
The `MockDml` class can be used in placed of a normal `Dml` class in the `@IsTest` context. The `MockDml` class manipulates the SObject records in memory, instead of actually inserting, modifying or deleting records in the Salesforce database.

### Instantiating Mocks
In `@IsTest` context, mock DML operations by calling the `DatabaseLayer.useMocks()` method. Once this is done, the `DatabaseLayer.newDml()` method will return `MockDml` objects. If the `newDml()` methood is called _before_ `useMocks()`, then those objects will continue to be instances of `Dml`. To prevent issues, call the `useMocks()` method as the first line in your test. 

### Simulating DML Failures
By default, `MockDml` objects will simulate successful DML operations:
```java
DatabaseLayer.useMocks();
Account account = new Account(Name = 'My Account');
Database.SaveResult result = DatabaseLayer.newDml()?.doInsert(account);
Assert.isTrue(result?.isSuccess(), 'DML did not succeed');
Assert.isNotNull(account?.Id, 'Account was not inserted');
```

To simulate failed DML operations, you must first indicate to the `MockDml` class that it should fail. Most use cases can be handled by calling the `fail()` method, which will cause each DML operation to fail:
```java
DatabaseLayer.useMocks();
Account account = new Account(Name = 'John Doe');
MockDml dml = (MockDml) DatabaseLayer.newDml();
dml?.fail();
try {
    dml?.doInsert(account);
    Assert.fail('DML operation did not fail');
} catch (System.DmlException error) {
    // As expected!
}
```

If your `Dml` object is responsible for more than one operation, or if you only want a subset of records to fail (ie., to test `allOrNone=false` operations), you can inject precise failure logic by passing an instance of `MockDml.ConditionalLogic` to the `failIf()` method:

```java
DatabaseLayer.useMocks();
Account account = new Account(Name = 'My Account');
MockDml dml = (MockDml) DatabaseLayer.newDml()?.setAllOrNone(false);
MockDml.ConditionalFailure logic = new ExampleFailure();
dml?.failIf(logic);
Database.SaveResult result = DatabaseLayer.newDml()?.doInsert(account);
Assert.isFalse(result?.isSuccess, 'DML Operation did not fail');
Assert.isNull(account?.Id, 'Account was inserted');
```

#### The `MockDml.ConditionalFailure` Interface

Evaluates a given SObject record and DML operation, and returns an Exception object if the operation should fail for that record. If `null` is returned, the operation will succeed. If an Exception is returned, the operation will fail in accordance with the current `Dml` object's defined `allOrNone` behavior. This behavior mirrors standard DML `allOrNone` logic:
- If `allOrNone == true`, the Exception returned by the `checkFailure()` method is thrown, and the entire operation fails.
- If `allOrNone == false`, only the current SObject fails. The matching `Database.*Result` returned by the DML operation will indicate that the record failed. The resulting error message for the result is derived from the Exception returned by the `checkFailure()` method. 

**Signatures**:
- `checkFailure(Dml.Operation operation, SObject record)`

Example:
```java
public class ExampleFailure implements MockDml.ConditionalFailure {
    public Exception checkFailure(Dml.Operation operation, SObject record) {
        // Fail any operations that manipulate Account records
        if (record?.getSObjectType() == Account.SObjectType) {
            return new System.DmlException();
        } else {
            // Success!
            return null;
        }
    }
}
```

### Validating DML Operations
Since the `MockDml` class does not actually manipulate records in the database, you cannot use SOQL to retrieve changes. Instead, use the included `History` objects to retrieve records that were manipulated by a `MockDml` instance. Example:

```java
@IsTest 
static void someTest() {
    DatabaseLayer.useMocks();
    Account acc = new Account(Name = 'John Doe');
    
    Test.startTest();
    DatabaseLayer.newDml()?.doInsert(acc);
    Test.stopTest();

    List<Account> insertedAccs = MockDml.Inserted.getRecords(Account.SObjectType);
    Assert.areEqual(1, insertedAccs?.size(), 'Account was not inserted');
    Account insertedAcc = insertedAccs[0];
    Assert.areEqual(acc?.Name, insertedAcc?.Name, 'Wrong Account Name');)
}
```

A `History` object exists for each major DML operation, and are enumerated as `public static final` properties on the `MockDml` class:

- `MockDml.CONVERTED`
- `MockDml.DELETED`
- `MockDml.INSERTED`
- `MockDml.PUBLISHED`
- `MockDml.UNDELETED`
- `MockDml.UPDATED`
- `MockDml.UPSERTED`

Each of the above `History` object includes three public methods:

#### `eraseHistory`
Clears the current History object; once called, the `getAll()` and `getRecords()` methods will return empty structures. Returns self.

Signature: `MockDml.History eraseHistory()`

#### `getAll`
Retrieves a map of records that were processed by the current DML operation, grouped by their `SObjectType`.

Signature: `Map<SObjectType, List<SObject>> getAll()`

#### `getRecords`
Retrieves a list of all records of the provided `SObjectType` that were processed by the current DML operation.

Signature: `List<SObject> getRecords(SObjectType objectType)`