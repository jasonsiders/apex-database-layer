The `Soql.TypeOf` class is used to construct TYPEOF clauses for polymorphic field queries in SOQL. This class implements the [`Soql.Selectable`](./The-Soql.Selectable-Interface) interface, allowing it to be used within SELECT clauses.

TYPEOF queries are used to query polymorphic relationships where a field can reference different SObject types. This is commonly used with fields like `Task.WhatId` or `Event.WhatId` that can point to Accounts, Opportunities, Cases, etc.

---

## Constructors

### `TypeOf(String fieldName)`

Creates a new TypeOf instance with the specified field name.

```apex
Soql.TypeOf typeOfClause = new Soql.TypeOf('WhatId');
```

### `TypeOf(SObjectField field)`

Creates a new TypeOf instance using an SObjectField reference.

```apex
Soql.TypeOf typeOfClause = new Soql.TypeOf(Task.WhatId);
```

### `TypeOf(Soql.ParentField field)`

Creates a new TypeOf instance using a parent field reference.

```apex
Soql.ParentField parentField = new Soql.ParentField(Task.WhatId, Account.Name);
Soql.TypeOf typeOfClause = new Soql.TypeOf(parentField);
```

---

## Methods

### `when`

Adds a WHEN clause for a specific SObjectType and returns a [`Soql.WhenClause`](./The-Soql.WhenClause-Class) builder for specifying fields to select.

- `Soql.WhenClause when(SObjectType objectType)`

```apex
Soql.TypeOf typeOfClause = new Soql.TypeOf(Task.WhatId)
    .when(Account.SObjectType)
        .thenSelect(Account.Name, Account.Phone)
    .when(Opportunity.SObjectType)
        .thenSelect(Opportunity.Name, Opportunity.StageName);
```

### `elseSelect`

Adds an ELSE clause to handle cases where the polymorphic field doesn't match any of the specified WHEN conditions. Since the SObjectType is unknown in ELSE clauses, only string field names are supported.

- `Soql.TypeOf elseSelect(String fieldName)`
- `Soql.TypeOf elseSelect(List<String> fieldNames)`
- `Soql.TypeOf elseSelect(String field1, String field2)`
- `Soql.TypeOf elseSelect(String field1, String field2, String field3)`
- `Soql.TypeOf elseSelect(String field1, String field2, String field3, String field4)`
- `Soql.TypeOf elseSelect(String field1, String field2, String field3, String field4, String field5)`

```apex
// Single field
typeOfClause.elseSelect('Name');

// Multiple fields
typeOfClause.elseSelect('Name', 'Type', 'Status');

// Using a list
typeOfClause.elseSelect(new List<String>{'Name', 'Description'});
```

### `toString`

Returns the formatted TYPEOF clause as a string for use in SOQL queries.

- `String toString()`

---

## Example Usage

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

List<Task> tasks = soql.query();
```

This generates the following SOQL:

```sql
SELECT Id, TYPEOF WhatId
    WHEN Account THEN Name, Phone
    WHEN Opportunity THEN Name, StageName
    ELSE Name
END
FROM Task
```

### TYPEOF Without ELSE Clause

```apex
Soql.TypeOf typeOfClause = new Soql.TypeOf(Task.WhatId)
    .when(Account.SObjectType)
        .thenSelect(Account.Name)
    .when(Contact.SObjectType)
        .thenSelect(Contact.FirstName, Contact.LastName);
```

This generates:

```sql
TYPEOF WhatId
    WHEN Account THEN Name
    WHEN Contact THEN FirstName, LastName
END
```

### Using with Different Field Types

```apex
// Using string field name
Soql.TypeOf typeOf1 = new Soql.TypeOf('WhatId');

// Using SObjectField
Soql.TypeOf typeOf2 = new Soql.TypeOf(Task.WhatId);

// Using parent field
Soql.ParentField parentField = new Soql.ParentField(Task.WhatId, Account.Name);
Soql.TypeOf typeOf3 = new Soql.TypeOf(parentField);
```
