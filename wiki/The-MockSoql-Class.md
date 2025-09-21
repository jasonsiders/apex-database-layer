This class extends the `Soql` class, and simulates queries made by `Soql` objects in `@IsTest` context when the framework is configured to use mocks.

The framework automatically returns a `MockSoql` instance whenever [DatabaseLayer.Soql.newQuery](./The-DatabaseLayer.SoqlProvider-Class#newQuery) is called after `DatabaseLayer.useMocks()` or `DatabaseLayer.useMockSoql()` is called.

Unlike `Soql`, `MockSoql` objects do not query the Salesforce database. Their queries return records based on custom logic injected by developers as part of the test.

Here is an example apex test that uses `MockSoql`:

```apex
@IsTest
static void someTest() {
  DatabaseLayer.useMocks();
  // Since useMocks was called, this should be a MockSoql object:
  Soql accountQuery = DatabaseLayer.Soql.newQuery(Account.SObjectType);
  // Inject some results that will be returned when the query runs:
  Account acc = new MockRecord(Account.SObjectType)
    ?.withId()
    ?.toSObject();
  MockSoql.setGlobalMock().withResults(new List<Account>{ acc });

  Test.startTest();
  List<Account> results = (List<Account>) accountQuery?.query();
  Test.stopTest();

  Assert.areEqual(1, results?.size(), 'Wrong # of Accounts returned');
  Assert.areEqual(acc?.Id, results?.get(0)?.Id, 'Did not return mock account');
}
```

---

## Methods

💡 **Important:** `MockSoql` inherits all of the same methods as its parent `Soql` class, documented [here](./The-Soql-Class#Methods). However, these methods do **not** interact with the Salesforce database.

### `setGlobalMock`

This static method defines query-mocking logic to be used for _all queries_. To assign this logic to _a specific query_, use the [instance method](./The-MockSoql-Class#setMock).

Use this method in conjunction with the [MockSoql.StaticResults](./The-MockSoql.StaticResults-Class) class for static query results, or use the [MockSoql.Simulator](./The-MockSoql.Simulator-Interface) interface to define your own custom logic.

- `static MockSoql.Simulator setGlobalMock(MockSoql.Simulator simulator)`
- `static MockSoql.StaticResults setGlobalMock()`

```apex
DatabaseLayer.useMocks();
MockSoql.setGlobalMock()?.withResults(someRecords);
```

### `setMock`

This instance method defines query-mocking logic to be used for _a specific query_. To assign this logic to _all queries_, use the [static method](./The-MockSoql-Class#setGlobalMock) instead.

Use this method in conjunction with the [MockSoql.StaticResults](./The-MockSoql.StaticResults-Class) class for static query results, or use the [MockSoql.Simulator](./The-MockSoql.Simulator-Interface) interface to define your own custom logic.

- `MockSoql.Simulator setMock(MockSoql.Simulator simulator)`
- `MockSoql.StaticResults setMock()`

```apex
DatabaseLayer.useMocks();
MockSoql mockQuery = (MockSoql) DatabaseLayer.Soql.newQuery(Account.SObjectType);
mockQuery?.setMock()?.withResults(someRecords);
```
