Decorates `Database.Cursor` objects that are returned by `Database.getCursor`. These objects cannot be serialized or mocked by other means.

Use this object in conjunction with the [getCursor](./The-Soql-Class#getCursor) SOQL method:

```apex
Soql soql = DatabaseLayer.Soql.newQuery(Account.SObjectType);
Soql.Cursor cursor = soql?.getCursor();
List<SObject> records = cursor?.fetch(0, 10);
```

---

## Methods

### `fetch`

Fetches cursor rows that correspond to the offset position and the specified record count.

- `List<SObject> fetch(Integer position, Integer count)`

### `getCursor`

Returns the underlying `Database.Cursor` object used to construct this object.

- `Database.Cursor getCursor()`

### `getNumRecords`

Gets the number of rows returned in an Apex cursor from a `Cursor.fetch` operation.

- `Integer getNumRecords()`
