Defines the enclosing logic for the [Soql.ConditionalLogic](./The-Soql.ConditionalLogic-Class) objects used in `WHERE` or `HAVING` clauses.

Use in the [setOuterWhereLogic](./The-Soql.Builder-Class#setOuterWhereLogic) or [setOuterHavingLogic](./The-Soql.Builder-Class#setOuterHavingLogic) builder methods:

```apex
Soql soql = DatabaseLayer.Soql.newQuery(User.SObjectType)
  ?.addWhere(User.IsActive, Soql.EQUALS, true)
  ?.addWhere(
    new Soql.ParentField(User.ProfileId, Profile.Name),
    Soql.EQUALS,
    'System Administrator'
  )
  ?.setOuterWhereLogic(Soql.LogicType.ANY_CONDITIONS)
  ?.toSoql();
```

When `setOuterWhereLogic(Soql.LogicType.ANY_CONDITIONS)` is used, any new criterion added to the query via the [addWhere](./The-Soql.Builder-Class#addWhere) method will be added with an `OR` keyword:

```apex
// SELECT Id FROM Opportunity WHERE StageName = 'Closed Won' OR Amount > 1000000
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
Soql soql = DatabaseLayer.Soql.newQuery(Opportunity.SObjectType)
  ?.setOuterWhereLogic(Soql.LogicType.ANY_CONDITIONS)
  ?.setWhere(isClosedWon)
  ?.setWhere(worthAMil)
  ?.toSoql();
```

---

## Values

- `ALL_CONDITIONS`
- `ANY_CONDITIONS`
