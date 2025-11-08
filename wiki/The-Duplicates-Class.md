The `Duplicates` class provides mockable abstraction over Salesforce's Datacloud duplicate detection APIs.

It encapsulates `Datacloud.FindDuplicates` and `Datacloud.FindDuplicatesByIds` methods, enabling developers to easily mock duplicate detection operations for unit testing without requiring actual duplicate rules or org configuration.

## Constructing `Duplicates` Objects

`Duplicates` objects cannot be directly constructed via the `new` keyword. Instead, access the class and its methods via the `DatabaseLayer.Duplicates` static property:

```apex
List<Duplicates.FindDuplicatesResult> results = DatabaseLayer.Duplicates.findDuplicates(records);
```

The `DatabaseLayer` class is responsible for instantiating database objects of the correct type at runtime. In `@IsTest` context, developers can call `DatabaseLayer.useMocks()`, and an instance of the `MockDuplicates` class will be returned instead:

```apex
DatabaseLayer.useMocks();
Assert.isInstanceOfType(DatabaseLayer.Duplicates, MockDuplicates.class, 'Not a mock');
```

## Finding Duplicates

The `Duplicates` class provides two overloaded `findDuplicates` methods that support both SObject records and record IDs as input.

### By Records

```apex
List<Account> accounts = [SELECT Id, Name FROM Account LIMIT 10];
List<Duplicates.FindDuplicatesResult> results = DatabaseLayer.Duplicates.findDuplicates(accounts);
```

### By IDs

```apex
List<Id> recordIds = new List<Id>{ '001xx000003DHP', '001xx000003DHQ' };
List<Duplicates.FindDuplicatesResult> results = DatabaseLayer.Duplicates.findDuplicates(recordIds);
```

## Duplicate Detection Results

The `findDuplicates` method returns a list of `FindDuplicatesResult` objects, each containing:

- **Success**: Boolean indicating whether the operation was successful
- **Errors**: List of any errors that occurred
- **DuplicateResults**: List of results for each input record

### FindDuplicatesResult

Contains the overall result of a duplicate detection operation for a set of records.

```apex
Duplicates.FindDuplicatesResult result = results[0];
Boolean success = result.getSuccess();
List<Duplicates.Error> errors = result.getErrors();
List<Duplicates.DuplicateResult> duplicates = result.getDuplicateResults();
```

### DuplicateResult

Contains duplicate matches for a specific record.

```apex
Duplicates.DuplicateResult dupResult = duplicates[0];
SObject originalRecord = dupResult.getRecord();
List<Duplicates.MatchResult> matches = dupResult.getMatchResults();
```

### MatchResult

Contains matches for a specific duplicate rule.

```apex
Duplicates.MatchResult match = matches[0];
String ruleName = match.getRule();
Integer matchCount = match.getSize();
List<Duplicates.MatchRecord> records = match.getMatchRecords();
```

### MatchRecord

Contains a single matched record and field differences.

```apex
Duplicates.MatchRecord matchRecord = records[0];
SObject matchedRecord = matchRecord.getRecord();
List<Duplicates.FieldDiff> differences = matchRecord.getFieldDiffs();
```

### FieldDiff

Contains information about a field that differs between records.

```apex
Duplicates.FieldDiff diff = differences[0];
String fieldName = diff.getFieldName();
Object differentValue = diff.getCompareValue();
```

### Error

Contains error information if duplicate detection fails.

```apex
Duplicates.Error error = errors[0];
String message = error.getMessage();
String statusCode = error.getStatusCode();
List<String> affectedFields = error.getFields();
```

## Mocking Duplicates for Testing

Use `MockDuplicates` to configure duplicate detection results without requiring actual duplicate rules:

```apex
@IsTest
static void testDuplicateDetection() {
    DatabaseLayer.useMocks();

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
        .withSuccess(true)
        .addDuplicateResult(duplicateResult);

    MockDuplicates.setGlobalMock().withResult(findDupResult);

    // Your test code here
    List<Duplicates.FindDuplicatesResult> results = DatabaseLayer.Duplicates.findDuplicates(
        new List<SObject>{ originalAccount }
    );

    Assert.areEqual(1, results.size());
}
```

### Configuring Mock Errors

```apex
Duplicates.Error error = new MockDuplicates.Error()
    .withMessage('Permission denied')
    .withStatusCode('FIELD_ERROR')
    .addField('Name');

Duplicates.FindDuplicatesResult mockResult = new MockDuplicates.FindDuplicatesResult()
    .withSuccess(false)
    .addError(error);

MockDuplicates.setGlobalMock().withResult(mockResult);
```

### Throwing Exceptions

```apex
MockDuplicates.setGlobalMock()
    .withError(new System.NullPointerException('Test error'));
```

## Integration with DatabaseLayer

`Duplicates` is integrated into the `DatabaseLayer` singleton and respects the mocking configuration:

```apex
@IsTest
static void testWithMocks() {
    DatabaseLayer.useMocks();
    // All operations use mocks
    DatabaseLayer.Duplicates.findDuplicates(records);
}

@IsTest
static void testWithRealData() {
    DatabaseLayer.useRealData();
    // All operations use real APIs
    DatabaseLayer.Duplicates.findDuplicates(records);
}
```
