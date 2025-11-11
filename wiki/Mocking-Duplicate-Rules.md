Using `DatabaseLayer.Duplicates`, you can easily engage mocks to test your code without directly interacting with Salesforce duplicate rules.

You can cover most test cases by adding just a few lines of code to your tests:

## Setting Up Mocks

First, ensure all duplicate detection operations in the code path to be tested use `DatabaseLayer.Duplicates` methods. Standard `Datacloud.FindDuplicates` operations **_cannot_** be mocked.

In `@IsTest` context, call [`DatabaseLayer.useMocks()`](./The-DatabaseLayer-Class#useMocks) or [`DatabaseLayer.useMockDuplicates()`](./The-DatabaseLayer-Class#useMockDuplicates). Now, any [Duplicates](./The-Duplicates-Class) operations will be processed by the [MockDuplicates](./The-MockDuplicates-Class) instead.

By default, `MockDuplicates` will return an empty result (no duplicates found). You can configure specific duplicate detection results using the [`MockDuplicates.BaseSimulator`](./The-MockDuplicates.BaseSimulator-Class) via the [`MockDuplicates.simulator`](./The-MockDuplicates-Class#simulator) property.

Finally, call the code you want to test. As it runs, the framework will run `MockDuplicates` logic instead of actually calling Salesforce duplicate detection APIs.

## Simulating No Duplicates Found

By default, `MockDuplicates` operations will simulate a successful duplicate detection operation with no duplicates found:

```apex
DatabaseLayer.useMocks();
Account account = new Account(Name = 'Acme Corp');
// By default, duplicate detection using mocks will succeed with no duplicates:
Duplicates.FindDuplicatesResult result = DatabaseLayer.Duplicates.findDuplicates(account);
Assert.isTrue(result?.isSuccess(), 'Detection failed');
Assert.areEqual(0, result?.getDuplicateResults()?.size(), 'Found unexpected duplicates');
```

## Simulating Duplicate Matches

To configure specific duplicate detection results, use the [MockDuplicates.BaseSimulator](./The-MockDuplicates.BaseSimulator-Class):

```apex
DatabaseLayer.useMocks();
// Configure the simulator to return duplicates for Account records:
Account existingAccount = (Account) new MockRecord(Account.SObjectType)
    .withId()
    .withField(Account.Name, 'Acme Corp')
    .toSObject();

MockDuplicates.simulator
    .withResults(Account.SObjectType)
        .addRule()
            .setRuleName('Account_Duplicate_Rule')
            .setSaveBehavior(MockDuplicates.SaveBehavior.ALLOW)
            .addMatch()
                .addRecord(existingAccount)
                    .setConfidence(95.0)
                    .addFieldDiff('Name', MockDuplicates.DiffType.IS_SAME);

// Now duplicate detection will find the configured match:
Account newAccount = new Account(Name = 'Acme Corp');
Duplicates.FindDuplicatesResult result = DatabaseLayer.Duplicates.findDuplicates(newAccount);
Assert.isTrue(result?.isSuccess(), 'Detection failed');
Assert.areEqual(1, result?.getDuplicateResults()?.size(), 'Expected duplicates');
```

## Simulating Failed Duplicate Detection

If you want duplicate detection to fail with an error, add errors to the result:

```apex
DatabaseLayer.useMocks();
MockDuplicates.simulator
    .withResults(Account.SObjectType)
        .addError(new System.HandledException('Duplicate rule error'));

// Now duplicate detection will fail:
Account account = new Account();
Duplicates.FindDuplicatesResult result = DatabaseLayer.Duplicates.findDuplicates(account);
Assert.isFalse(result?.isSuccess(), 'Detection should have failed');
Assert.areEqual(1, result?.getErrors()?.size(), 'Expected error');
```

## Simulating Complex Match Scenarios

The fluent API allows you to build complex duplicate detection scenarios:

```apex
DatabaseLayer.useMocks();
// Create mock matched records:
Account match1 = (Account) new MockRecord(Account.SObjectType)
    .withId()
    .withField(Account.Name, 'Acme Corporation')
    .toSObject();

Account match2 = (Account) new MockRecord(Account.SObjectType)
    .withId()
    .withField(Account.Name, 'ACME Corp')
    .toSObject();

// Configure multiple matches with field differences:
MockDuplicates.simulator
    .withResults(Account.SObjectType)
        .addRule()
            .setRuleName('Account_Fuzzy_Match_Rule')
            .setSaveBehavior(MockDuplicates.SaveBehavior.BLOCK)
            .addMatch()
                .addRecord(match1)
                    .setConfidence(92.5)
                    .addFieldDiff('Name', MockDuplicates.DiffType.IS_DIFFERENT)
                    .addFieldDiff('Phone', MockDuplicates.DiffType.IS_NULL)
                    .addAdditionalInfo('MatchEngine', 'FuzzyMatch')
                    .toTop()
            .addMatch()
                .addRecord(match2)
                    .setConfidence(85.0)
                    .addFieldDiff('Name', MockDuplicates.DiffType.IS_DIFFERENT);

// Test with the configured matches:
Account newAccount = new Account(Name = 'Acme Corp');
Duplicates.FindDuplicatesResult result = DatabaseLayer.Duplicates.findDuplicates(newAccount);
Duplicates.DuplicateResult duplicateResult = result?.getDuplicateResults()?.get(0);
Assert.isFalse(duplicateResult?.isAllowSave(), 'Save should be blocked');
Assert.areEqual(1, duplicateResult?.getMatchResults()?.size(), 'Expected match results');
Assert.areEqual(2, duplicateResult?.getMatchResults()?.get(0)?.getSize(), 'Expected 2 matches');
```

## Custom Simulator Logic

For advanced scenarios, implement the [MockDuplicates.Simulator](./The-MockDuplicates.Simulator-Interface) interface:

```apex
public class CustomDuplicateSimulator implements MockDuplicates.Simulator {
    public MockDuplicates.FindDuplicatesResult simulate(SObject record) {
        // Custom logic to determine duplicate detection results
        SObjectType objectType = record?.getSObjectType();
        MockDuplicates.FindDuplicatesResult result = new MockDuplicates.FindDuplicatesResult(objectType);

        // Add custom logic here...
        if (record.get('Name') == 'Test') {
            result.addRule()
                .addMatch()
                    .addRecord();
        }

        return result;
    }
}
```

Then use your custom simulator:

```apex
DatabaseLayer.useMocks();
MockDuplicates.setMock(new CustomDuplicateSimulator());
// Now your custom logic will be used for all duplicate detection
```
