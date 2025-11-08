The `Duplicates.DuplicateResult` class is a mockable wrapper containing duplicate matches for a specific record.

## Overview

This class represents the duplicate detection results for a single input record, including the original record and all matching records found.

## Methods

### `getRecord`

Returns the original record that was checked for duplicates.

```apex
global SObject getRecord()
```

**Returns:** The SObject record that was checked

### `getMatchResults`

Returns the match results grouped by duplicate detection rule.

```apex
global List<Duplicates.MatchResult> getMatchResults()
```

**Returns:** List of match results by rule; empty if no matches found

## Example Usage

```apex
Duplicates.DuplicateResult dupResult = findDuplicatesResult.getDuplicateResults()[0];

SObject originalRecord = dupResult.getRecord();
System.debug('Checking duplicates for: ' + originalRecord.Id);

for (Duplicates.MatchResult match : dupResult.getMatchResults()) {
    System.debug('Rule: ' + match.getRule());
    System.debug('Matches: ' + match.getSize());
}
```

## Testing with Mocks

When testing, use `MockDuplicates.DuplicateResult` to build test data:

```apex
Duplicates.DuplicateResult duplicateResult = new MockDuplicates.DuplicateResult()
    .withRecord(originalAccount)
    .addMatchResult(matchResult);
```

See [MockDuplicates.DuplicateResult](./The-MockDuplicates.DuplicateResult-Class) for mock implementation.
