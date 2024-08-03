# The `Soql` Class

- ! TODO ! Add some general information about the class

## Public Methods

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

#### `bind`
!TODO!

- `Soql.Builder bind(Map<String, Object> bindMap)`
- `Soql.Builder bind(String key, Object value)`
- `Soql.Builder bind(Soql.Binder binder)`

#### `deselectAll`
!TODO!

- `Soql.Builder deselectAll()`

#### `deselect`
!TODO!

- `Soql.Builder deselect(String fieldName)`
- `Soql.Builder deselect(SObjectField field)`

#### `defineAccess`
!TODO!

- `Soql.Builder defineAccess(System.AccessLevel accessLevel)`

#### `reset`
!TODO!

- `Soql.Builder reset()`

#### `selectAll`
!TODO!

- `Soql.Builder selectAll()`

#### `addSelect`
!TODO!

- `Soql.Builder addSelect(String fieldName, String alias)`
- `Soql.Builder addSelect(SObjectField field, String alias)`
- `Soql.Builder addSelect(String fieldName)`
- `Soql.Builder addSelect(SObjectField field)`
- `Soql.Builder addSelect(Soql.Aggregation aggregation)`
- `Soql.Builder addSelect(Soql.SubQuery subQuery)`

#### `fromEntity`
!TODO!
- `Soql.Builder fromEntity(SObjectType objectType)`

#### `usingScope`
!TODO!
- `Soql.Builder usingScope(Soql.Scope scope)`

#### `addWhere`
!TODO!

- `Soql.Builder addWhere(Soql.Criteria criteria)`
- `Soql.Builder addWhere(String fieldName, Soql.Operator operator, Object value)`
- `Soql.Builder addWhere(SObjectField field, Soql.Operator operator, Object value)`
- `Soql.Builder addWhere(String fieldName, Soql.Operator operator, Soql.Binder binder)`
- `Soql.Builder addWhere(SObjectField field, Soql.Operator operator, Soql.Binder binder)`

#### `setWhereLogic`
!TODO!

- `Soql.Builder setWhereLogic(Soql.LogicType newLogicType)`

#### `withSecurityEnforced`
!TODO!

- `Soql.Builder withSecurityEnforced()`

#### `groupBy`
!TODO!

- `Soql.Builder groupBy(String fieldName)`
- `Soql.Builder groupBy(SObjectField field)`

#### `addHaving`
!TODO!

- `Soql.Builder addHaving(Soql.Aggregation agg, Soql.Operator operator, Object value)`

#### `setHavingLogic`
!TODO!

- `Soql.Builder setHavingLogic(Soql.LogicType newLogicType)`

#### `orderBy`
!TODO!

- `Soql.Builder orderBy(Soql.SortOrder sortOrder)`
- `Soql.Builder orderBy(String fieldName, Soql.SortDirection direction)`
- `Soql.Builder orderBy(SObjectField field, Soql.SortDirection direction)`

#### `setRowLimit`
!TODO!

- `Soql.Builder setRowLimit(Integer rowLimit)`

#### `setRowOffset`
!TODO!

- `Soql.Builder setRowOffset(Integer rowOffset)`

#### `setUsage`
!TODO!

- `Soql.Builder setUsage(Soql.Usage usage)`

## Public Inner Types

### `Soql.AggregateResult`
### `Soql.Aggregation`
### `Soql.Binder`
### `Soql.Condition` 
### `Soql.Criteria`
### `Soql.ConditionalLogic`
### `Soql.Function`
### `Soql.InnerQuery`
Represents inner query logic, often used for filtering results in a `WHERE` clause. 

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

### `Soql.LogicType`
### `Soql.NullOrder`
### `Soql.QueryLocator`
### `Soql.Scope`
### `Soql.SortDirection`
### `Soql.SortOrder`
### `Soql.Subquery`
Represents child relationship queries within the broader query structure, used to return child objects related to the primary object. 

For example:

```sql
SELECT 
	Id, 
	(SELECT Id FROM Contacts) 
FROM Account`
```

This class extends `Soql.Builder`, and therefore has all of the same query-building [methods](#building-queries).

- `Soql.SubQuery(Schema.ChildRelationship relationship)`
- `Soql.SubQuery(SObjectField lookupFieldOnChildObject)`

### `Soql.Usage`

## Mocking SOQL Queries

- [ ] Simulating queries
	- The `MockSoql.Simulator` interface and `setMock()` method
	- (TODO) The `MockSoql.StaticSimulator` class?
- [ ] Constructing `AggregateResults`: The `MockSoql.AggregateResult` class
- [ ] Special Considerations for Mocking `QueryLocators`