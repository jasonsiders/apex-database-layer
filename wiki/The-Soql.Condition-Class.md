Represents a single `WHERE` clause element. For example, `WHERE StageName = 'Closed Won'`.

```apex
Soql.Condition condition = new Soql.Condition(
  Opportunity.StageName,
  Soql.Operator.EQUALS,
  'Closed Won'
);
```

Add `Soql.Condition` objects to an existing where via the `addWhere` method. When multiple conditions are present, the query will use `AND` logic to specify that all conditions must be true by default:

```apex
// SELECT Id FROM Opportunity WHERE StageName = 'Closed Won' AND Amount > 1000000
Soql.Condition isClosedWon = new Soql.Condition(
  Opportunity.StageName,
  Soql.Operator.EQUALS,
  'Closed Won'
);
Soql.Condition worthAMil = new Soql.Condition(
  Opportunity.Amount,
  Soql.Operator.GREATER_THAN,
  1000000
);
Soql query = DatabaseLayer.Soql.newQuery(Opportunity.SObjectType)
  ?.addWhere(isClosedWon)
  ?.addWhere(worthAMil)
  ?.toSoql();
```

To use `OR` logic instead, use the [setOuterWhereLogic](./The-Soql.Builder-Class#setOuterWhereLogic) builder method. To use complex or nested logic, use the [Soql.ConditionalLogic](./The-Soql.ConditionalLogic-Class) class.

Like `Soql.ConditionalLogic`, the `Soql.Conditional` class implements [Soql.Criteria](./The-Soql.Criteria-Interface) interface, which the framework uses internally to keep things tidy.

---

## Constructors

- `Soql.Condition(String property, Soql.Operator operator, Object value)`
- `Soql.Condition(SObjectField field, Soql.Operator operator, Object value)`
- `Soql.Condition(Soql.ParentField field, Soql.Operator operator, Object value)`
