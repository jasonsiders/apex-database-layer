Using `DatabaseLayer.Dml`, you can easily engage mocks to test your code without directly interacting with the Salesforce database.

You can cover most test cases by adding just a single line of code to your tests:

## Setting Up Mocks

First, ensure all DML statements in the code path to be tested use `DatabaseLayer.Dml` methods. Standard DML operations **_cannot_** be mocked.

In `@IsTest` context, call [`DatabaseLayer.useMocks()`](./The-DatabaseLayer-Class#useMocks) or [`DatabaseLayer.useMockDml()`](./The-DatabaseLayer-Class#useMockDml). Now, any [Dml](./The-Dml-Class) operations will be processed by the [MockDml](./The-MockDml-Class) instead.

By default, `MockDml` will simulate a successful DML operation. You can optionally inject errors using the [`MockDml.shouldFail`](./The-MockDml-Class#shouldFail) or [`MockDml.shouldFailIf`](./The-MockDml-Class#shouldFailIf) methods.

Finally, call the code you want to test. As it runs, the framework will run `MockDml` logic instead of actually calling the Salesforce database.

## Simulating Successful DML Operations

By default, `MockDml` operations will simulate a successful DML operation. Successful DML operations result in the following:

- Inserted (or upserted records without an Id) will be assigned a unique record Id which corresponds with its `SObjectType`.
- The resulting database result object(s) (ex., `Database.SaveResult`) will have `isSuccess` set to _true_.
- Since DML isn't _actually_ being processed, you won't be able to retrieve the records from the Salesforce database via SOQL. Instead, leverage `MockDml`'s own [mock database](./The-MockDml.Database-Class). This mock database stores all records that were operated on, for each DML operation. You can access these through the `MockDml`'s properties, ex. `MockDml.INSERTED`.

Example:

```apex
DatabaseLayer.useMocks();
Account account = new Account();
// By default, DML operations using mocks will succeed:
Database.SaveResult result = DatabaseLayer.Dml.doInsert(account);
Assert.isTrue(result?.isSuccess(), 'Insert failed');
Assert.isNotNull(account?.Id, 'Missing Id');
Assert.areEqual(true, MockDml.INSERTED.wasProcessed(account), 'Was not processed');
```

## Simulating Failed DML Operations

If you want all DML operations to fail, use the [shouldFail](./The-MockDml-Class#shouldFail) method.

```apex
DatabaseLayer.useMocks();
MockDml.shouldFail();
// Now all DML operations will fail:
Account account = new Account();
DatabaseLayer.Dml.doInsert(account);
// ! System.DmlException
```

If you want more advanced logic, or if you want to return a custom error, use the [shouldFailIf](./The-MockDml-Class#shouldFailIf) method. This method accepts a [MockDml.ConditionalFailure](./The-MockDml.ConditionalFailure-Interface) object, which returns an Exception to be thrown if certain conditions are met.

In this example, the insert succeeds, but the subsequent update fails:

```apex
DatabaseLayer.useMocks();
// See this class's logic below for more details:
MockDml.ConditionalFailure logic = new FailOnUpdate();
MockDml.shouldFailIf(logic);
// Now all DML "update" operations will fail:
Account account = new Account();
DatabaseLayer.Dml.doInsert(account);
account.OwnerId = UserInfo.getUserId();
DatabaseLayer.Dml.doUpdate(account);
// ! System.DmlException
```

```apex
public class FailOnUpdate implements MockDml.ConditionalFailure {
	public Exception checkFailure(Dml.Operation operation, SObject record) {
		if (operation == MockDml.DO_UPDATE) {
			// The operation should fail:
			return new System.DmlException();
		} else {
			// The operation should succeed:
			return null;
		}
	}
}
```

All mocked failures respect the mode of failure, as defined by the DML method's `allOrNone` flag:

```apex
DatabaseLayer.useMocks();
// All DML operations will fail, according to its AllOrNone value
MockDml.shouldFail();
Account account = new Account();
// AllOrNone = false, no error is thrown but the database result does not succeed:
Database.SaveResult result = DatabaseLayer.Dml.doInsert(account, false);
System.debug(result?.isSuccess()); // > "false"
// AllOrNone = true, an exception is thrown:
DatabaseLayer.Dml.doInsert(account, true);
// ! System.DmlException
```

## Special Cases

### Simulating Savepoints & Rollbacks

The framework also allows developers to simulate `System.Savepoint` objects and their associated operations. Using the [MockDml.SavepointHistory](./The-MockDml.SavepointHistory-Class) and [MockDml.Savepoint](./The-MockDml.Savepoint-Class) objects, developers can inspect how savepoints were used over the course of an apex test.

```apex
DatabaseLayer.useMocks();
Account account = new Account();

Test.startTest();
System.Savepoint sp = DatabaseLayer.Dml.setSavepoint();
DatabaseLayer.Dml.doInsert(account);
Database.rollback(sp);
Test.stopTest();

MockDml.Savepoint savepoint = MockDml.SAVEPOINTS?.get(0);
Assert.isTrue(savepoint?.wasRolledBack, 'Savepoint was not rolled back');
// Because the savepoint was rolled back, the Account wasn't actually inserted:
Assert.isTrue(MockDml.INSERTED?.getAll()?.isEmpty(), 'Records were inserted');
```

> _**Note**: By default, when a savepoint is rolled back, the `MockDml`'s database is reset to the point in time that the savepoint was generated. This behavior can be overridden, by setting `MockDml.MockDatabase.resetOnRollback = false`_.
