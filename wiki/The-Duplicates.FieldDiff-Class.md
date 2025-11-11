Represents field difference information between an original record and a matched duplicate record.

This class wraps `Datacloud.FieldDiff` and provides information about how a specific field differs between the records being compared.

## Properties

| Property Name | Data Type | Details |
|--------------|-----------|---------|
| difference | Object | The comparison value showing the difference for this field. Possible values: "DIFFERENT", "NULL", or "SAME". Read-only. |
| name | String | The name of the field that differs. Read-only. |

## Methods

### `getDifference`

Returns the comparison value for this field.

- `Object getDifference()`

```apex
Duplicates.FieldDiff diff = matchRecord.getFieldDiffs()?.get(0);
Object diffValue = diff?.getDifference();
System.debug('Difference: ' + diffValue); // "DIFFERENT", "NULL", or "SAME"
```

### `getName`

Returns the field name that differs.

- `String getName()`

```apex
String fieldName = diff?.getName();
System.debug('Field: ' + fieldName);
```

### `toDatacloudType`

Returns the underlying native `Datacloud.FieldDiff` instance.

- `Datacloud.FieldDiff toDatacloudType()`

```apex
Datacloud.FieldDiff nativeDiff = diff?.toDatacloudType();
```

## Example

```apex
Duplicates.MatchRecord matchRecord = matchResult.getMatchRecords()?.get(0);
for (Duplicates.FieldDiff diff : matchRecord.getFieldDiffs()) {
    System.debug(diff.getName() + ': ' + diff.getDifference());
}
```
