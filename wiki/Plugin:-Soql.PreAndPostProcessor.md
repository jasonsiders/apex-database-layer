This plugin allows developers to define logic to run immediately before, and/or immediately after a SOQL operation runs. This can be used for specialized functions, like logging.

## Setup

First, create an apex class that will be used to define your logic. Requirements:

- Class must be `public`.
- Class must have a `public` 0-arg constructor (either explicit or implicit).
- Class must implement the [`Soql.PreAndPostProcessor`](./The-Soql.PreAndPostProcessor-Interface) interface.

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

Next, navigate to `Setup > Custom Metadata Types > Database Layer Parameter > Manage Records` and create a new record with the following values:

| Field | Value |
|---|---|
| **Label** | SOQL Pre And Post Processor _(or any label you prefer)_ |
| **DeveloperName** | `SoqlPreAndPostProcessor` |
| **Value** | The fully-qualified name of your Apex class (e.g., `SomeApexClass`) |

---

## What Does it Do?

Once set up, the framework will do the following:

- Call your class's [`processPreSoql`](./The-Soql.PreAndPostProcessor-Interface#processPreSoql) method immediately _before_ processing a SOQL operation
- Call your class's [`processPostSoql`](./The-Soql.PreAndPostProcessor-Interface#processPostSoql) method immediately _after_ processing a SOQL operation
- Call your class's [`processSoqlError`](./The-Soql.PreAndPostProcessor-Interface#processSoqlError) method if an exception is thrown during a SOQL operation. After the interface method runs, the exception will be re-thrown.
