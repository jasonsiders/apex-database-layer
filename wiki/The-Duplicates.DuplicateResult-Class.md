Represents the duplicate detection result for a specific record from a specific duplicate rule.

This class wraps `Datacloud.DuplicateResult` and contains information about whether saving is allowed and the match results from the duplicate rule.

## Properties

| Property Name | Data Type | Details |
|--------------|-----------|---------|
| allowSave | Boolean | Indicates whether saving the record is allowed despite duplicates. Read-only. |
| duplicateRule | String | The name of the duplicate rule that was evaluated. Read-only. |
| duplicateRuleEntityType | String | The entity type of the duplicate rule. Read-only. |
| errorMessage | String | Any error message from the duplicate detection operation. Read-only. |
| matchResults | List&lt;[Duplicates.MatchResult](./The-Duplicates.MatchResult-Class)&gt; | List of match results containing matching records and their details. Read-only. |

## Methods

### `getDuplicateRule`

Returns the name of the duplicate rule that was evaluated.

- `String getDuplicateRule()`

```apex
Duplicates.DuplicateResult dupResult = result.getDuplicateResults()?.get(0);
String ruleName = dupResult?.getDuplicateRule();
System.debug('Rule: ' + ruleName);
```

### `getDuplicateRuleEntityType`

Returns the entity type of the duplicate rule.

- `String getDuplicateRuleEntityType()`

```apex
String entityType = dupResult?.getDuplicateRuleEntityType();
```

### `getErrorMessage`

Returns any error message from the duplicate detection.

- `String getErrorMessage()`

```apex
String errorMsg = dupResult?.getErrorMessage();
```

### `getMatchResults`

Returns the match results for this record.

- `List<Duplicates.MatchResult> getMatchResults()`

```apex
List<Duplicates.MatchResult> matches = dupResult?.getMatchResults();
for (Duplicates.MatchResult match : matches) {
    System.debug('Match Engine: ' + match.getMatchEngine());
}
```

### `isAllowSave`

Returns whether the duplicate detection allows saving the record.

- `Boolean isAllowSave()`

```apex
if (dupResult?.isAllowSave()) {
    System.debug('Save is allowed');
} else {
    System.debug('Save is blocked');
}
```

### `toDatacloudType`

Returns the underlying native `Datacloud.DuplicateResult` instance.

- `Datacloud.DuplicateResult toDatacloudType()`

```apex
Datacloud.DuplicateResult nativeResult = dupResult?.toDatacloudType();
```
