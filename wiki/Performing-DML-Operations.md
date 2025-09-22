Performing DML using `apex-database-layer` is simple!

[DatabaseLayer.Dml](./The-Dml-Class) wraps the standard `Database` class, and has 1:1 parity with its DML [methods](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_methods_system_database.htm).

To leverage the framework, simply use the `DatabaseLayer.Dml` equivalent of any `Database` DML method. In most cases, this means prefixing each method with "do" - since `insert`, `update`, etc. are reserved keywords in apex:

```apex
// Don't use these standard Database methods or DML keywords:
insert account;
Database.insert(account);
Database.insert(account, false);
Database.insert(account, false, System.AccessLevel.SYSTEM_MODE);
// Use the DatabaseLayer.Dml equivalent:
DatabaseLayer.Dml.doInsert(account);
DatabaseLayer.Dml.doInsert(account, false);
DatabaseLayer.Dml.doInsert(account, false, System.AccessLevel.SYSTEM_MODE);
```

---

## Why?

We recommend using `DatabaseLayer.Dml` instead of `Database` methods or standard DML keywords across your entire codebase. This practice has the following benefits:

- Easily [mock DML operations](./Mocking-DML-Operations) in tests, usually with just a single line of code!
- Enables [plugin functionality](./Plugin:-Dml.PreAndPostProcessor), which optionally runs logic before/after each DML operation (for example, logging).
