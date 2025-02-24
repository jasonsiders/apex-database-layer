@SuppressWarnings(
	'PMD.CognitiveComplexity, PMD.EmptyStatementBlock, PMD.ExcessiveParameterList, PMD.ExcessivePublicCount'
)
public with sharing virtual class Dml {
	/**
	 * This class is responsible for performing CRUD operations with the Salesforce database.
	 * While the apex language allows developers to directly interact with the database,
	 * use of these methods does not facilitate mocking.
	 * Use this class instead of the DML keywords [`insert`, `update`, `delete`, etc],
	 * or the corresponding Database methods [ex., `Database.insert()`].
	 * Each of this class's methods eventually ties back to an underlying `Database` method,
	 * ex., `new Dml().doInsert()` -> `Database.insert()`.
	 * To mock this instance, use the included `MockDml` class, or your own class which extends `Dml`.
	 * - NOTE: This class is intentionally set to API 59.0
	 * More recent versions do not support using "normal" SObjects in Database.*async/immediate methods
	 * This functionality is necessary for us to be able to properly cover these methods in tests,
	 * since we cannot introduce external objects as a part of this package.
	 **/
	private static final System.AccessLevel DEFAULT_ACCESS_LEVEL = System.AccessLevel.USER_MODE;

	public Dml(DatabaseLayer factory) {
		// Dml classes can't be constructed manually
		// Instead, use the DatabaseLayer.Dml static property
	}

	// ** Convert Methods
	public virtual List<Database.LeadConvertResult> doConvert(
		List<Database.LeadConvert> leadsToConvert,
		Database.DmlOptions options,
		System.AccessLevel accessLevel
	) {
		return Database.convertLead(leadsToConvert, options, accessLevel);
	}

	public List<Database.LeadConvertResult> doConvert(
		List<Database.LeadConvert> leadsToConvert,
		Boolean allOrNone,
		System.AccessLevel accessLevel
	) {
		return this.doConvert(leadsToConvert, this.initOptions(allOrNone), accessLevel);
	}

	public List<Database.LeadConvertResult> doConvert(
		List<Database.LeadConvert> leadsToConvert,
		Database.DmlOptions options
	) {
		return this.doConvert(leadsToConvert, options, DEFAULT_ACCESS_LEVEL);
	}

	public List<Database.LeadConvertResult> doConvert(List<Database.LeadConvert> leadsToConvert, Boolean allOrNone) {
		return this.doConvert(leadsToConvert, this.initOptions(allOrNone));
	}

	public List<Database.LeadConvertResult> doConvert(List<Database.LeadConvert> leadsToConvert) {
		return this.doConvert(leadsToConvert, true);
	}

	public Database.LeadConvertResult doConvert(
		Database.LeadConvert leadToConvert,
		Database.DmlOptions options,
		System.AccessLevel accessLevel
	) {
		return this.doConvert(new List<Database.LeadConvert>{ leadToConvert }, options, accessLevel)?.get(0);
	}

	public Database.LeadConvertResult doConvert(
		Database.LeadConvert leadToConvert,
		Boolean allOrNone,
		System.AccessLevel accessLevel
	) {
		Database.DmlOptions options = this.initOptions(allOrNone);
		return this.doConvert(leadToConvert, options, accessLevel);
	}

	public Database.LeadConvertResult doConvert(Database.LeadConvert leadToConvert, Database.DmlOptions options) {
		return this.doConvert(leadToConvert, options, DEFAULT_ACCESS_LEVEL);
	}

	public Database.LeadConvertResult doConvert(Database.LeadConvert leadToConvert, Boolean allOrNone) {
		return this.doConvert(leadToConvert, allOrNone, DEFAULT_ACCESS_LEVEL);
	}

	public Database.LeadConvertResult doConvert(Database.LeadConvert leadToConvert) {
		return this.doConvert(leadToConvert, true);
	}

	// ** Delete Methods
	public virtual List<Database.DeleteResult> doDelete(
		List<Id> recordIds,
		Boolean allOrNone,
		System.AccessLevel accessLevel
	) {
		return Database.delete(recordIds, allOrNone, accessLevel);
	}

	public List<Database.DeleteResult> doDelete(List<Id> recordIds, Boolean allOrNone) {
		return this.doDelete(recordIds, allOrNone, DEFAULT_ACCESS_LEVEL);
	}

	public List<Database.DeleteResult> doDelete(List<Id> recordIds, System.AccessLevel accessLevel) {
		return this.doDelete(recordIds, true, accessLevel);
	}

	public List<Database.DeleteResult> doDelete(List<Id> recordIds) {
		return this.doDelete(recordIds, DEFAULT_ACCESS_LEVEL);
	}

	public List<Database.DeleteResult> doDelete(
		List<SObject> records,
		Boolean allOrNone,
		System.AccessLevel accessLevel
	) {
		List<Id> recordIds = this.getListOfIds(records);
		return Database.delete(recordIds, allOrNone, accessLevel);
	}

	public List<Database.DeleteResult> doDelete(List<SObject> records, Boolean allOrNone) {
		return this.doDelete(records, allOrNone, DEFAULT_ACCESS_LEVEL);
	}

	public List<Database.DeleteResult> doDelete(List<SObject> records, System.AccessLevel accessLevel) {
		return this.doDelete(records, true, accessLevel);
	}

	public List<Database.DeleteResult> doDelete(List<SObject> records) {
		return this.doDelete(records, DEFAULT_ACCESS_LEVEL);
	}

	public Database.DeleteResult doDelete(Id recordId, Boolean allOrNone, System.AccessLevel accessLevel) {
		this.doDelete(new List<Id>{ recordId }, allOrNone, accessLevel)?.get(0);
	}

	public Database.DeleteResult doDelete(Id recordId, Boolean allOrNone) {
		return this.doDelete(recordId, allOrNone, DEFAULT_ACCESS_LEVEL);
	}

	public Database.DeleteResult doDelete(Id recordId, System.AccessLevel accessLevel) {
		return this.doDelete(recordId, true, accessLevel);
	}

	public Database.DeleteResult doDelete(Id recordId) {
		return this.doDelete(recordId, DEFAULT_ACCESS_LEVEL);
	}

	public Database.DeleteResult doDelete(SObject record, Boolean allOrNone, System.AccessLevel accessLevel) {
		return this.doDelete(record?.Id, allOrNone, accessLevel);
	}

	public Database.DeleteResult doDelete(SObject record, Boolean allOrNone) {
		return this.doDelete(recordId, allOrNone, DEFAULT_ACCESS_LEVEL);
	}

	public Database.DeleteResult doDelete(SObject record, System.AccessLevel accessLevel) {
		this.doDelete(recordId, true, accessLevel);
	}

	public Database.DeleteResult doDelete(SObject record) {
		return this.doDelete(recordId, DEFAULT_ACCESS_LEVEL);
	}

	// ** DeleteAsync Methods
	public virtual List<Database.DeleteResult> doDeleteAsync(
		List<SObject> records,
		DataSource.AsyncDeleteCallback callback,
		System.AccessLevel accessLevel
	) {
		return Database.deleteAsync(records, callback, accessLevel);
	}

	public List<Database.DeleteResult> doDeleteAsync(List<SObject> records, DataSource.AsyncDeleteCallback callback) {
		return this.doDeleteAsync(records, callback, DEFAULT_ACCESS_LEVEL);
	}

	public List<Database.DeleteResult> doDeleteAsync(List<SObject> records, System.AccessLevel accessLevel) {
		DataSource.AsyncDeleteCallback callback = new DefaultDeleteCallback();
		return this.doDeleteAsync(records, callback, accessLevel);
	}

	public List<Database.DeleteResult> doDeleteAsync(List<SObject> records) {
		return this.doDeleteAsync(records, DEFAULT_ACCESS_LEVEL);
	}

	public Database.DeleteResult doDeleteAsync(
		SObject record,
		DataSource.AsyncDeleteCallback callback,
		System.AccessLevel accessLevel
	) {
		return this.doDeleteAsync(new List<SObject>{ record }, callback, accessLevel)?.get(0);
	}

	public Database.DeleteResult doDeleteAsync(SObject record, DataSource.AsyncDeleteCallback callback) {
		return this.doDeleteAsync(record, callback, DEFAULT_ACCESS_LEVEL);
	}

	public Database.DeleteResult doDeleteAsync(SObject record, System.AccessLevel accessLevel) {
		return this.doDeleteAsync(new List<SObject>{ record }, accessLevel)?.get(0);
	}
	public Database.DeleteResult doDeleteAsync(SObject record) {
		return this.doDeleteAsync(record, DEFAULT_ACCESS_LEVEL);
	}

	// ** DeleteImmediate Methods
	public virtual List<Database.DeleteResult> doDeleteImmediate(
		List<SObject> records,
		System.AccessLevel accessLevel
	) {
		return Database.deleteImmediate(records, accessLevel);
	}

	public List<Database.DeleteResult> doDeleteImmediate(List<SObject> records) {
		return this.doDeleteImmediate(records, DEFAULT_ACCESS_LEVEL);
	}

	public Database.DeleteResult doDeleteImmediate(SObject record, System.AccessLevel accessLevel) {
		return this.doDeleteImmediate(new List<SObject>{ record }, accessLevel)?.get(0);
	}

	public Database.DeleteResult doDeleteImmediate(SObject record) {
		return this.doDeleteImmediate(record, DEFAULT_ACCESS_LEVEL);
	}

	// ** Insert Methods
	public virtual List<Database.SaveResult> doInsert(
		List<SObject> records,
		Database.DmlOptions options,
		System.AccessLevel accessLevel
	) {
		return Database.insert(records, options, accessLevel);
	}

	public List<Database.SaveResult> doInsert(
		List<SObject> records,
		Boolean allOrNone,
		System.AccessLevel accessLevel
	) {
		return this.doInsert(records, this.initOptions(allOrNone), accessLevel);
	}

	public List<Database.SaveResult> doInsert(List<SObject> records, Database.DmlOptions options) {
		return this.doInsert(records, options, DEFAULT_ACCESS_LEVEL);
	}

	public List<Database.SaveResult> doInsert(List<SObject> records, Boolean allOrNone) {
		return this.doInsert(records, allOrNone, DEFAULT_ACCESS_LEVEL);
	}

	public List<Database.SaveResult> doInsert(List<SObject> records, System.AccessLevel accessLevel) {
		return this.doInsert(records, true, accessLevel);
	}

	public List<Database.SaveResult> doInsert(List<SObject> records) {
		return this.doInsert(records, DEFAULT_ACCESS_LEVEL);
	}

	public Database.SaveResult doInsert(SObject record, Database.DmlOptions options, System.AccessLevel accessLevel) {
		return this.doInsert(new List<SObject>{ record }, options, accessLevel)?.get(0);
	}

	public Database.SaveResult doInsert(SObject record, Boolean allOrNone, System.AccessLevel accessLevel) {
		return this.doInsert(record, this.initOptions(allOrNone), accessLevel);
	}

	public Database.SaveResult doInsert(SObject record, Database.DmlOptions options) {
		return this.doInsert(record, options, DEFAULT_ACCESS_LEVEL);
	}

	public Database.SaveResult doInsert(SObject record, Boolean allOrNone) {
		return this.doInsert(record, allOrNone, DEFAULT_ACCESS_LEVEL);
	}

	public Database.SaveResult doInsert(SObject record, System.AccessLevel accessLevel) {
		return this.doInsert(record, true, accessLevel);
	}

	public Database.SaveResult doInsert(SObject record) {
		return this.doInsert(record, DEFAULT_ACCESS_LEVEL);
	}

	// ** InsertAsync Methods
	public virtual List<Database.SaveResult> doInsertAsync(
		List<SObject> records,
		DataSource.AsyncSaveCallback callback,
		System.AccessLevel accessLevel
	) {
		return Database.insertAsync(records, callback, accessLevel);
	}

	public List<Database.SaveResult> doInsertAsync(List<SObject> records, DataSource.AsyncSaveCallback callback) {
		return this.doInsertAsync(records, callback, DEFAULT_ACCESS_LEVEL);
	}

	public List<Database.SaveResult> doInsertAsync(List<SObject> records, System.AccessLevel accessLevel) {
		DataSource.AsyncSaveCallback callback = new Dml.DefaultSaveCallback();
		return this.doInsertAsync(records, callback, accessLevel);
	}

	public List<Database.SaveResult> doInsertAsync(List<SObject> records) {
		return this.doInsertAsync(records, DEFAULT_ACCESS_LEVEL);
	}

	public Database.SaveResult doInsertAsync(
		SObject record,
		DataSource.AsyncSaveCallback callback,
		System.AccessLevel accessLevel
	) {
		return this.doInsertAsync(new List<SObject>{ record }, callback, accessLevel)?.get(0);
	}
	public Database.SaveResult doInsertAsync(SObject record, DataSource.AsyncSaveCallback callback);
	public Database.SaveResult doInsertAsync(SObject record, System.AccessLevel accessLevel);
	public Database.SaveResult doInsertAsync(SObject record);

	// ** InsertImmediate Methods
	public virtual List<Database.SaveResult> doInsertImmediate(List<SObject> records, System.AccessLevel accessLevel) {
		return Database.insertImmediate(records, accessLevel);
	}

	public List<Database.SaveResult> doInsertImmediate(List<SObject> records);
	public Database.SaveResult doInsertImmediate(SObject record, System.AccessLevel accessLevel);
	public Database.SaveResult doInsertImmediate(SObject record);

	// ** Publish Methods
	public virtual List<Database.SaveResult> doPublish(List<SObject> events, Object callback) {
		// Callback: "An Apex class that implements the EventPublishFailureCallback Interface or EventPublishSuccessCallback Interface."
		// https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_class_System_eventbus.htm#apex_System_eventbus_publish_4
		return EventBus.publish(events, callback);
	}

	public List<Database.SaveResult> doPublish(List<SObject> events);
	public Database.SaveResult doPublish(SObject event, Object callback);
	public Database.SaveResult doPublish(SObject event);

	// ** Undelete Methods
	public virtual List<Database.UndeleteResult> doUndelete(
		List<Id> recordIds,
		Boolean allOrNone,
		System.AccessLevel accessLevel
	) {
		return Database.undelete(recordIds, allOrNone, accessLevel);
	}

	public List<Database.UndeleteResult> doUndelete(List<Id> recordIds, Boolean allOrNone);
	public List<Database.UndeleteResult> doUndelete(List<Id> recordIds, System.AccessLevel accessLevel);
	public List<Database.UndeleteResult> doUndelete(List<Id> recordIds);
	public List<Database.UndeleteResult> doUndelete(
		List<SObject> records,
		Boolean allOrNone,
		System.AccessLevel accessLevel
	);
	public List<Database.UndeleteResult> doUndelete(List<SObject> records, Boolean allOrNone);
	public List<Database.UndeleteResult> doUndelete(List<SObject> records, System.AccessLevel accessLevel);
	public List<Database.UndeleteResult> doUndelete(List<SObject> records);
	public Database.UndeleteResult doUndelete(Id recordId, Boolean allOrNone, System.AccessLevel accessLevel);
	public Database.UndeleteResult doUndelete(Id recordId, Boolean allOrNone);
	public Database.UndeleteResult doUndelete(Id recordId, System.AccessLevel accessLevel);
	public Database.UndeleteResult doUndelete(Id recordId);
	public Database.UndeleteResult doUndelete(SObject record, Boolean allOrNone, System.AccessLevel accessLevel);
	public Database.UndeleteResult doUndelete(SObject record, Boolean allOrNone);
	public Database.UndeleteResult doUndelete(SObject record, System.AccessLevel accessLevel);
	public Database.UndeleteResult doUndelete(SObject record);

	// ** Update Methods
	public virtual List<Database.SaveResult> doUpdate(
		List<SObject> records,
		Database.DmlOptions options,
		System.AccessLevel accessLevel
	) {
		return Database.update(records, options, accessLevel);
	}

	public List<Database.SaveResult> doUpdate(List<SObject> records, Database.DmlOptions options);
	public List<Database.SaveResult> doUpdate(List<SObject> records, Boolean allOrNone);
	public List<Database.SaveResult> doUpdate(List<SObject> records, System.AccessLevel accessLevel);
	public List<Database.SaveResult> doUpdate(List<SObject> records);
	public Database.SaveResult doUpdate(SObject record, Database.DmlOptions options, System.AccessLevel accessLevel);
	public Database.SaveResult doUpdate(SObject record, Database.DmlOptions options);
	public Database.SaveResult doUpdate(SObject record, Boolean allOrNone);
	public Database.SaveResult doUpdate(SObject record, System.AccessLevel accessLevel);
	public Database.SaveResult doUpdate(SObject record);

	// ** UpdateAsync Methods
	public virtual List<Database.SaveResult> doUpdateAsync(
		List<SObject> records,
		DataSource.AsyncSaveCallback callback,
		System.AccessLevel accessLevel
	) {
		return Database.updateAsync(records, callback, accessLevel);
	}

	public List<Database.SaveResult> doUpdateAsync(List<SObject> records, DataSource.AsyncSaveCallback callback);
	public List<Database.SaveResult> doUpdateAsync(List<SObject> records, System.AccessLevel accessLevel);
	public List<Database.SaveResult> doUpdateAsync(List<SObject> records);
	public Database.SaveResult doUpdateAsync(
		SObject record,
		DataSource.AsyncSaveCallback callback,
		System.AccessLevel accessLevel
	);
	public Database.SaveResult doUpdateAsync(SObject record, DataSource.AsyncSaveCallback callback);
	public Database.SaveResult doUpdateAsync(SObject record, System.AccessLevel accessLevel);
	public Database.SaveResult doUpdateAsync(SObject record);

	// ** UpdateImmediate Methods
	public virtual List<Database.SaveResult> doUpdateImmediate(List<SObject> records, System.AccessLevel accessLevel) {
		return Database.updateImmediate(records, accessLevel);
	}

	public List<Database.SaveResult> doUpdateImmediate(List<SObject> records);
	public Database.SaveResult doUpdateImmediate(SObject record, System.AccessLevel accessLevel);
	public Database.SaveResult doUpdateImmediate(SObject record);

	// ** Upsert Methods
	public virtual List<Database.UpsertResult> doUpsert(
		List<SObject> records,
		SObjectField externalIdField,
		Boolean allOrNone,
		System.AccessLevel accessLevel
	) {
		// Note: Supplying a null ExternalIdField value to Database.upsert will result in an Exception
		// To avoid this, call the correct overload depending on the supplied field value
		return (externalIdField != null)
			? Database.upsert(records, externalIdField, allOrNone, accessLevel)
			: Database.upsert(records, allOrNone, accessLevel);
	}

	public List<Database.UpsertResult> doUpsert(List<SObject> records, SObjectField externalIdField, Boolean allOrNone);
	public List<Database.UpsertResult> doUpsert(
		List<SObject> records,
		SObjectField externalIdField,
		System.AccessLevel accessLevel
	);
	public List<Database.UpsertResult> doUpsert(
		List<SObject> records,
		Boolean allOrNone,
		System.AccessLevel accessLevel
	);
	public List<Database.UpsertResult> doUpsert(List<SObject> records, SObjectField externalIdField);
	public List<Database.UpsertResult> doUpsert(List<SObject> records, Boolean allOrNone);
	public List<Database.UpsertResult> doUpsert(List<SObject> records, System.AccessLevel accessLevel);
	public List<Database.UpsertResult> doUpsert(List<SObject> records);
	public Database.UpsertResult doUpsert(
		SObject record,
		SObjectField externalIdField,
		Boolean allOrNone,
		System.AccessLevel accessLevel
	);
	public Database.UpsertResult doUpsert(SObject record, SObjectField externalIdField, Boolean allOrNone);
	public Database.UpsertResult doUpsert(SObject record, SObjectField externalIdField, System.AccessLevel accessLevel);
	public Database.UpsertResult doUpsert(SObject record, Boolean allOrNone, System.AccessLevel accessLevel);
	public Database.UpsertResult doUpsert(SObject record, SObjectField externalIdField);
	public Database.UpsertResult doUpsert(SObject record, Boolean allOrNone);
	public Database.UpsertResult doUpsert(SObject record, System.AccessLevel accessLevel);
	public Database.UpsertResult doUpsert(SObject record);

	// ** EmptyRecycleBin Methods
	public virtual List<Database.EmptyRecycleBinResult> emptyRecycleBin(List<Id> recordIds) {
		return Database.emptyRecycleBin(recordIds);
	}

	public List<Database.EmptyRecycleBinResult> emptyRecycleBin(List<SObject> records) {
		List<Id> recordIds = this.getListOfIds(records);
		return this.emptyRecycleBin(recordIds);
	}

	public Database.EmptyRecycleBinResult emptyRecycleBin(Id recordId) {
		return this.emptyRecycleBin(new List<Id>{ recordId });
	}

	public Database.EmptyRecycleBinResult emptyRecycleBin(SObject record) {
		return this.emptyRecycleBin(record?.Id);
	}

	// **** PRIVATE **** //
	private List<Id> getListOfIds(List<SObject> records) {
		// Converts a List<SObject> into a List<Id>
		return new List<Id>(new Map<Id, SObject>(records)?.keySet());
	}

	private List<SObject> getListOfRecords(List<Id> recordIds) {
		// Converts a List<Id> into a List<SObject>
		List<SObject> records = new List<SObject>();
		for (Id recordId : recordIds) {
			SObject record = recordId?.getSObjectType()?.newSObject(recordId);
			records?.add(record);
		}
		return records;
	}

	private Database.DmlOptions initOptions(Boolean allOrNone) {
		Database.DmlOptions options = new Database.DmlOptions();
		options.OptAllOrNone = allOrNone;
		return options;
	}

	// **** INNER **** //
	@TestVisible
	private class DefaultDeleteCallback extends DataSource.AsyncDeleteCallback {
		/**
		 *  If a callback isn't defined, doDeleteAsync() will use this class to gracefully handle callbacks
		 **/
		public override void processDelete(Database.DeleteResult result) {
			// Do nothing
		}
	}

	@TestVisible
	private class DefaultEventCallback implements EventBus.EventPublishFailureCallback, EventBus.EventPublishSuccessCallback {
		/**
		 * If a platform event callback isn't defined, doPublish() will use this class to gracefully handle callbacks
		 **/
		public void onFailure(EventBus.FailureResult result) {
			// Do nothing
		}

		public void onSuccess(EventBus.SuccessResult result) {
			// Do nothing
		}
	}

	@TestVisible
	private class DefaultSaveCallback extends DataSource.AsyncSaveCallback {
		/**
		 * If a callback isn't defined, doInsertAsync() & doUpdateAsync will use this class to gracefully handle callbacks
		 **/
		public override void processSave(Database.SaveResult result) {
			// Do nothing
		}
	}

	public enum Operation {
		DO_CONVERT,
		DO_DELETE,
		DO_DELETE_ASYNC,
		DO_DELETE_IMMEDIATE,
		DO_HARD_DELETE,
		DO_INSERT,
		DO_INSERT_ASYNC,
		DO_INSERT_IMMEDIATE,
		DO_PUBLISH,
		DO_UNDELETE,
		DO_UPDATE,
		DO_UPDATE_ASYNC,
		DO_UPDATE_IMMEDIATE,
		DO_UPSERT
	}
}
