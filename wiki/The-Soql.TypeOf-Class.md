The `Soql.TypeOf` class is designed to facilitate the construction of TYPEOF clauses for polymorphic field queries in SOQL. This class allows developers to query polymorphic relationships and handle different object types within a single query.

This class implements the [`Soql.Selectable`](./The-Soql.Selectable-Interface) interface, making it compatible with the fluent builder pattern used throughout the SOQL framework.

---

## Constructors

### `TypeOf(String relationshipName)`

Creates a new TypeOf instance with a relationship name.

**Parameters:**

- `relationshipName` - The polymorphic field name to query

**Example:**

```apex
Soql.TypeOf typeOfClause = new Soql.TypeOf('What');
```

### `TypeOf(SObjectField field)`

Creates a new TypeOf instance with an SObjectField.

**Parameters:**

- `field` - The polymorphic SObjectField to query

**Example:**

```apex
Soql.TypeOf typeOfClause = new Soql.TypeOf(Task.WhatId);
```

### `TypeOf(Soql.ParentField field)`

Creates a new TypeOf instance with a parent field.

**Parameters:**

- `field` - The polymorphic parent field to query

**Example:**

```apex
Soql.ParentField whatField = new Soql.ParentField('What');
Soql.TypeOf typeOfClause = new Soql.TypeOf(whatField);
```

---

## Methods

### `when`

Adds a WHEN clause and returns a builder for specifying fields.

**Signature:**

- `Soql.WhenClause when(SObjectType objectType)`

**Parameters:**

- `objectType` - The SObjectType to match in the WHEN clause

**Returns:**

- A [`Soql.WhenClause`](./The-Soql.WhenClause-Class) builder for specifying the fields to select

**Example:**

```apex
Soql.TypeOf typeOfClause = new Soql.TypeOf(Task.WhatId)
    .when(Account.SObjectType)
        .thenSelect(Account.Name, Account.Phone);
```

### `elseSelect`

Adds an ELSE clause with field names to select when no WHEN conditions match.

**Signatures:**

- `Soql.TypeOf elseSelect(List<String> fieldNames)`
- `Soql.TypeOf elseSelect(String fieldName)`
- `Soql.TypeOf elseSelect(String field1, String field2)`
- `Soql.TypeOf elseSelect(String field1, String field2, String field3)`
- `Soql.TypeOf elseSelect(String field1, String field2, String field3, String field4)`
- `Soql.TypeOf elseSelect(String field1, String field2, String field3, String field4, String field5)`

**Parameters:**

- `fieldNames` - List of field names to select in the ELSE clause
- `fieldName` - Single field name to select
- `field1`, `field2`, etc. - Individual field names (null values are filtered out)

**Returns:**

- This TypeOf instance for method chaining

**Examples:**

```apex
// Single field
typeOfClause.elseSelect('Name');

// Multiple fields
typeOfClause.elseSelect('Name', 'Id');

// List of fields
typeOfClause.elseSelect(new List<String>{'Name', 'CreatedDate'});
```

---

## Usage Examples

### Basic TYPEOF Query

```apex
Soql.TypeOf typeOfClause = new Soql.TypeOf(Task.WhatId)
    .when(Account.SObjectType)
        .thenSelect(Account.Name, Account.Phone)
    .when(Opportunity.SObjectType)
        .thenSelect(Opportunity.Name, Opportunity.StageName)
    .elseSelect('Name');

Soql soql = DatabaseLayer.Soql.newQuery(Task.SObjectType)
    .addSelect(typeOfClause)
    .toSoql();
```

### Complex TYPEOF with Multiple WHEN Clauses

```apex
Soql.TypeOf typeOfClause = new Soql.TypeOf(Event.WhatId)
    .when(Account.SObjectType)
        .thenSelect(Account.Name, Account.Type, Account.Industry)
    .when(Contact.SObjectType)
        .thenSelect(Contact.FirstName, Contact.LastName, Contact.Email)
    .when(Lead.SObjectType)
        .thenSelect(Lead.Name, Lead.Company, Lead.Status)
    .elseSelect('Name', 'Id');

List<Event> events = DatabaseLayer.Soql.newQuery(Event.SObjectType)
    .addSelect(typeOfClause)
    .addSelect(Event.Subject, Event.StartDateTime)
    .query();
```

---

## Related Classes

- [`Soql.WhenClause`](./The-Soql.WhenClause-Class) - Builder for WHEN clause construction
- [`Soql.Selectable`](./The-Soql.Selectable-Interface) - Interface implemented by this class
- [`Soql.Builder`](./The-Soql.Builder-Class) - Main query builder that uses TypeOf clauses
- [`Soql.ParentField`](./The-Soql.ParentField-Class) - For polymorphic parent field references
