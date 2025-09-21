This class decorates a `Schema.AggregateResult`, which cannot be mocked otherwise. Objects of this type are returned by the `Soql` class's [`aggregateQuery`](./The-Soql-Class#aggregateQuery) method, and can be mocked via the [`MockSoql.AggregateResult`](./The-MockSoql.AggregateResult-Class) class.

```apex
Soql.Aggregation count = new Soql.Aggregation(Soql.Function.COUNT, User.Id);
List<Soql.AggregateResult> results = DatabaseLayer.Soql.newQuery(User.SObjectType)
  ?.addSelect(count)
  ?.toSoql()
  ?.aggregateQuery();
Soql.AggregateResult firstResult = results?.get(0);
Integer numUsers = firstResult?.get('expr0');
```

---

## Methods

### `get`

Calls the underlying `Schema.AggregateResult` object's `get` method. The `key` parameter refers to the field alias if one is assigned, or the parameter's index in query preceded by the `expr` if one is not assigned (x, `expr0`).

- `Object get(String key)`
