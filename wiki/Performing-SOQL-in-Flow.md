The **SOQL: Get Record(s)** flow action queries records through [`DatabaseLayer.Soql`](./The-Soql-Class), with the options that Flow's Get Records element lacks:

- Conditions on parent fields, ex: `Account.Owner.IsActive`, and parent fields in the stored records
- The access level: `USER_MODE` or `SYSTEM_MODE`
- Custom condition logic with `NOT`, ex: `1 AND NOT (2 OR 3)`
- `LIKE` patterns, and `IN` / `NOT IN` against a text, number, date, or record collection
- `LIMIT`, `OFFSET`, `ALL ROWS`, and `FOR UPDATE`

Because the action uses `DatabaseLayer.Soql`, [plugins](./Plugin:-Soql.PreAndPostProcessor) run for each query, and Apex tests that call flows can [mock](./Mocking-SOQL-Queries) the queries with `DatabaseLayer.useMocks()`.

| Action              | Apex Class      | `Soql` Method |
| ------------------- | --------------- | ------------- |
| SOQL: Get Record(s) | `InvocableSoql` | `query`       |

---

## Differences from Get Records

The action looks like Get Records, but doesn't always behave like it. Check these before you swap one for the other:

- **Access level**: the action defaults to `USER_MODE`. In a record-triggered flow, Get Records runs in system context without sharing, so the same query can find fewer records, or fail the user's save when it selects a field they can't read. `SYSTEM_MODE` skips object permissions and field-level security, but still applies sharing unless the org opts out. See [Inputs](#inputs).
- **Blank values**: a blank value, ex: an unset resource or Empty String, on **Contains**, **Starts With**, or **Ends With** matches only records where the field is blank, where Get Records matches every record. A blank value on a range, ex: Greater Than an unset date, matches every record. See [Operators](#operators).
- **Bulk runs**: like Get Records, interviews share a query where they can. Some conditions prevent that, and then a bulk run has the potential to exceed SOQL's 100-query or 50,000-row limit, which fails the transaction. See [Bulk Behavior](#bulk-behavior) to avoid it.
- **Text case**: a merged query's rows are matched in Apex, which ignores case the same way in every locale, where SOQL follows the running user's. For a few letters, ex: the Turkish `İ` and `ı`, a merged query can miss rows a lone query finds, or, for Does Not Equal and Not In, keep rows it leaves out.
- **Rows**: **For Update** locks every row the query reads until the transaction ends, and can't sort. **All Rows** includes deleted and archived records.
- **Resources**: the action takes up to 5 resources of each type. See [Values](#values).
- **Mocks**: mocks don't filter, so a merged query's mock records go to no interview unless they populate the field the split uses. See [Testing with Mocks](#testing-with-mocks).

---

## Building the Query

In Flow Builder, add an **Action** element and search for `SOQL:`, under the **Database Layer** category. The action's editor mirrors Get Records. Below the object, click a section's heading to open or close it; only **Filter Records** starts open:

1. **Get Records of This Object**: search for the object to query.
2. **Select Fields to Store**: add the fields to include in the records. Records always include their ID, and every field used in a condition. **All Fields** stores every field of the object, or of a parent, ex: **Account ID > All Fields**, and replaces that object's fields already in the list. After it, that object offers only its lookups, to store its parents' fields. In user mode, it stores only the fields the running user can read.
3. **Filter Records**: choose **None** to get every record, or add conditions, and choose whether all of them, any of them, or custom logic must be met. Each condition has a field, an operator, and a value.
4. **Sort and Limit Records**: add the fields to sort by, each ascending or descending, with blank values first or last. Then set a limit, the most records to get, and an offset, how many to skip. In a bulk run, each applies to each interview; see [Bulk Behavior](#bulk-behavior). Without a sort, which records those are is up to the database.
5. **Advanced Query Options**: set the access level and **Rows**: **All Rows** includes deleted and archived records, and **For Update** locks the records for the rest of the transaction, but can't sort them. SOQL allows one of the two at a time.

Like Get Records, the menu lists each lookup once, by its label, ex: **Account ID**. Click it to pick the ID, or click its arrow to list the parent's fields, like Flow Builder's resource menu. You can also type the path, ex: `Account.Owner.`. Relationships go as deep as SOQL allows: six. A relationship to several objects, ex: a task's **Who**, offers only the fields SOQL allows on it without `TYPEOF`, such as Name and Type.

### Operators

The operators depend on the field's type, in Get Records' wording:

| Field Type                        | Operators                                                                                                       |
| --------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| Text, picklist, email, phone, URL | Equals, Does Not Equal, Contains, Starts With, Ends With, Like, In, Not In, Is Null                             |
| ID and lookup                     | Equals, Does Not Equal, In, Not In, Is Null                                                                     |
| Number, currency, date, date/time | Equals, Does Not Equal, Less Than, Greater Than, Less Than or Equal, Greater Than or Equal, In, Not In, Is Null |
| Time                              | Equals, Does Not Equal, Less Than, Greater Than, Less Than or Equal, Greater Than or Equal, Is Null             |
| Checkbox                          | Equals, Does Not Equal                                                                                          |
| Multi-select picklist             | Includes, Excludes, Equals, Does Not Equal, Is Null                                                             |

**Is Null** takes True or False, like Get Records: True finds records where the field is blank, and False finds records where it has a value. Its value can also be a Boolean resource, and an unset resource checks for blank.

**Contains**, **Starts With**, and **Ends With** match their value literally, so a `%` or `_` in it is a character, not a wildcard. **Like** passes its value through as a SOQL pattern, wildcards and all.

Unlike Get Records, a blank value, ex: an unset resource or Empty String, makes **Contains**, **Starts With**, and **Ends With** match only records where the field is blank, since the condition becomes `LIKE null`. Get Records matches every record instead. A blank value on a range, ex: Greater Than an unset date, matches every record.

### Values

A condition's value is a flow resource or a value typed into the picker:

- **Resources** need no Assignment element. The editor saves each one to a typed slot input, ex: `text1` or `recordCollection2`, and the query refers to the slot by name. The action takes up to 5 resources of each type.
- **Typed values** are saved in the query, as the field's type, ex: `42` for a number field.
- **Date literals**, ex: `TODAY` or `LAST_N_DAYS:30`, are listed for date and date/time fields, and can be typed.
- **In** and **Not In** take a collection resource. On an ID or lookup field, they also take a record collection of the field's object (or of any object, for a lookup to several objects, ex: Task.WhoId), and match the records' IDs. A record without an ID fails the action, since it can't match anything.
- **Includes** and **Excludes** take one of the field's picklist values, since SOQL can't bind them.

The action binds every value, typed or not, so no value becomes part of the SOQL text. Each value is converted to its field's type, ex: a flow number to an integer field's `Integer`, and a 15-character ID to its 18-character form.

### Inputs

| Input                                        | Type                  | Description                                                                                                                                                                                                                                                                       |
| -------------------------------------------- | --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Query Definition                             | Text                  | The query, as JSON. The editor writes it; see [Query Definition](#query-definition).                                                                                                                                                                                              |
| Access Level                                 | Text                  | `USER_MODE` (default) enforces the running user's object permissions, field-level security, and sharing rules. `SYSTEM_MODE` ignores object permissions and field-level security, but sharing rules still apply unless the org opts out, below. Any other value fails the action. |
| Text 1-5                                     | Text                  | Values for conditions. The editor assigns them.                                                                                                                                                                                                                                   |
| Number 1-5                                   | Number                | Values for conditions. The editor assigns them.                                                                                                                                                                                                                                   |
| Date 1-5, Date/Time 1-5, Time 1-5            | Date, Date/Time, Time | Values for conditions. The editor assigns them.                                                                                                                                                                                                                                   |
| Boolean 1-5                                  | Boolean               | Values for conditions. The editor assigns them.                                                                                                                                                                                                                                   |
| Text, Number, Date, Date/Time Collection 1-5 | Collections           | Values for In and Not In conditions. The editor assigns them.                                                                                                                                                                                                                     |
| Record Collection 1-5                        | SObject Collection    | Values for In and Not In conditions on ID and lookup fields, matched by the records' IDs. The editor assigns them.                                                                                                                                                                |

In a record-triggered flow, Get Records runs in system context without sharing, whoever saved the record. With `USER_MODE`, the query finds only the records that user can see, and fails their save if it selects a field they can't read. `SYSTEM_MODE` reads every field, but still finds only the records that user can see.

To match Get Records, set Access Level to `SYSTEM_MODE` and set the [`InvocableSoqlSystemModeWithoutSharing`](./DatabaseLayerParameter__mdt#invocablesoqlsystemmodewithoutsharing) parameter to `true`. Then `SYSTEM_MODE` ignores sharing too.

> _**Warning**: Flow isn't the only caller. Anyone with access to the `InvocableSoql` Apex class can call the action through the REST API and choose the query. With the parameter on, they can read any record in the org. Grant that class only to users who may see every record._

### Outputs

| Output       | Type               | Description                                                                                                                              |
| ------------ | ------------------ | ---------------------------------------------------------------------------------------------------------------------------------------- |
| Records      | SObject Collection | The records found, in query order. Empty, not blank, when nothing matches.                                                               |
| Record       | SObject            | The first record found, or blank when nothing matches.                                                                                   |
| Query String | Text               | The query, with this interview's values filled in, for Flow Builder's debug panel. The action binds values instead of running this text. |

The [Nebula Logger plugin](./Plugin:-Nebula-Logger), or any other [SOQL plugin](./Plugin:-Soql.PreAndPostProcessor), logs each query the action runs.

---

## Bulk Behavior

When many interviews run the action at once, ex: a record-triggered flow on a 200-record update, Flow passes them to the action in one call. Like Get Records, the action runs one merged query for them where it can, then gives each interview its own rows. Some conditions prevent that, and then a bulk run has the potential to:

- **Run too many queries**: interviews that can't merge run one query each. Past 100 queries in a synchronous transaction, or 200 in an asynchronous one, the transaction fails.
- **Read too many rows**: a merged query reads every row any interview could need. Past 50,000 rows, the transaction fails.
- **Use too much CPU time**: Apex checks a merged query's rows against each interview's conditions. Past 10 seconds in a synchronous transaction, or 60 in an asynchronous one, the transaction fails.

A query that fails for any other reason, ex: an invalid value, fails every interview that shares it.

Neither limit is a problem for most queries. Follow the guidelines below, then [test a bulk run](#testing-a-bulk-run).

### Keeping to One Query

Interviews merge when Apex can check each condition whose value differs between them:

- Values that differ merge on Equals, In, Contains, Starts With, Ends With, Like, Does Not Equal, Not In, and ranges on numbers, dates, date/times, and times. Prefer Equals or In, ex: Account ID Equals {!$Record.AccountId}.
- Don't put a value that differs under `NOT` in custom logic. `NOT (Title Equals {!$Record.Title})` runs one query per distinct title; Title Does Not Equal {!$Record.Title} merges.
- Give these the same value in every interview, joined to the rest by AND: date literals, Includes, Excludes, ranges on text, multi-select picklists, and currency fields in an org with several currencies.
- Don't put a wildcard in the middle of a Like pattern whose value differs, ex: `A%e`. Wildcards at either end merge.
- With **For Update**, vary only one condition, Equals or In, with no limit. Or vary only ID Equals, joined to the rest by AND, with any limit.

### Keeping Queries Selective

- Join broad conditions to a selective one by AND. When their values differ, a merged query leaves out Does Not Equal and Not In, and reads a range from its loosest value, ex: the earliest birthdate. Alone, either can read most of a large table. Pair them with a selective Equals, ex: Account ID Equals {!$Record.AccountId}.
- Vary as few conditions as you can. When several differ, a merged query also reads their combinations, ex: rows with one contact's account and another contact's title.
- When ranges or Contains differ, also vary an Equals or In joined to them by AND. Without one, Apex checks every row against most interviews' ranges or patterns. In testing, 200 interviews took about 4 seconds of CPU time over 600 rows, and 9 over 1,000.
- Don't rely on a limit. The limit applies to each interview after the split, so a limit of 1 over accounts with thousands of contacts each still reads every contact. The exception is when only exclusions by ID differ, ex: Contact ID Does Not Equal {!$Record.Id}.

### Testing a Bulk Run

Before you activate the flow, run it on as many records as it will see at once, ex: insert or update 200 records in an Apex test without mocks. Check `Limits.getQueries()`, or the SOQL count in the debug log. The [Nebula Logger plugin](./Plugin:-Nebula-Logger) logs each query the action runs.

---

## Testing with Mocks

With `DatabaseLayer.useMocks()` or `useMockSoql()`, the action's queries return [mock results](./Mocking-SOQL-Queries) instead of querying the database. Mocks don't filter, so a merged query's mock results are split by the varying condition's field, like real results. Populate that field in each mock record, or the split gives the record to no interview.

For example, if two interviews query contacts by account, return mock contacts with `AccountId` set:

```java
Account acme = (Account) new MockRecord(Account.SObjectType)?.withId()?.toSObject();
Contact contact = (Contact) new MockRecord(Contact.SObjectType)
	?.setField(Contact.AccountId, acme?.Id)
	?.withId()
	?.toSObject();
MockSoql.setGlobalMock()?.withResults(new List<Contact>{ contact });
```

---

## Query Definition

The editor saves the query as JSON in the **Query Definition** input. `InvocableSoql.Query` parses it:

```json
{
	"objectApiName": "Contact",
	"fields": ["LastName", "Account.Name"],
	"conditions": [
		{ "field": "AccountId", "operator": "IN", "slot": "recordCollection1" },
		{ "field": "LeadSource", "operator": "EQUALS", "value": "Web" },
		{ "field": "CreatedDate", "operator": "GREATER_THAN", "dateLiteral": "LAST_N_DAYS:30" },
		{ "field": "Account.Owner.IsActive", "operator": "EQUALS", "value": "true" }
	],
	"conditionLogic": "1 AND 2 AND (3 OR 4)",
	"orderBy": [{ "field": "LastName", "direction": "ASCENDING", "nullOrder": "NULLS_LAST" }],
	"rowLimit": 100,
	"usage": "ALL_ROWS"
}
```

| Property         | Description                                                                                                                                             |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `objectApiName`  | The object to query.                                                                                                                                    |
| `fields`         | The fields to select, including parent fields. `*` selects every field of the object, and `Account.*` every field of a parent. `Id` is implied.         |
| `conditions`     | Each condition's `field` and `operator`, and its value: a `slot`, a `value` or `values` as text, or a `dateLiteral`. `IS_NULL` takes `true` or `false`. |
| `conditionLogic` | `AND` (default), `OR`, or custom logic by condition number, using only numbers, `AND`, `OR`, `NOT`, and parentheses.                                    |
| `orderBy`        | Each sort field's `field`, `direction` (`ASCENDING` or `DESCENDING`), and `nullOrder` (`NULLS_FIRST` or `NULLS_LAST`).                                  |
| `rowLimit`       | The `LIMIT`, if any.                                                                                                                                    |
| `rowOffset`      | The `OFFSET`, if any.                                                                                                                                   |
| `usage`          | `ALL_ROWS` or `FOR_UPDATE`, if any.                                                                                                                     |

Operators are `EQUALS`, `NOT_EQUALS`, `LESS_THAN`, `GREATER_THAN`, `LESS_OR_EQUAL`, `GREATER_OR_EQUAL`, `LIKE`, `CONTAINS`, `STARTS_WITH`, `ENDS_WITH`, `IN`, `NOT_IN`, `INCLUDES`, `EXCLUDES`, and `IS_NULL`. The action checks every field, operator, date literal, and custom logic before it runs any query, and fails on anything it doesn't recognize.
