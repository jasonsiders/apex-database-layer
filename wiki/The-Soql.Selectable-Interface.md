This interface denotes objects that may be used in a SOQL `SELECT` clause.

While this is primarily used internally, developers may author their own `Selectable` objects for use in `SELECT` clauses.

Use `Soql.Selectable` objects in conjunction with the builder's [addSelect](./The-Soql.Builder-Class#addSelect) method when constructing a [Soql](./The-Soql-Class) object.

## Implementors

- [Soql.Aggregation](./The-Soql.Aggregation-Class)
- [Soql.InnerQuery](./The-Soql.InnerQuery-Class)
- [Soql.ParentField](./The-Soql.ParentField-Class)
- [Soql.Subquery](./The-Soql.Subquery-Class)
- [Soql.TypeOf](./The-Soql.TypeOf-Class)

## Methods

### `toString`

Outputs the formatted query element for use in the `SELECT` clause.
