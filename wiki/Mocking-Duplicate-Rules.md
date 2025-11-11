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
MockDuplicates.simulator.withResults(Account.SObjectType).addRule().addMatch().addRecord();
Account account = new Account(Name = 'Acme Corp');
Duplicates.FindDuplicatesResult result = DatabaseLayer.Duplicates.findDuplicates(account);
```

## Simulating Failed Duplicate Detection

If you want duplicate detection to fail with an error, add errors to the result:

```apex
DatabaseLayer.useMocks();
MockDuplicates.simulator.withResults(Account.SObjectType).addError();
Account account = new Account();
Duplicates.FindDuplicatesResult result = DatabaseLayer.Duplicates.findDuplicates(account);
```
