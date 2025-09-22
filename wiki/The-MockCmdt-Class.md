The `MockCmdt` class enables comprehensive mocking of Custom Metadata Type (CMDT) records in test contexts within the Salesforce platform.

This class provides the ability to independently mock different CMDT types, allowing for isolated and controlled testing scenarios. It integrates seamlessly with the [`Cmdt`](./The-Cmdt-Class) class to provide a consistent testing experience when working with Custom Metadata Types.

When `DatabaseLayer.useMocks()` is called, the `Cmdt` class automatically uses `MockCmdt` behavior instead of retrieving actual Custom Metadata Type records from the organization.

```apex
@IsTest
static void testCustomMetadataRetrieval() {
    // Create mock records
    MySetting__mdt mockSetting1 = new MySetting__mdt(
        DeveloperName = 'Setting_One',
        MasterLabel = 'Setting One',
        Value__c = 'Test Value 1'
    );

    // Set up the mock repository and add records
    MockCmdt.mock(MySetting__mdt.SObjectType)?.add(mockSetting1);

    // Test the functionality
    MySetting__mdt specificSetting = (MySetting__mdt) DatabaseLayer.Cmdt
        ?.ofType(MySetting__mdt.SObjectType)
        ?.getInstance('Setting_One');

    Assert.areEqual('Test Value 1', specificSetting.Value__c, 'Should return correct mock record');
}
```

Each Custom Metadata Type can be mocked independently. This allows for complex test scenarios where different CMDT types need different mock data:

```apex
@IsTest
static void testMultipleCmdtTypes() {
    DatabaseLayer.useMocks();

    // Mock different CMDT types independently
    MySetting__mdt testSetting = new MySetting__mdt(DeveloperName = 'Test_Setting');
    MockCmdt.mock(MySetting__mdt.SObjectType)?.add(testSetting);

    MockCmdt.mock(AnotherSetting__mdt.SObjectType)?.clear(); // No records

    // Each type behaves according to its own mock configuration
    List<MySetting__mdt> settings = (List<MySetting__mdt>) DatabaseLayer.Cmdt
        ?.ofType(MySetting__mdt.SObjectType)
        ?.getAll();
    List<AnotherSetting__mdt> otherSettings = (List<AnotherSetting__mdt>) DatabaseLayer.Cmdt
        ?.ofType(AnotherSetting__mdt.SObjectType)
        ?.getAll();

    Assert.areEqual(1, settings.size(), 'Should return 1 mock record');
    Assert.areEqual(0, otherSettings.size(), 'Should return no records');
}
```

The `MockCmdt` class is only available in test contexts (`@IsTest`). Attempting to use it in non-test code will result in compilation errors, ensuring that mock behavior is isolated to testing scenarios.

---

## Methods

### `mock`

Creates and configures a [MockCmdt.Repository](./The-MockCmdt.Repository-Class) for the specified Custom Metadata Type. This allows mocking CMDT records in tests without database operations.

- `static MockCmdt.Repository mock(SObjectType objectType)`

### `reset`

Removes an SObjectType from the list of repositories. Subsuquent calls to the `ofType` method will re-run the retrieval logic for that object type.

- `static void reset(SObjectType objectType)`
