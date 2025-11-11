Represents the top-level result of a duplicate detection operation.

This class wraps `Datacloud.FindDuplicatesResult` and contains duplicate rule results and any errors encountered during the operation.

## Properties

| Property Name    | Data Type                                                                        | Details                                                                           |
| ---------------- | -------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| duplicateResults | List&lt;[Duplicates.DuplicateResult](./The-Duplicates.DuplicateResult-Class)&gt; | List of duplicate results for each record that was checked. Read-only.            |
| errors           | List&lt;Database.Error&gt;                                                       | List of errors that occurred during the duplicate detection operation. Read-only. |
| success          | Boolean                                                                          | Indicates whether the duplicate detection operation was successful. Read-only.    |

## Methods

### `getDuplicateResults`

Returns the duplicate detection results.

- `List<Duplicates.DuplicateResult> getDuplicateResults()`

```apex
Duplicates.FindDuplicatesResult result = DatabaseLayer.Duplicates.findDuplicates(account);
for (Duplicates.DuplicateResult dupResult : result.getDuplicateResults()) {
    System.debug('Rule: ' + dupResult.getDuplicateRule());
}
```

### `getErrors`

Returns any errors that occurred during the operation.

- `List<Database.Error> getErrors()`

```apex
if (!result.isSuccess()) {
    for (Database.Error error : result.getErrors()) {
        System.debug('Error: ' + error.getMessage());
    }
}
```

### `isSuccess`

Returns whether the operation was successful.

- `Boolean isSuccess()`

```apex
if (result?.isSuccess()) {
    System.debug('Duplicate detection succeeded');
} else {
    System.debug('Duplicate detection failed');
}
```

### `toDatacloudType`

Returns the underlying native `Datacloud.FindDuplicatesResult` instance.

- `Datacloud.FindDuplicatesResult toDatacloudType()`

```apex
Datacloud.FindDuplicatesResult nativeResult = result?.toDatacloudType();
```

## Example

```apex
Account account = new Account(Name = 'Acme Corp');
Duplicates.FindDuplicatesResult result = DatabaseLayer.Duplicates.findDuplicates(account);

if (result.isSuccess()) {
    List<Duplicates.DuplicateResult> duplicates = result.getDuplicateResults();
    if (!duplicates.isEmpty()) {
        System.debug('Found ' + duplicates.size() + ' duplicate rule results');
    }
} else {
    System.debug('Errors: ' + result.getErrors());
}
```
