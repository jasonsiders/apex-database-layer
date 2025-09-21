Indicates the direction of the SOQL `ORDER BY` clause.

Use this in conjunction with the [addOrderBy](./The-Soql.Builder-Class#addOrderBy) builder method, and/or the [Soql.SortOrder](./The-Soql.SortOrder-Class) class.

```apex
Soql soql = DatabaseLayer.Soql
  ?.newQuery(Opportunity.SObjectType)
  ?.addOrderBy(Opportunity.Amount, Soql.SortDirection.DESCENDING)
  ?.toSoql();
```

---

## Values

- `ASCENDING`
- `DESCENDING`
