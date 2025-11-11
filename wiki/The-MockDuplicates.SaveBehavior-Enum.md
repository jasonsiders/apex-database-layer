Represents the `DuplicateResult`'s `allowSave` Boolean in an explicit way.

This enum provides a more readable way to specify whether records can be saved when duplicates are detected.

## Values

- `ALLOW` - Records can be saved despite duplicates being found (corresponds to `allowSave = true`)
- `BLOCK` - Records cannot be saved when duplicates are found (corresponds to `allowSave = false`)

## Example

```apex
DatabaseLayer.useMocks();

// Block saving when duplicates are found
MockDuplicates.simulator
    .withResults(Account.SObjectType)
        .addRule()
            .setSaveBehavior(MockDuplicates.SaveBehavior.BLOCK)
            .addMatch()
                .addRecord();

Account account = new Account(Name = 'Acme Corp');
Duplicates.FindDuplicatesResult result = DatabaseLayer.Duplicates.findDuplicates(account);
Duplicates.DuplicateResult dupResult = result.getDuplicateResults()?.get(0);

Assert.isFalse(dupResult.isAllowSave(), 'Save should be blocked');
```

```apex
DatabaseLayer.useMocks();

// Allow saving when duplicates are found (alert only)
MockDuplicates.simulator
    .withResults(Account.SObjectType)
        .addRule()
            .setSaveBehavior(MockDuplicates.SaveBehavior.ALLOW)
            .addMatch()
                .addRecord();

Account account = new Account(Name = 'Acme Corp');
Duplicates.FindDuplicatesResult result = DatabaseLayer.Duplicates.findDuplicates(account);
Duplicates.DuplicateResult dupResult = result.getDuplicateResults()?.get(0);

Assert.isTrue(dupResult.isAllowSave(), 'Save should be allowed');
```

## Usage in Tests

This enum makes test intentions clearer:

```apex
// Less clear
dupResult.allowSave = true;

// More clear
dupResult.setSaveBehavior(MockDuplicates.SaveBehavior.ALLOW);
```
