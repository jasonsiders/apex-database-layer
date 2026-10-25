The outcome of a [flow action](./Performing-DML-in-Flow) for one record. Flow can't read `Database` result types, so this Apex-defined type copies their outcome into fields that Flow can read.

## Properties

| Property Name | Data Type          | Details                                                                                               |
| ------------- | ------------------ | ----------------------------------------------------------------------------------------------------- |
| errors        | List&lt;String&gt; | Each error, formatted as `STATUS_CODE: Message (Field1, Field2)`. Empty when the operation succeeded. |
| id            | Id                 | The record's ID, or null when an insert failed. For a lead conversion, the lead's ID.                 |
| isCreated     | Boolean            | For an upsert, whether the record was inserted rather than updated. Null for the other operations.    |
| isSuccess     | Boolean            | Whether the operation succeeded for the record.                                                       |

## Constructors

Each constructor copies a `Database` result into a new `InvocableDmlResult`. The no-arg constructor returns an unsuccessful result with no errors, for Flow to create.

- `InvocableDmlResult()`
- `InvocableDmlResult(Database.DeleteResult result)`
- `InvocableDmlResult(Database.EmptyRecycleBinResult result)`
- `InvocableDmlResult(Database.LeadConvertResult result)`
- `InvocableDmlResult(Database.SaveResult result)`
- `InvocableDmlResult(Database.UndeleteResult result)`
- `InvocableDmlResult(Database.UpsertResult result)`

```apex
Database.SaveResult saveResult = DatabaseLayer.Dml.doInsert(account, false);
InvocableDmlResult result = new InvocableDmlResult(saveResult);
```

## Methods

### `fromList`

Converts a list of `Database` results, in the same order. `Database` result types share no interface, so each type has its own overload.

- `static List<InvocableDmlResult> fromList(List<Database.DeleteResult> deleteResults)`
- `static List<InvocableDmlResult> fromList(List<Database.EmptyRecycleBinResult> purgeResults)`
- `static List<InvocableDmlResult> fromList(List<Database.SaveResult> saveResults)`
- `static List<InvocableDmlResult> fromList(List<Database.UndeleteResult> undeleteResults)`
- `static List<InvocableDmlResult> fromList(List<Database.UpsertResult> upsertResults)`

```apex
List<Database.SaveResult> saveResults = DatabaseLayer.Dml.doInsert(accounts, false);
List<InvocableDmlResult> results = InvocableDmlResult.fromList(saveResults);
```
