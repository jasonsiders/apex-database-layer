The `Duplicates.MatchRecord` class is a mockable wrapper for a single matched record and its field differences.

## Overview

This class represents a specific record that matched in duplicate detection, along with the field values that differ from the original record.

## Methods

### `getRecord`

Returns the matched duplicate record.

```apex
global SObject getRecord()
```

**Returns:** The matched SObject record

### `getFieldDiffs`

Returns the field differences between the original and this matched record.

```apex
global List<Duplicates.FieldDiff> getFieldDiffs()
```

**Returns:** List of field differences; empty if all fields match

## Example Usage

```apex
for (Duplicates.MatchRecord matchRecord : matchResult.getMatchRecords()) {
    SObject matchedRecord = matchRecord.getRecord();

    System.debug('Found duplicate: ' + matchedRecord.Id);

    for (Duplicates.FieldDiff diff : matchRecord.getFieldDiffs()) {
        String fieldName = diff.getFieldName();
        Object diffValue = diff.getCompareValue();

        System.debug('Field ' + fieldName + ' differs: ' + diffValue);
    }
}
```

## Testing with Mocks

When testing, use `MockDuplicates.MatchRecord` to build test data:

```apex
Duplicates.MatchRecord matchRecord = new MockDuplicates.MatchRecord()
    .withRecord(duplicateAccount)
    .addFieldDiff(fieldDiff);
```

See [MockDuplicates.MatchRecord](./The-MockDuplicates.MatchRecord-Class) for mock implementation.
