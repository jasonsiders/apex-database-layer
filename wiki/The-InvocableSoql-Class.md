The `InvocableSoql` class provides a Flow action that offers richer SOQL query support than the standard "Get Records" element. Unlike the standard element, this action accepts raw SOQL strings with named bind variables, enabling parent/child subqueries, complex ORDER BY clauses, and other constructs that the standard element cannot express.

To stay within SOQL governor limits when Flow processes a record collection, identical query templates are automatically grouped and their bind values are merged into a single IN-list query where possible, providing intelligent bulkification.

This class is designed to give Flow builders the full power of SOQL while maintaining optimal performance through automatic query optimization.

## Flow Action Method

### `invoke`

The main invocable method that executes SOQL queries with automatic bulkification for identical queries.

- **Signature:** `global static List<Output> invoke(List<Input> inputs)`
- **Parameters:** 
  - `inputs` - List of query inputs containing query strings and bind variables
- **Returns:** List of query outputs with results populated
- **Category:** Database Layer
- **Label:** SOQL Query
- **Icon:** slds:standard:record_lookup

**Example Usage in Flow:**

The action can be used in Salesforce Flow to execute complex SOQL queries that aren't possible with the standard "Get Records" element:

```apex
// This would be configured in Flow Builder UI, but conceptually:
// Input 1:
// query: "SELECT Id, Name FROM Account WHERE Type = :accountType ORDER BY Name"
// binds: [{ key: "accountType", textValue: "Customer", typeName: "String" }]

// Input 2: 
// query: "SELECT Id, Name FROM Account WHERE Type = :accountType ORDER BY Name"  
// binds: [{ key: "accountType", textValue: "Partner", typeName: "String" }]

// The action will automatically optimize these into a single query:
// "SELECT Id, Name FROM Account WHERE Type IN ('Customer', 'Partner') ORDER BY Name"
```

## Input Class

The `Input` class represents the input structure for SOQL queries with bind variables.

### Properties

#### `binds`

List of bind variables for the query.

- **Type:** `List<FlowUntypedVariable>`
- **Access:** `global`
- **Flow Label:** Bind Variables

#### `query`

The SOQL query string to execute.

- **Type:** `String`
- **Access:** `global`
- **Required:** `true`
- **Flow Label:** Query

### Constructors

#### `Input()`

Initializes a new Input with an empty binds list.

```apex
Input input = new Input();
// input.binds is automatically initialized as an empty list
```

## Output Class

The `Output` class represents the output structure for SOQL query results.

### Properties

#### `allResults`

All records returned by the query.

- **Type:** `List<SObject>`
- **Access:** `global`
- **Flow Label:** All Results

#### `binds`

The bind variables used in the query.

- **Type:** `List<FlowUntypedVariable>`
- **Access:** `global`  
- **Flow Label:** Bind Variables

#### `firstResult`

The first record from the query results, or null if no results.

- **Type:** `SObject`
- **Access:** `global`
- **Flow Label:** First Result

#### `query`

The rendered SOQL query string with bind variable placeholders.

- **Type:** `String`
- **Access:** `global`
- **Flow Label:** Query

### Constructors

#### `Output()`

Initializes a new Output with empty results and binds.

```apex
Output output = new Output();
// output.allResults and output.binds are automatically initialized as empty lists
```

## Bulkification Features

The `InvocableSoql` class includes sophisticated bulkification logic that automatically optimizes multiple queries:

### Query Grouping
Identical query templates are grouped together to reduce the total number of SOQL queries executed.

### IN-List Optimization
When multiple inputs use the same query template but differ only in a single equality bind value, the action merges them into one IN-list query and fans the results back out to the correct outputs.

### Conditions for Optimization
- Queries must have identical structure (same SELECT, FROM, WHERE template, ORDER BY, etc.)
- Only one equality condition can differ between inputs
- The differing condition must use a simple field (no relationship traversal)
- The condition must use a named bind variable

**Example of Automatic Optimization:**

```apex
// Input queries:
// Query 1: "SELECT Id, Name FROM Account WHERE Type = :type"  (type = 'Customer')
// Query 2: "SELECT Id, Name FROM Account WHERE Type = :type"  (type = 'Partner') 
// Query 3: "SELECT Id, Name FROM Account WHERE Type = :type"  (type = 'Vendor')

// Automatically optimized to:
// "SELECT Id, Name FROM Account WHERE Type IN ('Customer', 'Partner', 'Vendor')"

// Results are then distributed back to each original output based on the Type field value
```

This optimization significantly reduces SOQL query consumption when processing collections in Flow, helping stay within governor limits while maintaining the flexibility of raw SOQL.