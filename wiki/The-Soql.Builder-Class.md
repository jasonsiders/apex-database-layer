This class is used to build query objects. It serves as the foundation for outer `Soql` queries, as well as other "query-like" objects: [`Soql.InnerQuery`](./The-Soql.InnerQuery-Class) and [`Soql.Subquery`](./The-Soql.Subquery-Class).

--

## Methods

### `addBind`

Adds binding variables to the query. Binding variables are used to dynamically insert values into the query.

- `Soql.Builder addBind(Map<String, Object> bindMap)`
- `Soql.Builder addBind(String key, Object value)`
- `Soql.Builder addBind(Soql.Binder binder)`

### `addGroupBy`

Adds fields to the GROUP BY clause of the query.

- `Soql.Builder addGroupBy(String fieldName)`
- `Soql.Builder addGroupBy(SObjectField field)`
- `Soql.Builder addGroupBy(Soql.ParentField field)`

### `addHaving`

Adds conditions to the HAVING clause of the query.

- `Soql.Builder addHaving(Soql.Aggregation agg, Soql.Operator operator, Object value)`

### `addSelect`

Adds fields or `Soql.Selectable` objects to the SELECT clause of the query. `Soql.Selectable` types include `Soql.Aggregation`, `Soql.ParentField`, `Soql.Subquery`, and `Soql.TypeOf` objects.

- `Soql.Builder addSelect(String fieldName, String alias)`
- `Soql.Builder addSelect(SObjectField field, String alias)`
- `Soql.Builder addSelect(Soql.ParentField field, String alias)`
- `Soql.Builder addSelect(String fieldName)`
- `Soql.Builder addSelect(List<SObjectField> fields)`
- `Soql.Builder addSelect(SObjectField field1, [field2, field3, field4, field5])`
- `Soql.Builder addSelect(List<Soql.Selectable> selectables)`
- `Soql.Builder addSelect(Soql.Selectable selectable1, [selectable2, selectable3, selectable4, selectable5])`

### `addWhere`

Adds conditions to the WHERE clause of the query.

- `Soql.Builder addWhere(Soql.Criteria criteria)`
- `Soql.Builder addWhere(String fieldName, Soql.Operator operator, Object value)`
- `Soql.Builder addWhere(SObjectField field, Soql.Operator operator, Object value)`
- `Soql.Builder addWhere(Soql.ParentField field, Soql.Operator operator, Object value)`
- `Soql.Builder addWhere(String fieldName, Soql.Operator operator, Soql.Binder binder)`
- `Soql.Builder addWhere(SObjectField field, Soql.Operator operator, Soql.Binder binder)`
- `Soql.Builder addWhere(Soql.ParentField field, Soql.Operator operator, Soql.Binder binder)`

### `deselect`

Removes specific fields from the SELECT clause of the query.

- `Soql.Builder deselect(String fieldName)`
- `Soql.Builder deselect(SObjectField field)`
- `Soql.Builder deselect(Soql.ParentField field)`

### `deselectAll`

Removes all fields from the SELECT clause of the query, essentially clearing any previously selected fields.

- `Soql.Builder deselectAll()`

### `addOrderBy`

Adds fields to the ORDER BY clause of the query.

- `Soql.Builder addOderBy(Soql.SortOrder sortOrder)`
- `Soql.Builder addOderBy(String fieldName, Soql.SortDirection direction)`
- `Soql.Builder addOderBy(SObjectField field, Soql.SortDirection direction)`
- `Soql.Builder addOderBy(Soql.ParentField field, Soql.SortDirection direction)`

### `reset`

Resets the builder to its default state, clearing all previously set clauses and parameters.

- `Soql.Builder reset()`

### `selectAll`

Selects all fields from the specified entity by querying the schema for all available fields.

- `Soql.Builder selectAll()`

### `setAccessLevel`

Sets the access level for the query.

- `Soql.Builder setAccessLevel(System.AccessLevel accessLevel)`

### `setFrom`

Sets the entity from which to query data. Only call this method if you need to override the SObjectType set when constructing the query, via the `DatabaseLayer.Soql.newQuery(SObjectType objectType)` method.

- `Soql.Builder setFrom(SObjectType objectType)`

### `setOuterHavingLogic`

Sets the logical operator (AND/OR) for combining HAVING conditions.

- `Soql.Builder setOuterHavingLogic(Soql.LogicType newLogicType)`

### `setOuterWhereLogic`

Sets the logical operator (AND/OR) for combining WHERE conditions.

- `Soql.Builder setOuterWhereLogic(Soql.LogicType newLogicType)`

### `setQueryIdentifier`

Assigns an identifier to the query. Callers can use this identifier to distinguish queries from one another, for example in mocks.

- `Soql setQueryIdentifier(String identifier)`

```apex
// In MyClass.cls:
Soql myQuery = DatabaseLayer.Soql
  ?.newQuery(Account.SObjectType)
  ?.setQueryIdentifier('My Account Query')
  ?.toSoql();

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

### `setRowLimit`

Sets the maximum number of rows to return in the query result.

- `Soql.Builder setRowLimit(Integer rowLimit)`

### `setRowOffset`

Sets the number of rows to skip before starting to return results.

- `Soql.Builder setRowOffset(Integer rowOffset)`

### `setScope`

Sets the scope for the query.

- `Soql.Builder setScope(Soql.Scope scope)`

### `setUsage`

Sets the usage context for the query.

- `Soql.Builder setUsage(Soql.Usage usage)`

### `toInnerQuery`

Explicitly casts the current `Soql.Builder` to a `Soql.InnerQuery` instance. Useful for chaining complex queries.

- `Soql.InnerQuery toInnerQuery()`

### `toSoql`

Explicitly casts the current `Soql.Builder` to a `Soql` instance. Useful for chaining complex queries.

- `Soql toSoql()`

### `toSubquery`

Explicitly casts the current `Soql.Builder` to a `Soql.Subquery` instance. Useful for chaining complex queries.

- `Soql.Subquery toSubquery()`

### `withSecurityEnforced`

Enforces security in the query to ensure that the user has appropriate access to the queried records.

- `Soql.Builder withSecurityEnforced()`
