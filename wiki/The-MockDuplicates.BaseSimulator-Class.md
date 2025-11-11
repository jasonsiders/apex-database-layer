Default simulator implementation that allows callers to inject simple simulation logic.

This class implements [MockDuplicates.Simulator](./The-MockDuplicates.Simulator-Interface) and provides methods to configure expected `FindDuplicatesResults` for each SObjectType.

## Methods

### `get`

Retrieves the configured `FindDuplicatesResult` for an object type. Returns the configured `FindDuplicatesResult`, or `null` if not configured.

- `MockDuplicates.FindDuplicatesResult get(String objectApiName)`
- `MockDuplicates.FindDuplicatesResult get(SObjectType objectType)`

```apex
MockDuplicates.FindDuplicatesResult result = MockDuplicates.simulator.get(Account.SObjectType);
```

### `withException`

Configures the simulator to throw an exception. Returns this instance for method chaining.

- `MockDuplicates.BaseSimulator withException(Exception error)`
- `MockDuplicates.BaseSimulator withException()`

```apex
MockDuplicates.simulator.withException(new System.DmlException('API Error'));
```

### `withResults`

Configures and returns a `FindDuplicatesResult` for an object type. Returns a `FindDuplicatesResult` instance for configuring duplicate detection results.

- `MockDuplicates.FindDuplicatesResult withResults(SObjectType objectType)`

```apex
MockDuplicates.FindDuplicatesResult result = MockDuplicates.simulator.withResults(Account.SObjectType);
```

### `simulate`

Simulates duplicate detection for a record. This method is called internally by the framework. Returns the configured `FindDuplicatesResult`, or throws an exception if configured.

- `MockDuplicates.FindDuplicatesResult simulate(SObject record)`

```apex
// This method is called internally by the framework
// You typically don't call it directly
```
