The `Duplicates.MatchResult` class is a mockable wrapper for matches from a specific duplicate detection rule.

## Overview

This class represents the duplicate matches found by a particular duplicate detection rule for a single record.

## Methods

### `getRule`

Returns the name of the duplicate detection rule that produced these matches.

```apex
global String getRule()
```

**Returns:** Rule name string

### `getSize`

Returns the total number of matching records found by this rule.

```apex
global Integer getSize()
```

**Returns:** Count of matched records

### `getMatchRecords`

Returns the individual matched records.

```apex
global List<Duplicates.MatchRecord> getMatchRecords()
```

**Returns:** List of matched records; empty if no matches

## Example Usage

```apex
for (Duplicates.MatchResult match : duplicateResult.getMatchResults()) {
    String ruleName = match.getRule();
    Integer matchCount = match.getSize();

    System.debug('Rule: ' + ruleName + ' found ' + matchCount + ' matches');

    for (Duplicates.MatchRecord matchRecord : match.getMatchRecords()) {
        SObject matched = matchRecord.getRecord();
        System.debug('Matched record: ' + matched.Id);
    }
}
```

## Testing with Mocks

When testing, use `MockDuplicates.MatchResult` to build test data:

```apex
Duplicates.MatchResult matchResult = new MockDuplicates.MatchResult()
    .withRule('Account Duplicate Rule')
    .withSize(1)
    .addMatchRecord(matchRecord);
```

See [MockDuplicates.MatchResult](./The-MockDuplicates.MatchResult-Class) for mock implementation.
