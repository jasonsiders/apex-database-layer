Default simulator implementation that allows callers to inject simple simulation logic.

This class implements [MockDuplicates.Simulator](./The-MockDuplicates.Simulator-Interface) and provides methods to configure expected `FindDuplicatesResults` for each SObjectType.

## Methods

### `get`

Retrieves the configured `FindDuplicatesResult` for an object type.

**Overloads:**

- `MockDuplicates.FindDuplicatesResult get(String objectApiName)`
- `MockDuplicates.FindDuplicatesResult get(SObjectType objectType)`

**Returns:** The configured `FindDuplicatesResult`, or `null` if not configured.

```apex
DatabaseLayer.useMocks();

// Configure results for Account
MockDuplicates.simulator.withResults(Account.SObjectType)
    .addRule();

// Retrieve the configured results
MockDuplicates.FindDuplicatesResult result = MockDuplicates.simulator.get(Account.SObjectType);
Assert.isNotNull(result, 'No result configured');

// Using string API name
MockDuplicates.FindDuplicatesResult result2 = MockDuplicates.simulator.get('Account');
```

### `withException`

Configures the simulator to throw an exception.

**Overloads:**

- `MockDuplicates.BaseSimulator withException(Exception error)`
- `MockDuplicates.BaseSimulator withException()`

**Returns:** This instance for method chaining.

```apex
DatabaseLayer.useMocks();

// Throw specific exception
MockDuplicates.simulator.withException(new System.DmlException('API Error'));

// Throw generic HandledException
MockDuplicates.simulator.withException();

// Now any duplicate detection will throw the exception
Account account = new Account();
try {
    DatabaseLayer.Duplicates.findDuplicates(account);
    Assert.fail('Should have thrown exception');
} catch (Exception e) {
    // Expected
}
```

### `withResults`

Configures and returns a `FindDuplicatesResult` for an object type.

- `MockDuplicates.FindDuplicatesResult withResults(SObjectType objectType)`

**Returns:** A `FindDuplicatesResult` instance for configuring duplicate detection results.

```apex
DatabaseLayer.useMocks();

// Configure results for Account
MockDuplicates.FindDuplicatesResult result = MockDuplicates.simulator
    .withResults(Account.SObjectType);

// Can now configure the result using fluent API
result.addRule()
    .addMatch()
        .addRecord();
```

### `simulate`

Simulates duplicate detection for a record. This method is called internally by the framework.

- `MockDuplicates.FindDuplicatesResult simulate(SObject record)`

**Returns:** The configured `FindDuplicatesResult`, or throws an exception if configured.

```apex
// This method is called internally by the framework
// You typically don't call it directly
```

## Example: Basic Configuration

```apex
DatabaseLayer.useMocks();

// Configure duplicate detection results
MockDuplicates.BaseSimulator simulator = MockDuplicates.simulator;

simulator.withResults(Account.SObjectType)
    .addRule()
        .setRuleName('Account_Duplicate_Rule')
        .setSaveBehavior(MockDuplicates.SaveBehavior.BLOCK)
        .addMatch()
            .addRecord()
                .setConfidence(95.0);

// Now test code that uses duplicate detection
Account account = new Account(Name = 'Acme Corp');
Duplicates.FindDuplicatesResult result = DatabaseLayer.Duplicates.findDuplicates(account);

Assert.isTrue(result.isSuccess(), 'Should succeed');
Assert.isFalse(result.getDuplicateResults()?.get(0)?.isAllowSave(), 'Should block save');
```

## Example: Multiple SObject Types

```apex
DatabaseLayer.useMocks();

// Configure results for multiple object types
MockDuplicates.simulator
    .withResults(Account.SObjectType)
        .addRule()
            .addMatch()
                .addRecord();

MockDuplicates.simulator
    .withResults(Contact.SObjectType)
        .addRule()
            .addMatch()
                .addRecord()
                    .setConfidence(88.0);

// Each object type returns its configured results
Duplicates.FindDuplicatesResult accountResult = DatabaseLayer.Duplicates.findDuplicates(new Account());
Duplicates.FindDuplicatesResult contactResult = DatabaseLayer.Duplicates.findDuplicates(new Contact());
```

## Example: Exception Configuration

```apex
DatabaseLayer.useMocks();

// Configure to throw exception for all duplicate detection
MockDuplicates.simulator.withException(new System.CalloutException('External service unavailable'));

// Any duplicate detection will throw the exception
try {
    DatabaseLayer.Duplicates.findDuplicates(new Account());
    Assert.fail('Should have thrown exception');
} catch (System.CalloutException e) {
    Assert.areEqual('External service unavailable', e.getMessage());
}
```
