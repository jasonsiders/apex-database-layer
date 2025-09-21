The `Cmdt` class provides a repository-based approach to retrieving Custom Metadata Type (CMDT) records within the Salesforce platform.

This class abstracts direct access to Custom Metadata Type records by providing a consistent, testable interface. It supports both real and mock CMDT record retrieval through a simplified repository pattern.

Acting as a centralized access point for CMDT operations, the class promotes separation of concerns and enables comprehensive testing through the [`MockCmdt`](./The-MockCmdt-Class) framework.

```apex
// Retrieve all records of a specific CMDT type
List<MySetting__mdt> allSettings = (List<MySetting__mdt>) DatabaseLayer.Cmdt.ofType(MySetting__mdt.SObjectType)
  ?.getAll();

// Retrieve a specific record by developer name
MySetting__mdt specificSetting = (MySetting__mdt) DatabaseLayer.Cmdt.ofType(MySetting__mdt.SObjectType)
  ?.getInstance('Default');
```

In test contexts, you can easily switch to mock behavior:

```apex
DatabaseLayer.useMocks();
MySetting__mdt mockSetting = new MySetting__mdt(DeveloperName = 'Test_Setting');
MockCmdt.mock(MySetting__mdt.SObjectType).add(mockSetting);

// This will now return the mock record
MySetting__mdt result = (MySetting__mdt) DatabaseLayer.Cmdt.ofType(MySetting__mdt.SObjectType)
  ?.getInstance('Test_Setting');
```

The class automatically handles namespace-aware record retrieval, ensuring compatibility with both managed and unmanaged packages. It uses a single [`Repository`](./The-Cmdt.Repository-Class) implementation that selects only non-long-text fields because queries on Custom Metadata Type records bypass SOQL governor limits unless they include long-text fields.

If you need to access long-text fields, you can either write a normal SOQL query or use a custom `Cmdt.Repository` implementation via the `withRepository()` method.

---

## Methods

### `ofType`

Gets or creates a [`Repository`](./The-Cmdt.Repository-Class) for the specified Custom Metadata Type. The repository provides methods to retrieve all records or specific records by developer name.

- `Cmdt.Repository ofType(SObjectType cmdtType)`
