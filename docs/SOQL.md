# The `Soql` Class

The `Soql` class is designed to facilitate the construction and execution of SOQL queries within the Salesforce platform.

This class abstracts direct inline SOQL queries, promoting testability by allowing query methods to be mocked using the `MockSoql` class. The class allows developers to create and execute fully customizable queries, with methods that map directly to Salesforce's underlying `Database` query methods.

Use this class in place of inline SOQL to pave the way for faster, more scalable unit test that run independent of the Salesforce database.

## Constructing `Soql` Objects

`Soql` objects cannot be directly constructed via the `new` keyword. Instead, use the `DatabaseLayer.Soql.newQuery(SObjectType fromSObject)` method:

```java
Soql query = (Soql) DatabaseLayer.Soql
  ?.newQuery(Account.SObjectType)
  ?.addSelect(Account.Name)
  ?.setRowLimit(200);
```

The `DatabaseLayer` class is responsible for instantiating database objects of the correct type at runtime. In `@IsTest` context, developers can call `DatabaseLayer.useMocks()`, and an instance of the `MockSoql` class will be returned instead:

```java
DatabaseLayer.useMocks();
MockSoql query = (MockSoql) DatabaseLayer.Soql.newQuery(Account.SObjectType);
Assert.isInstanceOfType(query, MockSoql.class, 'Not a mock');
```

## Building SOQL Queries

Use `Soql` class's various builder methods to construct a SOQL query. Each of these methods returns a `Soql.Builder` instance, which can be used to support fluent query constrution:

```java
Soql accountQuery = (Soql) DatabaseLayer.Soql.newQuery(Account.SObjectType)
  ?.addSelect(Account.Name)
  ?.addWhere(Account.Type, Soql.NOT_EQUALS, 'Internal')
  ?.withSecurityEnforced()
  ?.orderBy(Account.CreatedDate, Soql.SortDirection.DESCENDING)
  ?.setRowLimit(200);
List<Account> accounts = accountQuery?.query();
```

---

## Mocking SOQL Queries

The `MockSoql` class can be used in place of a normal `Soql` object in the `@IsTest` context. The `MockSoql` class allows developers to inject dynamic static or dynamic results in their query objects, instead of actually querying the Salesforce database.

### Instantiating Mocks

In `@IsTest` context, mock SOQL operations by calling the `DatabaseLayer.useMocks()` method. Once this is done, the `DatabaseLayer.Soql.newQuery()` method will return `MockSoql` objects. If the `DatabaseLayer.Soql.newQuery` method is called _before_ `useMocks`, then those objects will continue to be instances of `Soql`, and not `MockSoql`. To prevent issues, call the `useMocks()` method as the first line in your test.

### Injecting Mock Query Results

By default, the `MockSoql`'s query methods will return an empty result set of the type that you are expecting:

```java
DatabaseLayer.useMocks();
MockSoql soql = (MockSoql) DatabaseLayer.Soql.newQuery(Account.SObjectType);
List<Account> results = soql?.query();
Assert.areEqual(0, results?.size(), 'Wrong # of resuls');
```

For these queries to return actual results, developers must first inject logic via either the static [`setGlobalMock`](#the-setglobalmock-static-method) method, or the member [`setMock`](#the-setmock-method) method.

Both methods have two overloads - one which accepts and returns a [`MockSoql.Simulator`](#the-mocksoqlsimulator-interface) object, and a 0-argument overlaod which returns a [`MockSoql.StaticResults`](#the-mocksoqlstaticresults-class) object.

#### The `setGlobalMock` Static Method

This method assigns "default" query logic to _all_ `Soql` objects. This allows developers to inject mocks for queries without the need to expose those objects as `@TestVisible`, class-level variables.

The 0-argument version of this method injects a [`MockSoql.StaticResults`](#the-mocksoqlstaticresults-class) object, and returns that same object. You can use that object's `withResults` to inject a static `List<Object>` to be returned, or its `withError` method to inject a static `Exception` to be thrown.

```java
DatabaseLayer.useMocks();
List<Account> mockAccounts = SomeTestFactory.initAccounts();
MockSoql.setGlobalMock()?.withResults(mockAccounts);
```

For more complex query logic, use the 1-argument version of this method, which accepts a [`MockSoql.Simulator`](#the-mocksoqlsimulator-interface) object. You can create your own custom query logic by creating a class which implements this interface, and then pass it to all `Soql` objects through this method:

```java
DatabaseLayer.useMocks();
MockSoql.Simulator simulator = new MyCustomQueryLogic();
MockSoql.setGlobalMock(simulator);
```

- `MockSoql.Simulator static setGlobalMock(MockSoql.Simulator simulator)`
- `MockSoql.StaticResults static setGlobalMock()`

#### The `setMock` Method

This method assigns query logic to a _specific_ `Soql` object, overriding any global defaults set via `MockSoql.setGlobalMock`. In a real-world scenario, queries in a production class **must** be exposed as public/`@TestVisible` variables to use this method.

The 0-argument version of this method injects a [`MockSoql.StaticResults`](#the-mocksoqlstaticresults-class) object, and returns that same object. You can use that object's `withResults` to inject a static `List<Object>` to be returned, or its `withError` method to inject a static `Exception` to be thrown.

```java
DatabaseLayer.useMocks();
List<Account> mockAccounts = SomeTestFactory.initAccounts();
MockSoql queryToMock = (MockSoql) MyClass.SOME_QUERY;
queryToMock?.setMock()?.withResults(mockAccounts);
```

For more complex query logic, use the 1-argument version of this method, which accepts a [`MockSoql.Simulator`](#the-mocksoqlsimulator-interface) object. You can create your own custom query logic by creating a class which implements this interface, and then pass it to a `Soql` object through this method:

```java
DatabaseLayer.useMocks();
MockSoql.Simulator simulator = new MyCustomQueryLogic();
MockSoql queryToMock = (MockSoql) MyClass.SOME_QUERY;
queryToMock?.setMock(simulator);
```

- `MockSoql.Simulator setMock(MockSoql.Simulator simulator)`
- `MockSoql.StaticResults setMock()`

#### The `MockSoql.Simulator` Interface

The `MockSoql.Simulator` interface defines custom logic for returning query results. Use this interface when you need more complex logic than what [`MockSoql.StaticResults`](#the-mocksoqlstaticresults-class) can provide.

The interface has one required method:

- `List<Object> simulateQuery(Soql queryToMock)`

Callers can conditionally return results based on the details of the provided `Soql` argument. For example, you if the query is `FROM Task`, return a list of Tasks:

```java
private class CustomQueryLogic implements MockSoql.Simulator {
  public List<Object> simulateQuery(Soql queryToMock) {
    String fromSObjectName = queryToMock?.entity;
    if (fromSObjectName == Task.SObjectType.toString()) {
      return this.simulateTaskQuery();
    } else if (fromSObjectName == Account.SObjectType.toString()) {
      // You could imagine methods to simulate account queries here:
    } else {
      return new List<Object>();
    }
  }

  private List<Task> simulateTaskQuery() {
    // For each inserted contact, return a Task
    List<Task> results = new List<Task>();
    List<Contact> contacts = (List<Contact>) MockDml.INSERTED.getRecords(
      Contact.SObjectType
    );
    for (Contact contact : contacts) {
      Task task = (Task) new MockRecord(Task.SObjectType)
        ?.setField(Task.Subject, 'Introductory Call')
        ?.setField(Task.WhatId, contact?.AccountId)
        ?.setField(Task.WhoId, contact?.Id)
        ?.withId()
        ?.toSObject();
      results?.add(task);
    }
    return results;
  }
}
```

#### The `MockSoql.StaticResults` Class

Not all testing scenarios require the creation of a custom `MockSoql.Simulator` object. Most simple use cases can be handled by using the included `MockSoql.StaticResults` object.

This object cannot be directly constructed. Create an instance of this object by calling the 0-argument versions of the [`MockSoql.setGlobalMock`](#the-setglobalmock-static-method) static method, or the [`setMock`](#the-setmock-method) member method.

This object implements `MockSoql.Simulator` interface, and includes methods which allow callers to inject a static list of results, or an exception to be thrown. Whenever the query runs, the injected results are returned.

<h5>`withError`</h5>

Injects an error to be thrown each time the query runs. Callers can provide a specific exception object, if desired. The 0-argument overload of this method will inject a generic `System.QueryException`.

- `MockSoql.StaticResults withError(System.Exception error)`
- `MockSoql.StaticResults withError()`

```java
DatabaseLayer.useMocks();
// Queries will always throw a System.QueryException:
MockSoql.setGlobalMock()?.withError();
// Queries will always throw some other exception type:
System.Exception someOtherError = new System.CalloutException();
MockSoql.setGlobalMock()?.withError(someOtherError);
```

<h5>`withResults`</h5>

Injects a static list of results. This list will be returned each time the query runs.

- `MockSoql.StaticResults withResults(List<Object> results)`

```java
DatabaseLayer.useMocks();
Account mockAccount = (Account) new MockRecord(Account.SObjectType)?.withId()?.toSObject();
// Queries will always return the provided List<Object>
MockSoql.setGlobalMock()?.withResults(new List<Account>{ mockAccont });
```

### Special Considerations

#### Mocking Aggregate Queries

`MockSoql.AggregateResult` is a A constructable version of the `Soql.AggregateResult` class, which wraps the `Schema.AggregateResult` class and its methods. `Schema.AggregateResult` objects cannot be directly constructed, serialized, or otherwise mocked.

You can use this object along in conjunction with existing mocking methods to inject these results in queries. For example:

```java
DatabaseLayer.useMocks();
MockSoql.AggregateResult agg = new MockSoql.AggregateResult()?.addParameter('numRecords', 100);
MockSoql?.setGlobalMock()?.withResults(new List<MockSoql.AggregateResult>{ agg });
List<Soql.AggregateResult> results = soql?.aggregateQuery();
```

<h5>addParameter</h5>

Adds a column to the current `AggregateResult`. These can be created with or without an _alias_. If an alias isn't provided, the column is assigned a default alias, ex. `expr0'`. This mirrors the behavior of the underlying `Schema.AggregateResult` object.

- `MockSoql.AggregateResult addParameter(String alias, Object value)`
- `MockSoql.AggregateResult addParameter(Object value)`

#### Mocking Query Locators

The `Database.QueryLocator` object cannot be mocked in a traditional sense, since it manually constructed, or JSON-deserialized. The only way to create an object of this type is by directly interacting with the Salesforce database, via the `Database.getQueryLocator` method.

For this reason, the `Soql` class uses a decorator class, `Soql.QueryLocator`. For the most part, developers can interact with this object the same way they would with a `Database.QueryLocator`:

```java
Soql soql = (Soql) DatabaseLayer.Soql.newQuery(Account.SObjectType);
Soql.QueryLocator locator = query?.getQueryLocator();
String query = locator?.getQuery();
System.Iterator<SObject> iterator = locator?.iterator();
```

In mock implementations there is no underlying `Database.QueryLocator` driving the interactions; instead, the `MockSoql` class injects its mock results to the iterator returned by the query locator's `iterator` method.

There is one limitation to this approach, and that is that frameworks that rely on the underlying `Database.QueryLocator` object cannot be mocked. This is most prevalent in `Database.Batchable` classes that return a query locator object in its `start()` method. For example:

```java
public class MyBatch implements Database.Batchable<SObject> {
  @TestVisible
  private Soql soql = (Soql) DatabaseLayer.Soql.newQuery(Account.SObjectType);

  public Database.QueryLocator start(Database.BatchableContext ctx) {
    // The getCursor() method returns the underlying
    // Database.QueryLocator expected by this method
    return soql?.getQueryLocator()?.getCursor();
  }

  public void execute(Database.BatchableContext ctx, List<Account> accs) {
    // ...
  }

  public void finish(Database.BatchableContext ctx) {
    // ...
  }
}
```

The Soql class's `getQueryLocator` method returns a `Soql.QueryLocator`. In mock contexts, this object's underlying `Database.QueryLocator` will be `null`. This means that the `start` method will return a null object, causing the batch to fail:

```java
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

Developers can employ one of the following strategies to work around this:

- Have your unit tests call the batch's `start`, `execute`, and `finish` methods invidually.
- Amend the `start` method to return an [iterable object](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_iterable.htm) instead.
- Use `System.Queueable` jobs paired with a `System.Finalizer` instead of `Database.Batchable`.

---

## Public Methods

### Performing Queries

The `Soql` class contains several methods which provide parity with the query methods found in the standard [`Database`](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_methods_system_database.htm) class:

#### `aggregateQuery`

Performs aggregate queries and returns results as a list of `Soql.AggregateResult` objects. This type wraps the `Schema.AggregateResult` objects to provide mockable results in tests.

- `List<Soql.AggregateResult> aggregateQuery()`

#### `countQuery`

Executes a count query, which should only contain aggregation functions like `COUNT()`. Returns the count of records that match the query.

- `Integer countQuery()`

#### `getQueryLocator`

Retrieves a `Soql.QueryLocator` object that can be used to iterate over query results.

- `Soql.QueryLocator getQueryLocator()`

#### `query`

Executes the query and returns the results as a list of `SObject`. Alternatively, this method can return results as a specific `returnType`, ie., for aggregate queries.

- `List<SObject> query()`
- `Object query(Type returnType)`

#### `queryFirst`

Fetches the first result of the query or returns `null` if no results are found. This method is useful for cases where only a single result is expected.

- `SObject queryFirst()`

### Building Queries

These methods are derived from the `Soql.Builder` inner class. The `Soql` class extends this base class, along with other inner types, like `Soql.InnerClass` and `Soql.Subquery`. For this reason, you may have to cast new queries to the `Soql` type, especially when chaining builder methods together:

```java
// Invalid: "Illegal assignment from Soql.Builder to Soql"
Soql query = DatabaseLayer.Soql
  ?.newQuery(Account.SObjectType)
  ?.addSelect(Account.Name);

// Valid:
Soql query = (Soql) DatabaseLayer.Soql
  ?.newQuery(Account.SObjectType)
  ?.addSelect(Account.Name);
```

#### `addHaving`

Adds conditions to the HAVING clause of the query.

- `Soql.Builder addHaving(Soql.Aggregation agg, Soql.Operator operator, Object value)`

#### `addSelect`

Adds fields or `Soql.Selectable` objects to the SELECT clause of the query. `Soql.Selectable` types include `Soql.Aggregation`, `Soql.ParentField`, and `Soql.Subquery` objects.

- `Soql.Builder addSelect(String fieldName, String alias)`
- `Soql.Builder addSelect(SObjectField field, String alias)`
- `Soql.Builder addSelect(String fieldName)`
- `Soql.Builder addSelect(List<SObjectField> fields)`
- `Soql.Builder addSelect(SObjectField field1, [field2, field3, field4, field5])`
- `Soql.Builder addSelect(List<Soql.Selectable> selectables)`
- `Soql.Builder addSelect(Soql.Selectable selectable1, [selectable2, selectable3, selectable4, selectable5])`

#### `addWhere`

Adds conditions to the WHERE clause of the query.

- `Soql.Builder addWhere(Soql.Criteria criteria)`
- `Soql.Builder addWhere(String fieldName, Soql.Operator operator, Object value)`
- `Soql.Builder addWhere(SObjectField field, Soql.Operator operator, Object value)`
- `Soql.Builder addWhere(String fieldName, Soql.Operator operator, Soql.Binder binder)`
- `Soql.Builder addWhere(SObjectField field, Soql.Operator operator, Soql.Binder binder)`

#### `bind`

Adds binding variables to the query. Binding variables are used to dynamically insert values into the query.

- `Soql.Builder bind(Map<String, Object> bindMap)`
- `Soql.Builder bind(String key, Object value)`
- `Soql.Builder bind(Soql.Binder binder)`

#### `defineAccess`

Sets the access level for the query.

- `Soql.Builder defineAccess(System.AccessLevel accessLevel)`

#### `deselect`

Removes specific fields from the SELECT clause of the query.

- `Soql.Builder deselect(String fieldName)`
- `Soql.Builder deselect(SObjectField field)`

#### `deselectAll`

Removes all fields from the SELECT clause of the query, essentially clearing any previously selected fields.

- `Soql.Builder deselectAll()`

#### `fromSObject`

Sets the entity from which to query data. Only call this method if you need to override the SObjectType set when constructing the query, via the `DatabaseLayer.Soql.newQuery(SObjectType objectType)` method.

- `Soql.Builder fromSObject(SObjectType objectType)`

#### `groupBy`

Adds fields to the GROUP BY clause of the query.

- `Soql.Builder groupBy(String fieldName)`
- `Soql.Builder groupBy(SObjectField field)`

#### `orderBy`

Adds fields to the ORDER BY clause of the query.

- `Soql.Builder orderBy(Soql.SortOrder sortOrder)`
- `Soql.Builder orderBy(String fieldName, Soql.SortDirection direction)`
- `Soql.Builder orderBy(SObjectField field, Soql.SortDirection direction)`

#### `reset`

Resets the builder to its default state, clearing all previously set clauses and parameters.

- `Soql.Builder reset()`

#### `selectAll`

Selects all fields from the specified entity by querying the schema for all available fields.

- `Soql.Builder selectAll()`

#### `setOuterHavingLogic`

Sets the logical operator (AND/OR) for combining HAVING conditions.

- `Soql.Builder setOuterHavingLogic(Soql.LogicType newLogicType)`

#### `setQueryIdentifier`

Assigns an identifier to the query. Callers can use this identifier to distinguish queries from one another, for example in mocks.

- `Soql setQueryIdentifier(String identifier)`

```java
// In MyClass.cls:
Soql myQuery = (Soql) DatabaseLayer.Soql
  ?.newQuery(Account.SObjectType)
  ?.setQueryIdentifier('My Account Query');

// In MyClassTest.cls:
MockSoql.Simulator queryMock = new MyQueryMock();
DatabaseLayer.useMocks().setGlobalMock(queryMock);

private class MyQueryMock implements MockSoql.Simulator {
  public List<Object> simulateQuery(Soql queryToMock) {
    if (queryToMock?.identifier == 'My Account Query') {
      // Do some mocking logic specific to this query
    } else {
      // Do some other mocking logic for other queries...
    }
  }
}
```

#### `setRowLimit`

Sets the maximum number of rows to return in the query result.

- `Soql.Builder setRowLimit(Integer rowLimit)`

#### `setRowOffset`

Sets the number of rows to skip before starting to return results.

- `Soql.Builder setRowOffset(Integer rowOffset)`

#### `setUsage`

Sets the usage context for the query.

- `Soql.Builder setUsage(Soql.Usage usage)`

#### `setOuterWhereLogic`

Sets the logical operator (AND/OR) for combining WHERE conditions.

- `Soql.Builder setOuterWhereLogic(Soql.LogicType newLogicType)`

#### `toInnerQuery`

Explicitly casts the current `Soql.Builder` to a `Soql.InnerQuery` instance. Useful for chaining complex queries.

- `Soql.InnerQuery toInnerQuery()`

#### `toSoql`

Explicitly casts the current `Soql.Builder` to a `Soql` instance. Useful for chaining complex queries.

- `Soql toSoql()`

#### `toSubquery`

Explicitly casts the current `Soql.Builder` to a `Soql.Subquery` instance. Useful for chaining complex queries.

- `Soql.Subquery toSubquery()`

#### `usingScope`

Sets the scope for the query.

- `Soql.Builder usingScope(Soql.Scope scope)`

#### `withSecurityEnforced`

Enforces security in the query to ensure that the user has appropriate access to the queried records.

- `Soql.Builder withSecurityEnforced()`

## Public Inner Types

### Soql.AggregateResult

Wraps the `Schema.AggregateResult` class, which cannot be mocked otherwise. Objects of this type are returned by the `aggregateQuery` SOQL method, and can be mocked by the `MockSoql.AggregateResult` class

#### `get`

Calls the underlying `Schema.AggregateResult` object's `get` method. The `key` parameter refers to the field alias if one is assigned, or the parameter's index in query preceded by the `expr` if one is not assigned (x, `expr0`).

- `get(String key)`

### Soql.Aggregation

Represents an aggregate expression in a SOQL query. For example, `COUNT(Id) numRecords`. This class implements `Soql.Selectable`, and can be used in `addSelect` methods. This can also be with `addHaving` methods when making an aggregate query.

Each `Soql.Aggregation` is comprised of the following:

- (required) a `Soql.Function` (ex., `COUNT`
- (usually) a field (ex., `Id`)
- (optionally) An alias (ex, `numRecords`)

#### Constructors

- `Soql.Aggregation(Soql.Function, String innerFieldName)`
- `Soql.Aggregation(Soql.Function, SObjectField field)`
- `Soql.Aggregation(Soql.Function)`

#### `withAlias`

Adds an alias to the aggregation. Ex., `numRecords`.

- `Soql.Aggregation withAlias(String alias)`

### Soql.Binder

Registers a bind variable to be used in the query. Ex, `SELECT Id FROM Account WHERE Name = :foo`.

Use this method in conjunction with the `addWhere` and `bind` SOQL methods.

#### Constructors

- `Soql.Binder(String key, Object value)`
- `Soql.Binder(String key)`

#### `getKey`

Returns the name of the bind variable to be used in the query.

- `String getKey()`

#### `getValue`

Returns the underlying value to be substituted at runtime during the query.

- `Object getValue()`

#### `setValue`

Set the underlying value to be substituted for the bind variable. This is done at runtime, when the query is actually made, via the `Database.queryWithBinds()` method.

- `Soql.Binder setValue(Object value)`

### Soql.Condition

Represents a single `WHERE` clause element. For example, `WHERE StageName = 'Closed Won'`.

```java
Soql.Condition condition = new Soql.Condition(
  Opportunity.StageName,
  Soql.Operator.EQUALS,
  'Closed Won'
);
```

Add `Soql.Condition` objects to an existing where via the `addWhere` method. When multiple conditions are present, the query will use `AND` logic to specify that all conditions must be true by default:

```java
// SELECT Id FROM Opportunity WHERE StageName = 'Closed Won' AND Amount > 1000000
Soql.Condition isClosedWon = new Soql.Condition(
  Opportunity.StageName,
  Soql.Operator.EQUALS,
  'Closed Won'
);
Soql.Condition worthAMil = new Soql.Condition(
  Opportunity.Amount,
  Soql.Operator.GREATER_THAN,
  1000000
);
Soql soql = (Soql) DatabaseLayer.Soql.newQuery(Opportunity.SObjectType)
  ?.addWhere(isClosedWon)
  ?.addWhere(worthAMil);
```

To use `OR` logic instead, use the [`setOuterWhereLogic`](#setouterwherelogic) SOQL method. To use complex or nested logic, use the [Soql.ConditionalLogic](#conditionallogic) class.

Like `Soql.ConditionalLogic`, the `Soql.Conditional` class implements a base `Soql.Criteria` interface, which the framework uses internally to keep things tidy.

#### Constructors

- `Soql.Condition(String property, Soql.Operator operator, Object value)`
- `Soql.Condition(SObjectField field, Soql.Operator operator, Object value)`

### Soql.ConditionalLogic

Represents a set of criterion to be added to a query. These criterion can be `Soql.Condition` objects, or other (nested) `Soql.ConditionalLogic` objects. Depending on the specified `Soql.LogicType`, these conditions are be delimited by `AND` or `OR` keywords.

This pattern faciliates building extremely complex query logic, like the (unnecessarily complex) one below:

```java
/*
  SELECT Id FROM Opportunity WHERE (
    IsWon = true
    OR (
      Amount > 1000000
      AND (
        CloseDate >= 2024-01-01
        OR (
          Account.BillingState = 'CA'
          AND Amount > 20000000
        )
      )
    )
  )
*/
// (Account.BillingState = 'CA' AND Amount > 2000000)
Soql.Condition fromCa = new Soql.Condition(
  'Account.BillingState',
  Soql.Operator.EQUALS,
  'CA'
);
Soql.Condition greaterThan2Mil = new Soql.Condition(
  Opportunity.Amount,
  Soql.Operator.GREATER_THAN,
  2000000
);
Soql.ConditionalLogic nest1 = new Soql.ConditionalLogic()
  ?.addCondition(fromCa)
  ?.addCondition(greaterThan2Mil);
// (CloseDate >= 2024-01-01 OR (...))
Soql.Condition closedThisYear = new Soql.Condition(
  Opportunity.CloseDate,
  Soql.Operator.GREATER_OR_EQUAL,
  Date.newInstance(2024, 01, 01)
);
Soql.ConditionalLogic nest2 = new Soql.ConditionalLogic()
  ?.addCondition(closedThisYear)
  ?.addCondition(nest1)
  ?.setLogicType(Soql.LogicType.ANY_CONDITIONS);
// (Amount > 1000000 AND (...))
Soql.Condition greaterThan1Mil = new Soql.Condition(
  Opportunity.Amount,
  Soql.Operator.GREATER_THAN,
  1000000
);
Soql.ConditionalLogic nest3 = new Soql.ConditionalLogic()
  ?.addCondition(greaterThan1Mil)
  ?.addCondition(nest2);
// IsWon = true OR (...)
Soql.Condition isWon = new Soql.Condition(
  Opportunity.IsWon,
  Soql.Operator.EQUALS,
  true
);
Soql soql = (Soql) DatabaseLayer.Soql
  ?.newQuery(Opportunity.SObjectType)
  ?.setOuterWhereLogic(Soql.LogicType.ANY_CONDITIONS)
  ?.setWhere(isWon)
  ?.setWhere(nest3);
```

By default, the `Soql` class uses an internal `Soql.ConditionalLogic` object as the "enclosing" logic for `WHERE` and `HAVING` clauses. Calls to the `addWhere` or `addHaving` Soql methods add the criterion to the appropriate `Soql.ConditionalLogic` object under the hood. Calling the `setOuterWhereLogic` and `setOuterHavingLogic` Soql methods change the appropriate object's `Soql.LogicType`.

```java
// SELECT Id FROM Opportunity WHERE StageName = 'Closed Won' AND Amount > 1000000
Soql.Condition isClosedWon = new Soql.Condition(
  Opportunity.StageName,
  Soql.Operator.EQUALS,
  'Closed Won'
);
Soql.Condition worthAMil = new Soql.Condition(
  Opportunity.Amount,
  Soql.Operator.GREATER_THAN,
  1000000
);
Soql soql = (Soql) DatabaseLayer.Soql.newQuery(Opportunity.SObjectType)
  ?.addWhere(isClosedWon)
  ?.addWhere(worthAMil);
```

Like `Soql.Condition`, the `Soql.ConditionalLogic` class implements a base `Soql.Criteria` interface, which the framework uses internally to keep things tidy.

#### `addCondition`

Adds a `Soql.Criteria` object (`Soql.Condition` or another `Soql.ConditionalLogic` object(s)) to the current list of criterion.

- `Soql.ConditionalLogic addCondition(List<Soql.Criteria> criterion)`
- `Soql.ConditionalLogic addCondition(Soql.Criteria criteria)`
- `Soql.ConditionalLogic addCondition(String fieldName, Soql.Operator operator, Object value)`
- `Soql.ConditionalLogic addCondition(SObjectField field, Soql.Operator operator, Object value)`

#### `setLogicType`

Determines the enclosing `Soql.LogicType` object. This affects the delimiter that will be applied to the `Soql.ConditionalLogic`'s criterion at runtime; `ANY_CONDITIONS` will produce an "OR" delimiter. `ALL_CONDITIONS` will produce an "AND" delimiter. By default, the `Soql.ConditionalLogic` uses `Soql.LogicType.ALL_CONDITIONS`; there is no need to set this explicitly in most cases except for changing this to use "OR" logic.

- `Soql.ConditionalLogic setLogicType(Soql.LogicType logicType)`

### Soql.Cursor

Decorates `Database.Cursor` objects that are returned by `Database.getCursor`. These objects cannot be serialized or mocked by other means.

Use this object in conjunction with the `getCursor` method:

```java
Soql soql = DatabaseLayer.Soql.newQuery(Account.SObjectType);
Soql.Cursor cursor = soql?.getCursor();
List<SObject> records = cursor?.fetch(0, 10);
```

#### `fetch`

Fetches cursor rows that correspond to the offset position and the specified record count.

- `List<SObject> fetch(Integer position, Integer count)`

#### `getCursor`

Returns the underlying `Database.QueryLocator` object used to construct this object.

- `Database.QueryLocator getLocator()`

#### `getNumRecords`

Gets the number of rows returned in an Apex cursor from a `Cursor.fetch` operation.

- `Integer getNumRecords()`

### Soql.Function

Enumerates the different [Aggregate Functions](https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql_select_agg_functions.htm) that can be used in SOQL queries. Valid options include:

- `AVG`,
- `CALENDAR_MONTH`,
- `CALENDAR_QUARTER`,
- `CALENDAR_YEAR`,
- `COUNT`,
- `COUNT_DISTINCT`,
- `DAY_IN_MONTH`,
- `DAY_IN_WEEK`,
- `DAY_IN_YEAR`,
- `DAY_ONLY`,
- `FISCAL_MONTH`,
- `FISCAL_QUARTER`,
- `FISCAL_YEAR`,
- `FORMAT`,
- `HOUR_IN_DAY`,
- `MIN`,
- `MAX`,
- `SUM`,
- `WEEK_IN_MONTH`,
- `WEEK_IN_YEAR`

### Soql.InnerQuery

Represents inner query logic, used for filtering results in a `WHERE` clause. Use this in conjunction with the `addWhere` SOQL method. For example:

```java
// SELECT Id FROM Account WHERE Id IN (SELECT AccountId FROM Opportunity WHERE IsWon = true)
Soql.InnerQuery innerQuery = new Soql.InnerQuery(Opportunity.SObjectType)
  ?.addSelect(Opportunity.AccountId);
Soql soql = (Soql) Database.Soql.newQuery(Account.SObjectType)
  ?.addWhere(Account.Id, Soql.IN_COLLECTION, innerQuery);
```

This class extends `Soql.Builder`, and therefore has all of the same query-building [methods](#building-queries).

- `InnerQuery(SObjectType objectType)`

### Soql.InvalidParameterValueException

This custom exception type wraps the standard `System.InvalidParameterValueException` thrown by the Database.Cursor class in certain circumstances, ex., when using a negative Integer in a `fetch()` call. These exceptions can only be manually constructed in VF or Aura contexts, so they cannot be mocked in apex tests. Both `Soql` and `MockSoql` classes will throw this custom exception type instead.

### Soql.LogicType

Indicates the enclosing logic for the `Soql.ConditionalLogic` objects used in _WHERE_ or _HAVING_ clauses. Values include:

- `ALL_CONDITIONS`
- `ANY_CONDITIONS`

Use in the `setOuterWhereLogic` or `setOuterHavingLogic` SOQL methods. Example:

```java
Soql soql = (Soql) DatabaseLayer.Soql.newQuery(User.SObjectType)
  ?.addWhere(User.IsActive, Soql.EQUALS, true)
  ?.addWhere('Profile.Name', Soql.EQUALS, 'System Administrator')
  ?.setOuterWhereLogic(Soql.LogicType.ANY_CONDITIONS);
```

When `setOuterWhereLogic(Soql.LogicType.ANY_CONDITIONS)` is used, any new criterion added to the query via the `addWhere` method will be added with an `OR` keyword. For example:

```java
// SELECT Id FROM Opportunity WHERE StageName = 'Closed Won' OR Amount > 1000000
Soql.Condition isClosedWon = new Soql.Condition(
  Opportunity.StageName,
  Soql.Operator.EQUALS,
  'Closed Won'
);
Soql.Condition worthAMil = new Soql.Condition(
  Opportunity.Amount,
  Soql.Operator.GREATER_THAN,
  1000000
);
Soql soql = (Soql) DatabaseLayer.Soql.newQuery(Opportunity.SObjectType)
  ?.setOuterWhereLogic(Soql.LogicType.ANY_CONDITIONS)
  ?.setWhere(isClosedWon)
  ?.setWhere(worthAMil);
```

### Soql.NullOrder

Indicates how null values should be processed in _ORDER BY_ clauses. Values include:

- `NULLS_FIRST`
- `NULLS_LAST`

Use this in conjunction with the `Soql.SortOrder` class's `setNullOrder` method. Example:

```java
Soql.SortOrder sortOrder = new Soql.SortOrder(
  Opportunity.CloseDate,
  Soql.SortDirection.DESCENDING
);
sortOrder?.setNullOrder(Soql.NullOrder.NULLS_FIRST);
Soql soql = (Soql) DatabaseLayer.Soql.newQuery(Opportunity.SObject)?.orderBy(sortOrder);
```

### Soql.ParentField

Use this class to add parent (or multiple-grandparent) object fields to your query without using Strings, ex., `Account.Owner.Profile.Name`. This approach enforces referential integrity, and helps avoid runtime failures (if for example, the field doesn't exist or is misspelled).

The constructor accepts a `List<SObjectField>`, or up to six separate `SObjectField` arguments (up to five relationship fields, plus the actual field to be returned in the query). Each argument represents a field in the sequential "chain" of relationships leading from the `FROM` object to the ultimate field to be queried.

This class implements `Soql.Selectable`, and therefore can be used in conjunction with the `addSelect` method:

```java
Soql.ParentField field = new Soql.ParentField(Opportunity.AccountId, Account.OwnerId, User.Name);
// "SELECT Id, Account.Owner.Name FROM Opportunity"
Soql query = DatabaseLayer.Soql.newQuery(Opportunity.SObjectType)?.addSelect(field)?.toSoql();
```

#### Constructors

- `ParentField(List<SObjectField> relationshipFieldChain)`
- `ParentField(SObjectField field1, [field2, field3, field4, field5, field6])`

### Soql.QueryLocator

Decorates `Database.QueryLocator` objects that are returned by `Database.getQueryLocator`. These objects cannot be serialized or mocked by other means.

Use this object in conjunction with the `getQueryLocator` method:

```java
Soql soql = DatabaseLayer.Soql?.newQuery(Account.SObjectType);
Soql.QueryLocator locator = soql?.getQueryLocator();
```

#### `getLocator`

Returns the underlying `Database.QueryLocator` object used to construct this object.

- `Database.QueryLocator getLocator()`

#### `getQuery`

Returns the query from the underlying `Database.QueryLocator`'s `getQuery()` method.

- `String getQuery()`

#### `iterator`

Returns a `System.Iterator<SObject>` from the underlying `Database.QueryLocator`'s `iterator()` method.

- `System.Iterator<SObject> iterator()`

### Soql.Scope

Enumerates possible values to be used with the optional [_USING SCOPE_](https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql_select_using_scope.htm) SOQL clause. Values include:

- `DELEGATED`
- `EVERYTHING`
- `MINE`
- `MINE_AND_MY_GROUPS`
- `MY_TERRITORY`
- `MY_TEAM_TERRITORY`
- `TEAM`

Use this in conjunction with the `usingScope` SOQL method. For example:

```java
Soql soql = (Soql) DatabaseLayer.Soql.newQuery(User.SObjectType)
  ?.usingScope(Soql.Scope.EVERYTHING);
```

### Soql.SortDirection

Indicates the direction of the _ORDER BY_ clause. Values include:

- `ASCENDING`
- `DESCENDING`

Use this in conjunction with the `orderBy` SOQL method. For example:

```java
Soql soql = (Soql) DatabaseLayer.Soql
  ?.newQuery(Opportunity.SObjectType)
  ?.orderBy(Opportunity.Amount, Soql.SortDirection.DESCENDING);
```

### Soql.SortOrder

Represents the `ORDER BY` clause in a SOQL query. Use this object in conjunction with the `orderBy` SOQL method. For example:

```java
Soql.SortOrder firstCreated = new Soql.SortOrder(
  Account.CreatedDate,
  Soql.SortDirection.ASCENDING
);
Soql query = (Soql) DatabaseLayer.Soql
  ?.newQuery(Account.SObjectType)
  ?.orderBy(firstCreated);
```

#### Constructors

- `SortOrder(List<String> fieldNames, Soql.SortDirection direction)`
- `SortOrder(String fieldName, Soql.SortDirection)`
- `SortOrder(List<SObjectField> fields, Soql.SortDirection direction)`
- `SortOrder(SObjectField field, Soql.SortDirection direction)`

#### `setNullOrder`

Adds an optional "null order" clause to the `ORDER BY` condition. For example, "ORDER BY ExternalId\_\_c ASC NULLS LAST"

- `Soql.SortOrder setNullOrder(Soql.NullOrder nullOrder)`

### Soql.Subquery

Represents child relationship queries within the broader query structure, used to return child objects related to the primary object.

This class implements `Soql.Selectable`, and can be used in conjunction with the `addSelect` SOQL method. For example:

```java
// SELECT Id, (SELECT Id FROM Contacts) FROM Account
Soql.Subquery sub = new Soql.Subquery(Contact.AccountId);
Soql soql = (Soql) Database.Soql.newQuery(Account.SObjectType).addSelect(sub);
```

This class extends `Soql.Builder`, and therefore has all of the same query-building [methods](#building-queries).

#### Constructors:

- `Soql.Subquery(Schema.ChildRelationship relationship)`
- `Soql.Subquery(SObjectField lookupFieldOnChildObject)`

### Soql.Usage

Enumerates possible values to be used with the optional query suffixes. Values include:

- `ALL_ROWS`
- `FOR_VIEW`
- `FOR_REFERENCE`
- `FOR_UPDATE`

Use this in conjunction with the SOQL `setUsage` method. For example:

```java
// SELECT Id FROM Account FOR UPDATE
Soql soql = (Soql) DatabaseLayer.Soql.newQuery(Account.SObjectType)
  ?.setUsage(Soql.Usage.FOR_UPDATE);
```
