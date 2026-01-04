The `Soql.Parser` class is responsible for parsing SOQL query strings and converting them into `Soql.Builder` instances. This class provides the core functionality that enables the string-based SOQL query construction feature.

This inner class of `Soql` uses regex-based tokenization to parse most common SOQL patterns and constructs the appropriate builder methods to recreate the query.

## Supported SOQL Features

The parser supports parsing the following SOQL clauses and features:

- **SELECT** - Simple field selections and parent field references
- **FROM** - Target SObject specification
- **WHERE** - Conditions with AND/OR logic
- **ORDER BY** - Sorting with ASC/DESC and NULLS FIRST/LAST
- **GROUP BY** - Grouping with single and multiple fields
- **LIMIT** - Row limiting
- **OFFSET** - Result offset
- **USING SCOPE** - Record visibility scoping
- **FOR VIEW/UPDATE/REFERENCE** - Record locking
- **WITH SECURITY_ENFORCED** - Field-level security enforcement
- **Aggregate functions** - COUNT, AVG, SUM, MIN, MAX
- **Bind variables** - :variable syntax
- **Date literals** - TODAY, YESTERDAY, TOMORROW
- **Comparison operators** - =, !=, <, >, <=, >=, LIKE, IN, etc.

## Limitations

Current implementation limitations include:

- Complex nested WHERE logic with parentheses not yet supported
- HAVING clause parsing not yet implemented
- Subqueries and TYPEOF polymorphic queries not supported
- These features may be added in future iterations

---

## Methods

### `fromString`

Creates a new `Soql.Builder` instance by parsing the provided SOQL query string.

- `static Soql.Builder fromString(String soqlString, DatabaseLayer factory)`
    - **soqlString** - The SOQL query string to parse
    - **factory** - The DatabaseLayer instance to use for creating the Soql object
    - **Returns** - A configured `Soql.Builder` instance populated from the parsed query string
    - **Throws** - `Soql.Parser.ParserException` if the query string is invalid or cannot be parsed

**Example:**

```apex
String soqlString = 'SELECT Id, Name FROM Account WHERE Type = \'Customer\' ORDER BY Name LIMIT 10';
Soql.Builder builder = Soql.Parser.fromString(soqlString, DatabaseLayer.INSTANCE);
Soql query = builder.toSoql();
List<Account> accounts = query.query();
```

> :information_source: **Note:** This method is typically called internally by [`DatabaseLayer.SoqlProvider.newQuery(String)`](./The-DatabaseLayer.SoqlProvider-Class#newquery) rather than being called directly.

---

## Inner Classes

### `ParserException`

Exception thrown when SOQL string parsing fails due to invalid syntax or unsupported features.

**Extends:** `Exception`

**Usage:**

```apex
try {
    Soql query = DatabaseLayer.Soql.newQuery('INVALID SOQL SYNTAX');
} catch (Soql.Parser.ParserException ex) {
    System.debug('Failed to parse SOQL: ' + ex.getMessage());
}
```
