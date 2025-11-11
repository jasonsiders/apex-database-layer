Represents additional information associated with a duplicate match record in test scenarios.

This class extends [Duplicates.AdditionalInformationMap](./The-Duplicates.AdditionalInformationMap-Class) and provides a fluent API for building match metadata with navigation back to parent objects.

## Methods

### `setName`

Sets the name of this additional information entry. Returns this instance for method chaining.

- `MockDuplicates.AdditionalInformationMap setName(String name)`

```apex
info.setName('UpdatedKey');
```

### `setValue`

Sets the value of this additional information entry. Returns this instance for method chaining.

- `MockDuplicates.AdditionalInformationMap setValue(String value)`

```apex
info.setValue('NEW_VALUE_456');
```

### `toTop`

Navigates back to the top-level `FindDuplicatesResult`.

- `MockDuplicates.FindDuplicatesResult toTop()`

```apex
MockDuplicates.FindDuplicatesResult result = info.toTop();
```

### `up`

Navigates back to the parent `MatchRecord`.

- `MockDuplicates.MatchRecord up()`

```apex
MockDuplicates.MatchRecord matchRecord = info.up();
```
