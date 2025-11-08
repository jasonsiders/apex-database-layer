Testing duplicate detection logic requires mocking without actual duplicate rules configured in your org. The `MockDuplicates` class provides a complete mocking framework for this purpose.

## Enabling Mock Mode

In test methods, call `DatabaseLayer.useMocks()` to switch the Duplicates provider to use mock implementations:

```apex
@IsTest
static void testDuplicateDetection() {
    DatabaseLayer.useMocks();
    // All DatabaseLayer.Duplicates calls now use mocks
}
```

## Building Mock Results

`MockDuplicates` provides fluent builder classes to construct realistic duplicate detection results:

### Simple Success Result

```apex
Duplicates.FindDuplicatesResult mockResult = new MockDuplicates.FindDuplicatesResult()
    .asSuccessful();

MockDuplicates.setGlobalMock().withResult(mockResult);

List<Duplicates.FindDuplicatesResult> results = DatabaseLayer.Duplicates.findDuplicates(records);
Assert.isTrue(results[0].getSuccess());
```

### Result with Duplicate Matches

```apex
Account originalAccount = (Account) new MockRecord(Account.SObjectType)
    .withId()
    .toSObject();

Account duplicateAccount = (Account) new MockRecord(Account.SObjectType)
    .withId()
    .toSObject();

Duplicates.FieldDiff fieldDiff = new MockDuplicates.FieldDiff()
    .withFieldName('Name')
    .withCompareValue('Different Name');

Duplicates.MatchRecord matchRecord = new MockDuplicates.MatchRecord()
    .withRecord(duplicateAccount)
    .addFieldDiff(fieldDiff);

Duplicates.MatchResult matchResult = new MockDuplicates.MatchResult()
    .withRule('Account Duplicate Rule')
    .withSize(1)
    .addMatchRecord(matchRecord);

Duplicates.DuplicateResult duplicateResult = new MockDuplicates.DuplicateResult()
    .withRecord(originalAccount)
    .addMatchResult(matchResult);

Duplicates.FindDuplicatesResult findDupResult = new MockDuplicates.FindDuplicatesResult()
    .asSuccessful()
    .addDuplicateResult(duplicateResult);

MockDuplicates.setGlobalMock().withResult(findDupResult);

List<Duplicates.FindDuplicatesResult> results = DatabaseLayer.Duplicates.findDuplicates(
    new List<SObject>{ originalAccount }
);

Assert.areEqual(1, results.size());
Assert.isTrue(results[0].getSuccess());
```

### Failed Result with Errors

```apex
Duplicates.Error error = new MockDuplicates.Error()
    .withMessage('Permission denied')
    .withStatusCode('FIELD_ERROR')
    .addField('Name')
    .addField('Phone');

Duplicates.FindDuplicatesResult mockResult = new MockDuplicates.FindDuplicatesResult()
    .asFailed()
    .addError(error);

MockDuplicates.setGlobalMock().withResult(mockResult);

List<Duplicates.FindDuplicatesResult> results = DatabaseLayer.Duplicates.findDuplicates(records);

Assert.isFalse(results[0].getSuccess());
Assert.areEqual(1, results[0].getErrors().size());
```

## Configuring Mock Behavior

### Multiple Results

Configure different results for different calls:

```apex
List<Duplicates.FindDuplicatesResult> mockResults = new List<Duplicates.FindDuplicatesResult>();
mockResults.add(new MockDuplicates.FindDuplicatesResult().asSuccessful());
mockResults.add(new MockDuplicates.FindDuplicatesResult().asFailed());

MockDuplicates.setGlobalMock().withResults(mockResults);
```

### Throwing Exceptions

Simulate error conditions by configuring the mock to throw an exception:

```apex
MockDuplicates.setGlobalMock()
    .withError(new System.NullPointerException('API unavailable'));

try {
    DatabaseLayer.Duplicates.findDuplicates(records);
    Assert.fail('Should have thrown exception');
} catch (System.NullPointerException ex) {
    Assert.areEqual('API unavailable', ex.getMessage());
}
```

## Simulator Interface

For advanced mocking scenarios, implement the `MockDuplicates.Simulator` interface to provide custom logic:

```apex
public class CustomSimulator implements MockDuplicates.Simulator {
    public List<Duplicates.FindDuplicatesResult> simulate(Object input) {
        // Custom logic based on input
        List<Duplicates.FindDuplicatesResult> results = new List<Duplicates.FindDuplicatesResult>();
        // ... build results ...
        return results;
    }
}

// In test:
MockDuplicates.setGlobalMock(new CustomSimulator());
```

## Reference

See the following classes for complete API documentation:

- [MockDuplicates](./The-MockDuplicates-Class) - Mock implementation
- [MockDuplicates.Simulator](./The-MockDuplicates.Simulator-Interface) - Custom simulator interface
- [MockDuplicates.StaticResults](./The-MockDuplicates.StaticResults-Class) - Built-in simulator
