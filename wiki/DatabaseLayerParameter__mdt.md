The `DatabaseLayerParameter__mdt` custom metadata type provides optional named configuration parameters for the Apex Database Layer framework. Each record represents a single parameter, identified by its `DeveloperName`, with a string `Value__c` field.

> _**Note**: This object is **optional** — you do not need to create any records to enable the framework's core functionality._

## Fields

| Field | API Name | Type | Description |
|---|---|---|---|
| **Label** | `MasterLabel` | Text | A human-readable label for this parameter record |
| **DeveloperName** | `DeveloperName` | Text | The unique name used by the framework to look up this parameter |
| **Value** | `Value__c` | Text (255) | The string value for this parameter (e.g., an Apex class name) |
| **Description** | `Description__c` | Long Text Area (1000) | An optional description of what this parameter controls |

## Available Parameters

The following parameters are recognized by the framework. Any other `DeveloperName` values are ignored.

### `DmlPreAndPostProcessor`

| | |
|---|---|
| **Purpose** | Registers a plugin to run before and after every DML operation |
| **Value** | Fully-qualified Apex class name implementing [`Dml.PreAndPostProcessor`](./The-Dml.PreAndPostProcessor-Interface) |
| **Example Value** | `MyDmlLogger` |

See [Plugin: Dml.PreAndPostProcessor](./Plugin:-Dml.PreAndPostProcessor) for full setup instructions.

### `SoqlPreAndPostProcessor`

| | |
|---|---|
| **Purpose** | Registers a plugin to run before and after every SOQL operation |
| **Value** | Fully-qualified Apex class name implementing [`Soql.PreAndPostProcessor`](./The-Soql.PreAndPostProcessor-Interface) |
| **Example Value** | `MySoqlLogger` |

See [Plugin: Soql.PreAndPostProcessor](./Plugin:-Soql.PreAndPostProcessor) for full setup instructions.

## How Parameters Are Loaded

Parameters are read at runtime using `DatabaseLayerParameter__mdt.getInstance()` — no SOQL is consumed. The framework caches the results for the duration of the transaction.

To re-read parameters after mocking them in a test (e.g., after calling `MockCmdt.mock()`), call `DatabaseLayer.Utils.Plugins.init()` to flush the cache and reload.

## Testing With Parameters

Use [`DatabaseLayerTestUtils.initDmlAndSoqlPlugins`](./The-DatabaseLayerTestUtils-Class) to mock both plugin parameters in a single call:

```apex
@IsTest
static void myTest() {
    DatabaseLayerTestUtils.initDmlAndSoqlPlugins('MyPluginClassName');
    // ... test logic
}
```

To mock individual parameters, use `MockCmdt` directly:

```apex
DatabaseLayerParameter__mdt mockParam = new DatabaseLayerParameter__mdt(
    DeveloperName = 'DmlPreAndPostProcessor',
    Value__c = 'MyDmlPlugin'
);
MockCmdt.mock(DatabaseLayerParameter__mdt.SObjectType)?.add(mockParam);
DatabaseLayer.Utils.Plugins.init();
```
