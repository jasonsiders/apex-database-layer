Represents the results from a specific matching rule in test scenarios.

This class extends [Duplicates.MatchResult](./The-Duplicates.MatchResult-Class) and provides a fluent API for configuring matched records and errors.

## Methods

### `addError`

Adds an error to this match result.

**Overloads:**

- `MockDuplicates.MatchResult addError(Exception error)`
- `MockDuplicates.MatchResult addError()`

**Returns:** This instance for method chaining.

```apex
// Add specific exception
matchResult.addError(new System.DmlException('Match failed'));

// Add generic HandledException
matchResult.addError();
```

### `addRecord`

Adds a matched record to this match result.

**Overloads:**

- `MockDuplicates.MatchRecord addRecord(SObject record)`
- `MockDuplicates.MatchRecord addRecord()`

**Returns:** The created `MatchRecord` instance for method chaining.

```apex
// Add specific record
Account duplicate = (Account) new MockRecord(Account.SObjectType)
    .withId()
    .toSObject();
matchResult.addRecord(duplicate);

// Add auto-generated mock record
matchResult.addRecord();
```

### `clearErrors`

Removes all errors from this match result.

- `MockDuplicates.MatchResult clearErrors()`

**Returns:** This instance for method chaining.

```apex
matchResult.clearErrors();
```

### `clearRecords`

Removes all matched records from this match result.

- `MockDuplicates.MatchResult clearRecords()`

**Returns:** This instance for method chaining.

```apex
matchResult.clearRecords();
```

### `setMatchEngine`

Sets the matching engine name.

- `MockDuplicates.MatchResult setMatchEngine(String matchEngine)`

**Returns:** This instance for method chaining.

```apex
matchResult.setMatchEngine('CustomMatchEngine');
```

### `setRuleName`

Sets the matching rule name.

- `MockDuplicates.MatchResult setRuleName(String ruleName)`

**Returns:** This instance for method chaining.

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

## Example

```apex
DatabaseLayer.useMocks();

// Create duplicate records
Account dup1 = (Account) new MockRecord(Account.SObjectType)
    .withId()
    .withField(Account.Name, 'Acme Corp')
    .toSObject();

Account dup2 = (Account) new MockRecord(Account.SObjectType)
    .withId()
    .withField(Account.Name, 'ACME Corporation')
    .toSObject();

// Configure match result with multiple records
MockDuplicates.simulator
    .withResults(Account.SObjectType)
        .addRule()
            .addMatch()
                .setRuleName('Account_Standard_Match_Rule_v1_0')
                .setMatchEngine('ExactMatch')
                .addRecord(dup1)
                    .setConfidence(100.0)
                    .addFieldDiff('Name', MockDuplicates.DiffType.IS_SAME)
                    .up()
                .addRecord(dup2)
                    .setConfidence(85.0)
                    .addFieldDiff('Name', MockDuplicates.DiffType.IS_DIFFERENT);

// Test with the configured matches
Account account = new Account(Name = 'Acme Corp');
Duplicates.FindDuplicatesResult result = DatabaseLayer.Duplicates.findDuplicates(account);

Duplicates.MatchResult matchResult = result.getDuplicateResults()?.get(0)
    ?.getMatchResults()?.get(0);

Assert.areEqual('ExactMatch', matchResult.getMatchEngine(), 'Wrong engine');
Assert.areEqual(2, matchResult.getSize(), 'Expected 2 matches');
```

## Using Auto-Generated Records

The `addRecord()` overload without parameters automatically generates a mock record:

```apex
MockDuplicates.simulator
    .withResults(Account.SObjectType)
        .addRule()
            .addMatch()
                .addRecord() // Auto-generated Account with ID
                    .setConfidence(90.0)
                    .toTop()
            .addMatch()
                .addRecord() // Another auto-generated Account
                    .setConfidence(75.0);
```
