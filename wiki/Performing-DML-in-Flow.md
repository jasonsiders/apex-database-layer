The **Database Layer** flow actions perform DML through [`DatabaseLayer.Dml`](./The-Dml-Class), and expose the settings that Flow's standard data elements hide: `allOrNone`, the access level, and [`Database.DmlOptions`](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_methods_system_database_dmloptions.htm).

Because the actions use `DatabaseLayer.Dml`, [plugins](./Plugin:-Dml.PreAndPostProcessor) run for each operation, and Apex tests that call flows can [mock](./Mocking-DML-Operations) the DML with `DatabaseLayer.useMocks()`.

| Action            | Apex Class                    | `DatabaseLayer.Dml` Method |
| ----------------- | ----------------------------- | -------------------------- |
| Insert Records    | `InvocableDmlInsertRecords`   | `doInsert`                 |
| Update Records    | `InvocableDmlUpdateRecords`   | `doUpdate`                 |
| Upsert Records    | `InvocableDmlUpsertRecords`   | `doUpsert`                 |
| Delete Records    | `InvocableDmlDeleteRecords`   | `doDelete`                 |
| Undelete Records  | `InvocableDmlUndeleteRecords` | `doUndelete`               |
| Empty Recycle Bin | `InvocableDmlEmptyRecycleBin` | `emptyRecycleBin`          |
| Convert Lead      | `InvocableDmlConvertLead`     | `doConvert`                |

---

## Record Actions

In Flow Builder, add an **Action** element and search for the action by name, under the **Database Layer** category. Each record action's editor mirrors one of Flow Builder's data elements:

- **Insert Records** works like Create Records. Under **How Many Records to Insert**, choose **One** or **Multiple**, then select a record variable or record collection. Its ID must be blank.
- The other record actions work like Update Records and Delete Records. Select a record variable or record collection in **Record or Record Collection**. Each record must have an ID, except new records passed to Upsert Records.
- **Upsert Records** also works like Create Records with **Update Existing Record** turned on. Under **Field to use to identify existing record**, choose **Record ID**, **External ID**, or **Standard Field**. For the last two, pick one of the object's external ID fields, or one of its standard fields whose `idLookup` property is true, such as Contact's Email.

The records input takes a flow resource. The resource picker works like Flow Builder's: type `{!` or start typing to search, and select a record or lookup field to drill into it.

Then, optionally, expand **DML Options** to set the action's other inputs. Options take fixed values, not resources, since a batch of flow interviews runs one DML statement with the first interview's options. Assignment Rule ID is the exception: rule IDs differ between orgs, so set it to a resource, such as an ID from a Get Records on Assignment Rule.

### Inputs

Each action shows only the inputs that its operation uses.

| Input                               | Type    | Default     | Actions                        | Description                                                                                                                                                                                                                              |
| ----------------------------------- | ------- | ----------- | ------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Record / Record Collection          | SObject | (required)  | All                            | The records to process.                                                                                                                                                                                                                  |
| Access Level                        | Text    | `USER_MODE` | All but Empty Recycle Bin      | `USER_MODE` enforces the running user's object permissions, field-level security, and sharing rules. `SYSTEM_MODE` ignores object permissions and field-level security, but sharing rules still apply. Any other value fails the action. |
| All or None                         | Boolean | `true`      | All but Empty Recycle Bin      | When `true`, any failure rolls back every record and fails the action. When `false`, valid records are processed, and failures are reported in the results.                                                                              |
| External ID Field                   | Text    |             | Upsert Records                 | The API name of the external ID or standard ID lookup field that matches records, ex: `External_Id__c`. When blank, records match on their ID.                                                                                           |
| Allow Duplicates                    | Boolean | `false`     | Insert Records, Update Records | Save records that a duplicate rule would otherwise alert on.                                                                                                                                                                             |
| Allow Field Truncation              | Boolean | `false`     | Insert Records, Update Records | Truncate text values that are too long for their field, instead of failing.                                                                                                                                                              |
| Assignment Rule ID                  | Text    |             | Insert Records, Update Records | The ID of a specific Lead or Case assignment rule to run.                                                                                                                                                                                |
| Locale Options                      | Text    |             | Insert Records, Update Records | The language of any labels returned by the operation, ex: `en_US`.                                                                                                                                                                       |
| Run Duplicate Rules as Current User | Boolean | `false`     | Insert Records, Update Records | Enforce the running user's sharing rules when duplicate rules look for duplicates.                                                                                                                                                       |
| Trigger Auto-Response Email         | Boolean | `false`     | Insert Records, Update Records | Send auto-response emails for new Leads and Cases.                                                                                                                                                                                       |
| Trigger Other Email                 | Boolean | `false`     | Insert Records, Update Records | Send email to recipients outside the org.                                                                                                                                                                                                |
| Trigger User Email                  | Boolean | `false`     | Insert Records, Update Records | Send email to users in the org, ex: when a Case or Task is assigned.                                                                                                                                                                     |
| Use Default Assignment Rule         | Boolean | `false`     | Insert Records, Update Records | Run the default active assignment rule for Leads and Cases.                                                                                                                                                                              |

Apex's `Database.upsert`, `Database.delete`, and `Database.undelete` methods don't take `Database.DmlOptions`, and `Database.emptyRecycleBin` takes no settings at all.

### Outputs

| Output            | Type                            | Description                                                                                                    |
| ----------------- | ------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| Record            | SObject                         | The processed record. For a collection, the first record. Inserted and upserted records include their new IDs. |
| Record Collection | SObject Collection              | The processed records, in the same order as the input. Inserted and upserted records include their new IDs.    |
| Result            | `InvocableDmlResult`            | The record's outcome. For a collection, the first record's outcome.                                            |
| Result Collection | `InvocableDmlResult` Collection | Each record's outcome, in the same order as the records.                                                       |

`InvocableDmlResult` is an Apex-defined type with these fields:

- `errors`: each error, formatted as `STATUS_CODE: Message (Field1, Field2)`
- `id`: the record's ID, or blank if an insert failed. For Convert Lead, the lead's ID.
- `isCreated`: for Upsert Records, whether the record was inserted rather than updated. Blank for the other actions.
- `isSuccess`: whether the operation succeeded for the record

### Empty Recycle Bin

**Empty Recycle Bin** permanently deletes records that are already in the Recycle Bin. Use **Delete Records** first; a record that isn't in the Recycle Bin fails with `INVALID_ID_FIELD`. Removed records can't be restored.

---

## Convert Lead

**Convert Lead** converts one lead per flow interview. Its inputs are all text, ID, and boolean values, so it uses Flow Builder's standard property editor.

### Inputs

| Input                               | Type    | Default     | Description                                                                                                                                                                                            |
| ----------------------------------- | ------- | ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Lead ID                             | ID      | (required)  | The lead to convert.                                                                                                                                                                                   |
| Converted Status                    | Text    | (required)  | A lead status that counts as converted, ex: `Closed - Converted`.                                                                                                                                      |
| Account ID                          | ID      |             | An existing account to merge the lead into. When blank, the conversion creates an account.                                                                                                             |
| Contact ID                          | ID      |             | An existing contact to merge the lead into. When blank, the conversion creates a contact.                                                                                                              |
| Opportunity ID                      | ID      |             | An existing opportunity to merge the lead into. When blank, the conversion creates an opportunity.                                                                                                     |
| Don't Create Opportunity            | Boolean | `false`     | Convert the lead without an opportunity.                                                                                                                                                               |
| Opportunity Name                    | Text    |             | The new opportunity's name. When blank, it defaults to the lead's company.                                                                                                                             |
| Owner ID                            | ID      |             | The owner of the new account, contact, and opportunity. When blank, the lead's owner.                                                                                                                  |
| Overwrite Lead Source               | Boolean | `false`     | Replace the contact's lead source with the lead's.                                                                                                                                                     |
| Send Notification Email             | Boolean | `false`     | Email the owner set by Owner ID.                                                                                                                                                                       |
| Access Level                        | Text    | `USER_MODE` | `USER_MODE` enforces the running user's object permissions, field-level security, and sharing rules. `SYSTEM_MODE` ignores object permissions and field-level security, but sharing rules still apply. |
| All or None                         | Boolean | `true`      | When `true`, any failure rolls back every lead and fails the action. When `false`, valid leads are converted, and failures are reported in the result.                                                 |
| Allow Duplicates                    | Boolean | `false`     | Save accounts and contacts that a duplicate rule would otherwise alert on.                                                                                                                             |
| Run Duplicate Rules as Current User | Boolean | `false`     | Enforce the running user's sharing rules when duplicate rules look for duplicates.                                                                                                                     |

### Outputs

| Output         | Type                 | Description                                                             |
| -------------- | -------------------- | ----------------------------------------------------------------------- |
| Account ID     | ID                   | The account the lead was converted to.                                  |
| Contact ID     | ID                   | The contact the lead was converted to.                                  |
| Opportunity ID | ID                   | The opportunity the lead was converted to. Blank when none was created. |
| Result         | `InvocableDmlResult` | The conversion's outcome. Its `id` is the lead's ID.                    |

---

## Bulk Behavior

When many flow interviews run an action at once (ex: a record-triggered flow on a 200-record update), the action processes every interview's records in a single DML operation, which keeps the batch within DML limits.

One DML operation can only have one set of settings, so the **first** interview's settings apply to every interview in the batch. Use static values, not variables or formulas, for the settings inputs, so that every interview has the same settings, and the action behaves the same way however the interviews are batched.

Like Apex DML, the operation rejects a record listed twice, ex: when two contacts' interviews update the same account. Update Records throws `System.ListException: Duplicate id in list`, which fails every interview in the batch, even with **All or None** set to `false`. Upsert Records fails each copy with `DUPLICATE_VALUE`, and Convert Lead fails a lead's second conversion with `CANNOT_UPDATE_CONVERTED_LEAD`.

With **All or None** set to `true`, one invalid record fails the shared operation, and every interview in the batch fails with it. When interviews must succeed or fail independently, set **All or None** to `false`, and check each **Result** for errors.
