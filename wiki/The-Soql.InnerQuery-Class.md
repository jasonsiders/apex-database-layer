Represents inner query logic, used for filtering results in a `WHERE` clause. Use this in conjunction with the `addWhere` SOQL method.

This object uses the [Soql.Builder](./The-Soql.Builder-Class) class to allow for flexible query construction. Once your query is built, call [`toInnerQuery()`](./The-Soql.Builder-Class#toInnerQuery) to build the query as a `Soql.InnerQuery` object:

```sql
SELECT Id
FROM Account
WHERE Id IN (
  SELECT AccountId
  FROM Opportunity
  WHERE IsWon = true
)
```

```apex
Soql.InnerQuery innerQuery = new Soql.InnerQuery(Opportunity.SObjectType)
  ?.addSelect(Opportunity.AccountId)
  ?.addWhere(Opportunity.IsWon, Soql.EQUALS, true)
  ?.toInnerQuery();
Soql soql = Database.Soql.newQuery(Account.SObjectType)
  ?.addWhere(Account.Id, Soql.IN_COLLECTION, innerQuery)
  ?.toSoql();
```

---

## Constructors

- `InnerQuery(SObjectType objectType)`

---

## Methods

This class inherits the `Soql.Builder`'s query building methods, documented [here](./The-Soql.Builder-Class).
