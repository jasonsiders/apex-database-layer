Registers a bind variable to be used in the query. Ex, `SELECT Id FROM Account WHERE Name = :foo`.

Use this method in conjunction with the `addWhere` and `addBind` SOQL methods.

```apex
Soql.Binder profileName = new Soql.Binder('profileName', 'System Administrator');
Soql.Binder userId = new Soql.Binder('userId', UserInfo.getUserId());
Soql query = DatabaseLayer.Soql.newQuery(User.SObjectType)
  ?.addWhere(User.Id, Soql.NOT_EQUALS, userId)
  ?.addWhere(new Soql.ParentField(User.ProfileId, Profile.Name), Soql.EQUALS, profileName)
  ?.toSoql();
```

💡 Tip: When a child query (`Soql.InnerQuery` or `Soql.Subquery`) with binds is added to a parent `Soql` query, the parent query inherits its bind keys/values.

```apex
Soql.Binder owner = new Soql.Binder('ownerId', UserInfo.getUserId());
Soql.Subquery subquery = new Soql.Subquery(Opportunity.AccountId)
  ?.addWhere(Opportunity.OwnerId, Soql.EQUALS, owner)
  ?.toSubquery();
// No need to explicitly bind the 'owner' to the parent query:
Soql query = DatabaseLayer.Soql.newQuery(Account.SObjectType)
  ?.addSelect(subquery)
  ?.toSoql();
```

---

## Constructors

- `Soql.Binder(String key, Object value)`
- `Soql.Binder(String key)`

---

## Methods

### `getKey`

Returns the name of the bind variable to be used in the query.

- `String getKey()`

### `getValue`

Returns the underlying value to be substituted at runtime during the query.

- `Object getValue()`

### `setValue`

Set the underlying value to be substituted for the bind variable. This is done at runtime, when the query is actually made, via the `Database.queryWithBinds()` method.

- `Soql.Binder setValue(Object value)`
