The **Insert Records** flow action (`InvocableDmlInsertRecords`) inserts records through [`DatabaseLayer.Dml`](./The-Dml-Class), and exposes the DML settings that Flow's standard Create Records element hides: `allOrNone`, the access level, and every [`Database.DmlOptions`](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_methods_system_database_dmloptions.htm) setting.

Because the action uses `DatabaseLayer.Dml`, [plugins](./Plugin:-Dml.PreAndPostProcessor) run for each insert, and Apex tests that call flows can [mock](./Mocking-DML-Operations) the insert with `DatabaseLayer.useMocks()`.

---

## Configuring the Action

In Flow Builder, add an **Action** element and search for **Insert Records**, under the **Database Layer** category. The action's editor mirrors the Create Records element:

1. Under **How Many Records to Insert**, choose **One** or **Multiple**.
2. Select the record variable or record collection to insert. Its ID must be blank.
3. Optionally, set the access level, all-or-none behavior, and DML options.

Every input accepts a literal value or a flow resource. The resource picker works like Flow Builder's own: type `{!` or start typing to search, and select a record or lookup field to drill into it.

### Inputs

| Input                               | Type    | Default     | Description                                                                                                                                                |
| ----------------------------------- | ------- | ----------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Record / Record Collection          | SObject | (required)  | The records to insert.                                                                                                                                     |
| Access Level                        | Text    | `USER_MODE` | `USER_MODE` enforces the running user's object permissions, field-level security, and sharing rules. `SYSTEM_MODE` ignores them.                           |
| All or None                         | Boolean | `true`      | When `true`, any failure rolls back every record and fails the action. When `false`, valid records are inserted, and failures are reported in the results. |
| Allow Duplicates                    | Boolean | `false`     | Save records that a duplicate rule would otherwise alert on.                                                                                               |
| Allow Field Truncation              | Boolean | `false`     | Truncate text values that are too long for their field, instead of failing.                                                                                |
| Assignment Rule ID                  | Text    |             | The ID of a specific Lead or Case assignment rule to run.                                                                                                  |
| Locale Options                      | Text    |             | The language of any labels returned by the operation, ex: `en_US`.                                                                                         |
| Run Duplicate Rules as Current User | Boolean | `false`     | Enforce the running user's sharing rules when duplicate rules look for duplicates.                                                                         |
| Trigger Auto-Response Email         | Boolean | `false`     | Send auto-response emails for new Leads and Cases.                                                                                                         |
| Trigger Other Email                 | Boolean | `false`     | Send email to recipients outside the org.                                                                                                                  |
| Trigger User Email                  | Boolean | `false`     | Send email to users in the org, ex: when a Case or Task is assigned.                                                                                       |
| Use Default Assignment Rule         | Boolean | `false`     | Run the default active assignment rule for Leads and Cases.                                                                                                |

### Outputs

| Output            | Type                            | Description                                                                           |
| ----------------- | ------------------------------- | ------------------------------------------------------------------------------------- |
| Record            | SObject                         | The inserted record, with its new ID. Set when inserting one record.                  |
| Record Collection | SObject Collection              | The inserted records, with their new IDs. Set when inserting multiple.                |
| Result            | `InvocableDmlResult`            | The insert's outcome. Set when inserting one record.                                  |
| Result Collection | `InvocableDmlResult` Collection | Each record's outcome, in the same order as the records. Set when inserting multiple. |

`InvocableDmlResult` is an Apex-defined type with these fields:

- `errors`: each error, formatted as `STATUS_CODE: Message (Field1, Field2)`
- `id`: the new record's ID, or blank if the insert failed
- `isSuccess`: whether the record was inserted

---

## Bulk Behavior

When many flow interviews run the action at once (ex: a record-triggered flow on a 200-record update), interviews with the same settings share a single insert, which keeps the batch within DML limits.

With **All or None** set to `true`, one invalid record fails that shared insert, and every interview in it fails with it. When interviews must succeed or fail independently, set **All or None** to `false`, and check each **Result** for errors.
