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

Unlike Get Records, a blank value, ex: an unset resource, makes **Contains**, **Starts With**, and **Ends With** match only records where the field is blank, since the condition becomes `LIKE null`. Get Records matches every record instead. A blank value on a range, ex: Greater Than an unset date, matches every record.

### Values

A condition's value is a flow resource or a value typed into the picker:

- **Resources** need no Assignment element. The editor saves each one to a typed slot input, ex: `text1` or `recordCollection2`, and the query refers to the slot by name. The action takes up to 5 resources of each type.
- **Typed values** are saved in the query, as the field's type, ex: `42` for a number field.
- **Date literals**, ex: `TODAY` or `LAST_N_DAYS:30`, are listed for date and date/time fields, and can be typed.
- **In** and **Not In** take a collection resource. On an ID or lookup field, they also take a record collection of the field's object (or of any object, for a lookup to several objects, ex: Task.WhoId), and match the records' IDs. A record without an ID fails the action, since it can't match anything.
- **Includes** and **Excludes** take one of the field's picklist values, since SOQL can't bind them.

The action binds every value, typed or not, so no value becomes part of the SOQL text. Each value is converted to its field's type, ex: a flow number to an integer field's `Integer`, and a 15-character ID to its 18-character form.

### Inputs

| Input                                        | Type                  | Description                                                                                                                                                                                                                                               |
| -------------------------------------------- | --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Query Definition                             | Text                  | The query, as JSON. The editor writes it; see [Query Definition](#query-definition).                                                                                                                                                                      |
| Access Level                                 | Text                  | `USER_MODE` (default) enforces the running user's object permissions, field-level security, and sharing rules. `SYSTEM_MODE` ignores all three, like Get Records in a flow that runs in system context without sharing. Any other value fails the action. |
| Text 1-5                                     | Text                  | Values for conditions. The editor assigns them.                                                                                                                                                                                                           |
| Number 1-5                                   | Number                | Values for conditions. The editor assigns them.                                                                                                                                                                                                           |
| Date 1-5, Date/Time 1-5, Time 1-5            | Date, Date/Time, Time | Values for conditions. The editor assigns them.                                                                                                                                                                                                           |
| Boolean 1-5                                  | Boolean               | Values for conditions. The editor assigns them.                                                                                                                                                                                                           |
| Text, Number, Date, Date/Time Collection 1-5 | Collections           | Values for In and Not In conditions. The editor assigns them.                                                                                                                                                                                             |
| Record Collection 1-5                        | SObject Collection    | Values for In and Not In conditions on ID and lookup fields, matched by the records' IDs. The editor assigns them.                                                                                                                                        |

In a record-triggered flow, Get Records runs in system context without sharing, whoever saved the record. To match it, set Access Level to `SYSTEM_MODE`. With `USER_MODE`, the query finds only the records that user can see, and fails their save if it selects a field they can't read.

### Outputs

| Output       | Type               | Description                                                                                                                              |
| ------------ | ------------------ | ---------------------------------------------------------------------------------------------------------------------------------------- |
| Records      | SObject Collection | The records found, in query order. Empty, not blank, when nothing matches.                                                               |
| Record       | SObject            | The first record found, or blank when nothing matches.                                                                                   |
| Query String | Text               | The query, with this interview's values filled in, for Flow Builder's debug panel. The action binds values instead of running this text. |

The [Nebula Logger plugin](./Plugin:-Nebula-Logger), or any other [SOQL plugin](./Plugin:-Soql.PreAndPostProcessor), logs each query the action runs.

---

## Bulk Behavior

When many flow interviews run the action at once (ex: a record-triggered flow on a 200-record update), Flow passes every interview to the action in one call. Like Get Records, the action runs one query for them where it can, then gives each interview its own rows:

1. Interviews with the same query, access level, and values share one query.
2. Other interviews share one merged query that matches any of their values. Apex then checks each row against each interview's conditions. A condition whose values differ between interviews widens in the merged query:

    | Operator                                                                                    | Merged query                                                                                           |
    | ------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
    | Equals, In, Contains, Starts With, Ends With, Like                                          | Matches any interview's values                                                                         |
    | Greater Than, Less Than, and their Or Equal forms, on numbers, dates, date/times, and times | Reads past the loosest value, ex: the earliest date, or leaves the condition out when a value is blank |
    | Does Not Equal, Not In, Is Null                                                             | Leaves the condition out                                                                               |

    A condition whose value is the same for every interview stays in the merged query. Apex also checks it when a row could pass without it, ex: under **Any Condition Is Met (OR)**.

3. An interview runs its own query when Apex can't check one of its values: a Like pattern with a wildcard in its middle, ex: `A%e`. So does a blank value on a range, Contains, Starts With, Ends With, or Like that every interview shares, under OR or `NOT`, since SOQL treats such a blank as false under `NOT`.
4. Every interview runs its own query when any of these is true:

    - A condition whose values differ is under `NOT` in custom logic, which would narrow the rows instead of widening them.
    - Apex would have to check a condition it can't: a date literal, Includes, Excludes, a range on text, a multi-select picklist, or a currency field in an org with several currencies. Apex never has to when every interview has the same value and every row must pass the condition, as with **All Conditions Are Met (AND)**.
    - **Rows** is For Update, and the merged query would read rows no interview asked for, since it locks every row it reads. For Update merges only when one condition's values differ, it's Equals or In, and there's no limit, or it's Equals on the record's ID, which finds one row at most, with any limit.

Apex compares values the way SOQL does: text ignores case, except on case-sensitive fields, and a blank matches blank fields. Like Get Records, it ignores case the same way in every locale, where SOQL follows the running user's. For a few letters, ex: the Turkish `İ` and `ı`, or the Greek `ς`, a merged query can miss rows a lone query finds, or for Does Not Equal and Not In, keep rows it leaves out.

The limit and offset apply to each interview's rows after the split. A merged query reads every row any interview could need, as Get Records does. When several conditions vary, it also reads their combinations, ex: rows with one contact's account and another contact's title, which no interview needs. A limit of 1 over accounts with thousands of contacts each, a range on a large table, a Does Not Equal on a field other than the ID with no other condition, or a common combination can reach SOQL's 50,000-row limit.

When the only conditions whose values differ are Does Not Equal or Not In on the record's ID, the merged query keeps a limit: the limit and offset, plus the most IDs any interview excludes. Each ID excludes one row at most, so every interview still finds its rows.

For example, in a record-triggered flow on Contact:

| Conditions                                                                                                          | Queries for 200 contacts                                                                         |
| ------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| Account ID Equals {!$Record.AccountId}                                                                              | 1: `AccountId = :accountIds`, a list with a blank among them                                     |
| The same, with a limit of 1                                                                                         | 1: the merged query, then the first row for each contact                                         |
| Contact ID Does Not Equal {!$Record.Id}, with a limit of 1                                                          | 1: reads 2 rows, then gives each contact the first that isn't its own                            |
| Account ID Equals {!$Record.AccountId}, and Contact ID Does Not Equal {!$Record.Id}                                 | 1: the query leaves out Does Not Equal, and Apex drops each contact's own row                    |
| Account ID Equals {!$Record.AccountId} OR Title Equals {!$Record.Title}                                             | 1: matches any contact's account or title                                                        |
| Birthdate Greater Than {!$Record.Birthdate}                                                                         | 1: reads past the earliest birthdate                                                             |
| Account ID Equals {!$Record.AccountId}, and Birthdate Greater Than {!$Record.Birthdate}, with some birthdates blank | 1: a blank birthdate matches every record, so the query leaves out the range, and Apex checks it |
| NOT (Title Equals {!$Record.Title})                                                                                 | 1 per distinct title, which past 100 exceeds the synchronous limit                               |

Each distinct query counts against the transaction's SOQL limit: 100 queries in a synchronous transaction, 200 in an asynchronous one. A batch that can't merge can exceed it, which fails every interview in the batch.

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
