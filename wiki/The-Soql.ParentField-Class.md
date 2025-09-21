Use this class to add parent (or multiple-grandparent) object fields to your query without using Strings, ex., `Account.Owner.Profile.Name`. This approach enforces referential integrity, and helps avoid runtime failures (if for example, the field doesn't exist or is misspelled).

This class implements [Soql.Selectable](./The-Soql.Selectable-Interface), and therefore can be used in conjunction with the [addSelect](./The-Soql.Builder-Class#addSelect) builder method:

```sql
SELECT Id, Account.Owner.Name FROM Opportunity
```

```apex
Soql.ParentField field = new Soql.ParentField(
  Opportunity.AccountId,
  Account.OwnerId,
  User.Name
);
Soql query = DatabaseLayer.Soql.newQuery(Opportunity.SObjectType)
  ?.addSelect(field)
  ?.toSoql();
```

---

## Constructors

Accepts a `List<SObjectField>`, or up to six separate `SObjectField` arguments (up to five relationship fields, plus the actual field to be returned in the query). Each argument represents a field in the sequential "chain" of relationships leading from the `FROM` object to the ultimate field to be queried.

- `Soql.ParentField(List<SObjectField> relationshipFieldChain)`
- `Soql.ParentField(SObjectField field1, [field2, field3, field4, field5, field6])`
