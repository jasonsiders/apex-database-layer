The `Duplicates` class provides mockable abstraction over Salesforce's Datacloud duplicate detection APIs.

It encapsulates `Datacloud.FindDuplicates` and `Datacloud.FindDuplicatesByIds` methods, enabling developers to easily detect duplicate records in their Salesforce organization.

## Accessing Duplicates

`Duplicates` objects cannot be directly constructed via the `new` keyword. Instead, access the class and its methods via the `DatabaseLayer.Duplicates` static property:

```apex
List<Duplicates.FindDuplicatesResult> results = DatabaseLayer.Duplicates.findDuplicates(records);
```

## Finding Duplicates

The `Duplicates` class provides two overloaded `findDuplicates` methods that support both SObject records and record IDs as input.

### By Records

Detect duplicates for a list of SObject records:

```apex
List<Account> accounts = [SELECT Id, Name FROM Account LIMIT 10];
List<Duplicates.FindDuplicatesResult> results = DatabaseLayer.Duplicates.findDuplicates(accounts);
```

### By IDs

Detect duplicates for a list of record IDs:

```apex
List<Id> recordIds = new List<Id>{ '001xx000003DHP', '001xx000003DHQ' };
List<Duplicates.FindDuplicatesResult> results = DatabaseLayer.Duplicates.findDuplicates(recordIds);
```

## Processing Results

The `findDuplicates` method returns a list of `FindDuplicatesResult` objects, each containing:

- **Success**: Boolean indicating whether the operation was successful
- **Errors**: List of any errors that occurred
- **DuplicateResults**: List of results for each input record

### Checking for Success

```apex
List<Duplicates.FindDuplicatesResult> results = DatabaseLayer.Duplicates.findDuplicates(accounts);

if (results[0].getSuccess()) {
    // Process duplicate results
    List<Duplicates.DuplicateResult> duplicates = results[0].getDuplicateResults();
} else {
    // Handle errors
    List<Duplicates.Error> errors = results[0].getErrors();
    for (Duplicates.Error error : errors) {
        System.debug('Error: ' + error.getMessage());
    }
}
```

### Iterating Duplicate Results

```apex
for (Duplicates.DuplicateResult dupResult : results[0].getDuplicateResults()) {
    SObject originalRecord = dupResult.getRecord();
    List<Duplicates.MatchResult> matches = dupResult.getMatchResults();

    for (Duplicates.MatchResult match : matches) {
        String ruleName = match.getRule();
        Integer matchCount = match.getSize();

        for (Duplicates.MatchRecord matchRecord : match.getMatchRecords()) {
            SObject matchedRecord = matchRecord.getRecord();
            List<Duplicates.FieldDiff> differences = matchRecord.getFieldDiffs();
        }
    }
}
```

## Reference

See the following classes for complete API documentation:

- [The Duplicates Class](./The-Duplicates-Class) - Class reference and methods
- [Duplicates.FindDuplicatesResult](./The-Duplicates.FindDuplicatesResult-Class) - Result wrapper
- [Duplicates.DuplicateResult](./The-Duplicates.DuplicateResult-Class) - Per-record results
- [Duplicates.MatchResult](./The-Duplicates.MatchResult-Class) - Rule-based matches
- [Duplicates.MatchRecord](./The-Duplicates.MatchRecord-Class) - Individual matched record
- [Duplicates.FieldDiff](./The-Duplicates.FieldDiff-Class) - Field differences
- [Duplicates.Error](./The-Duplicates.Error-Class) - Error information
