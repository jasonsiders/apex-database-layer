This class is responsible for generating new `Soql` query objects. After `DatabaseLayer.useMocks()` or `DatabaseLayer.useMockSoql()` is called, the object returned by this class will be a `MockSoql` instance.

Callers access this class via the [`DatabaseLayer`](./The-DatabaseLayer-Class)'s `Soql` property:

```apex
// Generate a real SOQL query:
Soql query1 = DatabaseLayer.Soql.newQuery(Account.SObjectType);
Assert.isNotInstanceofType(query1, MockSoql.class, 'Is a Mock');
// Generate a mock SOQL query:
DatabaseLayer.useMocks();
Soql query2 = DatabaseLayer.Soql.newQuery(Account.SObjectType);
Assert.isInstanceofType(query2, MockSoql.class, 'Not a Mock');
```

---

### Methods

#### `newQuery`

Generates a new `Soql` query using the given `SObjectType` as the FROM object.

- `Soql newQuery(SObjectType objectType)`

Generates a new `Soql` query from a SOQL query string. Parses the provided SOQL string and constructs a Soql.Builder instance with the parsed components.

- `Soql newQuery(String soqlString)`
    - **soqlString** - The SOQL query string to parse (e.g., 'SELECT Id, Name FROM Account WHERE CreatedDate = TODAY LIMIT 10')
    - **Returns** - A configured SOQL builder instance populated from the parsed query string
    - **Throws** - `Soql.Parser.ParserException` if the query string is invalid or cannot be parsed

**Example:**

```apex
String queryStr = 'SELECT Id, Name FROM Account WHERE CreatedDate = TODAY ORDER BY Name ASC LIMIT 10';
Soql query = DatabaseLayer.Soql.newQuery(queryStr);
List<Account> accounts = query.query();
```
