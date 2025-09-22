The `Cmdt` class provides a repository-based approach to retrieving Custom Metadata Type (CMDT) records within the Salesforce platform.

This class abstracts direct access to Custom Metadata Type records by providing a consistent, testable interface. It supports both real and mock CMDT record retrieval, and implements intelligent caching for performance optimization.

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

The class implements intelligent caching based on the field types present in the Custom Metadata Type:

- **Records with Long Text Area fields**: Not cached due to potential memory constraints
- **Records without Long Text Area fields**: Cached for improved performance on subsequent retrievals

This caching strategy ensures optimal performance while avoiding potential memory issues with large text fields. The class also automatically handles namespace-aware record retrieval, ensuring compatibility with both managed and unmanaged packages.

---

## Methods

### `ofType`

Lazily generates a repository of custom metadata objects for the specified SObjectType. The repository provides methods to retrieve all records or specific records by developer name.

- `Cmdt.Repository ofType(SObjectType cmdtType)`
