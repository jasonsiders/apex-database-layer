The `Duplicates.FindDuplicatesResult` class is a mockable wrapper for Datacloud duplicate detection results.

## Overview

This class wraps the native `Datacloud.FindDuplicatesResult` and provides a testable interface for duplicate detection operations.

## Methods

### `getSuccess`

Returns whether the duplicate detection operation was successful.

```apex
global Boolean getSuccess()
```

**Returns:** `true` if the operation completed successfully; `false` if errors occurred

### `getErrors`

Returns any errors that occurred during the duplicate detection operation.

```apex
global List<Duplicates.Error> getErrors()
```

**Returns:** List of error wrappers; empty list if no errors occurred

### `getDuplicateResults`

Returns the duplicate detection results for each input record.

```apex
global List<Duplicates.DuplicateResult> getDuplicateResults()
```

**Returns:** List of duplicate results, one per input record

## Example Usage

```apex
List<Duplicates.FindDuplicatesResult> results = DatabaseLayer.Duplicates.findDuplicates(records);

for (Duplicates.FindDuplicatesResult result : results) {
    if (result.getSuccess()) {
        List<Duplicates.DuplicateResult> duplicates = result.getDuplicateResults();
        // Process duplicate results
    } else {
        List<Duplicates.Error> errors = result.getErrors();
        // Handle errors
    }
}
```

## Testing with Mocks

When testing, use `MockDuplicates.FindDuplicatesResult` to build realistic test data:

```apex
DatabaseLayer.useMocks();

Duplicates.FindDuplicatesResult mockResult = new MockDuplicates.FindDuplicatesResult()
    .asSuccessful()
    .addDuplicateResult(duplicateResult);

MockDuplicates.setGlobalMock().withResult(mockResult);
```

See [MockDuplicates.FindDuplicatesResult](./The-MockDuplicates.FindDuplicatesResult-Class) for mock implementation.
