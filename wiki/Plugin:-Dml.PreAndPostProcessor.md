This plugin allows developers to define logic to run immediately before, and/or immediately after a DML operation runs. This can be used for specialized functions, like logging.

## Setup

First, create an apex class that will be used to define your logic. Requirements:

- Class must be `public`.
- Class must have a `public` 0-arg constructor (either explicit or implicit).
- Class must implement the [`Dml.PreAndPostProcessor`](./The-Dml.PreAndPostProcessor-Interface) interface.

```apex
public class SomeApexClass implements Dml.PreAndPostProcessor {
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

Next, create a _Database Layer Setting_/`DatabaseLayerSetting__mdt` custom metadata record, called "Default" (unless one already exists).

Finally, list your apex class from the previous step in the `DML: Pre & Post Processor` field, as shown below:

<img width="1182" height="437" alt="image" src="https://github.com/user-attachments/assets/3aeda326-ae2e-4df7-8565-929dcff4025b" />

---

## What Does it Do?

Once set up, the framework will do the following:

- Call your class's [`processPreDml`](./The-Dml.PreAndPostProcessor-Interface#processPreDml) method immediately _before_ processing a DML operation
- Call your class's [`processPostDml`](./The-Dml.PreAndPostProcessor-Interface#processPostDml) method immediately _after_ processing a DML operation
- Call your class's [`processDmlError`](./The-Dml.PreAndPostProcessor-Interface#processdmlerror) method if an exception is thrown during a DML operation. After the interface method runs, the exception will be re-thrown.

⚠️ Note: If the DML operation results in an thrown exception (ie., if a failure occurs and `allOrNone=true`), then the `processPostDml` method will _**not**_ be called.
