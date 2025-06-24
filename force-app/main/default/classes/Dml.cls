@SuppressWarnings(
	'PMD.ApexDoc, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.EmptyStatementBlock, PMD.ExcessiveParameterList, PMD.ExcessivePublicCount'
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
	private static final DataSource.AsyncDeleteCallback DEFAULT_DELETE_CALLBACK = new Dml.EmptyDeleteCallback();
	private static final DataSource.AsyncSaveCallback DEFAULT_SAVE_CALLBACK = new Dml.EmptySaveCallback();

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
		return this.doConvert(leadsToConvert, this.initDmlOptions(allOrNone), accessLevel);
	}

	public List<Database.LeadConvertResult> doConvert(
		List<Database.LeadConvert> leadsToConvert,
		Database.DmlOptions options
	) {
		return this.doConvert(leadsToConvert, options, DEFAULT_ACCESS_LEVEL);
	}

	public List<Database.LeadConvertResult> doConvert(
		List<Database.LeadConvert> leadsToConvert,
		System.AccessLevel level
	) {
		return this.doConvert(leadsToConvert, true, level);
	}

	public List<Database.LeadConvertResult> doConvert(List<Database.LeadConvert> leadsToConvert, Boolean allOrNone) {
		return this.doConvert(leadsToConvert, this.initDmlOptions(allOrNone));
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
		return this.doConvert(new List<Database.LeadConvert>{ leadToConvert }, allOrNone, accessLevel)?.get(0);
	}

	public Database.LeadConvertResult doConvert(Database.LeadConvert leadToConvert, Database.DmlOptions options) {
		return this.doConvert(new List<Database.LeadConvert>{ leadToConvert }, options)?.get(0);
	}

	public Database.LeadConvertResult doConvert(Database.LeadConvert leadToConvert, Boolean allOrNone) {
		return this.doConvert(new List<Database.LeadConvert>{ leadToConvert }, allOrNone)?.get(0);
	}

	public Database.LeadConvertResult doConvert(Database.LeadConvert leadToConvert, System.AccessLevel level) {
		return this.doConvert(new List<Database.LeadConvert>{ leadToConvert }, level)?.get(0);
	}

	public Database.LeadConvertResult doConvert(Database.LeadConvert leadToConvert) {
		return this.doConvert(new List<Database.LeadConvert>{ leadToConvert })?.get(0);
	}

	// ** Delete Methods
	public virtual List<Database.DeleteResult> doDelete(
		List<SObject> records,
		Boolean allOrNone,
		System.AccessLevel accessLevel
	) {
		return Database.delete(records, allOrNone, accessLevel);
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

	public List<Database.DeleteResult> doDelete(List<Id> recordIds, Boolean allOrNone, System.AccessLevel accessLevel) {
		List<SObject> records = this.initRecordsFromIds(recordIds);
		return this.doDelete(records, allOrNone, accessLevel);
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

	public Database.DeleteResult doDelete(SObject record, Boolean allOrNone, System.AccessLevel accessLevel) {
		return this.doDelete(new List<SObject>{ record }, allOrNone, accessLevel)?.get(0);
	}

	public Database.DeleteResult doDelete(SObject record, Boolean allOrNone) {
		return this.doDelete(new List<SObject>{ record }, allOrNone)?.get(0);
	}

	public Database.DeleteResult doDelete(SObject record, System.AccessLevel accessLevel) {
		return this.doDelete(new List<SObject>{ record }, accessLevel)?.get(0);
	}

	public Database.DeleteResult doDelete(SObject record) {
		return this.doDelete(new List<SObject>{ record })?.get(0);
	}

	public Database.DeleteResult doDelete(Id recordId, Boolean allOrNone, System.AccessLevel accessLevel) {
		return this.doDelete(new List<Id>{ recordId }, allOrNone, accessLevel)?.get(0);
	}

	public Database.DeleteResult doDelete(Id recordId, Boolean allOrNone) {
		return this.doDelete(new List<Id>{ recordId }, allOrNone)?.get(0);
	}

	public Database.DeleteResult doDelete(Id recordId, System.AccessLevel accessLevel) {
		return this.doDelete(new List<Id>{ recordId }, accessLevel)?.get(0);
	}

	public Database.DeleteResult doDelete(Id recordId) {
		return this.doDelete(new List<Id>{ recordId })?.get(0);
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
		return this.doDeleteAsync(records, DEFAULT_DELETE_CALLBACK, accessLevel);
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
		return this.doDeleteAsync(new List<SObject>{ record }, callback)?.get(0);
	}

	public Database.DeleteResult doDeleteAsync(SObject record, System.AccessLevel accessLevel) {
		return this.doDeleteAsync(new List<SObject>{ record }, accessLevel)?.get(0);
	}

	public Database.DeleteResult doDeleteAsync(SObject record) {
		return this.doDeleteAsync(new List<SObject>{ record })?.get(0);
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
		return this.doDeleteImmediate(new List<SObject>{ record })?.get(0);
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
		return this.doInsert(records, this.initDmlOptions(allOrNone), accessLevel);
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
		return this.doInsert(new List<SObject>{ record }, allOrNone, accessLevel)?.get(0);
	}

	public Database.SaveResult doInsert(SObject record, Database.DmlOptions options) {
		return this.doInsert(new List<SObject>{ record }, options)?.get(0);
	}

	public Database.SaveResult doInsert(SObject record, Boolean allOrNone) {
		return this.doInsert(new List<SObject>{ record }, allOrNone)?.get(0);
	}

	public Database.SaveResult doInsert(SObject record, System.AccessLevel accessLevel) {
		return this.doInsert(new List<SObject>{ record }, accessLevel)?.get(0);
	}

	public Database.SaveResult doInsert(SObject record) {
		return this.doInsert(new List<SObject>{ record })?.get(0);
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
		return this.doInsertAsync(records, DEFAULT_SAVE_CALLBACK, accessLevel);
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

	public Database.SaveResult doInsertAsync(SObject record, DataSource.AsyncSaveCallback callback) {
		return this.doInsertAsync(new List<SObject>{ record }, callback)?.get(0);
	}

	public Database.SaveResult doInsertAsync(SObject record, System.AccessLevel accessLevel) {
		return this.doInsertAsync(new List<SObject>{ record }, accessLevel)?.get(0);
	}

	public Database.SaveResult doInsertAsync(SObject record) {
		return this.doInsertAsync(new List<SObject>{ record })?.get(0);
	}

	// ** InsertImmediate Methods
	public virtual List<Database.SaveResult> doInsertImmediate(List<SObject> records, System.AccessLevel accessLevel) {
		return Database.insertImmediate(records, accessLevel);
	}

	public List<Database.SaveResult> doInsertImmediate(List<SObject> records) {
		return this.doInsertImmediate(records, DEFAULT_ACCESS_LEVEL);
	}

	public Database.SaveResult doInsertImmediate(SObject record, System.AccessLevel accessLevel) {
		return this.doInsertImmediate(new List<SObject>{ record }, accessLevel)?.get(0);
	}

	public Database.SaveResult doInsertImmediate(SObject record) {
		return this.doInsertImmediate(new List<SObject>{ record })?.get(0);
	}

	// ** Publish Methods
	public virtual List<Database.SaveResult> doPublish(List<SObject> events) {
		// Callback: "An Apex class that implements the EventPublishFailureCallback Interface or EventPublishSuccessCallback Interface."
		// https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_class_System_eventbus.htm#apex_System_eventbus_publish_4
		return EventBus.publish(events);
	}

	public Database.SaveResult doPublish(SObject event) {
		return this.doPublish(new List<SObject>{ event })?.get(0);
	}

	// ** Undelete Methods
	public virtual List<Database.UndeleteResult> doUndelete(
		List<SObject> records,
		Boolean allOrNone,
		System.AccessLevel accessLevel
	) {
		return Database.undelete(records, allOrNone, accessLevel);
	}

	public List<Database.UndeleteResult> doUndelete(List<SObject> records, Boolean allOrNone) {
		return this.doUndelete(records, allOrNone, DEFAULT_ACCESS_LEVEL);
	}

	public List<Database.UndeleteResult> doUndelete(List<SObject> records, System.AccessLevel accessLevel) {
		return this.doUndelete(records, true, accessLevel);
	}

	public List<Database.UndeleteResult> doUndelete(List<SObject> records) {
		return this.doUndelete(records, DEFAULT_ACCESS_LEVEL);
	}

	public List<Database.UndeleteResult> doUndelete(
		List<Id> recordIds,
		Boolean allOrNone,
		System.AccessLevel accessLevel
	) {
		List<SObject> records = this.initRecordsFromIds(recordIds);
		return this.doUndelete(records, allOrNone, accessLevel);
	}

	public List<Database.UndeleteResult> doUndelete(List<Id> recordIds, Boolean allOrNone) {
		return this.doUndelete(recordIds, allOrNone, DEFAULT_ACCESS_LEVEL);
	}

	public List<Database.UndeleteResult> doUndelete(List<Id> recordIds, System.AccessLevel accessLevel) {
		return this.doUndelete(recordIds, true, accessLevel);
	}

	public List<Database.UndeleteResult> doUndelete(List<Id> recordIds) {
		return this.doUndelete(recordIds, DEFAULT_ACCESS_LEVEL);
	}

	public Database.UndeleteResult doUndelete(SObject record, Boolean allOrNone, System.AccessLevel accessLevel) {
		return this.doUndelete(new List<SObject>{ record }, allOrNone, accessLevel)?.get(0);
	}

	public Database.UndeleteResult doUndelete(SObject record, Boolean allOrNone) {
		return this.doUndelete(new List<SObject>{ record }, allOrNone)?.get(0);
	}

	public Database.UndeleteResult doUndelete(SObject record, System.AccessLevel accessLevel) {
		return this.doUndelete(new List<SObject>{ record }, accessLevel)?.get(0);
	}

	public Database.UndeleteResult doUndelete(SObject record) {
		return this.doUndelete(new List<SObject>{ record })?.get(0);
	}

	public Database.UndeleteResult doUndelete(Id recordId, Boolean allOrNone, System.AccessLevel accessLevel) {
		return this.doUndelete(new List<Id>{ recordId }, allOrNone, accessLevel)?.get(0);
	}

	public Database.UndeleteResult doUndelete(Id recordId, Boolean allOrNone) {
		return this.doUndelete(new List<Id>{ recordId }, allOrNone)?.get(0);
	}

	public Database.UndeleteResult doUndelete(Id recordId, System.AccessLevel accessLevel) {
		return this.doUndelete(new List<Id>{ recordId }, accessLevel)?.get(0);
	}

	public Database.UndeleteResult doUndelete(Id recordId) {
		return this.doUndelete(new List<Id>{ recordId })?.get(0);
	}

	// ** Update Methods
	public virtual List<Database.SaveResult> doUpdate(
		List<SObject> records,
		Database.DmlOptions options,
		System.AccessLevel accessLevel
	) {
		return Database.update(records, options, accessLevel);
	}

	public List<Database.SaveResult> doUpdate(
		List<SObject> records,
		Boolean allOrNone,
		System.AccessLevel accessLevel
	) {
		return this.doUpdate(records, this.initDmlOptions(allOrNone), accessLevel);
	}

	public List<Database.SaveResult> doUpdate(List<SObject> records, Database.DmlOptions options) {
		return this.doUpdate(records, options, DEFAULT_ACCESS_LEVEL);
	}

	public List<Database.SaveResult> doUpdate(List<SObject> records, Boolean allOrNone) {
		return this.doUpdate(records, allOrNone, DEFAULT_ACCESS_LEVEL);
	}

	public List<Database.SaveResult> doUpdate(List<SObject> records, System.AccessLevel accessLevel) {
		return this.doUpdate(records, true, accessLevel);
	}

	public List<Database.SaveResult> doUpdate(List<SObject> records) {
		return this.doUpdate(records, DEFAULT_ACCESS_LEVEL);
	}

	public Database.SaveResult doUpdate(SObject record, Database.DmlOptions options, System.AccessLevel accessLevel) {
		return this.doUpdate(new List<SObject>{ record }, options, accessLevel)?.get(0);
	}

	public Database.SaveResult doUpdate(SObject record, Boolean allOrNone, System.AccessLevel accessLevel) {
		return this.doUpdate(new List<SObject>{ record }, allOrNone, accessLevel)?.get(0);
	}

	public Database.SaveResult doUpdate(SObject record, Database.DmlOptions options) {
		return this.doUpdate(new List<SObject>{ record }, options)?.get(0);
	}

	public Database.SaveResult doUpdate(SObject record, Boolean allOrNone) {
		return this.doUpdate(new List<SObject>{ record }, allOrNone)?.get(0);
	}

	public Database.SaveResult doUpdate(SObject record, System.AccessLevel accessLevel) {
		return this.doUpdate(new List<SObject>{ record }, accessLevel)?.get(0);
	}

	public Database.SaveResult doUpdate(SObject record) {
		return this.doUpdate(new List<SObject>{ record })?.get(0);
	}

	// ** UpdateAsync Methods
	public virtual List<Database.SaveResult> doUpdateAsync(
		List<SObject> records,
		DataSource.AsyncSaveCallback callback,
		System.AccessLevel accessLevel
	) {
		return Database.updateAsync(records, callback, accessLevel);
	}

	public List<Database.SaveResult> doUpdateAsync(List<SObject> records, DataSource.AsyncSaveCallback callback) {
		return this.doUpdateAsync(records, callback, DEFAULT_ACCESS_LEVEL);
	}

	public List<Database.SaveResult> doUpdateAsync(List<SObject> records, System.AccessLevel accessLevel) {
		return this.doUpdateAsync(records, DEFAULT_SAVE_CALLBACK, accessLevel);
	}

	public List<Database.SaveResult> doUpdateAsync(List<SObject> records) {
		return this.doUpdateAsync(records, DEFAULT_ACCESS_LEVEL);
	}

	public Database.SaveResult doUpdateAsync(
		SObject record,
		DataSource.AsyncSaveCallback callback,
		System.AccessLevel accessLevel
	) {
		return this.doUpdateAsync(new List<SObject>{ record }, callback, accessLevel)?.get(0);
	}

	public Database.SaveResult doUpdateAsync(SObject record, DataSource.AsyncSaveCallback callback) {
		return this.doUpdateAsync(new List<SObject>{ record }, callback)?.get(0);
	}

	public Database.SaveResult doUpdateAsync(SObject record, System.AccessLevel accessLevel) {
		return this.doUpdateAsync(new List<SObject>{ record }, accessLevel)?.get(0);
	}

	public Database.SaveResult doUpdateAsync(SObject record) {
		return this.doUpdateAsync(new List<SObject>{ record })?.get(0);
	}

	// ** UpdateImmediate Methods
	public virtual List<Database.SaveResult> doUpdateImmediate(List<SObject> records, System.AccessLevel accessLevel) {
		return Database.updateImmediate(records, accessLevel);
	}

	public List<Database.SaveResult> doUpdateImmediate(List<SObject> records) {
		return this.doUpdateImmediate(records, DEFAULT_ACCESS_LEVEL);
	}

	public Database.SaveResult doUpdateImmediate(SObject record, System.AccessLevel accessLevel) {
		return this.doUpdateImmediate(new List<SObject>{ record }, accessLevel)?.get(0);
	}

	public Database.SaveResult doUpdateImmediate(SObject record) {
		return this.doUpdateImmediate(new List<SObject>{ record })?.get(0);
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

	public List<Database.UpsertResult> doUpsert(
		List<SObject> records,
		SObjectField externalIdField,
		Boolean allOrNone
	) {
		return this.doUpsert(records, externalIdField, allOrNone, DEFAULT_ACCESS_LEVEL);
	}

	public List<Database.UpsertResult> doUpsert(
		List<SObject> records,
		SObjectField externalIdField,
		System.AccessLevel accessLevel
	) {
		return this.doUpsert(records, externalIdField, true, accessLevel);
	}

	public List<Database.UpsertResult> doUpsert(
		List<SObject> records,
		Boolean allOrNone,
		System.AccessLevel accessLevel
	) {
		return this.doUpsert(records, null, allOrNone, accessLevel);
	}

	public List<Database.UpsertResult> doUpsert(List<SObject> records, SObjectField externalIdField) {
		return this.doUpsert(records, externalIdField, DEFAULT_ACCESS_LEVEL);
	}

	public List<Database.UpsertResult> doUpsert(List<SObject> records, Boolean allOrNone) {
		return this.doUpsert(records, allOrNone, DEFAULT_ACCESS_LEVEL);
	}

	public List<Database.UpsertResult> doUpsert(List<SObject> records, System.AccessLevel accessLevel) {
		return this.doUpsert(records, true, accessLevel);
	}

	public List<Database.UpsertResult> doUpsert(List<SObject> records) {
		return this.doUpsert(records, DEFAULT_ACCESS_LEVEL);
	}

	public Database.UpsertResult doUpsert(
		SObject record,
		SObjectField externalIdField,
		Boolean allOrNone,
		System.AccessLevel accessLevel
	) {
		return this.doUpsert(new List<SObject>{ record }, externalIdField, allOrNone, accessLevel)?.get(0);
	}

	public Database.UpsertResult doUpsert(SObject record, SObjectField externalIdField, Boolean allOrNone) {
		return this.doUpsert(new List<SObject>{ record }, externalIdField, allOrNone)?.get(0);
	}

	public Database.UpsertResult doUpsert(
		SObject record,
		SObjectField externalIdField,
		System.AccessLevel accessLevel
	) {
		return this.doUpsert(new List<SObject>{ record }, externalIdField, accessLevel)?.get(0);
	}

	public Database.UpsertResult doUpsert(SObject record, Boolean allOrNone, System.AccessLevel accessLevel) {
		return this.doUpsert(new List<SObject>{ record }, allOrNone, accessLevel)?.get(0);
	}

	public Database.UpsertResult doUpsert(SObject record, SObjectField externalIdField) {
		return this.doUpsert(new List<SObject>{ record }, externalIdField)?.get(0);
	}

	public Database.UpsertResult doUpsert(SObject record, Boolean allOrNone) {
		return this.doUpsert(new List<SObject>{ record }, allOrNone)?.get(0);
	}

	public Database.UpsertResult doUpsert(SObject record, System.AccessLevel accessLevel) {
		return this.doUpsert(new List<SObject>{ record }, accessLevel)?.get(0);
	}

	public Database.UpsertResult doUpsert(SObject record) {
		return this.doUpsert(new List<SObject>{ record })?.get(0);
	}

	// ** EmptyRecycleBin Methods
	public virtual List<Database.EmptyRecycleBinResult> emptyRecycleBin(List<SObject> records) {
		return Database.emptyRecycleBin(records);
	}

	public List<Database.EmptyRecycleBinResult> emptyRecycleBin(List<Id> recordIds) {
		List<SObject> records = this.initRecordsFromIds(recordIds);
		return this.emptyRecycleBin(records);
	}

	public Database.EmptyRecycleBinResult emptyRecycleBin(SObject record) {
		return this.emptyRecycleBin(new List<SObject>{ record })?.get(0);
	}

	public Database.EmptyRecycleBinResult emptyRecycleBin(Id recordId) {
		return this.emptyRecycleBin(new List<Id>{ recordId })?.get(0);
	}

	// ** Savepoint Methods
	/**
	 * These System.Savepoint methods mirror the Database class's static methods
	 * The benefit of calling these methods is largely to gain access to MockDml methods
	 * to assert if/which savepoints were set, rolled back, released, etc.
	 */
	public virtual void releaseSavepoint(System.Savepoint savepoint) {
		Database.releaseSavepoint(savepoint);
	}

	public virtual void rollback(System.Savepoint savepoint) {
		Database.rollback(savepoint);
	}

	public virtual System.Savepoint setSavepoint() {
		return Database.setSavepoint();
	}

	// **** PRIVATE **** //
	private Database.DmlOptions initDmlOptions(Boolean allOrNone) {
		Database.DmlOptions options = new Database.DmlOptions();
		options.OptAllOrNone = allOrNone;
		return options;
	}

	private List<SObject> initRecordsFromIds(List<Id> recordIds) {
		// Converts a List<Id> into a List<SObject> with those Ids:
		List<SObject> records = new List<SObject>();
		for (Id recordId : recordIds) {
			SObject record = recordId?.getSObjectType()?.newSObject(recordId);
			records?.add(record);
		}
		return records;
	}

	// **** INNER **** //
	@TestVisible
	private class EmptyDeleteCallback extends DataSource.AsyncDeleteCallback {
		/**
		 *  If a callback isn't defined, doDeleteAsync() will use this class to gracefully handle callbacks
		 **/
		public override void processDelete(Database.DeleteResult result) {
			// Do nothing
		}
	}

	@TestVisible
	private class EmptySaveCallback extends DataSource.AsyncSaveCallback {
		/**
		 * If a callback isn't defined, doInsertAsync() & doUpdateAsync will use this class to gracefully handle callbacks
		 **/
		public override void processSave(Database.SaveResult result) {
			// Do nothing
		}
	}
}
