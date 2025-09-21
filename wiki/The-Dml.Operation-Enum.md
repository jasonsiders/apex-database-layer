Enumerates all of the supported DML operations. The framework uses this in the [`Dml.Request`](./The-Dml.Request-Class) class and the [`MockDml.ConditionalFailure`](./The-MockDml.ConditionalFailure) interface to determine what type operation is being processed.

Example:

```apex
public class SomeLogic implements MockDml.ConditionalFailure {
  public Exception checkFailure(Dml.Operation operation, SObject record) {
    // Fail on update:
    return (operation == Dml.Operation.DO_UPDATE
    if (operation == Dml.Operation.DO_UPDATE) {
      return new System.DmlException();
    } else {
      return null;
    }
  }
}
```

## Values

- `DO_CONVERT`
- `DO_DELETE`
- `DO_INSERT`
- `DO_PUBLISH`
- `DO_PURGE`
- `DO_UNDELETE`
- `DO_UPDATE`
- `DO_UPSERT`
