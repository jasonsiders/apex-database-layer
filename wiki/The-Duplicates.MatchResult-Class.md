Represents the results from a specific matching rule within a duplicate detection operation.

This class wraps `Datacloud.MatchResult` and contains matched records and any errors encountered during matching.

## Properties

| Property Name | Data Type                                                                | Details                                                                     |
| ------------- | ------------------------------------------------------------------------ | --------------------------------------------------------------------------- |
| entityType    | String                                                                   | The entity type for this match result. Read-only.                           |
| errors        | List&lt;Database.Error&gt;                                               | List of errors that occurred during matching. Read-only.                    |
| matchEngine   | String                                                                   | The name of the match engine used for this result. Read-only.               |
| matchRecords  | List&lt;[Duplicates.MatchRecord](./The-Duplicates.MatchRecord-Class)&gt; | List of matching records found by this rule. Read-only.                     |
| rule          | String                                                                   | The name of the duplicate rule that generated this match result. Read-only. |
| size          | Integer                                                                  | The number of matching records found. Read-only.                            |
| success       | Boolean                                                                  | Indicates whether the match operation was successful. Read-only.            |

## Methods

### `getEntityType`

Returns the entity type for this match result.

- `String getEntityType()`

```apex
Duplicates.MatchResult matchResult = dupResult.getMatchResults()?.get(0);
String entityType = matchResult?.getEntityType();
```

### `getErrors`

Returns any errors that occurred during matching.

- `List<Database.Error> getErrors()`

```apex
if (!matchResult.isSuccess()) {
    for (Database.Error error : matchResult.getErrors()) {
        System.debug('Error: ' + error.getMessage());
    }
}
```

### `getMatchEngine`

Returns the match engine used for this result.

- `String getMatchEngine()`

```apex
String engine = matchResult?.getMatchEngine();
System.debug('Match Engine: ' + engine);
```

### `getMatchRecords`

Returns the matching records.

- `List<Duplicates.MatchRecord> getMatchRecords()`

```apex
for (Duplicates.MatchRecord matchRecord : matchResult.getMatchRecords()) {
    System.debug('Match: ' + matchRecord.getRecord());
}
```

### `getRule`

Returns the rule name for this match.

- `String getRule()`

```apex
String ruleName = matchResult?.getRule();
System.debug('Rule: ' + ruleName);
```

### `getSize`

Returns the number of matching records.

- `Integer getSize()`

```apex
Integer matchCount = matchResult?.getSize();
System.debug('Found ' + matchCount + ' matches');
```

### `isSuccess`

Returns whether the match operation was successful.

- `Boolean isSuccess()`

```apex
if (matchResult?.isSuccess()) {
    System.debug('Match operation succeeded');
}
```

### `toDatacloudType`

Returns the underlying native `Datacloud.MatchResult` instance.

- `Datacloud.MatchResult toDatacloudType()`

```apex
Datacloud.MatchResult nativeResult = matchResult?.toDatacloudType();
```

## Example

```apex
Duplicates.FindDuplicatesResult result = DatabaseLayer.Duplicates.findDuplicates(account);
for (Duplicates.DuplicateResult dupResult : result.getDuplicateResults()) {
    for (Duplicates.MatchResult matchResult : dupResult.getMatchResults()) {
        System.debug('Rule: ' + matchResult.getRule());
        System.debug('Engine: ' + matchResult.getMatchEngine());
        System.debug('Matches: ' + matchResult.getSize());

        for (Duplicates.MatchRecord matchRecord : matchResult.getMatchRecords()) {
            System.debug('  Duplicate: ' + matchRecord.getRecord());
        }
    }
}
```
