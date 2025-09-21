Enumerates all of the supported SOQL operations. The framework uses this in the [`Soql.Request`](./The-Soql.Request-Class) class to determine what type operation is being processed.

Example:

```apex
public class SomeLogic implements Soql.PreAndPostProcessor {
  public void preProcessSoql(Soql.Request request) {
    if (request?.operation == Soql.Operation.GET_QUERY_LOCATOR) {
      // Some special processing...
    }
  }

  // ... rest of interface omitted for brevity
}
```

## Values

- `AGGREGATE_QUERY`: Represents `Database.query` operations w/aggregations.
- `COUNT_QUERY`: Represents `Database.countQuery` operations.
- `GET_CURSOR`: Represents `Database.getCursor` operations.
- `GET_QUERY_LOCATOR`: Represents `Database.getQueryLocator` operations.
- `QUERY`: Represents `Database.query` operations w/o aggregations.
