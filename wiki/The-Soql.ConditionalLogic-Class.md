Represents a set of criterion to be added to a query. These criterion can be [Soql.Condition](./The-Soql.Condition-Class) objects, or other (nested) `Soql.ConditionalLogic` objects. Depending on the specified `Soql.LogicType`, these conditions are be delimited by `AND` or `OR` keywords.

This pattern facilitates building complex query logic, like the this contrived example:

```sql
SELECT Id
FROM Opportunity
WHERE (
  IsWon = true
  OR (
    Amount > 1000000
    AND (
      CloseDate >= 2024-01-01
      OR (
        Account.BillingState = 'CA'
        AND Amount > 20000000
      )
    )
  )
)
```

```apex
// (Account.BillingState = 'CA' AND Amount > 2000000)
Soql.Condition fromCa = new Soql.Condition(
  'Account.BillingState',
  Soql.Operator.EQUALS,
  'CA'
);
Soql.Condition greaterThan2Mil = new Soql.Condition(
  Opportunity.Amount,
  Soql.Operator.GREATER_THAN,
  2000000
);
Soql.ConditionalLogic nest1 = new Soql.ConditionalLogic()
  ?.addCondition(fromCa)
  ?.addCondition(greaterThan2Mil);
// (CloseDate >= 2024-01-01 OR (...))
Soql.Condition closedThisYear = new Soql.Condition(
  Opportunity.CloseDate,
  Soql.Operator.GREATER_OR_EQUAL,
  Date.newInstance(2024, 01, 01)
);
Soql.ConditionalLogic nest2 = new Soql.ConditionalLogic()
  ?.addCondition(closedThisYear)
  ?.addCondition(nest1)
  ?.setLogicType(Soql.LogicType.ANY_CONDITIONS);
// (Amount > 1000000 AND (...))
Soql.Condition greaterThan1Mil = new Soql.Condition(
  Opportunity.Amount,
  Soql.Operator.GREATER_THAN,
  1000000
);
Soql.ConditionalLogic nest3 = new Soql.ConditionalLogic()
  ?.addCondition(greaterThan1Mil)
  ?.addCondition(nest2);
// IsWon = true OR (...)
Soql.Condition isWon = new Soql.Condition(
  Opportunity.IsWon,
  Soql.Operator.EQUALS,
  true
);
Soql soql = DatabaseLayer.Soql
  ?.newQuery(Opportunity.SObjectType)
  ?.setOuterWhereLogic(Soql.LogicType.ANY_CONDITIONS)
  ?.setWhere(isWon)
  ?.setWhere(nest3)
  ?.toSoql();
```

By default, the `Soql` class uses an internal `Soql.ConditionalLogic` object as the "enclosing" logic for `WHERE` and `HAVING` clauses. Calls to the `addWhere` or `addHaving` Soql methods add the criterion to the appropriate `Soql.ConditionalLogic` object under the hood. Calling the [setOuterWhereLogic](./The-Soql.Builder-Class#setOuterWhereLogic) and [setOuterHavingLogic](./The-Soql.Builder-Class#setOuterHavingLogic) builder methods change the appropriate object's [Soql.LogicType](./The-Soql.LogicType-Enum).

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

Like `Soql.Condition`, the `Soql.ConditionalLogic` class implements [`Soql.Criteria`](./The-Soql.Criteria-Interface), which the framework uses internally to keep things tidy.

---

## Methods

### `addCondition`

Adds a `Soql.Criteria` object (`Soql.Condition` or another `Soql.ConditionalLogic` object(s)) to the current list of criterion.

- `Soql.ConditionalLogic addCondition(List<Soql.Criteria> criterion)`
- `Soql.ConditionalLogic addCondition(Soql.Criteria criteria)`
- `Soql.ConditionalLogic addCondition(String fieldName, Soql.Operator operator, Object value)`
- `Soql.ConditionalLogic addCondition(SObjectField field, Soql.Operator operator, Object value)`
- `Soql.ConditionalLogic addCondition(Soql.ParentField field, Soql.Operator operator, Object value)`

### `setLogicType`

Determines the enclosing `Soql.LogicType` object. This affects the delimiter that will be applied to the `Soql.ConditionalLogic`'s criterion at runtime; `ANY_CONDITIONS` will produce an "OR" delimiter. `ALL_CONDITIONS` will produce an "AND" delimiter. By default, the `Soql.ConditionalLogic` uses `Soql.LogicType.ALL_CONDITIONS`; there is no need to set this explicitly in most cases except for changing this to use "OR" logic.

- `Soql.ConditionalLogic setLogicType(Soql.LogicType logicType)`
