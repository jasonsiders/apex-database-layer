The `Soql.WhenClause` class is a builder for WHEN clauses in TYPEOF queries. This class is returned by the [`Soql.TypeOf.when()`](./The-Soql.TypeOf-Class#when) method and provides fluent methods for specifying which fields to select for a particular SObjectType.

This class is designed to be used in a fluent builder pattern, where you specify the SObjectType with `when()` and then chain `thenSelect()` to define the fields to select for that type.

---

## Methods

### `thenSelect`

Specifies the fields to select for this WHEN clause. Multiple overloads are available to support different numbers of SObjectFields.

- `Soql.TypeOf thenSelect(SObjectField field)`
- `Soql.TypeOf thenSelect(SObjectField field1, SObjectField field2)`
- `Soql.TypeOf thenSelect(SObjectField field1, SObjectField field2, SObjectField field3)`
- `Soql.TypeOf thenSelect(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4)`
- `Soql.TypeOf thenSelect(SObjectField field1, SObjectField field2, SObjectField field3, SObjectField field4, SObjectField field5)`
- `Soql.TypeOf thenSelect(List<SObjectField> fields)`

All `thenSelect()` methods return the parent [`Soql.TypeOf`](./The-Soql.TypeOf-Class) instance, allowing for continued method chaining.

---

## Example Usage

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
        .thenSelect(Account.Name, Account.Phone, Account.Type);
```

### Using List of Fields

```apex
List<SObjectField> accountFields = new List<SObjectField>{
    Account.Name,
    Account.Phone,
    Account.Type,
    Account.Industry
};

Soql.TypeOf typeOfClause = new Soql.TypeOf(Task.WhatId)
    .when(Account.SObjectType)
        .thenSelect(accountFields);
```

### Chaining Multiple WHEN Clauses

```apex
Soql.TypeOf typeOfClause = new Soql.TypeOf(Task.WhatId)
    .when(Account.SObjectType)
        .thenSelect(Account.Name, Account.Phone)
    .when(Opportunity.SObjectType)
        .thenSelect(Opportunity.Name, Opportunity.StageName)
    .when(Case.SObjectType)
        .thenSelect(Case.Subject, Case.Status);
```

### Complete TYPEOF Query Example

```apex
Soql.TypeOf typeOfClause = new Soql.TypeOf(Task.WhatId)
    .when(Account.SObjectType)
        .thenSelect(Account.Name, Account.Phone)
    .when(Opportunity.SObjectType)
        .thenSelect(Opportunity.Name, Opportunity.StageName, Opportunity.Amount)
    .elseSelect('Name');

Soql soql = DatabaseLayer.Soql.newQuery(Task.SObjectType)
    .addSelect(Task.Subject)
    .addSelect(typeOfClause)
    .toSoql();
```

This generates:

```sql
SELECT Id, Subject, TYPEOF WhatId
    WHEN Account THEN Name, Phone
    WHEN Opportunity THEN Name, StageName, Amount
    ELSE Name
END
FROM Task
```

---

## Notes

- The `WhenClause` class is designed for method chaining and should not be stored in variables
- All `thenSelect()` methods filter out `null` values automatically
- The class supports up to 5 individual SObjectField parameters, or unlimited fields via the `List<SObjectField>` overload
- After calling `thenSelect()`, you can continue chaining with additional `when()` clauses or an `elseSelect()` clause
