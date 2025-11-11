Using `DatabaseLayer.Soql`, you can easily engage mocks to test your code without directly interacting with the Salesforce database.

Read on below, and check out these resources for more information:

- [MockSoql Methods](./The-MockSoql-Class#Methods)
- [The MockSoql.Simulator Interface](./The-MockSoql.Simulator-Interface)

## Setting Up Mocks

Follow this process to mock queries in an `@IsTest` context:

1. Ensure all SOQL statements in the code path to be tested use `DatabaseLayer.Soql` class. Standard SOQL operations, via inline SOQL queries or `Database.query` methods cannot be mocked.
2. Call `DatabaseLayer.useMocks()` or `DatabaseLayer.useMockSoql()` as the first line of your apex test. Now, any `Soql` operations will be processed by `MockSoql` instead.
3. Define logic that tells your mocked queries what to return when they run. See [**Simulating SOQL Queries**](./Mocking-Soql-Queries#Simulating-SOQL-Queries) below for more details.
4. Call the code you want to test. As it runs, the framework will run the `MockSoql` logic you defined, instead of retrieving query results from the Salesforce database.

Example:

```apex
DatabaseLayer.useMocks();
// Use the `MockRecord` class to generate a mock account to be returned by the query:
Account account = (Account) new MockRecord(Account.SObjectType)?.withId()?.toSObject();
// All queries globally should return this account:
MockSoql.setGlobalMock().withResults(new List<Account>{ account });
// Run the query - this will use MockSoql:
List<Account> results = (List<Account>) DatabaseLayer.Soql.newQuery(Account.SObjectType)
  ?.setRowLimit(1)
  ?.toSoql()
  ?.query();
Assert.areEqual(1, results?.size(), 'Wrong # of results');
Assert.areEqual(account?.Id, results?.get(0)?.Id, 'Did not return mock account');
```

## Simulating SOQL Queries

By default, all `MockSoql` objects will return an empty list of results, but you can configure your queries to behave in one of the following ways:

- Return a static list of results each time your query runs
- Throw a static `Exception` each time your query runs.
- Dynamically determine the results of the query, using custom logic in the [`MockSoql.Simulator`](./The-MockSoql.Simulator-Interface) interface.

### Static vs. Dynamic Query Mocks

Mock query logic can be defined for all queries encountered during a transaction, via the static [`MockSoql.setGlobalMock()`](./The-MockSoql-Class#setGlobalMock) method. Or, they can be defined for each individual query, via the instance [`setMock()`](./The-MockSoql-Class#setMock) method.

Both approaches have their own set of benefits and drawbacks:

- `MockSoql.setGlobalMock`: (recommended) Allows you to define mocks without exposing queries as top-level class variables, but they are less flexible. If you encounter more than one query, you will likely need to use the `MockSoql.Simulator` interface to handle each query seprately, instead of injecting a static list of results to be returned.
- `setMock`: Gives the flexibility of defining per-query results to be returned, without using a `MockSoql.Simulator` implementation. In practice, this means all `Soql` queries in your production code must be exposed as top-level class variables, which can be less than ideal for a number of reasons.

We generally recommend the first approach, as it allows Soql queries to be properly encapsulated, while the `MockSoql.Simulator` interface offers the flexibility needed to handle even the most complex of test scenarios.

```apex
DatabaseLayer.useMocks();
Account account = (Account) new MockRecord(Account.SObjectType)?.withId()?.toSObject();
List<Account> accounts = new List<Account>{ account };
Soql query = DatabaseLayer.Soql.newQuery(Account.SObjectType)?.toSoql();
// Inject results for an individual query:
((MockSoql) query)?.setMock()?.withResults(accounts);
// Or, inject results for *all* queries encountered during the transaction:
MockSoql.setGlobalMock().withResults(accounts);
```

### Injecting Mocks

The [setGlobalMock](./The-MockSoql-Class#setGlobalMock) and [setMock](./The-MockSoql-Class#setMock) methods behave similarly, and support two different modes of mocking, using static or dynamic results.

When 0 arguments are passed to the method, the class returns a [MockSoql.StaticResults](./The-MockSoql.StaticResults-Class) object. This object has methods to inject the following:

- ([withResults](./The-MockSoql.StaticResults-Class#withResults)): Injects a static list of results to be returned when the query runs.
- ([withError[(./The-MockSoql.StaticResults-Class#withError)): Injects a static Exception to be thrown when the query runs.

Alternatively, you can pass a [`MockSoql.Simulator`](./The-MockSoql.Simulator-Interface) object to either of the `setMock` / `setGlobalMock` methods. This interface can be used to define dynamic query results to be returned when queries run. Think of this interface as the SOQL equivalent to the [`System.HttpCalloutMock` interface](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_interface_httpcalloutmock.htm) that Apex includes for HTTP Callouts.

```apex
DatabaseLayer.useMocks();
Account account = (Account) new MockRecord(Account.SObjectType)?.withId()?.toSObject();
List<Account> accounts = new List<Account>{ account };
Soql query = DatabaseLayer.Soql.newQuery(Account.SObjectType)?.toSoql();
// Inject static results:
MockSoql.setGlobalMock()?.withResults(accounts)
// Inject a System.QueryException:
MockSoql.setGlobalMock()?.withError();
// Inject a custom Exception:
System.Exception customError = new MyCustomError();
MockSoql.setGlobalMock()?.withError(customError);
// Inject dynamic query-mocking logic:
MockSoql.Simulator logic = new MyCustomQueryLogic();
MockSoql.setGlobalMock(logic);
```

---

## Special Cases

### Mocking Aggregate Queries

Unlike `SObject`s, `Schema.AggregateResult`s cannot be manually constructed or deserialized; they can only be generated by performing an actual SOQL query that interacts with the database.

For this reason, the `Soql` class returns its own [Soql.AggregateResult](./The-Soql.AggregateResult-Class) objects in aggregate queries. This class wraps the standard `Schema.AggregateResult` object, and offers access to all its same methods.

In tests, you can construct [MockSoql.AggregateResult](./The-MockSoql.AggregateResult-Class) objects and inject them in to your queries:

```apex
DatabaseLayer.useMocks();
MockSoql.AggregateResult agg = new MockSoql.AggregateResult()?.addParameter('numRecords', 100);
List<Soql.AggregateResult> mocks = new List<MockSoql.AggregateResult>{ agg });
MockSoql.setGlobalMock()?.withResults(mocks);
List<Soql.AggregateResult> results = soql?.aggregateQuery();
```

See the reference guide for more information about [Soql.AggregateResult](./The-Soql.AggregateResult-Class) and [MockSoql.AggregateResult](./The-MockSoql.AggregateResult-Class).

### Mocking Query Locators

The `Database.QueryLocator` object cannot be mocked in a traditional sense, since it manually constructed, or JSON-deserialized. The only way to create an object of this type is by directly interacting with the Salesforce database, via the `Database.getQueryLocator` method.

For this reason, `Soql`'s [getQueryLocator()](./The-Soql-Class#getQueryLocator) method returns a `Soql.QueryLocator` object, which wraps th standard `Database.QueryLocator` object and provides access to all its methods. For the most part, developers can interact with this object the same way they would with an ordinary `Database.QueryLocator`:

```apex
Soql soql = DatabaseLayer.Soql.newQuery(Account.SObjectType)?.toSoql();
Soql.QueryLocator locator = query?.getQueryLocator();
String query = locator?.getQuery();
System.Iterator<SObject> iterator = locator?.iterator();
```

There is one limitation to this approach: Certain frameworks (like `Database.Batchable`) that rely on the underlying `Database.QueryLocator` object cannot be mocked:

```apex
public class MyBatch implements Database.Batchable<SObject> {
	public Database.QueryLocator start(Database.BatchableContext ctx) {
		Soql.QueryLocator locator = DatabaseLayer.Soql.newQuery(Account.SObjectType)?.toSoql()?.getQueryLocator();
		// Retrieve the underlying Database.QueryLocator:
		return locator?.getLocator();
	}
	// ...rest of the class omitted for brevity...
}
```

The Soql class's `getQueryLocator` method returns a `Soql.QueryLocator`. In a mock context, the underlying `Database.QueryLocator` will be always be `null`. This means that the `start` method will return a null object, causing the batch to fail:

```apex
@IsTest
static void cannotMockBatchableQueryLocator() {
  DatabaseLayer.useMocks();
  MyBatch job = new MyBatch();

  Test.startTest();
  Database.executeBatch(job);
  Test.stopTest();
  // ! System.NullPointerException
}
```

You can employ one of the following strategies to work around this:

- Call the batch's `start`, `execute`, and `finish` methods invidually in your unit tests.
- Amend the batch's `start` method to return an [iterable object](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_iterable.htm) instead; there are some drawbacks to this approach.
- Use `System.Queueable` jobs paired with a `System.Finalizer` instead of `Database.Batchable`.
