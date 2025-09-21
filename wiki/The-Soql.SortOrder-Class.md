Represents a SOQL `ORDER BY` clause.

Use this object in conjunction with the [addOrderBy](./The-Soql.Builder-Class#addOrderBy) builder method:

```apex
Soql.SortOrder firstCreated = new Soql.SortOrder(
  Account.CreatedDate,
  Soql.SortDirection.ASCENDING
);
Soql query = DatabaseLayer.Soql
  ?.newQuery(Account.SObjectType)
  ?.addOrderBy(firstCreated)
  ?.toSoql();
```

---

## Constructors

- `Soql.SortOrder(List<String> fieldNames, Soql.SortDirection direction)`
- `Soql.SortOrder(String fieldName, Soql.SortDirection)`
- `Soql.SortOrder(List<SObjectField> fields, Soql.SortDirection direction)`
- `Soql.SortOrder(SObjectField field, Soql.SortDirection direction)`
- `Soql.SortOrder(List<Soql.ParentField> fields, Soql.SortDirection direction)`
- `Soql.SortOrder(Soql.ParentField field, Soql.SortDirection direction)`

---

## Methods

### `setNullOrder`

Adds an optional "null order" clause to the `ORDER BY` condition. For example, "ORDER BY ExternalId\_\_c ASC NULLS LAST"

- `Soql.SortOrder setNullOrder(Soql.NullOrder nullOrder)`
