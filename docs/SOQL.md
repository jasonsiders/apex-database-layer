# The `Soql` Class

The `Soql` class is designed to facilitate the construction and execution of SOQL queries within the Salesforce platform. This class abstracts direct inline SOQL queries, promoting testability by allowing query methods to be mocked using the `MockSoql` class. The class allows developers to create and execute fully customizable queries, with methods that map directly to Salesforce's underlying `Database` query methods. Use this class in place of inline SOQL to pave the way for faster, more scalable unit test that run independent of the Salesforce database.

## Constructing `Soql` Objects

`Soql` objects cannot be directly constructed via the `new` keyword. Instead, use `DatabaseLayer.newDml()`, and cast the result to the `Soql` type:
```java
Soql soql = (Soql) DatabaseLayer.newSoql(Account.SObjectType);
```

The `DatabaseLayer` class is responsible for instantiating database objects of the correct type at runtime. In `@IsTest` context, developers can call `DatabaseLayer.useMocks()`, and an instance of the `MockSoql` class will be returned instead:

```java
DatabaseLayer.useMocks();
Soql soql = (Soql) DatabaseLayer.newSoql(Account.SObjectType);
Assert.isInstanceOfType(soql, MockSoql.class, 'Not a mock');
```

## Public Methods

### Performing Queries

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
These methods are derived from the `Soql.Builder` inner class. The `Soql` class extends this base class, along with other inner types, like `Soql.InnerClass` and `Soql.Subquery`.

#### `addHaving`

Adds conditions to the HAVING clause of the query.

- `Soql.Builder addHaving(Soql.Aggregation agg, Soql.Operator operator, Object value)`

#### `addSelect`

Adds fields or aggregations to the SELECT clause of the query.

- `Soql.Builder addSelect(String fieldName, String alias)`
- `Soql.Builder addSelect(SObjectField field, String alias)`
- `Soql.Builder addSelect(String fieldName)`
- `Soql.Builder addSelect(SObjectField field)`
- `Soql.Builder addSelect(Soql.Aggregation aggregation)`
- `Soql.Builder addSelect(Soql.SubQuery subQuery)`

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

#### `fromEntity`

Sets the entity from which to query data.

- `Soql.Builder fromEntity(SObjectType objectType)`

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

#### `usingScope`

Sets the scope for the query.

- `Soql.Builder usingScope(Soql.Scope scope)`

#### `withSecurityEnforced`

Enforces security in the query to ensure that the user has appropriate access to the queried records.

- `Soql.Builder withSecurityEnforced()`

## Public Inner Types

### AggregateResult

Wraps the `Schema.AggregateResult` class, which cannot be mocked otherwise. Objects of this type are returned by the `aggregateQuery` SOQL method, and can be mocked by the `MockSoql.AggregateResult` class

#### `get`

Calls the underlying `Schema.AggregateResult` object's `get` method. The `key` parameter refers to the field alias if one is assigned, or the parameter's index in query preceded by the `expr` if one is not assigned (x, `expr0`).

- `get(String key)`

### Aggregation

Represents an aggregate expression in a SOQL query. For example, `COUNT(Id) numRecords`. Use these objects with the the `addSelect` or `addHaving` methods when making an aggregate query.

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

### Binder

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

### Condition 

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
Soql soql = (Soql) DatabaseLayer.newSoql(Opportunity.SObjectType)
  ?.addWhere(isClosedWon)
  ?.addWhere(worthAMil);
```

To use `OR` logic instead, use the [`setOuterWhereLogic`](#setouterwherelogic) SOQL method. To use complex or nested logic, use the [Soql.ConditionalLogic](#conditionallogic) class. 

Like `Soql.ConditionalLogic`, the `Soql.Conditional` class implements a base `Soql.Criteria` interface, which the framework uses internally to keep things tidy. 

#### Constructors

- `Soql.Condition(String property, Soql.Operator operator, Object value)`
- `Soql.Condition(SObjectField field, Soql.Operator operator, Object value)`

### ConditionalLogic

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
Soql soql = DatabaseLayer.newSoql(Opportunity.SObjectType)
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
Soql soql = (Soql) DatabaseLayer.newSoql(Opportunity.SObjectType)
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

### Function

Enumerates the different [Aggregate Functions](https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql_select_agg_functions.htm) that can be used in SOQL queries. Valid options include:

- `AVG`
- `COUNT`
- `COUNT_DISTINCT`
- `FORMAT`
- `MIN`
- `MAX`
- `SUM`

### InnerQuery

Represents inner query logic, used for filtering results in a `WHERE` clause. Use this in conjunction with the `addWhere` SOQL method. For example:

```java
// SELECT Id FROM Account WHERE Id IN (SELECT AccountId FROM Opportunity WHERE IsWon = true)
Soql.InnerQuery inner = new Soql.InnerQuery(Opportunity.SObjectType)
  ?.addSelect(Opportunity.AccountId);
Soql soql = (Soql) Database.newSoql(Account.SObjectType)
  ?.addSelect(inner);
```

This class extends `Soql.Builder`, and therefore has all of the same query-building [methods](#building-queries).

- `InnerQuery(SObjectType objectType)`

### LogicType

Indicates the enclosing logic for the `Soql.ConditionalLogic` objects used in _WHERE_ or _HAVING_ clauses.  Values include:
- `ALL_CONDITIONS`
- `ANY_CONDITIONS`

Use in the `setOuterWhereLogic` or `setOuterHavingLogic` SOQL methods. Example:
```java
Soql soql = (Soql) DatabaseLayer.newSoql(User.SObjectType)
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
Soql soql = (Soql) DatabaseLayer.newSoql(Opportunity.SObjectType)
  ?.setOuterWhereLogic(Soql.LogicType.ANY_CONDITIONS)
  ?.setWhere(isClosedWon)
  ?.setWhere(worthAMil);
```
### NullOrder

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
Soql soql = (Soql) DatabaseLayer.newSoql(Opportunity.SObject)?.orderBy(sortOrder);
```

### QueryLocator

Decorates `Database.QueryLocator` objects that are returned by `Database.getQueryLocator`. These objects cannot be serialized or mocked by other means. 

Use this object in conjunction with the `getQueryLocator` method:

```java
Soql soql = DatabaseLayer.newSoql(Account.SObjectType);
Soql.QueryLocator locator = soql?.getQueryLocator();
```

#### `getCursor`
Returns the underlying `Database.QueryLocator` object used to construct this object.

- `Database.QueryLocator getCursor()`

#### `getQuery`
Returns the query from the underlying `Database.QueryLocator`'s `getQuery()` method.

- `String getQuery()`

#### `iterator`
Returns a `System.Iterator<SObject>` from the underlying `Database.QueryLocator`'s `iterator()` method.

- `System.Iterator<SObject> iterator()`

### Scope

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
Soql soql = (Soql) DatabaseLayer.newSoql(User.SObjectType)
  ?.usingScope(Soql.Scope.EVERYTHING);
```

### SortDirection

Indicates the direction of the _ORDER BY_ clause. Values include:

- `ASCENDING`
- `DESCENDING`

Use this in conjunction with the `orderBy` SOQL method. For example:
```java
Soql soql = (Soql) DatabaseLayer.newSoql(Opportunity.SObjectType)
  ?.orderBy(Opportunity.Amount, Soql.SortDirection.DESCENDING);
```

### SortOrder

Represents the `ORDER BY` clause in a SOQL query. Use this object in conjunction with the `orderBy` SOQL method. For example:

```java
Soql.SortOrder firstCreated = new Soql.SortOrder(
  Account.CreatedDate, 
  Soql.SortDirection.ASCENDING
);
Soql soql = new Soql(Account.SObjectType)?.orderBy(firstCreated);
```

#### Constructors

- `SortOrder(List<String> fieldNames, Soql.SortDirection direction)`
- `SortOrder(String fieldName, Soql.SortDirection)`
- `SortOrder(List<SObjectField> fields, Soql.SortDirection direction)`
- `SortOrder(SObjectField field, Soql.SortDirection direction)`

#### `setNullOrder`
Adds an optional "null order" clause to the `ORDER BY` condition. For example, "ORDER BY ExternalId__c ASC NULLS LAST"

- `Soql.SortOrder setNullOrder(Soql.NullOrder nullOrder)`

### Subquery

Represents child relationship queries within the broader query structure, used to return child objects related to the primary object. 

Use this in conjunction with the `addSelect` SOQL method. For example:

```java
// SELECT Id, (SELECT Id FROM Contacts) FROM Account
Soql.SubQuery sub = new Soql.SubQuery(Contact.AccountId);
Soql soql = (Soql) Database.newSoql(Account.SObjectType).addSelect(sub);
```

This class extends `Soql.Builder`, and therefore has all of the same query-building [methods](#building-queries).

Constructors:

- `Soql.SubQuery(Schema.ChildRelationship relationship)`
- `Soql.SubQuery(SObjectField lookupFieldOnChildObject)`

### Usage

Enumerates possible values to be used with the optional query suffixes. Values include:

- `ALL_ROWS`
- `FOR_VIEW`
- `FOR_REFERENCE`
- `FOR_UPDATE`

Use this in conjunction with the SOQL `setUsage` method. For example:

```java
// SELECT Id FROM Account FOR UPDATE
Soql soql = (Soql) DatabaseLayer.newSoql(Account.SObjectType)
  ?.setUsage(Soql.Usage.FOR_UPDATE);
```

## Mocking SOQL Queries

The `MockSoql` class can be used in place of a normal `Soql` object in the `@IsTest` context. The `MockSoql` class allows developers to inject dynamic static or dynamic results in their query objects, instead of actually querying the Salesforce database.

### Instantiating Mocks
In `@IsTest` context, mock SOQL operations by calling the `DatabaseLayer.useMocks()` method. Once this is done, the `DatabaseLayer.newSoql()` method will return `MockSoql` objects. If the `newSoql` method is called _before_ `useMocks`, then those objects will continue to be instances of `Soql`, and not `MockSoql`. To prevent issues, call the `useMocks()` method as the first line in your test. 

### Injecting Mock Query Results
By default, the `MockSoql`'s query methods will return an empty result set of the type that you are expecting:

```java
DatabaseLayer.useMocks()`
MockSoql soql = (MockSoql) DatabaseLayer.newSoql(Account.SObjectType);
List<Account> results = soql?.query();
Assert.areEqual(0, results?.size(), 'Wrong # of resuls');
```

Each `MockSoql` object can be injected with static query results, logic that determines the query results, or an Exception. When the query runs, those results will be returned instead of what is actually in the Salesforce database.

For this reason, it's best practice to store each Soql object in a `@TestVisible` class variable (member or static), that can be easily accessed by your test code if needed.

#### Inject Static Results with the `setMock` Method
The easiest way to simulate queries is to use the `setMock` method with a static `List<Object>`. The provided results will be returned each time the query runs:

```java
DatabaseLayer.useMocks();
Account mockAccount = new MockRecord(Account.SObjectType)?.withId()?.toSObject();
MockSoql soql = (MockSoql) DatabaseLayer.newSoql(Account.SObjectType);
soql.useMocks(new List<Account>{ mockAccount });
List<Account> results = soql?.query();
Assert.areEqual(1, results?.size(), 'Wrong # of results');
```

Most of the time, this will be a `List<SObject>`, but you can also pass a `List<MockSoql.AggregateResult>` or a custom list type for aggregate queries:

```java
public class MyCustomType {
  String state;
  Integer numRecords;
}
```

```java
DatabaseLayer.useMocks();
MyCustomType mockResult = new MyCustomType();
mockResult.state = 'CA';
mockResult.numRecords = 123;
Soql.Aggregation count = new Soql.Aggregation(Soql.Function.COUNT, Account.Id)
  ?.withAlias('numRecords');
MockSoql soql = (MockSoql) DatabaseLayer.newSoql(Account.SObjectType)
  ?.addSelect(Account.BillingState, 'state')
  ?.addSelect(count);
soql.useMocks(new List<MyCustomType>{ mockResult });
List<MyCustomType> results = (List<MyCustomType>) soql?.query(
  List<MyCustomType>.class
);
```

#### Inject Dynamic Results with the `setMock` Method
Certain testing scenarios may require custom logic to determine the results returned by a query. For these scenarios, developers can leverage the `MockSoql.Simulator` interface with the `setMock` method.

The `MockSoql.Simulator` interface has one required method, which returns a `List<Object>`. This method will be run each time the query is run.

```java
private class CustomTaskQueryLogic implements MockSoql.Simulator {
  public List<Object> simulateQuery() {
    // For each inserted contact, return a Task
    List<Task> results = new List<Task>();
    List<Contact> contacts = (List<Contact>) MockDml.Inserted.getRecords(
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

```java
// Establish Dml & Soql objects to be used
DatabaseLayer.useMocks();
Dml dml = DatabaseLayer.newDml();
MockSoql soql = (MockSoql) DatabaseLayer.newSoql(Task.SObjectType)
  ?.addSelect(Task.WhatId)
  ?.addSelect(Task.WhoId);
// Mock with a custom class that leverages MockDml.Inserted to generate results
soql?.setMock(new CustomTaskQueryLogic());
// Mock insert an account + related contact
Account mockAccount = (Account) new MockRecord(Account.SObjectType)?.toSObject();
dml?.doInsert(mockAccount);
Contact mockContact = (Contact) new MockRecord(Contact.SObjectType)
  ?.setField(Contact.AccountId, mockAccount?.Id)
  ?.toSObject();
dml?.doInsert(mockContact);

Test.startTest();
List<Task> tasks = soql?.query();
Test.stopTest();

// Expecting 1 task x each inserted Contact
Assert.areEqual(1, tasks?.size(), 'Wrong # of tasks');
Task firstTask = tasks[0];
Assert.areEqual(mockAccount?.Id, firstTask?.WhatId, 'Wrong WhatId');
Assert.areEqual(mockContact?.Id, firstTask?.WhoId, 'Wrong WhoId');
```

#### Inject Exceptions with the `setError` Method
Developers can simulate `Database.QueryException`s and other errors that may occur when running queries, by using the `setError` method:

```java
DatabaseLayer.useMocks();
MockSoql soql = (MockSoql) DatabaseLayer.newSoql(Account.SObjectType);
soql?.setError();
soql?.query(); // ! System.QueryException
```

Callers can specify the exact exception to be thrown, if desired:
```java
DatabaseLayer.useMocks();
System.NullPointerException npe = new System.NullPointerException();
MockSoql soql = (MockSoql) DatabaseLayer.newSoql(Account.SObjectType);
soql?.setError(npe);
soql?.query(); // ! System.NullPointerException
```

### Mocking Query Locators
The `Database.QueryLocator` object cannot be mocked in a traditional sense, since it manually constructed, or JSON-deserialized. The only way to create an object of this type is by directly interacting with the Salesforce database, via the `Database.getQueryLocator` method. 

For this reason, the `Soql` class uses a decorator class, `Soql.QueryLocator`. For the most part, developers can interact with this object the same way they would with a `Database.QueryLocator`:

```java
Soql soql = (Soql) DatabaseLayer.newSoql(Account.SObjectType);
Soql.QueryLocator locator = soql?.getQueryLocator();
String query = locator?.getQuery();
System.Iterator<SObject> iterator = locator?.iterator();
```

In mock implementations there is no underlying `Database.QueryLocator` driving the interactions; instead, the `MockSoql` class injects its mock results to the iterator returned by the query locator's `iterator` method.

There is one limitation to this approach, and that is that frameworks that rely on the underlying `Database.QueryLocator` object cannot be mocked. This is most prevalent in `Database.Batchable` classes that return a query locator object in its `start()` method. For example:

```java
public class MyBatch implements Database.Batchable<SObject> {
  @TestVisible
  private Soql soql = (Soql) DatabaseLayer.newSoql(Account.SObjectType);

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

### The `MockSoql.AggregateResult` Class
A constructable version of the `Soql.AggregateResult` class, which wraps the `Schema.AggregateResult` class and its methods. `Schema.AggregateResult` objects cannot be directly constructed, serialized, or otherwise mocked. 

Use this object in conjunction with the `setMock` method, or the `MockSoql.Simulator` interface to inject results for aggregate queries. For example:

```java
DatabaseLayer.useMocks();
String alias = 'numRecords';
Soql.Aggregation count = new Soql.Aggregation(Soql.Function.COUNT, Account.Id)
  ?.withAlias(alias);
MockSoql soql = (MockSoql) DatabaseLayer.newSoql(Account.SObjectType)
  ?.addSelect(count);
MockSoql.AggregateResult agg = new MockSoql.AggregateResult()
  ?.addParameter(alias, 100);
soql?.setMock(new List<MockSoql.AggregateResult>{ agg });
List<Soql.AggregateResult> results = soql?.aggregateQuery();
Assert.areEqual(1, results?.size(), 'Wrong # of results');
Assert.areEqual(100, results[0]?.get(alias), 'Wrong count');
```

#### `addParameter`
Adds a column to the current `AggregateResult`. These can be created with or without an _alias_. If an alias isn't provided, the column is assigned a default alias, ex. `expr0'`. This mirrors the behavior of the underlying `Schema.AggregateResult` object. 

- `MockSoql.AggregateResult addParameter(String alias, Object value)`
- `MockSoql.AggregateResult addParameter(Object value)`