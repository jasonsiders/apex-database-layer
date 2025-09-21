Enumerates the different [Aggregate Functions](https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql_select_agg_functions.htm) that can be used in SOQL queries. Use this enum when constructing [Soql.Aggregation](./The-Soql.Aggregation-Class) objects.

```apex
Soql.Aggregation count = new Soql.Aggregation(Soql.Function.COUNT, User.Id);
Soql query = DatabaseLayer.Soql.newQuery(User.SObjectType)
  ?.addSelect(count)
  ?.toSoql();
```

---

## Values

- `AVG`,
- `CALENDAR_MONTH`,
- `CALENDAR_QUARTER`,
- `CALENDAR_YEAR`,
- `COUNT`,
- `COUNT_DISTINCT`,
- `DAY_IN_MONTH`,
- `DAY_IN_WEEK`,
- `DAY_IN_YEAR`,
- `DAY_ONLY`,
- `FISCAL_MONTH`,
- `FISCAL_QUARTER`,
- `FISCAL_YEAR`,
- `FORMAT`,
- `HOUR_IN_DAY`,
- `MIN`,
- `MAX`,
- `SUM`,
- `WEEK_IN_MONTH`,
- `WEEK_IN_YEAR`
