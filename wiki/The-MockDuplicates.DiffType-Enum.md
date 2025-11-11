Represents the possible field difference values in duplicate detection results.

This enum corresponds to the `Datacloud.FieldDiff.difference` property values as documented in the [Salesforce Datacloud.FieldDiff documentation](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_class_Datacloud_FieldDiff.htm#apex_Datacloud_FieldDiff_getDifference).

## Values

- `IS_DIFFERENT` - Indicates the field value is different between the original and matching record
- `IS_NULL` - Indicates the field value is null in one of the records
- `IS_SAME` - Indicates the field value is the same in both records

## Example

```apex
DatabaseLayer.useMocks();

MockDuplicates.simulator
    .withResults(Account.SObjectType)
        .addRule()
            .addMatch()
                .addRecord()
                    .addFieldDiff('Name', MockDuplicates.DiffType.IS_SAME)
                    .addFieldDiff('Phone', MockDuplicates.DiffType.IS_DIFFERENT)
                    .addFieldDiff('Website', MockDuplicates.DiffType.IS_NULL);

Account account = new Account(Name = 'Acme Corp');
Duplicates.FindDuplicatesResult result = DatabaseLayer.Duplicates.findDuplicates(account);

Duplicates.MatchRecord matchRecord = result.getDuplicateResults()?.get(0)
    ?.getMatchResults()?.get(0)
    ?.getMatchRecords()?.get(0);

for (Duplicates.FieldDiff diff : matchRecord.getFieldDiffs()) {
    System.debug(diff.getName() + ': ' + diff.getDifference());
    // Output:
    // Name: SAME
    // Phone: DIFFERENT
    // Website: NULL
}
```
