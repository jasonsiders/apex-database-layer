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

	public List<Database.DeleteResult> doDeleteAsync(List<SObject> records, DataSource.AsyncDeleteCallback callback);
	public List<Database.DeleteResult> doDeleteAsync(List<SObject> records, System.AccessLevel accessLevel);
	public List<Database.DeleteResult> doDeleteAsync(List<SObject> records);
	public Database.DeleteResult doDeleteAsync(
		SObject record,
		DataSource.AsyncDeleteCallback callback,
		System.AccessLevel accessLevel
	);
	public Database.DeleteResult doDeleteAsync(SObject record, DataSource.AsyncDeleteCallback callback);
	public Database.DeleteResult doDeleteAsync(SObject record, System.AccessLevel accessLevel);
	public Database.DeleteResult doDeleteAsync(SObject record);

	// ** DeleteImmediate Methods
	public virtual List<Database.DeleteResult> doDeleteImmediate(
		List<SObject> records,
		System.AccessLevel accessLevel
	) {
		return Database.deleteImmediate(records, accessLevel);
	}

	public List<Database.DeleteResult> doDeleteImmediate(List<SObject> records);
	public Database.DeleteResult doDeleteImmediate(SObject record, System.AccessLevel accessLevel);
	public Database.DeleteResult doDeleteImmediate(SObject record);

	// ** Insert Methods
	public virtual List<Database.SaveResult> doInsert(
		List<SObject> records,
		Database.DmlOptions options,
		System.AccessLevel accessLevel
	) {
		return Database.insert(records, options, accessLevel);
	}

	public List<Database.SaveResult> doInsert(List<SObject> records, Boolean allOrNone, System.AccessLevel accessLevel);
	public List<Database.SaveResult> doInsert(List<SObject> records, Database.DmlOptions options);
	public List<Database.SaveResult> doInsert(List<SObject> records, Boolean allOrNone);
	public List<Database.SaveResult> doInsert(List<SObject> records, System.AccessLevel accessLevel);
	public List<Database.SaveResult> doInsert(List<SObject> records);
	public Database.SaveResult doInsert(SObject record, Database.DmlOptions options, System.AccessLevel accessLevel);
	public Database.SaveResult doInsert(SObject record, Boolean allOrNone, System.AccessLevel accessLevel);
	public Database.SaveResult doInsert(SObject record, Database.DmlOptions options);
	public Database.SaveResult doInsert(SObject record, Boolean allOrNone);
	public Database.SaveResult doInsert(SObject record, System.AccessLevel accessLevel);
	public Database.SaveResult doInsert(SObject record);

	// ** InsertAsync Methods
	public virtual List<Database.SaveResult> doInsertAsync(
		List<SObject> records,
		DataSource.AsyncSaveCallback callback,
		System.AccessLevel accessLevel
	) {
		return Database.insertAsync(records, callback, accessLevel);
	}

	public List<Database.SaveResult> doInsertAsync(List<SObject> records, DataSource.AsyncSaveCallback callback);
	public List<Database.SaveResult> doInsertAsync(List<SObject> records, System.AccessLevel accessLevel);
	public List<Database.SaveResult> doInsertAsync(List<SObject> records);
	public Database.SaveResult doInsertAsync(
		SObject records,
		DataSource.AsyncSaveCallback callback,
		System.AccessLevel accessLevel
	);
	public Database.SaveResult doInsertAsync(SObject records, DataSource.AsyncSaveCallback callback);
	public Database.SaveResult doInsertAsync(SObject records, System.AccessLevel accessLevel);
	public Database.SaveResult doInsertAsync(SObject records);

	// ** InsertImmediate Methods
	public virtual List<Database.SaveResult> doInsertImmediate(List<SObject> records, System.AccessLevel accessLevel) {
		return Database.insertImmediate(records, accessLevel);
	}

	// ** Publish Methods
	public virtual List<Database.SaveResult> doPublish(List<SObject> events, Object callback) {
		// Callback: "An Apex class that implements the EventPublishFailureCallback Interface or EventPublishSuccessCallback Interface."
		// https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_class_System_eventbus.htm#apex_System_eventbus_publish_4
		return EventBus.publish(events, callback);
	}

	// ** Undelete Methods
	public virtual List<Database.UndeleteResult> doUndelete(
		List<Id> recordIds,
		Boolean allOrNone,
		System.AccessLevel accessLevel
	) {
		return Database.undelete(recordIds, allOrNone, accessLevel);
	}

	// ** Update Methods
	public virtual List<Database.SaveResult> doUpdate(
		List<SObject> records,
		Database.DmlOptions options,
		System.AccessLevel accessLevel
	) {
		return Database.update(records, options, accessLevel);
	}

	// ** UpdateAsync Methods
	public virtual List<Database.SaveResult> doUpdateAsync(
		List<SObject> records,
		DataSource.AsyncSaveCallback callback,
		System.AccessLevel accessLevel
	) {
		return Database.updateAsync(records, callback, accessLevel);
	}

	// ** UpdateImmediate Methods
	public virtual List<Database.SaveResult> doUpdateImmediate(List<SObject> records, System.AccessLevel accessLevel) {
		return Database.updateImmediate(records, accessLevel);
	}

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
