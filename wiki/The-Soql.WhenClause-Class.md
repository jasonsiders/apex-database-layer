The `Soql.WhenClause` class is a builder for constructing WHEN clauses in TYPEOF queries. This class provides a fluent interface for specifying which fields to select when a particular SObjectType matches in a polymorphic field query.

This class is designed to work in conjunction with the [`Soql.TypeOf`](./The-Soql.TypeOf-Class) class and follows the builder pattern to enable method chaining.

---

## Constructor

### `WhenClause(Soql.TypeOf parent, SObjectType objectType)`

Creates a new WhenClause builder instance. This constructor is private and should not be called directly. Instead, use the `when()` method on a [`Soql.TypeOf`](./The-Soql.TypeOf-Class) instance.

**Parameters:**

- `parent` - The parent TypeOf instance
- `objectType` - The SObjectType for this WHEN clause

---

## Methods

### `thenSelect`

Specifies fields to select for this WHEN clause. All methods return the parent [`Soql.TypeOf`](./The-Soql.TypeOf-Class) instance to enable continued chaining.

**Signatures:**

- `Soql.TypeOf thenSelect(List<SObjectField> fields)`
- `Soql.TypeOf thenSelect(SObjectField field)`
- `Soql.TypeOf thenSelect(SObjectField field1, SObjectField field2)`
- `Soql.TypeOf thenSelect(SObjectField field1, SObjectField field2, SObjectField field3)`
- `Soql.TypeOf thenSelect(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4)`
- `Soql.TypeOf thenSelect(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5)`
- `Soql.TypeOf thenSelect(List<Soql.Selectable> fields)`
- `Soql.TypeOf thenSelect(Soql.Selectable field)`
- `Soql.TypeOf thenSelect(Soql.Selectable field1, Soql.Selectable field2)`
- `Soql.TypeOf thenSelect(Soql.Selectable field1, Soql.Selectable field2, Soql.Selectable field3)`
- `Soql.TypeOf thenSelect(Soql.Selectable field1, Soql.Selectable field2, Soql.Selectable field3, Soql.Selectable field4)`
- `Soql.TypeOf thenSelect(Soql.Selectable field1, Soql.Selectable field2, Soql.Selectable field3, Soql.Selectable field4, Soql.Selectable field5)`

**Parameters:**

- `fields` - List of SObjectFields or Soql.Selectables to select for this WHEN clause
- `field`, `field1`, `field2`, etc. - Individual SObjectFields or Soql.Selectables to select (null values are automatically filtered out)

**Returns:**

- The parent [`Soql.TypeOf`](./The-Soql.TypeOf-Class) instance for continued method chaining

**Features:**

- **Null Filtering**: Automatically filters out null SObjectField and Soql.Selectable values
- **Type Safety**: Ensures only valid SObjectFields and Soql.Selectables are included
- **Method Chaining**: Returns parent TypeOf for continued fluent interface usage
- **Polymorphic Support**: Accepts both SObjectFields and Soql.Selectables (including ParentFields, Aggregations, etc.)

---

## Usage Examples

### Single Field Selection

```apex
Soql.TypeOf typeOfClause = new Soql.TypeOf(Task.WhatId)
    .when(Account.SObjectType)
        .thenSelect(Account.Name);
```

### Multiple Field Selection

```apex
Soql.TypeOf typeOfClause = new Soql.TypeOf(Task.WhatId)
    .when(Account.SObjectType)
        .thenSelect(Account.Name, Account.Phone, Account.Industry);
```

### List-Based Selection

```apex
List<SObjectField> accountFields = new List<SObjectField>{
    Account.Name,
    Account.Phone,
    Account.Type,
    Account.Industry,
    Account.BillingCity
};

Soql.TypeOf typeOfClause = new Soql.TypeOf(Task.WhatId)
    .when(Account.SObjectType)
        .thenSelect(accountFields);
```

### Multiple WHEN Clauses

```apex
Soql.TypeOf typeOfClause = new Soql.TypeOf(Task.WhatId)
    .when(Account.SObjectType)
        .thenSelect(Account.Name, Account.Phone)
    .when(Opportunity.SObjectType)
        .thenSelect(Opportunity.Name, Opportunity.StageName, Opportunity.Amount)
    .when(Contact.SObjectType)
        .thenSelect(Contact.FirstName, Contact.LastName, Contact.Email)
    .elseSelect('Name');
```

### Using Soql.Selectable Objects

```apex
// Using ParentField (cross-object fields)
Soql.ParentField parentField = new Soql.ParentField(Account.OwnerId, User.Name);
Soql.TypeOf typeOfClause = new Soql.TypeOf(Task.WhatId)
    .when(Account.SObjectType)
        .thenSelect(parentField, Account.Phone);
```

### Mixed Field Types

```apex
// Combining SObjectFields and Soql.Selectables
Soql.ParentField ownerName = new Soql.ParentField(Account.OwnerId, User.Name);
List<Soql.Selectable> fields = new List<Soql.Selectable>{
    Account.Name,
    Account.Phone,
    ownerName
};

Soql.TypeOf typeOfClause = new Soql.TypeOf(Task.WhatId)
    .when(Account.SObjectType)
        .thenSelect(fields);
```

### Null Field Handling

```apex
// Null fields are automatically filtered out
SObjectField nullField = null;
Soql.Selectable nullSelectable = null;
Soql.TypeOf typeOfClause = new Soql.TypeOf(Task.WhatId)
    .when(Account.SObjectType)
        .thenSelect(Account.Name, nullField, Account.Phone, nullSelectable); // null values are ignored
```

---

## Design Pattern

The WhenClause class follows the **Builder Pattern** principles:

1. **Fluent Interface**: Method chaining enables readable query construction
2. **Immutable Operations**: Each method call returns the parent object for continued chaining
3. **Type Safety**: Strong typing with SObjectField and Soql.Selectable parameters prevents runtime errors
4. **Defensive Programming**: Automatic null filtering prevents invalid field references
5. **Polymorphic Field Support**: Accepts multiple field types through the Soql.Selectable interface

**Example of Fluent Chaining:**

```apex
// Using mixed SObjectField and Soql.Selectable types
Soql.ParentField accountOwnerName = new Soql.ParentField(Account.OwnerId, User.Name);
Soql soql = DatabaseLayer.Soql.newQuery(Task.SObjectType)
    .addSelect(
        new Soql.TypeOf(Task.WhatId)
            .when(Account.SObjectType)
                .thenSelect(Account.Name, Account.Phone, accountOwnerName)
            .when(Opportunity.SObjectType)
                .thenSelect(Opportunity.Name, Opportunity.StageName)
            .elseSelect('Name')
    )
    .addWhere(Task.Subject, Soql.NOT_EQUALS, null)
    .toSoql();
```

---

## Related Classes

- [`Soql.TypeOf`](./The-Soql.TypeOf-Class) - Parent class that creates WhenClause instances
- [`Soql.Builder`](./The-Soql.Builder-Class) - Main query builder that accepts TypeOf clauses
- [`Soql.Selectable`](./The-Soql.Selectable-Interface) - Interface implemented by TypeOf for builder compatibility
