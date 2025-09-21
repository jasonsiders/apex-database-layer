The `Dml` class is designed to streamline and enhance DML operations within Salesforce.

It encapsulates standard DML keywords and Database methods, providing a simplified interface for CRUD operations. This class enables developers to easily mock DML operations, improving unit testing and reducing complexity.

## Constructing `Dml` Objects

`Dml` objects cannot be directly constructed via the `new` keyword. Instead, access the class and its methods via the `DatabaseLayer.Dml` static property:

```apex
DatabaseLayer.Dml.doInsert(record);
```

The `DatabaseLayer` class is responsible for instantiating database objects of the correct type at runtime. In `@IsTest` context, developers can call `DatabaseLayer.useMocks()`, and an instance of the `MockDml` class will be returned instead:

```apex
DatabaseLayer.useMocks();
Assert.isInstanceOfType(DatabaseLayer.Dml, MockDml.class, 'Not a mock');
```

## Performing DML

The `Dml` class contains methods which mirror the functionality of DML methods in the standard [`Database` class](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_methods_system_database.htm), including its numerous method overloads.

Since DML keywords (like `insert`, `update`, and `delete`) are reserved, the `Dml` class's methods are prefixed with the "do" predicate. For example, `doInsert`, `doUpdate`, and `doDelete`.

```apex
DatabaseLayer.Dml.doUpdate(account, false, System.AccessLevel.USER_MODE);
```

## Methods

### `doConvert`

Converts a lead into an account and contact, as well as (optionally) an opportunity.

See [`Database.convertLead`](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_methods_system_database.htm#apex_System_Database_convertLead) for more information.

### `doDelete`

Deletes an existing sObject record, such as an individual account or contact, from your organization's data.

See [`Database.delete`](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_methods_system_database.htm#apex_System_Database_delete) for more information.

### `doDeleteAsync`

Initiates requests to delete the external data that corresponds to the specified external object records. The request is executed asynchronously, as a background operation, and is sent to the external system that's defined by the external object's associated external data source. Allows referencing a callback class whose processDelete method is called for each record after deletion.

See [`Database.deleteAsync`](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_methods_system_database.htm#apex_System_database_deleteAsync) for more information.

### `doDeleteImmediate`

Initiates requests to delete the external data that corresponds to the specified external object records. The requests are executed synchronously and are sent to the external systems that are defined by the external objects' associated external data sources. If the Apex transaction contains pending changes, the synchronous operations can't be completed and throw exceptions.

See [`Database.deleteImmediate`](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_methods_system_database.htm#apex_System_database_deleteImmediate) for more information.

### `doInsert`

Adds an sObject, such as an individual account or contact, to your organization's data.

See [`Database.insert`](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_methods_system_database.htm#apex_System_Database_insert) for more information.

### `doInsertAsync`

Initiates requests to add external object data to the relevant external systems. The requests are executed asynchronously, as background operations, and are sent to the external systems that are defined by the external objects' associated external data sources. Allows referencing a callback class whose processSave method is called for each record after the remote operations are completed.

See [`Database.insertAsync`](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_methods_system_database.htm#apex_System_database_insertAsync) for more information.

### `doInsertImmediate`

Initiates requests to add external object data to the relevant external systems. The requests are executed synchronously and are sent to the external systems that are defined by the external objects' associated external data sources. If the Apex transaction contains pending changes, the synchronous operations can't be completed and throw exceptions.

See [`Database.insertImmediate`](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_methods_system_database.htm#apex_System_database_insertImmediate) for more information.

### `doPublish`

Publishes the given list of platform events.

See [`EventBus.publish`](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_class_System_eventbus.htm#apex_System_eventbus_publish) for the full list of method signatures.

### `doUndelete`

Restores an existing sObject record, such as an individual account or contact, from your organization's Recycle Bin.

See [`Database.undelete`](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_methods_system_database.htm#apex_System_Database_undelete) for the full list of method signatures.

### `doUpdate`

Modifies an existing sObject record, such as an individual account or contact, in your organization's data.

See [`Database.update`](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_methods_system_database.htm#apex_System_Database_update) for the full list of method signatures.

### `doUpdateAsync`

Initiates requests to update external object data on the relevant external systems. The requests are executed asynchronously, as background operations, and are sent to the external systems that are defined by the external objects' associated external data sources. Allows referencing a callback class whose processSave method is called for each record after the remote operations are completed.

See [`Database.updateAsync`](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_methods_system_database.htm#apex_System_database_updateAsync) for more information.

### `doUpdateImmediate`

Initiates requests to update external object data on the relevant external systems. The requests are executed synchronously and are sent to the external systems that are defined by the external objects' associated external data sources. If the Apex transaction contains pending changes, the synchronous operations can't be completed and throw exceptions.

See [`Database.updateImmediate`](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_methods_system_database.htm#apex_System_Database_updateImmediate) for more information.

### `doUpsert`

Creates a new sObject record or updates an existing sObject record within a single statement, using a specified field to determine the presence of existing objects, or the ID field if no field is specified.

See [`Database.upsert`](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_methods_system_database.htm#apex_System_Database_upsert) for more information.

### `emptyRecycleBin`

Permanently deletes the specified records from the Recycle Bin.

See [`Database.emptyRecycleBin`](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_methods_system_database.htm#apex_System_Database_emptyRecycleBin) for more information.

### `releaseSavepoint`

Releases a given savepoint. All savepoints that are subsequent to the given one are also released.

See [`Database.releaseSavepoint`](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_methods_system_database.htm#apex_System_database_releaseSavepoint) for more information.

### `rollback`

See [`Database.rollback`](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_methods_system_database.htm#apex_System_Database_rollback) for more information.

### `setSavepoint`

Returns a savepoint variable that can be stored as a local variable, then used with the rollback method to restore the database to that point.

See [`Database.setSavepoint`](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_methods_system_database.htm#apex_System_Database_setSavepoint) for more information.
