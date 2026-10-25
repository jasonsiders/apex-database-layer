One flow interview's input to a record [flow action](./Performing-DML-in-Flow): its records, and the settings for the DML operation.

In a batch of interviews, [`InvocableDml.run`](./The-InvocableDml-Class) uses the first input's settings for every interview. Each action uses only the settings its operation supports; see [Inputs](./Performing-DML-in-Flow#inputs).

## Properties

| Property Name                  | Data Type           | Details                                                                                                                |
| ------------------------------ | ------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| accessLevel                    | String              | `USER_MODE` or `SYSTEM_MODE`. Defaults to `USER_MODE`. See `getAccessLevel`.                                           |
| allOrNone                      | Boolean             | Whether any failure rolls back every record. Defaults to `true`. See `getAllOrNone`.                                   |
| allowDuplicates                | Boolean             | Maps to `Database.DmlOptions.DuplicateRuleHeader.AllowSave`. Defaults to `false`.                                      |
| allowFieldTruncation           | Boolean             | Maps to `Database.DmlOptions.AllowFieldTruncation`. Defaults to `false`.                                               |
| assignmentRuleId               | Id                  | Maps to `Database.DmlOptions.AssignmentRuleHeader.AssignmentRuleId`.                                                   |
| externalIdField                | String              | The API name of the field that matches records to upsert, ex: `External_Id__c`. When blank, records match on their ID. |
| localeOptions                  | String              | Maps to `Database.DmlOptions.LocaleOptions`, ex: `en_US`.                                                              |
| record                         | SObject             | A single record. Processed before `recordCollection`.                                                                  |
| recordCollection               | List&lt;SObject&gt; | A collection of records.                                                                                               |
| runDuplicateRulesAsCurrentUser | Boolean             | Maps to `Database.DmlOptions.DuplicateRuleHeader.RunAsCurrentUser`. Defaults to `false`.                               |
| triggerAutoResponseEmail       | Boolean             | Maps to `Database.DmlOptions.EmailHeader.TriggerAutoResponseEmail`. Defaults to `false`.                               |
| triggerOtherEmail              | Boolean             | Maps to `Database.DmlOptions.EmailHeader.TriggerOtherEmail`. Defaults to `false`.                                      |
| triggerUserEmail               | Boolean             | Maps to `Database.DmlOptions.EmailHeader.TriggerUserEmail`. Defaults to `false`.                                       |
| useDefaultAssignmentRule       | Boolean             | Maps to `Database.DmlOptions.AssignmentRuleHeader.UseDefaultRule`. Defaults to `false`.                                |

## Methods

### `getAccessLevel`

Returns the `System.AccessLevel` named by `accessLevel`, or `USER_MODE` when it's blank. Throws a `System.IllegalArgumentException` for any other value, so a typo fails instead of running in a mode the flow didn't ask for.

- `System.AccessLevel getAccessLevel()`

```apex
InvocableDml.Input input = new InvocableDml.Input();
input.accessLevel = 'SYSTEM_MODE';
System.AccessLevel accessLevel = input.getAccessLevel(); // System.AccessLevel.SYSTEM_MODE
```

### `getAllOrNone`

Returns `allOrNone`, or `true` when it's null, matching DML statements.

- `Boolean getAllOrNone()`

```apex
InvocableDml.Input input = new InvocableDml.Input();
Boolean allOrNone = input.getAllOrNone(); // true
```

### `initDmlOptions`

Returns a new `Database.DmlOptions` with this input's settings. Unset booleans default to `false`, matching a new `Database.DmlOptions`. `OptAllOrNone` is set to `getAllOrNone()`.

- `Database.DmlOptions initDmlOptions()`

```apex
InvocableDml.Input input = new InvocableDml.Input();
input.allowFieldTruncation = true;
Database.DmlOptions options = input.initDmlOptions();
List<Database.SaveResult> results = DatabaseLayer.Dml.doInsert(records, options, input.getAccessLevel());
```
