This interface defines logic to be run before/after SOQL operations, as well as when an exception is thrown during a SOQL operation. You can use this for logging, or other specialized use cases.

All interface methods include a `Soql.Request` object. This object includes contextual information about the operation to be processed. See the [`Soql.Request`](./The-Soql.Request-Class) class for the full list of parameters.

Read more about how this plugin works [**here**](./Plugin:-Soql.PreAndPostProcessor).

Example:

```apex
public class SomeApexClass implements Soql.PreAndPostProcessor {
  // This sample PreAndPostProcessor logs SOQL operations, using Nebula Logger:
  public void processPreSoql(Soql.Request request) {
    Logger.finest('About to query: ' + JSON.serialize(request));
    Logger.finest(msg);
  }

  public void processPostSoql(Soql.Request request, List<Object> results) {
    List<SObject> records = (List<Object> instanceof List<SObject>) ? results : new List<SObject>();
    Logger.finest('Processed query ' + JSON.serialize(request))?.setRecord(records);
  }

  public void processSoqlError(Soql.Request request, Exception error) {
    String msg = request?.operation + ' error: ' + error;
    Logger.error(msg)?.setExceptionDetails(error);
    Logger.saveLog();
  }
}
```

## Methods

### `processSoqlError`

Defines logic to run when an exception is thrown during a Soql operation.

Once this method runs, the framework will re-throw the Exception. If this is not desired, wrap your SOQL operation in a `try/catch` block. You cannot do this from within the interface itself.

- `void processSoqlError(Soql.Request request, Exception error)`

### `processPreSoql`

Defines logic to be run immediately before a SOQL operation.

- `void processPreSoql(Soql.Request request)`

### `processPostSoql`

Defines logic to be run immediately after a SOQL operation.

Note: This method is not called if the SOQL operation yields a thrown exception. You can use the [`processSoqlError`](./The-Soql.PreAndPostProcessor-Interface#processdmlerror) method to handle these errors instead.

- `void processPostSoql(Soql.Request request, List<Object> databaseResults)`

:warning: **Note**: Depending on your use case, you may need to explicitly cast the results to the appropriate type based on the `operation` being processed:

<table>
  <tr>
    <th>SOQL Operation</th>
    <th>Database Result Type</th>
  </tr>
  <tr>
    <td><code>AGGREGATE_QUERY</code></td>
    <td><code>Soql.AggregateQuery</code></td>
  </tr>
  <tr>
    <td><code>COUNT_QUERY</code></td>
    <td><code>Integer</code></td>
  </tr>
  <tr>
    <td><code>GET_CURSOR</code></td>
    <td><code>Soql.Cursor</code></td>
  </tr>
  <tr>
    <td><code>GET_QUERY_LOCATOR</code></td>
    <td><code>Soql.QueryLocator</code></td>
  </tr>
  <tr>
    <td><code>QUERY</code></td>
    <td><code>List<SObject></code></td>
  </tr>
</table>
