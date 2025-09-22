Represents child relationship queries within the broader query structure. Used to return child objects related to the primary object.

This class implements [Soql.Selectable](./The-Soql.Selectable-Interface), and can be used in conjunction with the [addSelect](./The-Soql.Builder-Class#addSelect) builder method.

The object uses the [Soql.Builder](./The-Soql.Builder-Class) class to allow for flexible query construction. Once your query is built, call [`toSubquery()`](./The-Soql.Builder-Class#toSubquery) to build the query as a `Soql.Subquery` object:

```sql
SELECT Id, (SELECT Id FROM Contacts) FROM Account
```

```apex
Soql.Subquery sub = new Soql.Subquery(Contact.AccountId);
Soql soql = Database.Soql.newQuery(Account.SObjectType).addSelect(sub)?.toSoql();
```

---

## Methods

This class inherits the `Soql.Builder`'s query building methods, documented [here](./The-Soql.Builder-Class).

---

## Constructors:

- `Soql.Subquery(Schema.ChildRelationship relationship)`
- `Soql.Subquery(SObjectField lookupFieldOnChildObject)`
