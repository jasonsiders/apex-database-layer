This class extends the `Duplicates` class, and simulates duplicate detection operations in `@IsTest` context when the framework is configured to use mocks.

The framework automatically uses a `MockDuplicates` instance for duplicate detection operations whenever `DatabaseLayer.Duplicates` is called after `DatabaseLayer.useMocks()` or `DatabaseLayer.useMockDuplicates()` is called.

Unlike `Duplicates`, `MockDuplicates` does not interact with actual Salesforce duplicate rules. It simulates duplicate detection results by default with no duplicates found, though it's possible to configure specific duplicate matches, errors, and field differences.

Here is an example apex test that uses `MockDuplicates`:

```apex
@IsTest
static void someTest() {
    DatabaseLayer.useMocks();
    Account account = (Account) new MockRecord(Account.SObjectType)
        .withField(Account.Name, 'Acme Corp')
        .toSObject();

    // Configure duplicate matches
    MockDuplicates.simulator
        .withResults(Account.SObjectType)
            .addRule()
                .addMatch()
                    .addRecord(account);

    Test.startTest();
    Duplicates.FindDuplicatesResult result = DatabaseLayer.Duplicates.findDuplicates(account);
    Test.stopTest();

    // The duplicate detection didn't actually run, but it appears to have!
    Assert.isTrue(result?.isSuccess(), 'Detection failed');
    Assert.areEqual(1, result.getDuplicateResults()?.size(), 'Expected duplicates');
}
```

---

## Properties

| Property Name | Data Type | Details |
|--------------|-----------|---------|
| simulator | [MockDuplicates.Simulator](./The-MockDuplicates.Simulator-Interface) | The current simulator instance controlling duplicate detection behavior. Access this property to configure or verify which simulator is configured in tests. |

## Methods

All `MockDuplicates` methods inherit from its parent `Duplicates` class, documented [here](./The-Duplicates-Class#Methods). However, these methods do **not** interact with actual duplicate rules.

### `setMock`

Sets a custom simulator to control duplicate detection behavior in tests.

**Overloads:**

- `static MockDuplicates.Simulator setMock(MockDuplicates.Simulator simulator)`
- `static MockDuplicates.BaseSimulator setMock()`

**Examples:**

```apex
DatabaseLayer.useMocks();
// Initialize with the default BaseSimulator
MockDuplicates.BaseSimulator simulator = MockDuplicates.setMock();

// Configure duplicate results
simulator.withResults(Account.SObjectType)
    .addRule()
        .addMatch()
            .addRecord();
```

```apex
DatabaseLayer.useMocks();
// Use a custom simulator implementation
CustomDuplicateSimulator customSim = new CustomDuplicateSimulator();
MockDuplicates.setMock(customSim);
```

## Using the BaseSimulator

The default `MockDuplicates.BaseSimulator` provides a fluent API for configuring duplicate detection results:

```apex
DatabaseLayer.useMocks();

// Create mock matched records
Account duplicate1 = (Account) new MockRecord(Account.SObjectType)
    .withId()
    .withField(Account.Name, 'Acme Corp')
    .toSObject();

// Configure the simulator
MockDuplicates.simulator
    .withResults(Account.SObjectType)
        .addRule(Account.SObjectType)
            .setRuleName('Account_Duplicate_Rule')
            .setSaveBehavior(MockDuplicates.SaveBehavior.BLOCK)
            .setErrorMessage('Duplicate found')
            .addMatch()
                .setRuleName('Account_Standard_Match_Rule_v1_0')
                .setMatchEngine('FuzzyMatch')
                .addRecord(duplicate1)
                    .setConfidence(95.0)
                    .addFieldDiff('Name', MockDuplicates.DiffType.IS_SAME)
                    .addAdditionalInfo('MatchKey', 'ACME_CORP');

// Now test code that uses duplicate detection
Account newAccount = new Account(Name = 'Acme Corp');
Duplicates.FindDuplicatesResult result = DatabaseLayer.Duplicates.findDuplicates(newAccount);
```

## Simulating Errors

You can configure the simulator to throw exceptions or return errors:

```apex
DatabaseLayer.useMocks();

// Option 1: Configure simulator to throw exception
MockDuplicates.simulator.withException(new System.HandledException('API Error'));

// Option 2: Add errors to the result
MockDuplicates.simulator
    .withResults(Account.SObjectType)
        .addError(new System.DmlException('Duplicate detection failed'));
```

## Custom Simulator Implementation

For advanced scenarios, implement the `MockDuplicates.Simulator` interface:

```apex
public class MyCustomSimulator implements MockDuplicates.Simulator {
    public MockDuplicates.FindDuplicatesResult simulate(SObject record) {
        SObjectType objectType = record?.getSObjectType();
        MockDuplicates.FindDuplicatesResult result = new MockDuplicates.FindDuplicatesResult(objectType);

        // Add custom logic here
        if (record.get('Name')?.contains('Acme')) {
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
MockDuplicates.setMock(new MyCustomSimulator());
```
