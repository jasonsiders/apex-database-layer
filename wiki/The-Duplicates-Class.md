The `Duplicates` class handles duplicate detection operations and provides mockable abstraction over Salesforce's DataCloud duplicate detection APIs. It calls the native `Datacloud.FindDuplicates.findDuplicates()` API and wraps results in testable classes.

## Constructing `Duplicates` Objects

`Duplicates` objects cannot be directly constructed via the `new` keyword. Instead, access the class and its methods via the `DatabaseLayer.Duplicates` static property:

```apex
DatabaseLayer.Duplicates.findDuplicates(records);
```

The `DatabaseLayer` class is responsible for instantiating the correct type at runtime. In `@IsTest` context, developers can call `DatabaseLayer.useMocks()`, and an instance of the `MockDuplicates` class will be returned instead:

```apex
DatabaseLayer.useMocks();
Assert.isInstanceOfType(DatabaseLayer.Duplicates, MockDuplicates.class, 'Not a mock');
```

## Methods

### `findDuplicates`

Executes duplicate detection on a list of SObject records.

```apex
global List<Duplicates.FindDuplicatesResult> findDuplicates(List<SObject> records)
```

**Parameters:**
- `records` - The records to check for duplicates

**Returns:** List of `FindDuplicatesResult` objects wrapping duplicate detection results

**Throws:** Exceptions from the DataCloud API propagate to the caller (e.g., if no duplicate rules are active or DataCloud is unavailable)

### `findDuplicates` (Overload)

Executes duplicate detection on a list of record IDs. Internally queries the records by ID before calling the DataCloud API (which requires SObject instances).

```apex
global List<Duplicates.FindDuplicatesResult> findDuplicates(Iterable<Id> recordIds)
```

**Parameters:**
- `recordIds` - The record IDs to check for duplicates

**Returns:** List of `FindDuplicatesResult` objects wrapping duplicate detection results

**Throws:** Exceptions from the DataCloud API propagate to the caller (e.g., if no duplicate rules are active or DataCloud is unavailable)

## Inner Classes

### Request

Handles execution of duplicate detection requests against the native Datacloud APIs.

See [Duplicates.Request](./The-Duplicates.Request-Class)

### FindDuplicatesResult

Mockable wrapper for duplicate detection results.

See [Duplicates.FindDuplicatesResult](./The-Duplicates.FindDuplicatesResult-Class)

### DuplicateResult

Wrapper for duplicate matches for a specific record.

See [Duplicates.DuplicateResult](./The-Duplicates.DuplicateResult-Class)

### MatchResult

Wrapper for matches from a specific duplicate rule.

See [Duplicates.MatchResult](./The-Duplicates.MatchResult-Class)

### MatchRecord

Wrapper for a specific matched record and field differences.

See [Duplicates.MatchRecord](./The-Duplicates.MatchRecord-Class)

### FieldDiff

Wrapper for field differences between matched records.

See [Duplicates.FieldDiff](./The-Duplicates.FieldDiff-Class)

### Error

Wrapper for error information from duplicate detection operations.

See [Duplicates.Error](./The-Duplicates.Error-Class)

## Integration with DatabaseLayer

`Duplicates` is integrated into the `DatabaseLayer` singleton and respects the mocking configuration:

```apex
@IsTest
static void testWithMocks() {
    DatabaseLayer.useMocks();
    // All operations use mocks
    DatabaseLayer.Duplicates.findDuplicates(records);
}

@IsTest
static void testWithRealData() {
    DatabaseLayer.useRealData();
    // All operations use real APIs
    DatabaseLayer.Duplicates.findDuplicates(records);
}
```

## Usage Guides

- [Detecting Duplicates](./Detecting-Duplicates) - Guide on using duplicate detection
- [Mocking Duplicates](./Mocking-Duplicates) - Guide on mocking for tests
