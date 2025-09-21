This interface defines logic to be run before/after DML operations, as well as when an exception is thrown during a DML operation. You can use this for logging, or other specialized use cases.

All interface methods include a `Dml.Request` object. This object includes contextual information about the operation to be processed. See the [`Dml.Request`](./The-Dml.Request-Class) class for the full list of parameters.

Read more about how this plugin works [**here**](./Plugin:-Dml.PreAndPostProcessor).

Example:

```apex
public class MyPlugin implements Dml.PreAndPostProcessor {
  // This sample PreAndPostProcessor logs DML operations, using Nebula Logger:
  public void processPreDml(Dml.Request request) {
    Logger.finest('About to process ' + this.getLogSuffix(request))?.setRecord(request?.records);
    Logger.finest(msg)?.setRecord(request?.records);
  }

  public void processPostDml(Dml.Request request, List<Object> results) {
    Logger.finest('Processed ' + this.getLogSuffix(request))?.setRecord(request?.records);
  }

  public void processDmlError(Dml.Request request, Exception error) {
    String msg = request?.operation + ' error: ' + error;
    Logger.error(msg)?.setExceptionDetails(error);
    Logger.saveLog();
  }

  private String getLogSuffix(Dml.Request req) {
    return req?.numRecords + ' ' + req?.sObjectType + ' records. Operation: ' + req?.operation;
  }
}
```

## Methods

### `processDmlError`

Defines logic to run when an exception is thrown during a Dml operation.

Once this method runs, the framework will re-throw the Exception. If this is not desired, wrap your DML operation in a `try/catch` block. You cannot do this from within the interface itself.

Note: This message does not handle _partial success_ DML operations, since failures here do not yield an Exception. To handle these operations, use the `processPostDml` method and the `isSuccess()` method on the database result objects.

- `void processDmlError(Dml.Request request, Exception error)`

### `processPreDml`

Defines logic to be run immediately before a DML operation.

- `void processPreDml(Dml.Request request)`

### `processPostDml`

Defines logic to be run immediately before a DML operation.

Also includes a `List<Object>`, which represents the Database results (ie., `Database.SaveResult`, `Database.DeleteResult`, `Database.UpsertResult`, etc) produced by the DML operation. Since these objects do not share a common interface, the return type must be a generic `List<Object>`.

Note: This method is not called if the DML operation yields a thrown exception. You can use the [`processDmlError`](./The-Dml.PreAndPostProcessor-Interface#processdmlerror) method to handle these errors instead.

- `void processPostDml(Dml.Request request, List<Object> databaseResults)`

:warning: **Note**: Depending on your use case, you may need to explicitly cast the results to the appropriate type based on the `operation` being processed:

<table>
  <tr>
    <th>DML Operation</th>
    <th>Database Result Type</th>
  </tr>
  <tr>
    <td><code>DO_CONVERT</code></td>
    <td><code>Database.ConvertResult</code></td>
  </tr>
  <tr>
    <td><code>DO_INSERT</code>, <code>DO_PUBLISH</code>, <code>DO_UPDATE</code></td>
    <td><code>Database.SaveResult</code></td>
  </tr>
  <tr>
    <td><code>DO_PURGE</code></td>
    <td><code>Database.EmptyRecycleBinResult</code></td>
  </tr>
  <tr>
    <td><code>DO_UNDELETE</code></td>
    <td><code>Database.UndeleteResult</code></td>
  </tr>
  <tr>
    <td><code>DO_UPSERT</code></td>
    <td><code>Database.UpsertResult</code></td>
  </tr>
</table>
