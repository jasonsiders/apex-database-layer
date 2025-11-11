Interface for custom simulator implementations.

Implement this interface to provide custom duplicate detection logic in tests that goes beyond what the [MockDuplicates.BaseSimulator](./The-MockDuplicates.BaseSimulator-Class) provides.

## Methods

### `simulate`

Simulates duplicate detection for a given record.

- `MockDuplicates.FindDuplicatesResult simulate(SObject record)`

**Parameters:**
- `record` - The SObject record to check for duplicates

**Returns:** The `FindDuplicatesResult` containing simulated duplicate detection results.

## Example: Custom Implementation

```apex
public class CustomDuplicateSimulator implements MockDuplicates.Simulator {
    private Map<String, List<SObject>> duplicatesByName;

    public CustomDuplicateSimulator() {
        this.duplicatesByName = new Map<String, List<SObject>>();
    }

    public void addDuplicate(String name, SObject duplicate) {
        if (!this.duplicatesByName.containsKey(name)) {
            this.duplicatesByName.put(name, new List<SObject>());
        }
        this.duplicatesByName.get(name).add(duplicate);
    }

    public MockDuplicates.FindDuplicatesResult simulate(SObject record) {
        SObjectType objectType = record?.getSObjectType();
        MockDuplicates.FindDuplicatesResult result = new MockDuplicates.FindDuplicatesResult(objectType);

        // Check if this record has any duplicates based on Name field
        String recordName = (String) record.get('Name');
        List<SObject> duplicates = this.duplicatesByName.get(recordName);

        if (duplicates != null && !duplicates.isEmpty()) {
            MockDuplicates.DuplicateResult dupResult = result.addRule();
            dupResult.setRuleName('Custom_Name_Match_Rule');
            dupResult.setSaveBehavior(MockDuplicates.SaveBehavior.BLOCK);

            MockDuplicates.MatchResult matchResult = dupResult.addMatch();
            matchResult.setMatchEngine('CustomNameMatcher');

            for (SObject duplicate : duplicates) {
                matchResult.addRecord(duplicate)
                    .setConfidence(100.0)
                    .addFieldDiff('Name', MockDuplicates.DiffType.IS_SAME);
            }
        }

        return result;
    }
}
```

## Using the Custom Simulator

```apex
@IsTest
static void testCustomSimulator() {
    DatabaseLayer.useMocks();

    // Create the custom simulator
    CustomDuplicateSimulator simulator = new CustomDuplicateSimulator();

    // Add duplicate records
    Account duplicate = (Account) new MockRecord(Account.SObjectType)
        .withId()
        .withField(Account.Name, 'Acme Corp')
        .toSObject();
    simulator.addDuplicate('Acme Corp', duplicate);

    // Set it as the active simulator
    MockDuplicates.setMock(simulator);

    Test.startTest();
    // Test with matching name
    Account account1 = new Account(Name = 'Acme Corp');
    Duplicates.FindDuplicatesResult result1 = DatabaseLayer.Duplicates.findDuplicates(account1);
    Assert.areEqual(1, result1.getDuplicateResults()?.size(), 'Should find duplicate');

    // Test with non-matching name
    Account account2 = new Account(Name = 'Different Corp');
    Duplicates.FindDuplicatesResult result2 = DatabaseLayer.Duplicates.findDuplicates(account2);
    Assert.areEqual(0, result2.getDuplicateResults()?.size(), 'Should not find duplicate');
    Test.stopTest();
}
```

## Example: Conditional Logic

```apex
public class ConditionalDuplicateSimulator implements MockDuplicates.Simulator {
    public MockDuplicates.FindDuplicatesResult simulate(SObject record) {
        SObjectType objectType = record?.getSObjectType();
        MockDuplicates.FindDuplicatesResult result = new MockDuplicates.FindDuplicatesResult(objectType);

        // Only find duplicates if record has a specific field value
        if (record.get('Industry') == 'Technology') {
            result.addRule()
                .addMatch()
                    .addRecord()
                        .setConfidence(90.0);
        }

        return result;
    }
}
```

```apex
DatabaseLayer.useMocks();
MockDuplicates.setMock(new ConditionalDuplicateSimulator());

// This will find duplicates
Account techAccount = new Account(Industry = 'Technology');
Duplicates.FindDuplicatesResult result1 = DatabaseLayer.Duplicates.findDuplicates(techAccount);
Assert.areEqual(1, result1.getDuplicateResults()?.size());

// This will not find duplicates
Account retailAccount = new Account(Industry = 'Retail');
Duplicates.FindDuplicatesResult result2 = DatabaseLayer.Duplicates.findDuplicates(retailAccount);
Assert.areEqual(0, result2.getDuplicateResults()?.size());
```
