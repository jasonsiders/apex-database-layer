Decorates `Database.QueryLocator` objects that are returned by `Database.getQueryLocator`. These objects cannot be serialized or mocked by other means.

Use this object in conjunction with the [getQueryLocator](./The-Soql-Class#getQueryLocator) method:

```apex
Soql soql = DatabaseLayer.Soql?.newQuery(Account.SObjectType);
Soql.QueryLocator locator = soql?.getQueryLocator();
```

---

## Methods

### `getLocator`

Returns the underlying `Database.QueryLocator` object used to construct this object.

- `Database.QueryLocator getLocator()`

### `getQuery`

Returns the query from the underlying `Database.QueryLocator`'s `getQuery()` method.

- `String getQuery()`

### `iterator`

Returns a `System.Iterator<SObject>` from the underlying `Database.QueryLocator`'s `iterator()` method.

- `System.Iterator<SObject> iterator()`
