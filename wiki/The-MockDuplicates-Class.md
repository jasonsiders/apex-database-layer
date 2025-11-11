This class extends the `Duplicates` class, and simulates duplicate detection operations in `@IsTest` context when the framework is configured to use mocks.

The framework automatically uses a `MockDuplicates` instance for duplicate detection operations whenever `DatabaseLayer.Duplicates` is called after `DatabaseLayer.useMocks()` or `DatabaseLayer.useMockDuplicates()` is called.

Unlike `Duplicates`, `MockDuplicates` does not interact with actual Salesforce duplicate rules. It simulates duplicate detection results by default with no duplicates found, though it's possible to configure specific duplicate matches, errors, and field differences.

For examples of using `MockDuplicates` in tests, see [Mocking Duplicate Rules](./Mocking-Duplicate-Rules).

---

## Properties

| Property Name | Data Type                                                            | Details                                                                                                                                                      |
| ------------- | -------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| simulator     | [MockDuplicates.Simulator](./The-MockDuplicates.Simulator-Interface) | The current simulator instance controlling duplicate detection behavior. Access this property to configure or verify which simulator is configured in tests. |

## Methods

All `MockDuplicates` methods inherit from its parent `Duplicates` class, documented [here](./The-Duplicates-Class#Methods). However, these methods do **not** interact with actual duplicate rules.

### `setMock`

Sets a custom simulator to control duplicate detection behavior in tests.

- `static MockDuplicates.Simulator setMock(MockDuplicates.Simulator simulator)`
- `static MockDuplicates.BaseSimulator setMock()`

```apex
DatabaseLayer.useMocks();
// Initialize with the default BaseSimulator
MockDuplicates.BaseSimulator simulator = MockDuplicates.setMock();

// Configure duplicate results
simulator.withResults(Account.SObjectType)
    .addRule()
        .addMatch()
            .addRecord();
```

```apex
DatabaseLayer.useMocks();
// Use a custom simulator implementation
CustomDuplicateSimulator customSim = new CustomDuplicateSimulator();
MockDuplicates.setMock(customSim);
```

## Read More

- [Mocking Duplicate Rules](./Mocking-Duplicate-Rules) - Guide for using MockDuplicates in tests
- [MockDuplicates.BaseSimulator](./The-MockDuplicates.BaseSimulator-Class) - The default simulator implementation
- [MockDuplicates.Simulator](./The-MockDuplicates.Simulator-Interface) - Interface for custom simulator implementations
