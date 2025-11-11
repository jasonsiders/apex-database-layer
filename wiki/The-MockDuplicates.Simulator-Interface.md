Interface for custom simulator implementations.

Implement this interface to provide custom duplicate detection logic in tests that goes beyond what the [MockDuplicates.BaseSimulator](./The-MockDuplicates.BaseSimulator-Class) provides.

## Methods

### `simulate`

Simulates duplicate detection for a given record. The `record` parameter is the SObject record to check for duplicates. Returns the `FindDuplicatesResult` containing simulated duplicate detection results.

- `MockDuplicates.FindDuplicatesResult simulate(SObject record)`

```apex
public class CustomSimulator implements MockDuplicates.Simulator {
	public MockDuplicates.FindDuplicatesResult simulate(SObject record) {
		MockDuplicates.FindDuplicatesResult result = new MockDuplicates.FindDuplicatesResult(record.getSObjectType());
		result.addRule().addMatch().addRecord();
		return result;
	}
}
```
