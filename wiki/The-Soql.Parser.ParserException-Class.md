The `Soql.Parser.ParserException` class is a custom exception thrown by the [`Soql.Parser`](./The-Soql.Parser-Class) when SOQL string parsing fails due to invalid syntax or unsupported features.

This exception extends the standard Apex `Exception` class and provides specific error information when SOQL parsing encounters problems.

**Extends:** `Exception`

## Usage

This exception is thrown automatically by the parser when it encounters:

- Invalid SOQL syntax
- Unsupported SOQL features (see [Parser limitations](./The-Soql.Parser-Class#limitations))
- Malformed query strings
- Missing required clauses

**Example:**
```apex
try {
    // This will throw a ParserException due to invalid syntax
    Soql query = DatabaseLayer.Soql.newQuery('INVALID SOQL SYNTAX');
} catch (Soql.Parser.ParserException ex) {
    System.debug('Failed to parse SOQL: ' + ex.getMessage());
    // Handle the parsing error appropriately
}
```

## Common Scenarios

The `ParserException` is typically thrown in these scenarios:

1. **Invalid SOQL Syntax:**
   ```apex
   // Missing FROM clause
   String invalidSoql = 'SELECT Id, Name';
   ```

2. **Unsupported Features:**
   ```apex
   // Complex nested parentheses (not yet supported)
   String complexSoql = 'SELECT Id FROM Account WHERE (Type = \'A\' AND (Status = \'Active\' OR Status = \'Pending\'))';
   ```

3. **Malformed Field References:**
   ```apex
   // Invalid field syntax
   String malformedSoql = 'SELECT Id,, Name FROM Account';
   ```

## Error Handling Best Practices

When working with SOQL string parsing, consider implementing proper error handling:

```apex
public static List<Account> safeQuery(String soqlString) {
    try {
        Soql query = DatabaseLayer.Soql.newQuery(soqlString);
        return query.query();
    } catch (Soql.Parser.ParserException ex) {
        System.debug(LoggingLevel.ERROR, 'SOQL parsing failed: ' + ex.getMessage());
        // Fallback to a safe default query or return empty list
        return new List<Account>();
    }
}
```