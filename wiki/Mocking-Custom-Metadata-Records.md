Using `DatabaseLayer.Cmdt`, you can easily engage mocks to test your code without directly interacting with Custom Metadata Type records in your Salesforce organization.

## Setting Up Mocks

First, ensure all Custom Metadata Type access in the code path to be tested uses `DatabaseLayer.Cmdt` methods. Standard Custom Metadata Type access methods **_cannot_** be mocked:

```apex
// Don't do this:
Map<String, MySetting__mdt> all = MySetting__mdt.getAll();
MySetting__mdt instance = MySetting__mdt.getInstance('Some_Record');
// Do this instead:
Cmdt.Repository repo = DatabaseLayer.Cmdt?.ofType(MySetting__mdt.SObjectType);
Map<String, MySetting__mdt> all = (Map<String, MySetting__mdt>) repo?.getAll();
MySetting__mdt instance = repo?.getInstance('Some_Record');
// Or chain methods together in a one-liner:
Map<String, MySetting__mdt> all = (Map<String, MySetting__mdt>) DatabaseLayer.Cmdt
    ?.ofType(MySetting__mdt.SObjectType)
    ?.getAll();
```

To mock Custom Metadata records, use the [`MockCmdt.mock`](./The-MockCmdt-Class#mock) method to configure mock repositories for specific Custom Metadata Types. This can be done independently of other database operation mocking - you don't need to call `DatabaseLayer.useMocks()` to mock Custom Metadata records.

Once `MockCmdt.mock` is called for a Custom Metadata Type, subsequent `getAll()` and `getInstance()` calls on the `Cmdt.Repository` will return an empty list and `null` respectively, until you explicitly configure mock records using the mock repository methods.

Finally, call the code you want to test. As it runs, the framework will use your configured mock data instead of actually retrieving Custom Metadata Type records from your organization.

## Simulating Custom Metadata Records

Use the `MockCmdt.mock()` method to configure a repository with the desired records for testing.

Example:

```apex
@IsTest
static void testCustomMetadataAccess() {
    // Create mock Custom Metadata records
    List<MySetting__mdt>
    MySetting__mdt setting1 = new MySetting__mdt(
        DeveloperName = 'Setting_One',
        MasterLabel = 'Setting One',
        Value__c = 'Test Value 1'
    );
    MySetting__mdt setting2 = new MySetting__mdt(
        DeveloperName = 'Setting_Two',
        MasterLabel = 'Setting Two',
        Value__c = 'Test Value 2'
    );

    Test.startTest();
    MockCmdt.mock(MySetting__mdt.SObjectType).add(setting1).add(setting2);
    Test.stopTest();

    // Test retrieval of all records
    Map<String, MySetting__mdt> allSettings = (Map<String, MySetting__mdt>) DatabaseLayer.Cmdt
        .ofType(MySetting__mdt.SObjectType)
        .getAll();
    Assert.areEqual(2, allSettings.size(), 'Should return 2 mock records');

    // Test retrieval of specific record
    MySetting__mdt specificSetting = (MySetting__mdt) DatabaseLayer.Cmdt
        .ofType(MySetting__mdt.SObjectType)
        .getInstance('Setting_One');
    Assert.areEqual('Test Value 1', specificSetting.Value__c, 'Should return correct mock record');
    Assert.isNotNull(specificSetting, 'Should find the specific setting');
}
```

## Managing Mock Data

The [`MockCmdt.Repository`](./The-MockCmdt.Repository-Class) provides several methods for managing mock data during tests:

### Adding Records

```apex
MySetting__mdt setting = new MySetting__mdt(DeveloperName = 'Test_Setting');
MockCmdt.Repository repo = MockCmdt.mock(MySetting__mdt.SObjectType);

// Add a single record
repo.add(setting);

// Add multiple records
repo.add(new List<MySetting__mdt>{ setting1, setting2 });
```

### Removing Records

```apex
// Remove specific records
repo.remove(setting);
repo.remove(new List<MySetting__mdt>{ setting1, setting2 });

// Remove by developer name
repo.remove('Test_Setting');

// Clear all records
repo.clear();
```

## Independent Mocking

Each Custom Metadata Type can be mocked independently. This allows for complex test scenarios where different CMDT types need different configurations:

```apex
@IsTest
static void testMultipleCustomMetadataTypes() {
    // Configure different CMDT types with different data
    ApiSetting__mdt apiSetting = new ApiSetting__mdt(DeveloperName = 'Production_API');
    MockCmdt.mock(ApiSetting__mdt.SObjectType)?.add(apiSetting);

    MockCmdt.mock(FeatureFlag__mdt.SObjectType)?.add(
        new List<FeatureFlag__mdt>{
            new FeatureFlag__mdt(DeveloperName = 'Feature_A', Enabled__c = true),
            new FeatureFlag__mdt(DeveloperName = 'Feature_B', Enabled__c = false)
        }
    );

    MockCmdt.mock(NotificationSetting__mdt.SObjectType)?.clear(); // No notification settings

    // Each type behaves according to its own mock configuration
    List<ApiSetting__mdt> apiSettings = (List<ApiSetting__mdt>) DatabaseLayer.Cmdt
        ?.ofType(ApiSetting__mdt.SObjectType)
        ?.getAll();
    List<FeatureFlag__mdt> features = (List<FeatureFlag__mdt>) DatabaseLayer.Cmdt
        ?.ofType(FeatureFlag__mdt.SObjectType)
        ?.getAll();
    List<NotificationSetting__mdt> notifications = (List<NotificationSetting__mdt>) DatabaseLayer.Cmdt
        ?.ofType(NotificationSetting__mdt.SObjectType)
        ?.getAll();

    Assert.areEqual(1, apiSettings.size(), 'Should have 1 API setting');
    Assert.areEqual(2, features.size(), 'Should have 2 feature flags');
    Assert.areEqual(0, notifications.size(), 'Should have no notification settings');
}
```

## Combining with Other Mocks

Custom Metadata mocking works independently but can be combined with other database operation mocking:

```apex
@IsTest
static void testWithCombinedMocks() {
    // Mock Custom Metadata independently
    MockCmdt.mock(MySetting__mdt.SObjectType)
        .add(new MySetting__mdt(DeveloperName = 'Test_Setting', Value__c = 'Test'));

    // Also mock DML and SOQL operations
    DatabaseLayer.useMocks();

    // Both types of mocking work together
    MySetting__mdt setting = (MySetting__mdt) DatabaseLayer.Cmdt
        .ofType(MySetting__mdt.SObjectType)
        .getInstance('Test_Setting');

    Account mockAccount = new Account(Name = 'Test Account');
    DatabaseLayer.Dml.doInsert(mockAccount);

    Assert.isNotNull(setting, 'Custom Metadata mock should work');
    Assert.isNotNull(mockAccount.Id, 'DML mock should work');
}
```

## Resetting Mock State

Use the `MockCmdt.reset()` method to clear the mock configuration for a specific Custom Metadata Type:

```apex
// Reset specific CMDT type
MockCmdt.reset(MySetting__mdt.SObjectType);

// The next call to ofType() will create a fresh, empty repository
List<MySetting__mdt> settings = (List<MySetting__mdt>) DatabaseLayer.Cmdt
    .ofType(MySetting__mdt.SObjectType).getAll();
Assert.areEqual(0, settings.size(), 'Should be empty after reset');
```
