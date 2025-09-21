A constructable version of the [`Soql.AggregateResult`](./The-Soql.AggregateResult) class, which wraps the `Schema.AggregateResult` class and its methods. `Schema.AggregateResult` objects cannot be directly constructed, serialized, or otherwise mocked.

You can use this object along in conjunction with existing mocking methods to inject these results in queries. For example:

```apex
DatabaseLayer.useMocks();
MockSoql.AggregateResult agg = new MockSoql.AggregateResult()?.addParameter('numRecords', 100);
MockSoql?.setGlobalMock()?.withResults(new List<MockSoql.AggregateResult>{ agg });
List<Soql.AggregateResult> results = soql?.aggregateQuery();
```

---

### Methods

#### `addParameter`

Adds a column to the current `AggregateResult`. These can be created with or without an _alias_. If an alias isn't provided, the column is assigned a default alias, ex. `expr0'`. This mirrors the behavior of the underlying `Schema.AggregateResult` object.

- `MockSoql.AggregateResult addParameter(String alias, Object value)`
- `MockSoql.AggregateResult addParameter(Object value)`
