Represents additional information associated with a duplicate match record in test scenarios.

This class extends [Duplicates.AdditionalInformationMap](./The-Duplicates.AdditionalInformationMap-Class) and provides a fluent API for building match metadata with navigation back to parent objects.

## Methods

### `setName`

Sets the name of this additional information entry.

- `MockDuplicates.AdditionalInformationMap setName(String name)`

**Returns:** This instance for method chaining.

```apex
MockDuplicates.AdditionalInformationMap info = matchRecord
    .addAdditionalInfo('MatchKey', 'ACME_123')
    .setName('UpdatedKey');
```

### `setValue`

Sets the value of this additional information entry.

- `MockDuplicates.AdditionalInformationMap setValue(String value)`

**Returns:** This instance for method chaining.

```apex
info.setValue('NEW_VALUE_456');
```

### `toTop`

Navigates back to the top-level `FindDuplicatesResult`.

- `MockDuplicates.FindDuplicatesResult toTop()`

```apex
MockDuplicates.FindDuplicatesResult result = MockDuplicates.simulator
    .withResults(Account.SObjectType)
        .addRule()
            .addMatch()
                .addRecord()
                    .addAdditionalInfo('Key', 'Value')
                        .toTop(); // Returns to FindDuplicatesResult
```

### `up`

Navigates back to the parent `MatchRecord`.

- `MockDuplicates.MatchRecord up()`

```apex
MockDuplicates.MatchRecord matchRecord = info.up();
```

## Example

```apex
DatabaseLayer.useMocks();

MockDuplicates.simulator
    .withResults(Account.SObjectType)
        .addRule()
            .addMatch()
                .addRecord()
                    .addAdditionalInfo('MatchEngine', 'FuzzyMatch')
                        .setValue('ExactMatch') // Change the value
                        .up() // Navigate back to MatchRecord
                    .addAdditionalInfo('Confidence', '95.5')
                        .toTop(); // Navigate to FindDuplicatesResult
```
