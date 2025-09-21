Enumerates possible values to be used with various optional query suffixes.

Use this in conjunction with the [setUsage](./The-Soql.Builder-Class#setUsage) builder method:

```sql
SELECT Id FROM Account FOR UPDATE
```

```apex
Soql query = DatabaseLayer.Soql.newQuery(Account.SObjectType)
  ?.setUsage(Soql.Usage.FOR_UPDATE)
  ?.toSoql();
```

---

## Values

- `ALL_ROWS`
- `FOR_VIEW`
- `FOR_REFERENCE`
- `FOR_UPDATE`
