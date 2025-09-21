This interface denotes objects that may be used in a SOQL `WHERE` or `HAVING` clause.

While this is primarily used internally, developers may author their own `Criteria` objects for use in `WHERE` or `HAVING` clauses.

Use `Soql.Criteria` objects in conjunction with the builder's [addWhere](./The-Soql.Builder-Class#addWhere) and [addHaving](./The-Soql.Builder-Class#addHaving) methods when constructing a [Soql](./The-Soql-Class) object.

## Implementors

- [Soql.Condition](./The-Soql.Condition-Class)
- [Soql.ConditionalLogic](./The-Soql.ConditionalLogic-Class)

## Methods

### `toString`

Outputs the formatted query element for use in the `WHERE` or `HAVING` clause.
