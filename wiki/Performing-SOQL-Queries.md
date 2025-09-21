To retrieve records from the database using Apex Database Layer, developers can use the [Soql](./The-Soql-Class) class.

## Building Queries

Create a new `Soql` object by calling [`DatabaseLayer.Soql.newQuery`](./The-DatabaseLayer.SoqlProvider-Class#newQuery).

`Soql` employs a builder pattern that allows you to flexibly generate a query that matches your specifications. You can view all of the available query-building methods [here](./The-Soql.Builder-Class).

Once your query is ready to "build", use the [`toSoql()`](./The-Soql-Class#toSoql) method to cast the query back to a concrete `Soql` instance:

```apex
Soql query = DatabaseLayer.Soql.newQuery(Account.SObjectType)
  ?.addSelect(Account.CreatedDate, Account.Name, Account.OwnerId)
  ?.addWhere(Account.OwnerId, Soql.EQUALS, UserInfo.getUserId())
  ?.addOrderBy(Account.CreatedDate, Soql.SortDirection.DESCENDING)
  ?.setRowLimit(1)
  ?.toSoql();
System.debug(query);
// "SELECT Id, CreatedDate, Name, OwnerId FROM Account WHERE OwnerId = '005000000000000000' ORDER BY CreatedDate DESC LIMIT 1"
```

As shown above, printing the query will output the actual query to be executed.

---

## Executing Queries

Call the appropriate method directly from your `Soql` object to execute a SOQL query, instead of the corresponding `Database` class methods or inline SOQL queries:

```apex
// Don't use these standard query methods:
List<Account> accounts = [SELECT Id, Name FROM Account];
List<Account> accounts = Database.query('SELECT Id, Name FROM Account');
// Use this instead!
List<Account> accounts = (List<Account>) DatabaseLayer.Soql.newQuery(Account.SObjectType)
  ?.addSelect(Account.Name)
  ?.toSoql()
  ?.query();
```

The `Soql` class supports all [Database class](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_methods_system_database.htm) query methods. View all `Soql` methods [here](./The-Soql-Class#Methods).

---

## Why?

We recommend using `DatabaseLayer.Soql` instead of `Database` methods or inline SOQL queries across your entire codebase. This practice has the following benefits:

- Easily [mock SOQL queries](./Mocking-SOQL-Queries) in tests with just a couple of lines of code.
- `DatabaseLayer.Soql` couples the type-safety and referential integrity of inline SOQL queries and the flexibility of "dynamic" string-based queries using `Database.query`.
- `DatabaseLayer.Soql` objects are easily extendable. You can one query as a "template" for other similar queries.
