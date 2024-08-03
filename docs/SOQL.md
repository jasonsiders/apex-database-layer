# The `Soql` Class

- ! TODO ! Add some general information about the class

## Public Methods

### Performing Queries

#### `aggregateQuery`
Performs aggregate queries and returns results as a list of `Soql.AggregateResult` objects. This method wraps the `Schema.AggregateResult` objects to provide mockable results in tests.
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

#### `setHavingLogic`
Sets the logical operator (AND/OR) for combining HAVING conditions.

- `Soql.Builder setHavingLogic(Soql.LogicType newLogicType)`

#### `setRowLimit`
Sets the maximum number of rows to return in the query result.

- `Soql.Builder setRowLimit(Integer rowLimit)`

#### `setRowOffset`
Sets the number of rows to skip before starting to return results.

- `Soql.Builder setRowOffset(Integer rowOffset)`

#### `setUsage`
Sets the usage context for the query.

- `Soql.Builder setUsage(Soql.Usage usage)`

#### `setWhereLogic`
Sets the logical operator (AND/OR) for combining WHERE conditions.

- `Soql.Builder setWhereLogic(Soql.LogicType newLogicType)`

#### `usingScope`
Sets the scope for the query.

- `Soql.Builder usingScope(Soql.Scope scope)`

#### `withSecurityEnforced`
Enforces security in the query to ensure that the user has appropriate access to the queried records.

- `Soql.Builder withSecurityEnforced()`

## Public Inner Types

### AggregateResult
### Aggregation
### Binder
### Condition 
### Criteria
### ConditionalLogic
### Function
### InnerQuery
Represents inner query logic, used for filtering results in a `WHERE` clause. 

For example:
```sql
SELECT Id 
FROM Account 
WHERE Id IN (
	SELECT AccountId 
	FROM Opportunity 
	WHERE StageName = 'Closed Won'
)
```

This class extends `Soql.Builder`, and therefore has all of the same query-building [methods](#building-queries).

Constructors:
- `InnerQuery(SObjectType objectType)`

### LogicType
### NullOrder
### QueryLocator
### Scope
### SortDirection
### SortOrder
### Subquery
Represents child relationship queries within the broader query structure, used to return child objects related to the primary object. 

For example:

```sql
SELECT Id, (SELECT Id FROM Contacts) 
FROM Account`
```

This class extends `Soql.Builder`, and therefore has all of the same query-building [methods](#building-queries).

Constructors:

- `Soql.SubQuery(Schema.ChildRelationship relationship)`
- `Soql.SubQuery(SObjectField lookupFieldOnChildObject)`

### Usage

## Mocking SOQL Queries

- [ ] Simulating queries
	- The `MockSoql.Simulator` interface and `setMock()` method
	- (TODO) The `MockSoql.StaticSimulator` class?
- [ ] Constructing `AggregateResults`: The `MockSoql.AggregateResult` class
- [ ] Special Considerations for Mocking `QueryLocators`