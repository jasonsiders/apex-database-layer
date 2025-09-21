Object used to represent the operator token in SOQL `WHERE` and `HAVING` clauses. The framework uses this to format these clauses.

All possible values are enumerates as `public static final` properties on the [Soql](./The-Soql-Class) class. This enables developers to interact with this class as if it were an enum of sorts:

```apex
Soql query = DatabaseLayer.Soql.newQuery(User.SObjectType)
  ?.addWhere(field, Soql.EQUALS, 'System Administrator')
  ?.toSoql();
```

---

## Values

<table>
  <thead>
    <tr>
      <th>Property</th>
      <th>Operator</th>
    </tr>
  </thead>
  <tbody>
    <tr><td><code>Soql.EQUALS</code></td><td>=</td></tr>
    <tr><td><code>Soql.NOT_EQUALS</code></td><td>!=</td></tr>
    <tr><td><code>Soql.IN_COLLECTION</code></td><td>IN</td></tr>
    <tr><td><code>Soql.NOT_IN_COLLECTION</code></td><td>NOT IN</td></tr>
    <tr><td><code>Soql.GREATER_THAN</code></td><td>&gt;</td></tr>
    <tr><td><code>Soql.GREATER_OR_EQUAL</code></td><td>&gt;=</td></tr>
    <tr><td><code>Soql.LESS_THAN</code></td><td>&lt;</td></tr>
    <tr><td><code>Soql.LESS_OR_EQUAL</code></td><td>&lt;=</td></tr>
    <tr><td><code>Soql.STARTS_WITH</code></td><td>LIKE</td></tr>
    <tr><td><code>Soql.NOT_STARTS_WITH</code></td><td>NOT LIKE</td></tr>
    <tr><td><code>Soql.ENDS_WITH</code></td><td>LIKE</td></tr>
    <tr><td><code>Soql.NOT_ENDS_WITH</code></td><td>NOT LIKE</td></tr>
    <tr><td><code>Soql.CONTAINS</code></td><td>LIKE</td></tr>
    <tr><td><code>Soql.NOT_CONTAINS</code></td><td>NOT LIKE</td></tr>
  </tbody>
</table>
