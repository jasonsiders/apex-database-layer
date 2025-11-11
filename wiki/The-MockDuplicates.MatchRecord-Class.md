Represents a specific matched record in a duplicate detection result for test scenarios.

This class extends [Duplicates.MatchRecord](./The-Duplicates.MatchRecord-Class) and provides a fluent API for configuring match details including the record, confidence score, field differences, and additional information.

## Methods

### `addAdditionalInfo`

Adds additional information metadata to this match record. Returns the created `AdditionalInformationMap` instance for method chaining.

- `MockDuplicates.AdditionalInformationMap addAdditionalInfo(String name, String value)`

```apex
matchRecord.addAdditionalInfo('MatchEngine', 'FuzzyMatch');
```

### `addFieldDiff`

Adds a field difference to this match record. The `fieldName` parameter specifies the API name of the field, and `difference` specifies the type of difference: `IS_DIFFERENT`, `IS_NULL`, or `IS_SAME`. Returns the created `FieldDiff` instance for method chaining.

- `MockDuplicates.FieldDiff addFieldDiff(String fieldName, MockDuplicates.DiffType difference)`

```apex
matchRecord.addFieldDiff('Name', MockDuplicates.DiffType.IS_SAME);
```

### `clearAdditionalInfo`

Removes all additional information from this match record. Returns this instance for method chaining.

- `MockDuplicates.MatchRecord clearAdditionalInfo()`

```apex
matchRecord.clearAdditionalInfo();
```

### `clearFieldDiffs`

Removes all field differences from this match record. Returns this instance for method chaining.

- `MockDuplicates.MatchRecord clearFieldDiffs()`

```apex
matchRecord.clearFieldDiffs();
```

### `setConfidence`

Sets the match confidence score (0-100). Returns this instance for method chaining.

- `MockDuplicates.MatchRecord setConfidence(Decimal confidence)`

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
