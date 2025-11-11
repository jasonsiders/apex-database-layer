Represents a specific matched record in a duplicate detection result.

This class wraps `Datacloud.MatchRecord` and contains the matching record, confidence score, field differences, and additional information about the match.

## Properties

| Property Name         | Data Type                                                                                          | Details                                                                        |
| --------------------- | -------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| additionalInformation | List&lt;[Duplicates.AdditionalInformationMap](./The-Duplicates.AdditionalInformationMap-Class)&gt; | Additional information about the match as name-value pairs. Read-only.         |
| fieldDiffs            | List&lt;[Duplicates.FieldDiff](./The-Duplicates.FieldDiff-Class)&gt;                               | List of field differences between the original and matching record. Read-only. |
| matchConfidence       | Decimal                                                                                            | The confidence score for this match. Read-only.                                |
| record                | SObject                                                                                            | The matching SObject record. Read-only.                                        |

## Methods

### `getAdditionalInformation`

Returns additional information about the match.

- `List<Duplicates.AdditionalInformationMap> getAdditionalInformation()`

```apex
Duplicates.MatchRecord matchRecord = matchResult.getMatchRecords()?.get(0);
for (Duplicates.AdditionalInformationMap info : matchRecord.getAdditionalInformation()) {
    System.debug(info.getName() + ': ' + info.getValue());
}
```

### `getFieldDiffs`

Returns the field differences between original and matching record.

- `List<Duplicates.FieldDiff> getFieldDiffs()`

```apex
for (Duplicates.FieldDiff diff : matchRecord.getFieldDiffs()) {
    System.debug(diff.getName() + ' is ' + diff.getDifference());
}
```

### `getMatchConfidence`

Returns the match confidence score.

- `Decimal getMatchConfidence()`

```apex
Decimal confidence = matchRecord?.getMatchConfidence();
System.debug('Confidence: ' + confidence + '%');
```

### `getRecord`

Returns the matching record.

- `SObject getRecord()`

```apex
SObject duplicateRecord = matchRecord?.getRecord();
System.debug('Duplicate: ' + duplicateRecord);
```

### `toDatacloudType`

Returns the underlying native `Datacloud.MatchRecord` instance.

- `Datacloud.MatchRecord toDatacloudType()`

```apex
Datacloud.MatchRecord nativeRecord = matchRecord?.toDatacloudType();
```

## Example

```apex
Duplicates.MatchResult matchResult = dupResult.getMatchResults()?.get(0);
for (Duplicates.MatchRecord matchRecord : matchResult.getMatchRecords()) {
    System.debug('Match: ' + matchRecord.getRecord());
    System.debug('Confidence: ' + matchRecord.getMatchConfidence());

    for (Duplicates.FieldDiff diff : matchRecord.getFieldDiffs()) {
        System.debug('  ' + diff.getName() + ': ' + diff.getDifference());
    }
}
```
