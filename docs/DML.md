# The `Dml` Class

The `Dml` class is designed to streamline and enhance DML operations within Salesforce.

It encapsulates standard DML keywords and Database methods, providing a simplified interface for CRUD operations. This class enables developers to easily mock DML operations, improving unit testing and reducing complexity.

## Constructing `Dml` Objects

`Dml` objects cannot be directly constructed via the `new` keyword. Instead, access the class and its methods via the `DatabaseLayer.Dml` static property:

```java
DatabaseLayer.Dml.doInsert(record);
```

The `DatabaseLayer` class is responsible for instantiating database objects of the correct type at runtime. In `@IsTest` context, developers can call `DatabaseLayer.useMocks()`, and an instance of the `MockDml` class will be returned instead:

```java
DatabaseLayer.useMocks();
Assert.isInstanceOfType(DatabaseLayer.Dml, MockDml.class, 'Not a mock');
```

## Performing DML

The `Dml` class contains methods which mirror the functionality of DML methods in the standard [`Database` class](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_methods_system_database.htm), including its numerous method overloads.

Since DML keywords (like `insert`, `update`, and `delete`) are reserved, the `Dml` class's methods are prefixed with the "do" predicate. For example, `doInsert`, `doUpdate`, and `doDelete`.

All public methods:

- `doConvert`
- `doDelete`
- `doDeleteAsync`
- `doDeleteImmediate`
- `doInsert`
- `doInsertAsync`
- `doInsertImmediate`
- `doPublish`
- `doUndelete`
- `doUpdate`
- `doUpdateAsync`
- `doUpdateImmediate`
- `doUpsert`
- `emptyRecycleBin`
- `releaseSavepoint`
- `rollback`
- `setSavepoint`

Example:

```java
// Specify allOrNone and access level
DatabaseLayer.Dml.doUpdate(account, false, System.AccessLevel.USER_MODE);
// Use the default implementation
DatabaseLayer.Dml.doUpdate(account);
```

You can also control `System.Savepoint`s via the Dml class. This allows you to reference `MockDml.Savepoint`s in tests, which can be used to assert how a savepoint behaved during a given transaction (ie., if a savepoint(s) were set, rolled back and/or released). Read more about this [here](#simulating-savepoints--rollbacks).

```java
System.Savepoint savepoint = DatabaseLayer.Dml.setSavepoint();
DatabaseLayer.Dml.rollback(savepoint);
Assert.isTrue(MockDml.SAVEPOINTS.get(0).wasRolledBack);
```

### Public Inner Types

#### The `Dml.Operation` Enum

Enumerates all of the supported DML operations. The framework uses this in the `Dml.Request` class to determine what type operation is being processed. Values include:

- `DO_CONVERT`
- `DO_DELETE`
- `DO_INSERT`
- `DO_PUBLISH`
- `DO_PURGE`
- `DO_UNDELETE`
- `DO_UPDATE`
- `DO_UPSERT`

> :warning: Note: This enum was introduced in v2.4.0, and will eventually replace the `MockDml.Operation` enum, which will be removed in v3.0.0.

#### The `Dml.PreAndPostProcessor` Interface

You can use this interface in conjunction with the plugin framework to define logic that runs just before, and/or just after DML operations are run. You can use this for logging, or other specialized use cases.

Read more about how DML Plugins work [**here**](#dml-plugins).

The interface contains two required methods:

- `void processPreDml(Dml.Request request)`
- `void processPostDml(Dml.Request request, List<Object> databaseResults)`

The `processPreDml` method is called just _before_ processing DML; `processPostDml` is called just _after_ processing DML.

Both methods include a `Dml.Request` parameter, which includes information about the DML operation, including the records being processed, the type of DML operation, any special behavior - like `allOrNone`, whether the request will be processed via mocks, and more. See the [`Dml.Request`](#the-dmlrequest-class) class for the full list of parameters.

The `processPostDml` also includes a `List<Object>`, which represents the Database results (ie., `Database.SaveResult`, `Database.DeleteResult`, `Database.UpsertResult`, etc) produced by the DML operation. Since these objects do not share a common interface, the return type must be a generic `List<Object>`. You can cast the results to the appropriate type based on the `operation` being processed:

<table>
	<tr>
		<th>DML Operation</th>
		<th>Database Result Type</th>
	</tr>
	<tr>
		<td><code>DO_CONVERT</code></td>
		<td><code>Database.ConvertResult</code></td>
	</tr>
	<tr>
		<td><code>DO_INSERT</code>, <code>DO_PUBLISH</code>, <code>DO_UPDATE</code></td>
		<td><code>Database.SaveResult</code></td>
	</tr>
	<tr>
		<td><code>DO_PURGE</code></td>
		<td><code>Database.EmptyRecycleBinResult</code></td>
	</tr>
	<tr>
		<td><code>DO_UNDELETE</code></td>
		<td><code>Database.UndeleteResult</code></td>
	</tr>
	<tr>
		<td><code>DO_UPSERT</code></td>
		<td><code>Database.UpsertResult</code></td>
	</tr>
</table>

Example:

```java
public class MyPlugin implements Dml.PreAndPostProcessor {
	// This sample PreAndPostProcessor logs DML operations, using Nebula Logger:
	public void processPreDml(Dml.Request request) {
		Logger.finest('About to process ' + this.getLogSuffix(request))?.setRecord(request?.records);

		Logger.finest(msg)?.setRecord(request?.records);
	}

	public void processPostDml(Dml.Request request, List<Object> results) {
		Logger.finest('Processed ' + this.getLogSuffix(request))?.setRecord(request?.records);
	}

	private String getLogSuffix(Dml.Request req) {
		return req?.numRecords + ' ' + req?.sObjectType + ' records. Operation: ' + req?.operation;
	}
}
```

#### The `Dml.Request` Class

The `Dml.Request` represents the parameters that the framework uses to process each DML statement. All requests include the records being processed, the DML operation being processed, and additional/optional configuration details.

This type cannot be manually constructed, and all of its properties are read-only. The framework auto-generates a `Dml.Request` object whenever you call a `DatabaseLayer.Dml` method.

##### Properties:

All properties are read-only, and optional unless otherwise otherwise listed:

- `System.AccessLevel accessLevel`: Determines if the DML operation is processed via SYSTEM_MODE or USER_MODE. Defaults to USER_MODE.
- `String accessLevelName`: Outputs the name of the _accessLevel_ property in JSON, since `System.AccessLevel` objects are not supported in JSON.
- `String asyncDeleteCallback`: Prints the string-value of the _deleteCallback_ property, which is omitted from JSON since its implementation may or may not be supported in JSON.
- `String asyncSaveCallback`: Prints the string-value of the _saveCallback_ property, which is omitted from JSON since its implementation may or may not be supported in JSON.
- `DataSource.AsyncDeleteCallback deleteCallback`: A callback object that can optionally be passed to async DML delete methods that support external objects, ex. `DatabaseLayer.Dml.doDeleteAsync()`.
- `String externalIdFieldName`: Prints the API Name of the _externalIdField_.
- `SObjectField externalIdField`: An optional primary key field to be used in upsert operations.
- `Boolean isMockDml`: True if the request was processed using `DatabaseLayer.useMocks()`. Else, always False.
- `Boolean isOperationAsync`: True for async DML methods that support external objects, like `DatabaseLayer.Dml.doInsertAsync()`. Else, always False.
- `Boolean isOperationImmediate`: True for synchronous DML methods that support external objects, like `DatabaseLayer.Dml.doInsertImmediate()`. Else, always False.
- `List<Database.LeadConvert> leadsToConvert`: Leads to be converted; only present in a DO_CONVERT operation.
- `Integer numRecords`: Outputs the number of records being processed. This can be useful, since _records_ and _leadsToConvert_ are always omitted from JSON output to conserve resources.
- `Dml.Operation operation`: The type of DML operation being processed. This is always present.
- `Database.DmlOptions options`: Stores advanced configuration options for the DML operation. The most common property is _OptAllOrNone_, which determines if partial failures are allowed.
- `List<SObject> records`: The record(s) being processed. This is present in all operations, except DO_CONVERT.
- `DataSource.AsyncSaveCallback saveCallback`: A callback object that can optionally be passed to async DML insert/update methods that support external objects, ex. `DatabaseLayer.Dml.doInsertAsync()`.
- `String sObjectType`: Outputs the API Name of the SObjectType being processed, if known. For DO_CONVERT, outputs "Database.LeadConvert". When unknown, outputs "SObject".

For logging purposes, you can safely JSON-serialize the `Dml.Request`, though Some of the properties of this class may be omitted to save on resources, or because they are not supported in JSON. Example:

```json
{
	"sObjectType": "Account",
	"options": {
		"OptAllOrNone": true,
		"EmailHeader": {},
		"DuplicateRuleHeader": {},
		"AssignmentRuleHeader": {}
	},
	"operation": "DO_INSERT",
	"numRecords": 1,
	"isOperationImmediate": false,
	"isOperationAsync": false,
	"isMockDml": false,
	"asyncSaveCallback": "EmptySaveCallback:[]",
	"asyncDeleteCallback": "EmptyDeleteCallback:[]",
	"accessLevelName": "USER_MODE"
}
```

Note: The _records_ and _leadsToConvert_ properties are _never_ printed in JSON, but can still be accessed by referencing them directly, ex., `request?.records`.

## DML Plugins

You can optionally define an Apex class which can perform pre/post processing tasks on your DML operations. For example, logging via your logging framework of choice.

Plugins are handled by a Custom Metadata Type, and the `Dml.PreAndPostProcessor` interface. Read more about this interface [**here**](#the-dmlpreandpostprocessor-interface).

Follow these steps to create your own DML plugin:

1. Create an Apex Class that includes your desired logic. Requirements:

- This class must implement `Dml.PreAndPostProcessor`.
- This class must be `public` or `global`, and have an accessible 0-arg constructor (either implicit or explicit).

2. Create a `DatabaseLayerSetting__mdt` record, if one doesn't already exist.

- Note: There may only be a single record at a time; this is enforced by a validation rule.

3. Set the _DML: Pre & Post Processor_ field to the fully qualified API name of your Apex Class, including namespace if applicable.

## Mocking DML Operations

The `MockDml` class can be used in placed of a normal `Dml` class in the `@IsTest` context. The `MockDml` class manipulates the SObject records in memory, instead of actually inserting, modifying or deleting records in the Salesforce database.

### Instantiating Mocks

In `@IsTest` context, mock DML operations by calling the `DatabaseLayer.useMocks()` method. Once this is done, the `DatabaseLayer.Dml` method will return `MockDml` objects. If the `Dml` methood is called _before_ `useMocks()`, then those objects will continue to be instances of `Dml`. To prevent issues, call the `useMocks()` method as the first line in your test:

```java
@IsTest
static void example() {
  DatabaseLayer.useMocks();
  Case testCase = new Case();

  Test.startTest();
  DatabaseLayer.Dml.doInsert(testCase);
  Assert.areEqual(0, Limits.getDmlStatements(), 'DML was processed?');
  Test.stopTest();

  Integer numInserted = MockDml.INSERTED?.getRecords(Case.SObjectType)?.size();
  Assert.areEqual(1, numInserted, 'Wrong # of cases inserted');
  Assert.isNotNull(testCase?.Id, 'Test Case was not inserted');
}
```

### Simulating DML Failures

By default, `MockDml` objects will simulate successful DML operations:

```java
DatabaseLayer.useMocks();
Account account = new Account(Name = 'My Account');
Database.SaveResult result = DatabaseLayer.Dml.doInsert(account);
Assert.isTrue(result?.isSuccess(), 'DML did not succeed');
Assert.isNotNull(account?.Id, 'Account was not inserted');
```

To simulate failed DML operations, you must first inject failure(s) into the framework. Most use cases can be handled by calling `MockDml.shouldFail()`, which causes all subsuquent DML operations to fail:

```java
DatabaseLayer.useMocks();
MockDml.shouldFail();
Account account = new Account(Name = 'John Doe');
try {
  DatabaseLayer.Dml?.doInsert(account);
  Assert.fail('DML operation did not fail');
} catch (System.DmlException error) {
  // As expected!
}
```

You can inject more precise failure logic by passing an instance of [`MockDml.ConditionalLogic`](#the-mockdmlconditionalfailure-interface) to `MockDml.shouldFailIf()` method. This can be useful if only one of multiple DML operations, or subset of records within the same DML operation should fail:

```java
DatabaseLayer.useMockDml();
// The "ExampleFailure" class will only fail on DML updates
MockDml.ConditionalFailure logic = new ExampleFailure();
MockDml?.shouldFailIf(logic);
Database.SaveResult result = DatabaseLayer.Dml.doInsert(account);
Assert.isFalse(result?.isSuccess, 'DML Operation did not fail');
Assert.isNull(account?.Id, 'Account was inserted');
```

Read more about the `MockDml.ConditionalFailure` interface [here](#the-mockdmlconditionalfailure-interface).

### Simulating Savepoints & Rollbacks

Out of the box, salesforce doesn't give you many tools to check how savepoints were used over the course of a test. When used in conjunction with the `Dml` class's savepoint methods, `MockDml` gives you the ability to inspect each savepoint generated in a transaction, along with details about how they were used, ie., whether they were rolled back or released.

Example:

```java
DatabaseLayer.useMocks();

Test.startTest();
System.Savepoint sp1 = DatabaseLayer.Dml.setSavepoint();
System.Savepoint sp2 = DatabaseLayer.Dml.setSavepoint();
System.Savepoint sp3 = DatabaseLayer.Dml.setSavepoint();
DatabaseLayer.Dml.rollback(sp2);
DatabaseLayer.Dml.releaseSavepoint(sp3);
Test.stopTest();

Assert.areEqual(3, MockDml.SAVEPOINTS?.getAll()?.size(), 'Wrong # of savepoints');
// sp1 should not be rolled back *or* released:
MockDml.Savepoint mockSp1 = MockDml.SAVEPOINTS.get(0);
Assert.areEqual(false, mockSp1?.wasReleased);
Assert.areEqual(false, mockSp1?.wasRolledBack);
// sp2 was rolled back:
MockDml.Savepoint mockSp2 = MockDml.SAVEPOINTS.get(1);
Assert.areEqual(false, mockSp2?.wasReleased);
Assert.areEqual(true, mockSp2?.wasRolledBack);
// sp3 was released:
MockDml.Savepoint mockSp3 = MockDml.SAVEPOINTS.get(2);
Assert.areEqual(true, mockSp3?.wasReleased);
Assert.areEqual(false, mockSp3?.wasRolledBack);
```

Read more about the `MockDml.Savepoint` class [here](#the-mockdmlsavepoint-class).

Read more about the `MockDml.SavepointHistory` class [here](#the-mockdmlsavepointhistory-class).

### Validating DML Operations

The `MockDml` class does not _actually_ manipulate records in the Salesforce database, so you cannot use SOQL to retrieve changes. Instead, use the MockDml's mock `Database` object to reference records that were manipulated by `MockDml`.

The mock database (`MockDml.Database`) consists of several `History` objects, one for each major DML operation. You can reference the database these through static getter properties:

- `MockDml.CONVERTED`
- `MockDml.DELETED`
- `MockDml.INSERTED`
- `MockDml.PUBLISHED`
- `MockDml.PURGED`
- `MockDml.UNDELETED`
- `MockDml.UPDATED`
- `MockDml.UPSERTED`

Example:

```java
@IsTest
static void someTest() {
  DatabaseLayer.useMocks();
  Account acc = new Account(Name = 'John Doe');

  Test.startTest();
  DatabaseLayer.Dml.doInsert(acc);
  Test.stopTest();

  List<Account> insertedAccs = MockDml.INSERTED.getRecords(Account.SObjectType);
  Assert.areEqual(1, insertedAccs?.size(), 'Account was not inserted');
}
```

Read more about the `MockDml.Database` class [here](#the-mockdmldatabase-class).

Read more about the `MockDml.History` class [here](#the-mockdmlhistory-class).

### Public Inner Types

#### The `MockDml.ConditionalFailure` Interface

Evaluates a given SObject record and DML operation, and returns an Exception object if the operation should fail for that record.

If `null` is returned, the operation will succeed. If an Exception is returned, the operation will fail in accordance with the current `Dml` object's defined `allOrNone` behavior. This behavior mirrors standard DML `allOrNone` logic:

- If `allOrNone == true`, the Exception returned by the `checkFailure()` method is thrown, and the entire operation fails.
- If `allOrNone == false`, only the current SObject fails. The matching Database Result object returned by the DML operation will indicate that the record failed. The resulting error message for the result is derived from the Exception returned by the `checkFailure()` method.

The interface contains just one required method.

##### `checkFailure`

The only required method to be implemented by the interface. This method is called once per DML operation, per record submitted for processing.

- `checkFailure(MockDml.Operation operation, SObject record)`

Example:

```java
public class ExampleFailure implements MockDml.ConditionalFailure {
  public Exception checkFailure(MockDml.Operation operation, SObject record) {
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

:warning: **IMPORTANT**: Starting in version 3.0.0, the `MockDml.Operation` enum will be replaced with the `Dml.Operation` enum. These enums have the same values. To prepare for the transition, add a _duplicate_ method to your classes that include `Dml.Operation`. Then in a subsequent release, the `MockDml.Operation` enum will be removed entirely.

#### The `MockDml.Database` Class

Simulates a Salesforce database when mocks are used. The class stores a `MockDml.History` object for each DML method, along with logic to handle savepoint/rollback behavior.

This object is available as a public static property, `MockDml.MockDatabase`. A blank database object is initialized by default. As records are submitted for mock DML over time, the records are then added to the appropriate history object.

This class has the following public properties:

- `MockDml.RecordHistory converted`: A read-only property containing a history object that stores all upserted records during a transaction. The `MockDml.CONVERTED` getter property returns this value from the current mock database.
- `MockDml.RecordHistory deleted`: A read-only property containing a history object that stores all upserted records during a transaction. The `MockDml.DELETED` getter property returns this value from the current mock database.
- `MockDml.RecordHistory inserted`: A read-only property containing a history object that stores all upserted records during a transaction. The `MockDml.INSERTED` getter property returns this value from the current mock database.
- `MockDml.PlatformEventHistory published`: A read-only property containing a history object that stores all upserted records during a transaction. The `MockDml.PUBLISHED` getter property returns this value from the current mock database.
- `MockDml.RecordHistory purged`: A read-only property containing a history object that stores all upserted records during a transaction. The `MockDml.PURGED` getter property returns this value from the current mock database.
- `MockDml.RecordHistory undeleted`: A read-only property containing a history object that stores all upserted records during a transaction. The `MockDml.UNDELETED` getter property returns this value from the current mock database.
- `MockDml.RecordHistory updated`: A read-only property containing a history object that stores all upserted records during a transaction. The `MockDml.UPDATED` getter property returns this value from the current mock database.
- `MockDml.RecordHistory upserted`: A read-only property containing a history object that stores all upserted records during a transaction. The `MockDml.UPSERTED` getter property returns this value from the current mock database.
- `Boolean resetOnRollback`: This property determines how the database will behave when a rollback occurs.
    - By default (`true`), savepoints will store a "snapshot" of the mock database at the time that they were initialized. Rolling back the savepoint will then cause the current `MockDatabase` to be replaced with that snapshot.
    - If set to `false`, the database will "ignore" rollbacks. You'll be still be able to reference any records that were processed in the corresponding history object, even if they were rolled back. This may be desireable if you want to see what happened before the rollback occurred, or to improve performance in cases where this isn't needed.

The class has just one public method:

##### `snapshot`

This method returns a shallow copy of the current `MockDatabase`, using JSON-serialization. Changes to this snapshot object will not mutate the database object that generated it, and vice-versa.

- `MockDml.Database snapshot()`

#### The `MockDml.History` Class

The `MockDml.History` class stores records that were submitted for a particular DML operation while using mocks. It contains methods that allow callers to inspect what changes were made during the course of a test.

The `MockDml.History` class includes these public methods:

##### `eraseHistory`

:warning: **Important**: This method is deprecated, and will soon be removed in a future release. Replace all instances of this method with `MockDml.eraseAllHistories()`.

Clears the current History object.

- `MockDml.History eraseHistory()`

##### `get`

Returns a specific record that was processed by the current DML operation. Returns `null` if no such record was processed.

- `get(SObjectType objectType, String idOrUuid)`
- `get(Id recordId)`
- `get(SObject record)`

##### `getAll`

Retrieves a map of records that were processed by the current DML operation, grouped by their `SObjectType`:

- `Map<SObject, List<SObject>> getAll()`

##### `getRecords`

Retrieves a list of all records of the provided `SObjectType` that were processed by the current DML operation.

- `List<SObject> getRecords(SObjectType objectType)`

##### `wasProcessed`

Determines if a specific record was processed by the current DML operation.

- `wasProcessed(SObjectType objectType, String idOrUuid)`
- `wasProcessed(Id recordId)`
- `wasProcessed(SObject record)`

Example:

```java
@IsTest
static void someTest() {
  DatabaseLayer.useMocks();
  Account acc = new Account(Name = 'John Doe');

  Test.startTest();
  DatabaseLayer.Dml.doInsert(acc);
  Test.stopTest();

  List<Account> insertedAccs = MockDml.INSERTED.getRecords(Account.SObjectType);
  Assert.areEqual(1, insertedAccs?.size(), 'Account was not inserted');
}
```

#### The `MockDml.Savepoint` Class

This class decorates a `System.Savepoint` object, and keeps track of its usage throughout a transaction. Refer to this object's properties when you need to assert if a savepoint was rolled back or released.

You can access `MockDml.Savepoint`s via the `MockDml.SavepointHistory` class, which is acccessible via the `MockDml.SAVEPOINTS` static property. Read more about the `MockDml.SavepointHistory` class [here](#the-mockdmlsavepointhistory-class).

The object has the following properties:

- `Integer index`: (Read-only) The Savepoint's index, corresponding with the number of savepoints generated in the transaction, starting with 0.
- `String name`: (Read-only) The `System.Savepoint`'s name, which is discoverable via the savepoint's `toString()` implementation.
- `Boolean wasReleased`: (Read-only) Indicates whether `DatabaseLayer.Dml.releaseSavepoint()` was called for the current savepoint.
- `Booelan wasRolledBack`: (Read-only) Indicates whether `DatabaseLayer.Dml.rollback()` was called for the current savepoint.

Example:

```java
DatabaseLayer.useMocks();
System.Savepoint savepoint = DatabaseLayer.Dml.setSavepoint();

Test.startTest();
DatabaseLayer.Dml.rollback(savepoint);
Test.stopTest();

MockDml.Savepoint sp = MockDml.SAVEPOINTS.get(0);
Assert.areEqual(true, sp?.wasRolledBack);
Assert.areEqual(false, sp?.wasReleased);
```

#### The `MockDml.SavepointHistory` Class

This class stores all `MockDml.Savepoint` objects generated throughout a transction. You can interact with this class's methods to retrieve a specific savepoint, or all savepoints.

##### `getAll`

Returns all `MockDml.Savepoint` objects generated in a transaction, via `DatabaseLayer.Dml.setSavepoint()`.

- `List<MockDml.Savepoint> getAll()`

##### `get`

Returns a specific `MockDml.Savepoint` object, by the specified index or `System.Savepoint` object.

- `MockDml.Savepoint get(Integer index)`
- `MockDml.Savepoint get(System.Savepoint)`

Example:

```java
DatabaseLayer.useMocks();
System.Savepoint sp1 = DatabaseLayer.Dml.setSavepoint();
System.Savepoint sp2 = DatabaseLayer.Dml.setSavepoint();
// Get all savepoints:
List<MockDml.Savepoint> all = MockDml.SAVEPOINTS?.getAll();
// Get a specific savepoint:
MockDml.Savepoint first = MockDml.SAVEPOINTS?.get(0);
MockDml.Savepoint second = MockDml.SAVEPOINTS?.get(sp2);
```
