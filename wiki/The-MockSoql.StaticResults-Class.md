Not all testing scenarios require the creation of a custom `MockSoql.Simulator` object. Most simple use cases can be handled by using the included `MockSoql.StaticResults` object.

This object cannot be directly constructed. Create an instance of this object by calling the 0-argument versions of the `MockSoql.setGlobalMock()` static method, or the `setMock()` instance method.

This object implements `MockSoql.Simulator` interface, and includes methods which allow callers to inject a static list of results, or an exception to be thrown. Whenever the query runs, the injected results are returned.

---

### Methods

#### `withError`

Injects an error to be thrown each time the query runs. Callers can provide a specific exception object, if desired. The 0-argument overload of this method will inject a generic `System.QueryException`.

- `MockSoql.StaticResults withError(System.Exception error)`
- `MockSoql.StaticResults withError()`

```apex
DatabaseLayer.useMocks();
// Queries will always throw a System.QueryException:
MockSoql.setGlobalMock()?.withError();
// Queries will always throw some other exception type:
System.Exception someOtherError = new System.CalloutException();
MockSoql.setGlobalMock()?.withError(someOtherError);
```

#### `withResults`

Injects a static list of results. This list will be returned each time the query runs.

- `MockSoql.StaticResults withResults(List<Object> results)`

```apex
DatabaseLayer.useMocks();
Account mockAccount = (Account) new MockRecord(Account.SObjectType)?.withId()?.toSObject();
// Queries will always return the provided List<Object>
MockSoql.setGlobalMock()?.withResults(new List<Account>{ mockAccont });
```
