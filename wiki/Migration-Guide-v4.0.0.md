Starting in `v4.0.0`, the `DatabaseLayerSetting__mdt` custom metadata type has been replaced by `DatabaseLayerParameter__mdt`. This is a breaking change that affects anyone who has:

- Configured DML or SOQL plugins via `DatabaseLayerSetting__mdt`
- Accessed framework settings directly via `DatabaseLayerUtils.getSettings()` in custom code

### Migration Steps

Follow these steps to successfully migrate to `v4.0.0`:

#### 1. Install `v3.x` (the latest `v3` release)

This is the last version before the breaking change. Install it before proceeding so you have a stable baseline to migrate from.

You can find the latest `v3` release [**here**](https://github.com/jasonsiders/apex-database-layer/releases).

#### 2. Re-configure your plugin settings

In `v3.x`, plugins were configured via a **single** `DatabaseLayerSetting__mdt` record (enforced by a validation rule) with dedicated fields:

| Field                        | Value                      |
| ---------------------------- | -------------------------- |
| `DmlPreAndPostProcessor__c`  | Fully-qualified class name |
| `SoqlPreAndPostProcessor__c` | Fully-qualified class name |

In `v4.0.0`, each parameter is its own **`DatabaseLayerParameter__mdt`** record, identified by its `DeveloperName`:

| DeveloperName             | Value                      |
| ------------------------- | -------------------------- |
| `DmlPreAndPostProcessor`  | Fully-qualified class name |
| `SoqlPreAndPostProcessor` | Fully-qualified class name |

**Steps:**

1. Navigate to `Setup > Custom Metadata Types > Database Layer Parameter > Manage Records`
2. For each plugin you had configured in `DatabaseLayerSetting__mdt`, create a corresponding `DatabaseLayerParameter__mdt` record using the table above
3. Once verified, delete (or deactivate) your old `DatabaseLayerSetting__mdt` record

> **Note:** If you are using the [Nebula Logger plugin](./Plugin:-Nebula-Logger), these records are bundled with the updated plugin package and will be created automatically on install.

#### 3. Replace any direct usages of `DatabaseLayerUtils.getSettings()`

In `v3.x`, the framework exposed settings via:

```apex
Map<SObjectField, String> settings = DatabaseLayer.Utils.getSettings();
String value = settings?.get(DatabaseLayerSetting__mdt.SomField__c);
```

In `v4.0.0`, settings are replaced by named parameters, accessed via:

```apex
String value = DatabaseLayer.Utils.getParameter('SomeParameterName');
```

Search your codebase for references to `getSettings()` or `DatabaseLayerSetting__mdt` and update them accordingly.

#### 4. Update test code

In `v3.x`, tests that exercised plugin behavior used `DatabaseLayerTestUtils.initSettings()`:

```apex
// v3.x
DatabaseLayerTestUtils.initSettings(new DatabaseLayerSetting__mdt(
    DmlPreAndPostProcessor__c = 'MyClass',
    SoqlPreAndPostProcessor__c = 'MyClass'
));
```

In `v4.0.0`, use `DatabaseLayerTestUtils.initDmlAndSoqlPlugins()`:

```apex
// v4.0.0
DatabaseLayerTestUtils.initDmlAndSoqlPlugins('MyClass');
```

See the [`DatabaseLayerTestUtils`](./The-DatabaseLayerTestUtils-Class) documentation for full details.

#### 5. Install `v4.0.0`

You can find instructions to install this package [**here**](https://github.com/jasonsiders/apex-database-layer/releases/tag/v4.0.0).

:tada: Congrats! If you made it this far, your installation has been successfully upgraded.
