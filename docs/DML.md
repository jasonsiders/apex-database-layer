# The `Dml` Class

The `Dml` class is designed to streamline and enhance DML operations within Salesforce. It encapsulates standard DML keywords and Database methods, providing a simplified interface for CRUD operations. This class enables developers to easily mock DML operations, improving unit testing and reducing complexity. Additionally, it supports dynamic and asynchronous DML execution, immediate operations, and custom extensibility. Use the `Dml` class to write cleaner, more maintainable code while efficiently managing complex business logic.

## Constructing `Dml` Objects

`Dml` objects cannot be directly constructed via the `new` keyword. Instead, use `DatabaseLayer.newDml()`:
```java
Dml dml = DatabaseLayer.newDml();
```

The `DatabaseLayer` class is responsible for instantiating database objects of the correct type at runtime. In `@IsTest` context, developers can call `DatabaseLayer.useMocks()`, and an instance of the `MockDml` class will be returned instead:

```java
DatabaseLayer.useMocks();
Dml dml = DatabaseLayer.useMocks();
Assert.isInstanceOfType(dml, MockDml.class, 'Not a mock');
```

## Public Methods

### Performing DML

#### `doConvert`

Used to convert leads using the provided `Database.LeadConvert` instances. It leverages the standard `Database.convertLead` method to perform the conversion.

- `List<Database.LeadConvertResult> doConvert(List<Database.LeadConvert> leadsToConvert)`
- `Database.LeadConvertResult doConvert(Database.LeadConvert leadToConvert)`

#### `doDelete`

Used to delete records from the Salesforce database. It leverages the standard `Database.delete` method to perform the deletion.

- `List<Database.DeleteResult> doDelete(List<Id> recordIds)`
- `Database.DeleteResult doDelete(Id recordId)`
- `Database.DeleteResult doDelete(SObject record)`
- `List<Database.DeleteResult> doDelete(List<SObject> records)`

#### `doDeleteAsync`

Used to delete records asynchronously from the Salesforce database. It leverages the standard `Database.deleteAsync` method to perform the deletion.

- `List<Database.DeleteResult> doDeleteAsync(List<SObject> records)`
- `List<Database.DeleteResult> doDeleteAsync(List<Id> recordIds)`
- `Database.DeleteResult doDeleteAsync(Id recordId)`
- `Database.DeleteResult doDeleteAsync(SObject record)`

#### `doDeleteImmediate`

Used to delete records immediately from the Salesforce database. It leverages the standard `Database.deleteImmediate` method to perform the deletion.

- `List<Database.DeleteResult> doDeleteImmediate(List<SObject> records)`
- `List<Database.DeleteResult> doDeleteImmediate(List<Id> recordIds)`
- `Database.DeleteResult doDeleteImmediate(Id recordId)`
- `Database.DeleteResult doDeleteImmediate(SObject record)`

#### `doDml`

Used to perform dynamic DML operations on records. The type of operation to be perfomed is based on the specified `Dml.Operation` value.

- `List<Object> doDml(Operation operation, List<SObject> records)`
- `Object doDml(Operation operation, SObject record)`

#### `doHardDelete`

Used to hard delete records from the Salesforce database. The specified records are deleted permanently, and cannot be recovered from the recycle bin.

- `List<Database.DeleteResult> doHardDelete(List<Id> recordIds)`
- `Database.DeleteResult doHardDelete(Id recordId)`
- `List<Database.DeleteResult> doHardDelete(List<SObject> records)`
- `Database.DeleteResult doHardDelete(SObject record)`

#### `doInsert`

Used to insert records into the Salesforce database. It leverages the standard `Database.insert` method to perform the insertion.

- `List<Database.SaveResult> doInsert(List<SObject> records)`
- `Database.SaveResult doInsert(SObject record)`

#### `doInsertAsync`

Used to insert records asynchronously into the Salesforce database. It leverages the standard `Database.insertAsync` method to perform the insertion.

- `List<Database.SaveResult> doInsertAsync(List<SObject> records)`
- `Database.SaveResult doInsertAsync(SObject record)`

#### `doInsertImmediate`

Used to insert records immediately into the Salesforce database. It leverages the standard `Database.insertImmediate` method to perform the insertion.

- `List<Database.SaveResult> doInsertImmediate(List<SObject> records)`
- `Database.SaveResult doInsertImmediate(SObject record)`

#### `doPublish`

Used to publish platform events to the Salesforce event bus.

- `List<Database.SaveResult> doPublish(List<SObject> events)`
- `Database.SaveResult doPublish(SObject event)`

#### `doUndelete`

Used to undelete records from the Salesforce recycle bin, restoring them to their original state.

- `List<Database.UndeleteResult> doUndelete(List<Id> recordIds)`
- `Database.UndeleteResult doUndelete(Id recordId)`
- `Database.UndeleteResult doUndelete(SObject record)`
- `List<Database.UndeleteResult> doUndelete(List<SObject> records)`

#### `doUpdate`

Used to update records in the Salesforce database. It leverages the standard `Database.update` method to perform the update.

- `List<Database.SaveResult> doUpdate(List<SObject> records)`
- `Database.SaveResult doUpdate(SObject record)`

#### `doUpdateAsync`

Used to update records asynchronously in the Salesforce database. It leverages the standard `Database.updateAsync` method to perform the update.

- `List<Database.SaveResult> doUpdateAsync(List<SObject> records)`
- `Database.SaveResult doUpdateAsync(SObject record)`

#### `doUpdateImmediate`

Used to update records immediately in the Salesforce database. It leverages the standard `Database.updateImmediate` method to perform the update.

- `List<Database.SaveResult> doUpdateImmediate(List<SObject> records)`
- `Database.SaveResult doUpdateImmediate(SObject record)`

#### `doUpsert`

Used to insert or update records in the Salesforce database, based on whether the records already exist. It leverages the standard `Database.upsert` method to perform the operation.

- `List<Database.UpsertResult> doUpsert(List<SObject> records)`
- `Database.UpsertResult doUpsert(SObject record)`

### Configuring DML Settings

#### `getAccessLevel`

This method returns the current access level to be used in all DML operations.

- `System.AccessLevel getAccessLevel()`

#### `getAllOrNone`

This method returns the current all-or-none behavior to be used in all DML operations. Defaults to `true` to mirror the behavior of standard `Database` DML methods.

- `Boolean getAllOrNone()`

#### `getDeleteCallback`

This method returns the current `AsyncDeleteCallback` to be used in `doDeleteAsync()` operations.

- `DataSource.AsyncDeleteCallback getDeleteCallback()`

#### `getSaveCallback`

This method returns the current `AsyncSaveCallback` to be used in `doInsertAsync()` and `doUpdateAsync()` operations.

- `DataSource.AsyncSaveCallback getSaveCallback()`

#### `getDmlOptions`

This method returns the current `DmlOptions` class to be used in all DML operations.

- `Database.DmlOptions getDmlOptions()`

#### `getExternalIdField`

This method returns the current external ID field to be used in upsert operations.

- `SObjectField getExternalIdField()`

#### `reset`

This method resets the current DML class's parameters to their default values.

- `Dml reset()`

#### `setAccessLevel`

This method sets the access level to be used in DML operations.

- `Dml setAccessLevel(System.AccessLevel level)`

#### `setAllOrNone`

This method sets the all-or-none parameter for DML methods, determining whether partial failures will cause the entire operation to fail.

- `Dml setAllOrNone(Boolean value)`

#### `setCallback`

This method sets the callback function to be run in `doDeleteAsync()` operations.

- `Dml setCallback(DataSource.AsyncDeleteCallback deleteCallback)`

This method sets the callback function to be run in `doInsertAsync()` and `doUpdateAsync()` operations.

- `Dml setCallback(DataSource.AsyncSaveCallback saveCallback)`

#### `setDmlOptions`

This method sets the `DmlOptions` to be used in all DML operations going forward.

- `Dml setDmlOptions(Database.DmlOptions dmlOptions)`

#### `setExternalIdField`

This method sets the external ID field to be used in upsert operations, instead of the record ID.

- `Dml setExternalIdField(SObjectField field)`

## Public Inner Types

### `Dml.Operation`
The `Dml.Operation` enum enumerates the different dml operations that can be performed using the `Dml` class. 

Values:
- `DO_CONVERT`
- `DO_DELETE`
- `DO_DELETE_ASYNC`
- `DO_DELETE_IMMEDIATE`
- `DO_HARD_DELETE`
- `DO_INSERT`
- `DO_INSERT_ASYNC`
- `DO_INSERT_IMMEDIATE`
- `DO_PUBLISH`
- `DO_UNDELETE`
- `DO_UPDATE`
- `DO_UPDATE_ASYNC`
- `DO_UPDATE_IMMEDIATE`
- `DO_UPSERT`

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

- `MockDml.History eraseHistory()`

#### `getAll`
Retrieves a map of records that were processed by the current DML operation, grouped by their `SObjectType`.

- `Map<SObjectType, List<SObject>> getAll()`

#### `getRecords`
Retrieves a list of all records of the provided `SObjectType` that were processed by the current DML operation.

- `List<SObject> getRecords(SObjectType objectType)`