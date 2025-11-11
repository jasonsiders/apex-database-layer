Represents a field-level difference between records in test scenarios.

This class extends [Duplicates.FieldDiff](./The-Duplicates.FieldDiff-Class) and provides a fluent API for specifying how fields differ in duplicate matches.

## Methods

### `setDifference`

Sets the type of difference for this field.

- `MockDuplicates.FieldDiff setDifference(MockDuplicates.DiffType difference)`

**Returns:** This instance for method chaining.

**Parameters:**
- `difference` - The difference type: `IS_DIFFERENT`, `IS_NULL`, or `IS_SAME`

```apex
MockDuplicates.FieldDiff diff = matchRecord
    .addFieldDiff('Name', MockDuplicates.DiffType.IS_SAME)
    .setDifference(MockDuplicates.DiffType.IS_DIFFERENT); // Change it
```

### `setName`

Sets the API name of the field.

- `MockDuplicates.FieldDiff setName(String name)`

**Returns:** This instance for method chaining.

```apex
diff.setName('Phone');
```

### `toTop`

Navigates back to the top-level `FindDuplicatesResult`.

- `MockDuplicates.FindDuplicatesResult toTop()`

```apex
MockDuplicates.FindDuplicatesResult result = diff.toTop();
```

### `up`

Navigates back to the parent `MatchRecord`.

- `MockDuplicates.MatchRecord up()`

```apex
MockDuplicates.MatchRecord matchRecord = diff.up();
```

## Example

```apex
DatabaseLayer.useMocks();

Account duplicate = (Account) new MockRecord(Account.SObjectType)
    .withId()
    .withField(Account.Name, 'Acme Corp')
    .withField(Account.Phone, '555-1234')
    .toSObject();

MockDuplicates.simulator
    .withResults(Account.SObjectType)
        .addRule()
            .addMatch()
                .addRecord(duplicate)
                    .addFieldDiff('Name', MockDuplicates.DiffType.IS_SAME)
                    .addFieldDiff('Phone', MockDuplicates.DiffType.IS_DIFFERENT)
                    .addFieldDiff('Website', MockDuplicates.DiffType.IS_NULL)
                        .up() // Navigate back to MatchRecord
                    .setConfidence(87.5);

Account account = new Account(Name = 'Acme Corp', Phone = '555-9999');
Duplicates.FindDuplicatesResult result = DatabaseLayer.Duplicates.findDuplicates(account);

Duplicates.MatchRecord match = result.getDuplicateResults()?.get(0)
    ?.getMatchResults()?.get(0)
    ?.getMatchRecords()?.get(0);

Assert.areEqual(3, match.getFieldDiffs()?.size(), 'Expected 3 field diffs');
```
