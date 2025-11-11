Represents the top-level result of a duplicate detection operation in test scenarios.

This class extends [Duplicates.FindDuplicatesResult](./The-Duplicates.FindDuplicatesResult-Class) and provides a fluent API for building complete duplicate detection results.

## Constructor

### `FindDuplicatesResult`

Creates a new `FindDuplicatesResult` for a specific SObjectType.

- `global FindDuplicatesResult(SObjectType objectType)`

```apex
MockDuplicates.FindDuplicatesResult result = new MockDuplicates.FindDuplicatesResult(Account.SObjectType);
```

## Methods

### `addRule`

Adds a duplicate rule result for a specific object type.

**Overloads:**

- `MockDuplicates.DuplicateResult addRule(SObjectType objectType)`
- `MockDuplicates.DuplicateResult addRule()`

**Returns:** The created `DuplicateResult` instance for method chaining.

```apex
// Add rule for specific object type
result.addRule(Account.SObjectType);

// Add rule for the default object type
result.addRule();
```

### `addError`

Adds an error to the result.

**Overloads:**

- `MockDuplicates.FindDuplicatesResult addError(Exception error)`
- `MockDuplicates.FindDuplicatesResult addError()`

**Returns:** This instance for method chaining.

```apex
// Add specific exception
result.addError(new System.DmlException('Duplicate detection failed'));

// Add generic HandledException
result.addError();
```

### `clearErrors`

Removes all errors from the result.

- `MockDuplicates.FindDuplicatesResult clearErrors()`

**Returns:** This instance for method chaining.

```apex
result.clearErrors();
```

### `clearDuplicateResults`

Removes all duplicate rule results.

- `MockDuplicates.FindDuplicatesResult clearDuplicateResults()`

**Returns:** This instance for method chaining.

```apex
result.clearDuplicateResults();
```

## Example

```apex
DatabaseLayer.useMocks();

// Build a complete duplicate detection result
MockDuplicates.FindDuplicatesResult result = MockDuplicates.simulator
    .withResults(Account.SObjectType)
        .addRule()
            .setRuleName('Account_Standard_Duplicate_Rule')
            .setSaveBehavior(MockDuplicates.SaveBehavior.BLOCK)
            .addMatch()
                .addRecord()
                    .setConfidence(95.0)
                    .addFieldDiff('Name', MockDuplicates.DiffType.IS_SAME)
                    .toTop();

// Test the configured result
Account account = new Account(Name = 'Acme Corp');
Duplicates.FindDuplicatesResult testResult = DatabaseLayer.Duplicates.findDuplicates(account);

Assert.isTrue(testResult.isSuccess(), 'Should succeed');
Assert.areEqual(1, testResult.getDuplicateResults()?.size(), 'Should have one rule result');
```

## Fluent API Chain

The class supports fluent method chaining:

```apex
MockDuplicates.simulator
    .withResults(Account.SObjectType)
        .clearDuplicateResults() // Start fresh
        .clearErrors()
        .addRule()
            .setRuleName('Rule_1')
            .addMatch()
                .addRecord()
                    .toTop()
        .addRule()
            .setRuleName('Rule_2')
            .addMatch()
                .addRecord();
```
