This plugin leverages the [Plugin Framework](./The-Plugin-Framework) to automatically logs details about your DML and SOQL operations, via _Nebula Logger_.

[Nebula Logger](https://github.com/jongpie/NebulaLogger/tree/main) is a popular logging framework for Salesforce. Like Apex Database Layer, it's free, and open-source.

## Getting Started

### Prerequisites

To use this plugin, you must have the most recent version of [Apex Database Layer](https://github.com/jasonsiders/apex-database-layer) and [Nebula Logger](https://github.com/jongpie/NebulaLogger/tree/main) installed.

### Installation

If you're using both the latest & unmanaged versions of _Apex Database Layer_ and _Nebula Logger_ installed, you may install this plugin as an unlocked package.

First, locate the latest version of the plugin package, called `nebula-logger-plugin@latest` in [`sfdx-project.json`](https://github.com/jasonsiders/apex-database-layer/blob/main/sfdx-project.json):

```sh
sf package install --package <<package_version_id>> --wait 10
```

> :warning: **Note:** If you are using a managed version of _Apex Database Layer_ and/or _Nebula Logger_, you won't be able to formally install the package. Instead, manually copy the contents of these two Apex Classes in your desired environment:
>
> - [`DatabaseLayerNebulaLoggerAdapter.cls`](https://github.com/jasonsiders/apex-database-layer/blob/main/plugins/nebula-logger/source/classes/DatabaseLayerNebulaLoggerAdapter.cls)
> - [`DatabaseLayerNebulaLoggerAdapterTest.cls`](https://github.com/jasonsiders/apex-database-layer/blob/main/plugins/nebula-logger/source/classes/DatabaseLayerNebulaLoggerAdapterTest.cls))

### Setup

Once installed, navigate to `Setup > Custom Metadata Types > Database Layer Parameter > Manage Records` and create two records:

| DeveloperName             | Value                              |
| ------------------------- | ---------------------------------- |
| `DmlPreAndPostProcessor`  | `DatabaseLayerNebulaLoggerAdapter` |
| `SoqlPreAndPostProcessor` | `DatabaseLayerNebulaLoggerAdapter` |

**Note:** Once configured, these custom metadata records won't be altered by upgrading the _Apex Database Layer_ package, or the plugin package itself.

---

## Usage

Whenever a DML or SOQL operation runs, the plugin will log the details of those operations to Nebula Logger. This results in log entries with the `apex-database-layer` _Log Entry Tag_.

### DML Logging

Just before a DML operation is processed, the plugin will issue a `FINEST` log entry summarizing the action that's about to take place.

- The [`Dml.Request`](./The-Dml.Request-Class) is serialized and shown in the message body
- The records being operated on are shown in the `Related Records` tab

<img width="1400" alt="image" src="https://github.com/user-attachments/assets/d9e8cfd1-5f87-4a0e-ad60-abe0593902fe" />
<img width="1400" alt="image" src="https://github.com/user-attachments/assets/04beeed6-ddbf-476e-84ee-2aaf3a029a9a" />

After a DML operation is processed, the plugin issues another `FINEST` log entry summarizing the action that took place.

- The [`Dml.Request`](./The-Dml.Request-Class) is serialized and shown in the message body
- The records that were operated on are shown in the `Related Records` tab
- The relevant database result objects (ex., `Database.SaveResult`) are shown in the `Related Records` tab

<img width="1400" alt="image" src="https://github.com/user-attachments/assets/f4f18658-2021-4d14-941d-30394a984ba3" />
<img width="1402" alt="image" src="https://github.com/user-attachments/assets/975e8713-9300-41f3-be4d-0b8b276f2e89" />

If an exception is thrown during a DML operation, an `ERROR` log entry is issued:

- The `Exception` message is shown in the message body
- The [`Dml.Request`](./The-Dml.Request-Class) is serialized and shown in the message body
- The records that were operated on are shown in the `Related Records` tab

<img width="1403" alt="image" src="https://github.com/user-attachments/assets/9c3ff70f-e955-4b5c-bd49-b8cabdf3a5dd" />

### SOQL Logging

Just before a SOQL operation is processed, the plugin issues a `FINEST` log entry summarizing the query about to take place:

- The text of the query is available in the message body

<img width="1429" alt="image" src="https://github.com/user-attachments/assets/fa66b1a5-3aea-41e3-b27d-abe183694548" />

After a SOQL operation is processed, the plugin issues another `FINEST` log entry summarizing the query and its results:

- The text of the query is available in the message body
- The resulting SObject records are available in the `Related Records` tab
    - Note: Other query operations (ex., `getCursor`, `countQuery`) that do _not_ output SObjects will be printed in the message body instead

<img width="1431" alt="image" src="https://github.com/user-attachments/assets/51b574ed-ef2f-42ef-b97d-96f965290982" />
<img width="1406" alt="image" src="https://github.com/user-attachments/assets/e37a5a19-72b0-4701-aa17-06c16343b034" />

If an exception is thrown during a SOQL operation, an `ERROR` log entry is issued:

- The text of the query is available in the message body
- The `Exception` message is shown in the message body

<img width="1402" alt="image" src="https://github.com/user-attachments/assets/2e879830-1a85-4e7f-881b-dc8f154aeb0b" />

### Considerations

#### `MockSoql`: Additional query logs for non-standard SOQL operations

Many `MockSoql` query operations use the `query` method as the basis for building mock results. This may result in additional logs being issued.

For example, `MockSoql.getQueryLocator` calls `MockSoql.query` to generate the list of records to be returned, and then wraps the results in a `Soql.QueryLocator`. In this scenario, the plugin issues 4 `FINEST` logs: one before/after `MockSoql.getQueryLocator`, and one before/after `MockSoql.query`.
