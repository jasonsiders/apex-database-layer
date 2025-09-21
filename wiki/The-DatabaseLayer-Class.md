The `DatabaseLayer` class serves as a centralized access point for all DML and SOQL operations within the application. It simplifies and standardizes how database interactions are performed and tested.

It abstracts direct access to the Salesforce database by exposing the static properties `DatabaseLayer.Dml`, `DatabaseLayer.Soql`, and `DatabaseLayer.Cmdt`. Callers can use these properties to perform operations without tightly coupling their logic to platform-specific implementations.

Acting as a pseudo-namespace, the class organizes all database-related logic under a single, consistent API, promoting separation of concerns and reducing duplication across the codebase.

Developers can easily switch between real and mock implementations of database logic with a single line of code: `DatabaseLayer.useMocks()`. The framework internally tracks whether real or mock logic should be used and automatically provisions the appropriate instance, allowing for a seamless testing experience.

```apex
// Perform real database operations!
List<Account> accounts = (List<Account>) DatabaseLayer.Soql.newQuery(Account.SObjectType)
  ?.addSelect(Account.OwnerId)
  ?.addOrderBy(Account.CreatedDate, Soql.SortDirection.DESCENDING)
  ?.setRowLimit(1)
  ?.toSoql()
  ?.query();
Account firstAccount = accounts?.get(0);
firstAccount.OwnerId = UserInfo.getUserId();
DatabaseLayer.Dml.doUpdate(firstAccount);
```

```apex
// Perform mock database operations
DatabaseLayer.useMocks();
Account mockAccount = (Account) new MockRecord(Account.SObjectType)?.withId()?.toSObject();
// Query Mocking:
MockSoql.setGlobalMock().withResults(new List<Account>{ mockAccount });
List<Account> accounts = (List<Account>) DatabaseLayer.Soql.newQuery(Account.SObjectType)?.query();
Assert.areEqual(0, Limits.getQueries(), 'Used real SOQL');
Assert.areEqual(1, accounts?.size(), 'Wrong # of Accounts returned');
// DML Mocking:
Account firstAccount = accounts?.get(0);
firstAccount.OwnerId = UserInfo.getUserId();
DatabaseLayer.Dml.doUpdate(firstAccount);
Assert.isTrue(MockDml.UPDATED.wasProcessed(firstAccount), 'Was not updated');
Assert.areEqual(0, Limits.getDmlStatements(), 'Used real DML');
```

---

## Properties

<table>
  <thead>
    <tr>
      <th>Property</th>
      <th>Data Type</th>
      <th>Details</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Dml</td>
      <td>Dml</td>
      <td>Getter returns the current <code>Dml</code> instance. For normal database operations, this is a <a href="./The-Dml-Class">Dml</a> object. For mock database operations, this is a <a href="./The-MockDml-Class">MockDml</a> object.</td>
    </tr>
    <tr>
      <td>Soql</td>
      <td>Soql</td>
      <td>Provisions a new <code>Soql</code> object of the correct type. For normal database operations, this is a <a href="./The-Soql-Class">Soql</a> object. For mock database operations, this is a <a href="./The-MockSoql-Class">MockSoql</a> object.</td>
    </tr>
    <tr>
      <td>Cmdt</td>
      <td>Cmdt</td>
      <td>Provides access to Custom Metadata Type records through repository-based access. Returns a <a href="./The-Cmdt-Class">Cmdt</a> object that can be used to retrieve CMDT records with intelligent caching and mock support.</td>
    </tr>
  </tbody>
</table>

---

## Methods

### `useMocks`

Configures the framework to use Mock DML and Mock SOQL operations, instead of interacting with the actual Salesforce database. Once this is called, `DatabaseLayer.Dml` will return a `MockDml` object; `Database.Soql.newQuery` will return a `MockSoql` object. This static method is only visible in the `@IsTest` context.

- `static void useMocks()`

### `useMockDml`

Configures the framework to use Mock DML operations, instead of interacting with the actual Salesforce database. Once this is called, `DatabaseLayer.Dml` will return a `MockDml` object. This static method is only visible in the `@IsTest` context.

- `static void useMockDml()`

### `useMockSoql`

Configures the framework to use Mock SOQL operations, instead of interacting with the actual Salesforce database. Once this is called, `Database.Soql.newQuery` will return a `MockSoql` object.

This static method is only visible in the `@IsTest` context.

- `static void useMocks()`

### `useRealData`

Configures the framework to use real DML & SOQL operations that interact with the actual Salesforce database, instead of mocks.
This is the default state of the application; there is no need to call it unless some variation of `DatabaseLayer.useMocks()` was called earlier in the transaction. Once this is called, `DatabaseLayer.Dml` will return a `Dml` object; `Database.Soql.newQuery` will return a `Soql` object.

This static method is only visible in the `@IsTest` context.

- `static void useRealData()`

### `useRealDml`

Configures the framework to use real DML operations that interact with the actual Salesforce database, instead of mocks.
This is the default state of the application; there is no need to call it unless `DatabaseLayer.useMocks()` or `DatabaseLayer.useMockDml()` was called earlier in the transaction. Once this is called, `DatabaseLayer.Dml` will return a `Dml` object.

This static method is only visible in the `@IsTest` context.

- `static void useRealDml()`

### `useRealSoql`

Configures the framework to use real SOQL operations that interact with the actual Salesforce database, instead of mocks.
This is the default state of the application; there is no need to call it unless `DatabaseLayer.useMocks()` or `DatabaseLayer.useMockSoql()` was called earlier in the transaction. Once this is called, `Database.Soql.newQuery` will return a `Soql` object.

This static method is only visible in the `@IsTest` context.

- `static void useRealSoql()`
