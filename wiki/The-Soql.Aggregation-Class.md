Represents an aggregate expression in a SOQL query. For example, `COUNT(Id) numRecords`. This class implements `Soql.Selectable`, and can be used in `addSelect` methods. This can also be with `addHaving` methods when making an aggregate query.

Each `Soql.Aggregation` is comprised of the following properties:

- (always) a `Soql.Function` (ex., `COUNT`)
- (usually) a field (ex., `Id`)
- (optionally) An alias (ex, `numRecords`)

```apex
// "COUNT()"
Soql.Aggregation agg1 = new Soql.Aggregation(Soql.Function.COUNT);
// "CALENDAR_YEAR(CreatedDate)
Soql.Aggregation agg2 = new Soql.Aggregation(Soql.Function.CALENDAR_YEAR, Account.CreatedDate);
// "MAX(CreatedDate) lastCreated"
Soql.Aggregation agg3 = new Soql.Aggregation(Soql.Function.MAX, Account.CreatedDate)?.withAlias('lastCreated');
```

---

## Constructors

- `Soql.Aggregation(Soql.Function, String innerFieldName)`
- `Soql.Aggregation(Soql.Function, SObjectField field)`
- `Soql.Aggregation(Soql.Function, Soql.ParentField field)`
- `Soql.Aggregation(Soql.Function)`

---

## Methods

### `withAlias`

Adds an alias to the aggregation. Ex., `numRecords`.

- `Soql.Aggregation withAlias(String alias)`
