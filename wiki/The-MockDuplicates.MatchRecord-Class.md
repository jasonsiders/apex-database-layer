Represents a specific matched record in a duplicate detection result for test scenarios.

This class extends [Duplicates.MatchRecord](./The-Duplicates.MatchRecord-Class) and provides a fluent API for configuring match details including the record, confidence score, field differences, and additional information.

## Methods

### `addAdditionalInfo`

Adds additional information metadata to this match record.

- `MockDuplicates.AdditionalInformationMap addAdditionalInfo(String name, String value)`

**Returns:** The created `AdditionalInformationMap` instance for method chaining.

```apex
matchRecord.addAdditionalInfo('MatchEngine', 'FuzzyMatch')
    .addAdditionalInfo('MatchKey', 'ACME_123');
```

### `addFieldDiff`

Adds a field difference to this match record.

- `MockDuplicates.FieldDiff addFieldDiff(String fieldName, MockDuplicates.DiffType difference)`

**Returns:** The created `FieldDiff` instance for method chaining.

**Parameters:**
- `fieldName` - The API name of the field
- `difference` - The type of difference: `IS_DIFFERENT`, `IS_NULL`, or `IS_SAME`

```apex
matchRecord.addFieldDiff('Name', MockDuplicates.DiffType.IS_SAME)
    .up()
    .addFieldDiff('Phone', MockDuplicates.DiffType.IS_DIFFERENT);
```

### `clearAdditionalInfo`

Removes all additional information from this match record.

- `MockDuplicates.MatchRecord clearAdditionalInfo()`

**Returns:** This instance for method chaining.

```apex
matchRecord.clearAdditionalInfo();
```

### `clearFieldDiffs`

Removes all field differences from this match record.

- `MockDuplicates.MatchRecord clearFieldDiffs()`

**Returns:** This instance for method chaining.

```apex
matchRecord.clearFieldDiffs();
```

### `setConfidence`

Sets the match confidence score (0-100).

- `MockDuplicates.MatchRecord setConfidence(Decimal confidence)`

**Returns:** This instance for method chaining.

```apex
matchRecord.setConfidence(95.5);
```

### `toTop`

Navigates back to the top-level `FindDuplicatesResult`.

- `MockDuplicates.FindDuplicatesResult toTop()`

```apex
MockDuplicates.FindDuplicatesResult result = matchRecord.toTop();
```

### `up`

Navigates back to the parent `MatchResult`.

- `MockDuplicates.MatchResult up()`

```apex
MockDuplicates.MatchResult matchResult = matchRecord.up();
```

## Example

```apex
DatabaseLayer.useMocks();

// Create the duplicate record to match against
Account duplicate = (Account) new MockRecord(Account.SObjectType)
    .withId()
    .withField(Account.Name, 'Acme Corporation')
    .withField(Account.Phone, '555-1234')
    .toSObject();

// Configure a detailed match record
MockDuplicates.simulator
    .withResults(Account.SObjectType)
        .addRule()
            .addMatch()
                .addRecord(duplicate)
                    .setConfidence(92.5)
                    .addFieldDiff('Name', MockDuplicates.DiffType.IS_DIFFERENT)
                    .up()
                    .addFieldDiff('Phone', MockDuplicates.DiffType.IS_SAME)
                    .up()
                    .addFieldDiff('Website', MockDuplicates.DiffType.IS_NULL)
                    .up()
                    .addAdditionalInfo('MatchEngine', 'FuzzyMatch')
                    .up()
                    .addAdditionalInfo('MatchScore', '92.5');

// Test with the configured match
Account account = new Account(Name = 'Acme Corp', Phone = '555-1234');
Duplicates.FindDuplicatesResult result = DatabaseLayer.Duplicates.findDuplicates(account);

Duplicates.MatchRecord match = result.getDuplicateResults()?.get(0)
    ?.getMatchResults()?.get(0)
    ?.getMatchRecords()?.get(0);

Assert.areEqual(92.5, match.getMatchConfidence(), 'Wrong confidence');
Assert.areEqual(3, match.getFieldDiffs()?.size(), 'Wrong field diff count');
Assert.areEqual(2, match.getAdditionalInformation()?.size(), 'Wrong info count');
```
