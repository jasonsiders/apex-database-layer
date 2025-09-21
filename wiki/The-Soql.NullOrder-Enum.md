Indicates how null values should be processed in SOQL `ORDER BY` clauses.

Use this in conjunction with the `Soql.SortOrder` class's [setNullOrder](./The-Soql.SortOrder-Class#setNullOrder) method.

```apex
Soql.SortOrder sortOrder = new Soql.SortOrder(
  Opportunity.CloseDate,
  Soql.SortDirection.DESCENDING
)?.setNullOrder(
  Soql.NullOrder.NULLS_FIRST
);
Soql query = DatabaseLayer.Soql.newQuery(Opportunity.SObject)
  ?.addOrderBy(sortOrder)
  ?.toSoql();
```

---

## Values

- `NULLS_FIRST`
- `NULLS_LAST`
