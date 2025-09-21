Enumerates possible values to be used with the optional [_USING SCOPE_](https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql_select_using_scope.htm) SOQL clause.

Use this in conjunction with the [setScope](./The-Soql.Builder-Class#setScope) builder method:

```apex
Soql query = DatabaseLayer.Soql.newQuery(User.SObjectType)
  ?.setScope(Soql.Scope.EVERYTHING)
  ?.toSoql();
```

---

## Values

- `DELEGATED`
- `EVERYTHING`
- `MINE`
- `MINE_AND_MY_GROUPS`
- `MY_TERRITORY`
- `MY_TEAM_TERRITORY`
- `TEAM`
