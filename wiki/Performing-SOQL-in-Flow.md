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

## Building the Query

In Flow Builder, add an **Action** element and search for `SOQL:`, under the **Database Layer** category. The action's editor mirrors Get Records. Below the object, click a section's heading to open or close it; only **Filter Records** starts open:

1. **Get Records of This Object**: search for the object to query.
2. **Select Fields to Store**: add the fields to include in the records. Records always include their ID, and every field used in a condition. **All Fields** stores every field of the object, or of a parent, ex: **Account > All Fields**, and replaces that object's fields already in the list. After it, that object offers only its relationships, to store its parents' fields. In user mode, it stores only the fields the running user can read.
3. **Filter Records**: add conditions, and choose whether all of them, any of them, or custom logic must be met. Each condition has a field, an operator, and a value.
4. **Sort and Limit Records**: add the fields to sort by, each ascending or descending, with blank values first or last. Then set a limit, the most records to get, and an offset, how many to skip. Without a sort, which records those are is up to the database.
5. **Advanced Query Options**: set the access level and **Rows**: **All Rows** includes deleted and archived records, and **For Update** locks the records for the rest of the transaction, but can't sort them. SOQL allows one of the two at a time.

To use a parent's field, pick its relationship, ex: **Account**, and the menu lists the parent's fields, like Flow Builder's resource menu. You can also type the path, ex: `Account.Owner.`. Relationships go as deep as SOQL allows: six. A relationship to several objects, ex: a task's **Who**, offers only the fields SOQL allows on it without `TYPEOF`, such as Name and Type.

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

### Values

A condition's value is a flow resource or a value typed into the picker:

- **Resources** need no Assignment element. The editor saves each one to a typed slot input, ex: `text1` or `recordCollection2`, and the query refers to the slot by name. The action takes up to 5 resources of each type.
- **Typed values** are saved in the query, as the field's type, ex: `42` for a number field.
- **Date literals**, ex: `TODAY` or `LAST_N_DAYS:30`, are listed for date and date/time fields, and can be typed.
- **In** and **Not In** take a collection resource. On an ID or lookup field, they also take a record collection of the field's object (or of any object, for a lookup to several objects, ex: Task.WhoId), and match the records' IDs. A record without an ID fails the action, since it can't match anything.
- **Includes** and **Excludes** take one of the field's picklist values, since SOQL can't bind them.

The action binds every value, typed or not, so no value becomes part of the SOQL text. Each value is converted to its field's type, ex: a flow number to an integer field's `Integer`, and a 15-character ID to its 18-character form.

### Inputs

| Input                                        | Type                  | Description                                                                                                                                                                                                                                        |
| -------------------------------------------- | --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Query Definition                             | Text                  | The query, as JSON. The editor writes it; see [Query Definition](#query-definition).                                                                                                                                                               |
| Access Level                                 | Text                  | `USER_MODE` (default) enforces the running user's object permissions, field-level security, and sharing rules. `SYSTEM_MODE` ignores object permissions and field-level security, but sharing rules still apply. Any other value fails the action. |
| Text 1-5                                     | Text                  | Values for conditions. The editor assigns them.                                                                                                                                                                                                    |
| Number 1-5                                   | Number                | Values for conditions. The editor assigns them.                                                                                                                                                                                                    |
| Date 1-5, Date/Time 1-5, Time 1-5            | Date, Date/Time, Time | Values for conditions. The editor assigns them.                                                                                                                                                                                                    |
| Boolean 1-5                                  | Boolean               | Values for conditions. The editor assigns them.                                                                                                                                                                                                    |
| Text, Number, Date, Date/Time Collection 1-5 | Collections           | Values for In and Not In conditions. The editor assigns them.                                                                                                                                                                                      |
| Record Collection 1-5                        | SObject Collection    | Values for In and Not In conditions on ID and lookup fields, matched by the records' IDs. The editor assigns them.                                                                                                                                 |

### Outputs

| Output       | Type               | Description                                                                                                                              |
| ------------ | ------------------ | ---------------------------------------------------------------------------------------------------------------------------------------- |
| Records      | SObject Collection | The records found, in query order. Empty, not blank, when nothing matches.                                                               |
| Record       | SObject            | The first record found, or blank when nothing matches.                                                                                   |
| Query String | Text               | The query, with this interview's values filled in, for Flow Builder's debug panel. The action binds values instead of running this text. |

The [Nebula Logger plugin](./Plugin:-Nebula-Logger), or any other [SOQL plugin](./Plugin:-Soql.PreAndPostProcessor), logs each query the action runs.

---

## Bulk Behavior

When many flow interviews run the action at once (ex: a record-triggered flow on a 200-record update), Flow passes every interview to the action in one call. The action shares queries across interviews where it can:

1. Interviews with the same query, access level, and values share one query.
2. Interviews whose values differ in exactly one condition share one merged query, when all of these are true:

    - The condition logic is **All Conditions Are Met (AND)**.
    - The query has no limit and no offset, which would cut rows from the merged query that belong to some interviews.
    - The condition's operator is Equals, In (including record collections), Contains, Starts With, Ends With, or Like with a simple pattern: text with an optional `%` at either end, ex: `Acme%`.
    - The field isn't a multi-select picklist, or a currency field in an org with several currencies, where SOQL compares converted amounts but returns each record's own.

    The merged query takes every interview's value, then the action gives each interview the rows whose field matches its own value. It compares text the way SOQL does: ignoring case, except on case-sensitive fields.

3. Everything else runs one query per distinct set of values. Interviews whose varying value is blank share one query, since `= null` means **Is Null**.

For example, in a record-triggered flow on Contact, with the condition **Account ID Equals {!$Record.AccountId}**:

| Batch                                                        | Queries                                                       |
| ------------------------------------------------------------ | ------------------------------------------------------------- |
| 200 contacts on the same account                             | 1                                                             |
| 200 contacts on 150 different accounts                       | 1: `AccountId = :accountIds`, then split                      |
| 200 contacts on 150 accounts, 10 with no account             | 2: the merged query, and one for no account                   |
| 200 contacts, filtered by account and by their own last name | 200: two conditions vary, which exceeds the synchronous limit |
| 200 contacts on 150 accounts, with a limit of 1              | 150: one per account, which exceeds the synchronous limit     |

Each distinct query counts against the transaction's SOQL limit: 100 queries in a synchronous transaction, 200 in an asynchronous one. A batch that can't merge can exceed it, which fails every interview in the batch. To keep a batch within the limit, vary only one condition per query, or move the varying values into one collection and use **In**.

A query that fails, ex: from an invalid value, fails every interview that shares it.

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
