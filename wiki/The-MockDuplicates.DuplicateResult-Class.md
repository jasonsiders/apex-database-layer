Represents a duplicate rule result with match results and save behavior in test scenarios.

This class extends [Duplicates.DuplicateResult](./The-Duplicates.DuplicateResult-Class) and provides a fluent API for building duplicate detection results for a specific rule.

## Methods

### `addMatch`

Adds a match result for a specific record. Returns the created `MatchResult` instance for method chaining.

- `MockDuplicates.MatchResult addMatch()`

```apex
MockDuplicates.MatchResult match = dupResult.addMatch();
```

### `clearMatches`

Removes all match results from this duplicate rule result. Returns this instance for method chaining.

- `MockDuplicates.DuplicateResult clearMatches()`

```apex
dupResult.clearMatches();
```

### `setErrorMessage`

Sets the error message for this duplicate rule result. Returns this instance for method chaining.

- `MockDuplicates.DuplicateResult setErrorMessage(String errorMessage)`

```apex
dupResult.setErrorMessage('Custom duplicate alert message');
```

### `setRuleName`

Sets the duplicate rule name. Returns this instance for method chaining.

- `MockDuplicates.DuplicateResult setRuleName(String ruleName)`

```apex
dupResult.setRuleName('Account_Duplicate_Rule');
```

### `setSaveBehavior`

Sets whether records can be saved despite duplicates. The `behavior` parameter can be either `MockDuplicates.SaveBehavior.ALLOW` or `MockDuplicates.SaveBehavior.BLOCK`. Returns this instance for method chaining.

- `MockDuplicates.DuplicateResult setSaveBehavior(MockDuplicates.SaveBehavior behavior)`

```apex
dupResult.setSaveBehavior(MockDuplicates.SaveBehavior.BLOCK);
```

### `toTop`

Navigates back to the top-level `FindDuplicatesResult`.

- `MockDuplicates.FindDuplicatesResult toTop()`

```apex
MockDuplicates.FindDuplicatesResult result = dupResult.toTop();
```

### `up`

Navigates back to the parent `FindDuplicatesResult`.

- `MockDuplicates.FindDuplicatesResult up()`

```apex
MockDuplicates.FindDuplicatesResult result = dupResult.up();
```
