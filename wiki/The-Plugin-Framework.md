Apex Database Layer includes a mechanism to inject custom logic, or "plugins" in certain corners of the application. Use this plugin framework to make the framework your own!

> 💡 _Have an idea for a new plugin? Create an [issue](https://github.com/jasonsiders/apex-database-layer/issues/new)._

## How It Works

The framework includes a custom metadata type, _Database Layer Setting_ / `DatabaseLayerSetting__mdt`.

> _**Note**: This object is \_optional_ - you do not need to create any records to enable the framework's core functionality.\_

To leverage the plugin framework, create a `DatabaseLayerSetting__mdt` record. There can only be one such record, and it must be called "Default":

<img width="1182" height="437" alt="image" src="https://github.com/user-attachments/assets/7595376c-afb0-4498-8c2e-5a7e1f0df3cb" />

Each plugin looks at field(s) in the _Plugins_ section on the custom metadata record. For example, [Dml.PreAndPostProcessor](./Plugin:-Dml.PreAndPostProcessor) uses an apex class named in the _DML: Pre & Post Processor_ field to perform its logic.

## Currently Supported Plugins

- [Dml.PreAndPostProcessor](./Plugin:-Dml.PreAndPostProcessor): Defines logic to be run immediately before and/or immediately after a DML operation. Use this plugin for specialized logic, like logging, for example.

- [Soql.PreAndPostProcessor](./Plugin:-Soql.PreAndPostProcessor): Defines logic to be run immediately before and/or immediately after a SOQL operation. Use this plugin for specialized logic, like logging, for example.
