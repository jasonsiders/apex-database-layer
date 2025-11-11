The `Duplicates` class provides a mockable interface for Salesforce duplicate detection operations.

It wraps the standard `Datacloud.FindDuplicates` APIs, enabling developers to easily mock duplicate detection in unit tests. This class allows you to check for duplicate records without being dependent on actual duplicate rules configured in your org during testing.

## Constructing `Duplicates` Objects

`Duplicates` objects cannot be directly constructed via the `new` keyword. Instead, access the class and its methods via the `DatabaseLayer.Duplicates` static property:

```apex
Duplicates.FindDuplicatesResult result = DatabaseLayer.Duplicates.findDuplicates(record);
```

The `DatabaseLayer` class is responsible for instantiating database objects of the correct type at runtime. In `@IsTest` context, developers can call `DatabaseLayer.useMocks()`, and an instance of the `MockDuplicates` class will be returned instead:

```apex
DatabaseLayer.useMocks();
Assert.isInstanceOfType(DatabaseLayer.Duplicates, MockDuplicates.class, 'Not a mock');
```

## Performing Duplicate Detection

The `Duplicates` class contains methods which mirror the functionality of the standard [`Datacloud.FindDuplicates` class](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_class_Datacloud_FindDuplicatesResult.htm).

```apex
Account account = new Account(Name = 'Acme Corp');
Duplicates.FindDuplicatesResult result = DatabaseLayer.Duplicates.findDuplicates(account);
if (result?.isSuccess()) {
    for (Duplicates.DuplicateResult dupResult : result.getDuplicateResults()) {
        System.debug('Rule: ' + dupResult.getDuplicateRule());
        for (Duplicates.MatchResult matchResult : dupResult.getMatchResults()) {
            System.debug('Matches: ' + matchResult.getSize());
        }
    }
}
```

## Methods

### `findDuplicates`

Executes duplicate detection on one or more records.

- `Duplicates.FindDuplicatesResult findDuplicates(SObject record)`
- `Duplicates.FindDuplicatesResult findDuplicates(Id recordId)`
- `List<Duplicates.FindDuplicatesResult> findDuplicates(List<SObject> records)`
- `List<Duplicates.FindDuplicatesResult> findDuplicates(Iterable<Id> recordIds)`

```apex
Account account = new Account(Name = 'Acme Corp');
Duplicates.FindDuplicatesResult result = DatabaseLayer.Duplicates.findDuplicates(account);
```

## Considerations

- The Datacloud API limits input to 1-50 records per call
- All records must be of the same SObjectType
- See [Datacloud.FindDuplicates](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_class_Datacloud_FindDuplicatesResult.htm) for more information
