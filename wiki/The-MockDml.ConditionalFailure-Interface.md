Evaluates a given SObject record and DML operation, and returns an `Exception` object if the operation should fail for that record.

---

### Methods

#### `checkFailure`

- `checkFailure(Dml.Operation operation, SObject record)`

The only required method to be implemented by the interface. This method is called once per DML operation, per record submitted for processing.

If `null` is returned, the operation will succeed. If an Exception is returned, the operation will fail in accordance with the current `Dml` object's defined `allOrNone` behavior. This behavior mirrors standard DML `allOrNone` logic:

- If `allOrNone == true`, the Exception returned by the `checkFailure()` method is thrown, and the entire operation fails.
- If `allOrNone == false`, only the current SObject fails. The matching Database Result object returned by the DML operation will indicate that the record failed. The resulting error message for the result is derived from the Exception returned by the `checkFailure()` method.

Example:

```apex
public class ExampleFailure implements MockDml.ConditionalFailure {
	public Exception checkFailure(Dml.Operation operation, SObject record) {
		// Fail any operations that manipulate Account records
		if (record?.getSObjectType() == Account.SObjectType) {
			return new System.DmlException();
		} else {
			// Success!
			return null;
		}
	}
}
```
