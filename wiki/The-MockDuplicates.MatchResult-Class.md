Represents the results from a specific matching rule in test scenarios.

This class extends [Duplicates.MatchResult](./The-Duplicates.MatchResult-Class) and provides a fluent API for configuring matched records and errors.

## Methods

### `addError`

Adds an error to this match result. Returns this instance for method chaining.

- `MockDuplicates.MatchResult addError(Exception error)`
- `MockDuplicates.MatchResult addError()`

```apex
matchResult.addError(new System.DmlException('Match failed'));
```

### `addRecord`

Adds a matched record to this match result. Returns the created `MatchRecord` instance for method chaining.

- `MockDuplicates.MatchRecord addRecord(SObject record)`
- `MockDuplicates.MatchRecord addRecord()`

```apex
MockDuplicates.MatchRecord matchRecord = matchResult.addRecord();
```

### `clearErrors`

Removes all errors from this match result. Returns this instance for method chaining.

- `MockDuplicates.MatchResult clearErrors()`

```apex
matchResult.clearErrors();
```

### `clearRecords`

Removes all matched records from this match result. Returns this instance for method chaining.

- `MockDuplicates.MatchResult clearRecords()`

```apex
matchResult.clearRecords();
```

### `setMatchEngine`

Sets the matching engine name. Returns this instance for method chaining.

- `MockDuplicates.MatchResult setMatchEngine(String matchEngine)`

```apex
matchResult.setMatchEngine('CustomMatchEngine');
```

### `setRuleName`

Sets the matching rule name. Returns this instance for method chaining.

- `MockDuplicates.MatchResult setRuleName(String ruleName)`

```apex
matchResult.setRuleName('Account_Fuzzy_Match_Rule_v2_0');
```

### `toTop`

Navigates back to the top-level `FindDuplicatesResult`.

- `MockDuplicates.FindDuplicatesResult toTop()`

```apex
MockDuplicates.FindDuplicatesResult result = matchResult.toTop();
```

### `up`

Navigates back to the parent `DuplicateResult`.

- `MockDuplicates.DuplicateResult up()`

```apex
MockDuplicates.DuplicateResult dupResult = matchResult.up();
```
