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

## Public Methods

### Performing DML

The `Dml` class contains methods which mirror the functionality of DML methods in the standard [`Database` class](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_methods_system_database.htm), including its numerous method overloads:

```java
// Specify allOrNone and access level
DatabaseLayer.Dml.doUpdate(account, false, System.AccessLevel.USER_MODE);
// Use the default implementation
DatabaseLayer.Dml.doUpdate(account);
```

Since DML keywords (like `insert`, `update`, and `delete`) are reserved, the `Dml` class's methods are prefixed with the "do" predicate. For example, `doInsert`, `doUpdate`, and `doDelete`.

> **Note:** The `emptyRecycleBin` method name is not a reserved keyword, so the "do" predicate is not used:
>
> ```java
> DatabaseLayer.Dml.emptyRecycleBin(account);
> ```

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

To simulate failed DML operations, you must first indicate to the `MockDml` class that it should fail. Most use cases can be handled by calling the `fail()` method, which will cause all subsuquent DML operations to fail:

```java
DatabaseLayer.useMocks();
Account account = new Account(Name = 'John Doe');
MockDml dml = (MockDml) DatabaseLayer.Dml;
dml?.fail();
try {
	dml?.doInsert(account);
	Assert.fail('DML operation did not fail');
} catch (System.DmlException error) {
	// As expected!
}
```

You can inject more precise failure logic by passing an instance of [`MockDml.ConditionalLogic`](#the-mockdmlconditionalfailure-interface) to the `failIf()` method. This can be useful if only one of multiple DML operations, or subset of records within the same DML operation should fail:

```java
// The "ExampleFailure" class will only fail on DML updates
MockDml.ConditionalFailure logic = new ExampleFailure();
DatabaseLayer.useMockDml()?.failIf(logic);
Database.SaveResult result = DatabaseLayer.Dml.doInsert(account);
Assert.isFalse(result?.isSuccess, 'DML Operation did not fail');
Assert.isNull(account?.Id, 'Account was inserted');
```

Read more about the `MockDml.ConditionalFailure` interface [here](#the-mockdmlconditionalfailure-interface).

### Simulating Savepoints & Rollbacks

Out of the box, salesforce doesn't give you many tools to check how savepoints were used over the course of a test. When used in conjunction with the `Dml` class's savepoint methods, `MockDml` gives you the ability to inspect each savepoint generated in a transaction, along with details about how they were used, ie., whether they were rolled back or released:

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

##### `snapshot`

This method returns a shallow copy of the current `MockDatabase`, using JSON-serialization. Changes to this snapshot object will not mutate the database object that generated it, and vice-versa.

- `MockDml.Database snapshot()`

#### The `MockDml.History` Class

The `MockDml.History` class stores records that were submitted for a particular DML operation while using mocks. It contains methods that allow callers to inspect what changes were made during the course of a test.

The `MockDml.History` class includes three public methods:

##### `eraseHistory`

Clears the current History object; once called, the `getAll()` and `getRecords()` methods will return empty structures. Returns self.

- `MockDml.History eraseHistory()`

##### `getAll`

Retrieves a map of records that were processed by the current DML operation, grouped by their `SObjectType`'s API Name.

- `Map<String, List<SObject>> getAll()`

##### `getRecords`

Retrieves a list of all records of the provided `SObjectType` that were processed by the current DML operation.

- `List<SObject> getRecords(SObjectType objectType)`

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

TODO!

#### The `MockDml.SavepointHistory` Class

TODO!
