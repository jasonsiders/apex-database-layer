The `Soql` class is designed to facilitate the construction and execution of SOQL queries within the Salesforce platform.

This class abstracts direct inline SOQL queries, promoting testability by allowing query methods to be mocked using the [`MockSoql`](./The-MockSoql-Class) class. The class allows developers to create and execute fully customizable queries, with methods that map directly to Salesforce's underlying `Database` query methods.

Use this class in place of inline SOQL to pave the way for faster, more scalable unit tests that run independent of the Salesforce database.

## Constructing `Soql` Objects

`Soql` objects cannot be directly constructed via the `new` keyword. Instead, use the `DatabaseLayer.Soql.newQuery(SObjectType fromSObject)` method.

The object uses the [Soql.Builder](./The-Soql.Builder-Class) class to allow for flexible query construction. Once your query is built, call [`toSoql()`](./The-Soql.Builder-Class#toSoql) to build the query as a `Soql` object:

```apex
Soql query = DatabaseLayer.Soql
  ?.newQuery(Account.SObjectType)
  ?.addSelect(Account.Name)
  ?.setRowLimit(200)
  ?.toSoql();
```

In `@IsTest` context, the `DatabaseLayer.useMocks()` method ensures that an instance of the `MockSoql` class will be returned for each subsuquent `newQuery` call:

```apex
DatabaseLayer.useMocks();
MockSoql query = (MockSoql) DatabaseLayer.Soql.newQuery(Account.SObjectType);
Assert.isInstanceOfType(query, MockSoql.class, 'Not a mock');
```

## Building SOQL Queries

Use `Soql.Builder` class's various builder methods to construct a SOQL query. Each of these methods returns a `Soql.Builder` instance, which can be used to support fluent query constrution:

```apex
Soql accountQuery = DatabaseLayer.Soql.newQuery(Account.SObjectType)
  ?.addSelect(Account.Name)
  ?.addWhere(Account.Type, Soql.NOT_EQUALS, 'Internal')
  ?.withSecurityEnforced()
  ?.addOrderBy(Account.CreatedDate, Soql.SortDirection.DESCENDING)
  ?.setRowLimit(200)
  ?.toSoql();
List<Account> accounts = accountQuery?.query();
```

### Performing SOQL Queries

The `Soql` class contains several methods which provide parity with the query methods found in the standard [`Database`](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_methods_system_database.htm) class:

---

## Methods

> :warning: _**Note:** The `Soql` class includes several methods used to build SOQL queries. These methods are inherited from the `Soql.Builder` class. The [`Soql.InnerQuery`](./The-Soql.InnerQuery-Class) and [`Soql.Subquery`](./The-Soql.Subquery-Class) also extend `Soql.Builder`, and share the same query-building methods._
>
> _All query-building methods are documented here: [`Soql.Builder`](./The-Soql.Builder-Class)_

### `aggregateQuery`

Performs aggregate queries and returns results as a list of `Soql.AggregateResult` objects. This type wraps the `Schema.AggregateResult` objects to provide mockable results in tests.

- `List<Soql.AggregateResult> aggregateQuery()`

### `countQuery`

Executes a count query, which should only contain aggregation functions like `COUNT()`. Returns the count of records that match the query.

- `Integer countQuery()`

### `getCursor`

Retrieves a `Soql.Cursor` object, which decorates a `Database.Cursor` object.

- `Soql.Cursor getCursor()`

### `getQueryLocator`

Retrieves a `Soql.QueryLocator` object, which decorates a `Database.QueryLocator` object.

- `Soql.QueryLocator getQueryLocator()`

### `query`

Executes the query and returns the results as a list of `SObject`. Alternatively, this method can return results as a specific `returnType`, ie., for aggregate queries.

- `List<SObject> query()`
- `Object query(Type returnType)`

### `queryAndMap`

Executes the SOQL query and returns matching records mapped by their Id. Returns `Map<Id, SObject>` rather than a typed subtype because Apex does not support covariant casting of generic Map types.

**Note:** Even if all records are `Account` instances, a `Map<Id, SObject>` cannot be cast to `Map<Id, Account>` at runtime. If a typed map is needed, use `query()` and construct the map directly: `new Map<Id, User>((List<User>) soql.query())`

- `Map<Id, SObject> queryAndMap()`

### `queryFirst`

Fetches the first result of the query or returns `null` if no results are found. This method is useful for cases where only a single result is expected.

- `SObject queryFirst()`

### `setQueryIdentifier`

Assigns an identifier to the query. Callers can use this identifier to distinguish queries from one another, for example in mocks.

- `Soql setQueryIdentifier(String identifier)`
