This custom exception type decorates a standard `System.InvalidParameterValueException` thrown by the Database.Cursor class in certain circumstances, ex., when using a negative Integer in a `fetch()` call.

This is necessary since `System.InvalidParameterValueException` objects can only be manually constructed in VF or Aura contexts. Therefore, they cannot be mocked in apex tests.

Both `Soql` and `MockSoql` classes will throw this custom exception type instead of the standard Exception type:

```apex
try {
  Soql.Cursor cursor = DatabaseLayer.Soql.newQuery(Account.SObjectType)?.getCursor();
  cursor?.fetch(0, -1);
} catch (Soql.InvalidParameterValueException error) {
  // Can't fetch a negative value!
}
```
