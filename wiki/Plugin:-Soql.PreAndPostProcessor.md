This plugin allows developers to define logic to run immediately before, and/or immediately after a SOQL operation runs. This can be used for specialized functions, like logging.

## Setup

First, create an apex class that will be used to define your logic. Requirements:

- Class must be `public`.
- Class must have a `public` 0-arg constructor (either explicit or implicit).
- Class must implement the [`Dml.PreAndPostProcessor`](./The-Dml.PreAndPostProcessor-Interface) interface.

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

  public void processDmlError(Soql.Request request, Exception error) {
    String msg = request?.operation + ' error: ' + error;
    Logger.error(msg)?.setExceptionDetails(error);
    Logger.saveLog();
  }
}
```

Next, create a _Database Layer Setting_/`DatabaseLayerSetting__mdt` custom metadata record, called "Default" (unless one already exists).

Finally, list your apex class from the previous step in the `SOQL: Pre & Post Processor` field, as shown below:

<img width="1191" height="443" alt="image" src="https://github.com/user-attachments/assets/d7d0aac9-b78b-43d9-aa68-8544b91d9443" />

---

## What Does it Do?

Once set up, the framework will do the following:

- Call your class's [`processPreSoql`](./The-Soql.PreAndPostProcessor-Interface#processPreSoql) method immediately _before_ processing a SOQL operation
- Call your class's [`processPostSoql`](./The-Soql.PreAndPostProcessor-Interface#processPostSoql) method immediately _after_ processing a SOQL operation
- Call your class's [`processSoqlError`](./The-Soql.PreAndPostProcessor-Interface#processSoqlError) method if an exception is thrown during a SOQL operation. After the interface method runs, the exception will be re-thrown.
