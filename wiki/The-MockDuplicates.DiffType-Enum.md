Represents the possible field difference values in duplicate detection results.

This enum corresponds to the `Datacloud.FieldDiff.difference` property values as documented in the [Salesforce Datacloud.FieldDiff documentation](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_class_Datacloud_FieldDiff.htm#apex_Datacloud_FieldDiff_getDifference).

## Values

- `IS_DIFFERENT` - Indicates the field value is different between the original and matching record
- `IS_NULL` - Indicates the field value is null in one of the records
- `IS_SAME` - Indicates the field value is the same in both records

## Example

```apex
matchRecord.addFieldDiff('Name', MockDuplicates.DiffType.IS_SAME);
```
