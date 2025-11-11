Represents a duplicate rule result with match results and save behavior in test scenarios.

This class extends [Duplicates.DuplicateResult](./The-Duplicates.DuplicateResult-Class) and provides a fluent API for building duplicate detection results for a specific rule.

## Methods

### `addMatch`

Adds a match result for a specific record.

- `MockDuplicates.MatchResult addMatch()`

**Returns:** The created `MatchResult` instance for method chaining.

```apex
MockDuplicates.DuplicateResult dupResult = MockDuplicates.simulator
    .withResults(Account.SObjectType)
        .addRule()
            .addMatch() // First match
            .up()
            .addMatch(); // Second match
```

### `clearMatches`

Removes all match results from this duplicate rule result.

- `MockDuplicates.DuplicateResult clearMatches()`

**Returns:** This instance for method chaining.

```apex
dupResult.clearMatches();
```

### `setErrorMessage`

Sets the error message for this duplicate rule result.

- `MockDuplicates.DuplicateResult setErrorMessage(String errorMessage)`

**Returns:** This instance for method chaining.

```apex
dupResult.setErrorMessage('Custom duplicate alert message');
```

### `setRuleName`

Sets the duplicate rule name.

- `MockDuplicates.DuplicateResult setRuleName(String ruleName)`

**Returns:** This instance for method chaining.

```apex
dupResult.setRuleName('Account_Duplicate_Rule');
```

### `setSaveBehavior`

Sets whether records can be saved despite duplicates.

- `MockDuplicates.DuplicateResult setSaveBehavior(MockDuplicates.SaveBehavior behavior)`

**Returns:** This instance for method chaining.

**Parameters:**
- `behavior` - Either `MockDuplicates.SaveBehavior.ALLOW` or `MockDuplicates.SaveBehavior.BLOCK`

```apex
// Block saving when duplicates are found
dupResult.setSaveBehavior(MockDuplicates.SaveBehavior.BLOCK);

// Allow saving when duplicates are found
dupResult.setSaveBehavior(MockDuplicates.SaveBehavior.ALLOW);
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

## Example

```apex
DatabaseLayer.useMocks();

MockDuplicates.simulator
    .withResults(Account.SObjectType)
        .addRule()
            .setRuleName('Standard_Account_Duplicate_Rule')
            .setErrorMessage('This account may be a duplicate')
            .setSaveBehavior(MockDuplicates.SaveBehavior.BLOCK)
            .addMatch()
                .addRecord()
                    .toTop()
        .addRule(Contact.SObjectType) // Can add multiple rules
            .setRuleName('Standard_Contact_Duplicate_Rule')
            .setSaveBehavior(MockDuplicates.SaveBehavior.ALLOW);
```
