Apex Database Layer includes a mechanism to inject custom logic, or "plugins" in certain corners of the application. Use this plugin framework to make the framework your own!

> 💡 _Have an idea for a new plugin? Create an [issue](https://github.com/jasonsiders/apex-database-layer/issues/new)._

## How It Works

The framework reads configuration from the `DatabaseLayerParameter__mdt` custom metadata type. Each record represents a single named parameter, identified by its `DeveloperName`, with a string `Value__c` field.

> _**Note**: This object is **optional** — you do not need to create any records to enable the framework's core functionality._

To configure a plugin, create a `DatabaseLayerParameter__mdt` record whose `DeveloperName` matches the parameter name for that plugin, and set `Value__c` to the fully-qualified Apex class name that implements the plugin interface.

For the full list of supported parameter names and what they configure, see [DatabaseLayerParameter\_\_mdt Parameters](./DatabaseLayerParameter__mdt).

## Currently Supported Plugins

- [Dml.PreAndPostProcessor](./Plugin:-Dml.PreAndPostProcessor): Defines logic to be run immediately before and/or immediately after a DML operation. Use this plugin for specialized logic, like logging, for example.

- [Soql.PreAndPostProcessor](./Plugin:-Soql.PreAndPostProcessor): Defines logic to be run immediately before and/or immediately after a SOQL operation. Use this plugin for specialized logic, like logging, for example.
