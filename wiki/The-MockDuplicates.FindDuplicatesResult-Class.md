Represents the top-level result of a duplicate detection operation in test scenarios.

This class extends [Duplicates.FindDuplicatesResult](./The-Duplicates.FindDuplicatesResult-Class) and provides a fluent API for building complete duplicate detection results.

## Constructor

### `FindDuplicatesResult`

Creates a new `FindDuplicatesResult` for a specific SObjectType.

- `global FindDuplicatesResult(SObjectType objectType)`

```apex
MockDuplicates.FindDuplicatesResult result = new MockDuplicates.FindDuplicatesResult(Account.SObjectType);
```

## Methods

### `addRule`

Adds a duplicate rule result for a specific object type. Returns the created `DuplicateResult` instance for method chaining.

- `MockDuplicates.DuplicateResult addRule(SObjectType objectType)`
- `MockDuplicates.DuplicateResult addRule()`

```apex
MockDuplicates.DuplicateResult dupResult = result.addRule();
```

### `addError`

Adds an error to the result. Returns this instance for method chaining.

- `MockDuplicates.FindDuplicatesResult addError(Exception error)`
- `MockDuplicates.FindDuplicatesResult addError()`

```apex
result.addError(new System.DmlException('Duplicate detection failed'));
```

### `clearErrors`

Removes all errors from the result. Returns this instance for method chaining.

- `MockDuplicates.FindDuplicatesResult clearErrors()`

```apex
result.clearErrors();
```

### `clearDuplicateResults`

Removes all duplicate rule results. Returns this instance for method chaining.

- `MockDuplicates.FindDuplicatesResult clearDuplicateResults()`

```apex
result.clearDuplicateResults();
```
