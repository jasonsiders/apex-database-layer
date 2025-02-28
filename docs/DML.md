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

In `@IsTest` context, mock DML operations by calling the `DatabaseLayer.useMocks()` method. Once this is done, the `DatabaseLayer.Dml` method will return `MockDml` objects. If the `Dml` methood is called _before_ `useMocks()`, then those objects will continue to be instances of `Dml`. To prevent issues, call the `useMocks()` method as the first line in your test.

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

#### The `MockDml.ConditionalFailure` Interface

Evaluates a given SObject record and DML operation, and returns an Exception object if the operation should fail for that record. If `null` is returned, the operation will succeed. If an Exception is returned, the operation will fail in accordance with the current `Dml` object's defined `allOrNone` behavior. This behavior mirrors standard DML `allOrNone` logic:

-   If `allOrNone == true`, the Exception returned by the `checkFailure()` method is thrown, and the entire operation fails.
-   If `allOrNone == false`, only the current SObject fails. The matching Database Result object returned by the DML operation will indicate that the record failed. The resulting error message for the result is derived from the Exception returned by the `checkFailure()` method.

-   `checkFailure(MockDml.Operation operation, SObject record)`

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

### Validating DML Operations

Since the `MockDml` class does not actually manipulate records in the database, you cannot use SOQL to retrieve changes. Instead, use the MockDml `History` objects to retrieve records that were manipulated by a `MockDml` instance.

A `History` object exists for each major DML operation, and are enumerated as static properties on the `MockDml` class:

-   `MockDml.CONVERTED`
-   `MockDml.DELETED`
-   `MockDml.INSERTED`
-   `MockDml.PUBLISHED`
-   `MockDml.UNDELETED`
-   `MockDml.UPDATED`
-   `MockDml.UPSERTED`

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

Each of the above `History` object includes three public methods:

#### `eraseHistory`

Clears the current History object; once called, the `getAll()` and `getRecords()` methods will return empty structures. Returns self.

-   `MockDml.History eraseHistory()`

#### `getAll`

Retrieves a map of records that were processed by the current DML operation, grouped by their `SObjectType`.

-   `Map<SObjectType, List<SObject>> getAll()`

#### `getRecords`

Retrieves a list of all records of the provided `SObjectType` that were processed by the current DML operation.

-   `List<SObject> getRecords(SObjectType objectType)`
