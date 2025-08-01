@SuppressWarnings(
	'PMD.ApexDoc,PMD.AvoidGlobalModifier,PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.ExcessiveClassLength,PMD.ExcessivePublicCount'
)
global inherited sharing virtual class Dml {
	/**
	 * This class is responsible for performing CRUD operations with the Salesforce database.
	 * While the apex language allows developers to directly interact with the database,
	 * use of these methods does not facilitate mocking.
	 * Use this class instead of the DML keywords [`insert`, `update`, `delete`, etc],
	 * or the corresponding Database methods [ex., `Database.insert()`].
	 * Each of this class's methods eventually ties back to an underlying `Database` method,
	 * ex., `new Dml().doInsert()` -> `Database.insert()`.
	 * Use the included `MockDml` class to perform Mock DML
	 **/
	private static final System.AccessLevel DEFAULT_ACCESS_LEVEL = System.AccessLevel.USER_MODE;
	private static final DataSource.AsyncDeleteCallback DEFAULT_DELETE_CALLBACK = new Dml.EmptyDeleteCallback();
	private static final DataSource.AsyncSaveCallback DEFAULT_SAVE_CALLBACK = new Dml.EmptySaveCallback();
	private static final SObjectField PLUGIN_FIELD = DatabaseLayerSetting__mdt.DmlPreAndPostProcessor__c;
	private static Dml.PreAndPostProcessor plugin;

	public Dml(DatabaseLayer factory) {
		// Note: Dml classes can't be constructed manually; instead, use the DatabaseLayer.Dml static property
		this.initPlugins();
	}

	// ** Convert Methods
	global List<Database.LeadConvertResult> doConvert(
		List<Database.LeadConvert> leadsToConvert,
		Database.DmlOptions options,
		System.AccessLevel accessLevel
	) {
		Dml.Request request = this.initRequest(Dml.Operation.DO_CONVERT, leadsToConvert);
		request.options = options;
		request.accessLevel = accessLevel;
		return (List<Database.LeadConvertResult>) request?.process();
	}

	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global List<Database.LeadConvertResult> doConvert(
		List<Database.LeadConvert> leadsToConvert,
		Boolean allOrNone,
		System.AccessLevel accessLevel
	) {
		return this.doConvert(leadsToConvert, Dml.initDmlOptions(allOrNone), accessLevel);
	}

	global List<Database.LeadConvertResult> doConvert(
		List<Database.LeadConvert> leadsToConvert,
		Database.DmlOptions options
	) {
		return this.doConvert(leadsToConvert, options, DEFAULT_ACCESS_LEVEL);
	}

	global List<Database.LeadConvertResult> doConvert(
		List<Database.LeadConvert> leadsToConvert,
		System.AccessLevel level
	) {
		return this.doConvert(leadsToConvert, true, level);
	}

	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global List<Database.LeadConvertResult> doConvert(List<Database.LeadConvert> leadsToConvert, Boolean allOrNone) {
		return this.doConvert(leadsToConvert, Dml.initDmlOptions(allOrNone));
	}

	global List<Database.LeadConvertResult> doConvert(List<Database.LeadConvert> leadsToConvert) {
		return this.doConvert(leadsToConvert, true);
	}

	global Database.LeadConvertResult doConvert(
		Database.LeadConvert leadToConvert,
		Database.DmlOptions options,
		System.AccessLevel accessLevel
	) {
		return this.doConvert(new List<Database.LeadConvert>{ leadToConvert }, options, accessLevel)?.get(0);
	}

	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global Database.LeadConvertResult doConvert(
		Database.LeadConvert leadToConvert,
		Boolean allOrNone,
		System.AccessLevel accessLevel
	) {
		return this.doConvert(new List<Database.LeadConvert>{ leadToConvert }, allOrNone, accessLevel)?.get(0);
	}

	global Database.LeadConvertResult doConvert(Database.LeadConvert leadToConvert, Database.DmlOptions options) {
		return this.doConvert(new List<Database.LeadConvert>{ leadToConvert }, options)?.get(0);
	}

	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global Database.LeadConvertResult doConvert(Database.LeadConvert leadToConvert, Boolean allOrNone) {
		return this.doConvert(new List<Database.LeadConvert>{ leadToConvert }, allOrNone)?.get(0);
	}

	global Database.LeadConvertResult doConvert(Database.LeadConvert leadToConvert, System.AccessLevel level) {
		return this.doConvert(new List<Database.LeadConvert>{ leadToConvert }, level)?.get(0);
	}

	global Database.LeadConvertResult doConvert(Database.LeadConvert leadToConvert) {
		return this.doConvert(new List<Database.LeadConvert>{ leadToConvert })?.get(0);
	}

	// ** Delete Methods
	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global List<Database.DeleteResult> doDelete(
		List<SObject> records,
		Boolean allOrNone,
		System.AccessLevel accessLevel
	) {
		Dml.Request request = this.initRequest(Dml.Operation.DO_DELETE, records);
		request.allOrNone = allOrNone;
		request.accessLevel = accessLevel;
		return (List<Database.DeleteResult>) request?.process();
	}

	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global List<Database.DeleteResult> doDelete(List<SObject> records, Boolean allOrNone) {
		return this.doDelete(records, allOrNone, DEFAULT_ACCESS_LEVEL);
	}

	global List<Database.DeleteResult> doDelete(List<SObject> records, System.AccessLevel accessLevel) {
		return this.doDelete(records, true, accessLevel);
	}

	global List<Database.DeleteResult> doDelete(List<SObject> records) {
		return this.doDelete(records, DEFAULT_ACCESS_LEVEL);
	}

	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global List<Database.DeleteResult> doDelete(List<Id> recordIds, Boolean allOrNone, System.AccessLevel accessLevel) {
		List<SObject> records = this.initRecordsFromIds(recordIds);
		return this.doDelete(records, allOrNone, accessLevel);
	}

	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global List<Database.DeleteResult> doDelete(List<Id> recordIds, Boolean allOrNone) {
		return this.doDelete(recordIds, allOrNone, DEFAULT_ACCESS_LEVEL);
	}

	global List<Database.DeleteResult> doDelete(List<Id> recordIds, System.AccessLevel accessLevel) {
		return this.doDelete(recordIds, true, accessLevel);
	}

	global List<Database.DeleteResult> doDelete(List<Id> recordIds) {
		return this.doDelete(recordIds, DEFAULT_ACCESS_LEVEL);
	}

	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global Database.DeleteResult doDelete(SObject record, Boolean allOrNone, System.AccessLevel accessLevel) {
		return this.doDelete(new List<SObject>{ record }, allOrNone, accessLevel)?.get(0);
	}

	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global Database.DeleteResult doDelete(SObject record, Boolean allOrNone) {
		return this.doDelete(new List<SObject>{ record }, allOrNone)?.get(0);
	}

	global Database.DeleteResult doDelete(SObject record, System.AccessLevel accessLevel) {
		return this.doDelete(new List<SObject>{ record }, accessLevel)?.get(0);
	}

	global Database.DeleteResult doDelete(SObject record) {
		return this.doDelete(new List<SObject>{ record })?.get(0);
	}

	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global Database.DeleteResult doDelete(Id recordId, Boolean allOrNone, System.AccessLevel accessLevel) {
		return this.doDelete(new List<Id>{ recordId }, allOrNone, accessLevel)?.get(0);
	}

	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global Database.DeleteResult doDelete(Id recordId, Boolean allOrNone) {
		return this.doDelete(new List<Id>{ recordId }, allOrNone)?.get(0);
	}

	global Database.DeleteResult doDelete(Id recordId, System.AccessLevel accessLevel) {
		return this.doDelete(new List<Id>{ recordId }, accessLevel)?.get(0);
	}

	global Database.DeleteResult doDelete(Id recordId) {
		return this.doDelete(new List<Id>{ recordId })?.get(0);
	}

	// ** DeleteAsync Methods
	global List<Database.DeleteResult> doDeleteAsync(
		List<SObject> records,
		DataSource.AsyncDeleteCallback callback,
		System.AccessLevel accessLevel
	) {
		Dml.Request request = this.initRequest(Dml.Operation.DO_DELETE, records);
		request.accessLevel = accessLevel;
		request.asyncDeleteCallback = callback;
		request.isOperationAsync = true;
		return (List<Database.DeleteResult>) request?.process();
	}

	global List<Database.DeleteResult> doDeleteAsync(List<SObject> records, DataSource.AsyncDeleteCallback callback) {
		return this.doDeleteAsync(records, callback, DEFAULT_ACCESS_LEVEL);
	}

	global List<Database.DeleteResult> doDeleteAsync(List<SObject> records, System.AccessLevel accessLevel) {
		return this.doDeleteAsync(records, DEFAULT_DELETE_CALLBACK, accessLevel);
	}

	global List<Database.DeleteResult> doDeleteAsync(List<SObject> records) {
		return this.doDeleteAsync(records, DEFAULT_ACCESS_LEVEL);
	}

	global Database.DeleteResult doDeleteAsync(
		SObject record,
		DataSource.AsyncDeleteCallback callback,
		System.AccessLevel accessLevel
	) {
		return this.doDeleteAsync(new List<SObject>{ record }, callback, accessLevel)?.get(0);
	}

	global Database.DeleteResult doDeleteAsync(SObject record, DataSource.AsyncDeleteCallback callback) {
		return this.doDeleteAsync(new List<SObject>{ record }, callback)?.get(0);
	}

	global Database.DeleteResult doDeleteAsync(SObject record, System.AccessLevel accessLevel) {
		return this.doDeleteAsync(new List<SObject>{ record }, accessLevel)?.get(0);
	}

	global Database.DeleteResult doDeleteAsync(SObject record) {
		return this.doDeleteAsync(new List<SObject>{ record })?.get(0);
	}

	// ** DeleteImmediate Methods
	global List<Database.DeleteResult> doDeleteImmediate(List<SObject> records, System.AccessLevel accessLevel) {
		Dml.Request request = this.initRequest(Dml.Operation.DO_DELETE, records);
		request.accessLevel = accessLevel;
		request.isOperationImmediate = true;
		return (List<Database.DeleteResult>) request?.process();
	}

	global List<Database.DeleteResult> doDeleteImmediate(List<SObject> records) {
		return this.doDeleteImmediate(records, DEFAULT_ACCESS_LEVEL);
	}

	global Database.DeleteResult doDeleteImmediate(SObject record, System.AccessLevel accessLevel) {
		return this.doDeleteImmediate(new List<SObject>{ record }, accessLevel)?.get(0);
	}

	global Database.DeleteResult doDeleteImmediate(SObject record) {
		return this.doDeleteImmediate(new List<SObject>{ record })?.get(0);
	}

	// ** Insert Methods
	global List<Database.SaveResult> doInsert(
		List<SObject> records,
		Database.DmlOptions options,
		System.AccessLevel accessLevel
	) {
		Dml.Request request = this.initRequest(Dml.Operation.DO_INSERT, records);
		request.accessLevel = accessLevel;
		request.options = options;
		return (List<Database.SaveResult>) request?.process();
	}

	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global List<Database.SaveResult> doInsert(
		List<SObject> records,
		Boolean allOrNone,
		System.AccessLevel accessLevel
	) {
		return this.doInsert(records, Dml.initDmlOptions(allOrNone), accessLevel);
	}

	global List<Database.SaveResult> doInsert(List<SObject> records, Database.DmlOptions options) {
		return this.doInsert(records, options, DEFAULT_ACCESS_LEVEL);
	}

	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global List<Database.SaveResult> doInsert(List<SObject> records, Boolean allOrNone) {
		return this.doInsert(records, allOrNone, DEFAULT_ACCESS_LEVEL);
	}

	global List<Database.SaveResult> doInsert(List<SObject> records, System.AccessLevel accessLevel) {
		return this.doInsert(records, true, accessLevel);
	}

	global List<Database.SaveResult> doInsert(List<SObject> records) {
		return this.doInsert(records, DEFAULT_ACCESS_LEVEL);
	}

	global Database.SaveResult doInsert(SObject record, Database.DmlOptions options, System.AccessLevel accessLevel) {
		return this.doInsert(new List<SObject>{ record }, options, accessLevel)?.get(0);
	}

	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global Database.SaveResult doInsert(SObject record, Boolean allOrNone, System.AccessLevel accessLevel) {
		return this.doInsert(new List<SObject>{ record }, allOrNone, accessLevel)?.get(0);
	}

	global Database.SaveResult doInsert(SObject record, Database.DmlOptions options) {
		return this.doInsert(new List<SObject>{ record }, options)?.get(0);
	}

	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global Database.SaveResult doInsert(SObject record, Boolean allOrNone) {
		return this.doInsert(new List<SObject>{ record }, allOrNone)?.get(0);
	}

	global Database.SaveResult doInsert(SObject record, System.AccessLevel accessLevel) {
		return this.doInsert(new List<SObject>{ record }, accessLevel)?.get(0);
	}

	global Database.SaveResult doInsert(SObject record) {
		return this.doInsert(new List<SObject>{ record })?.get(0);
	}

	// ** InsertAsync Methods
	global List<Database.SaveResult> doInsertAsync(
		List<SObject> records,
		DataSource.AsyncSaveCallback callback,
		System.AccessLevel accessLevel
	) {
		Dml.Request request = this.initRequest(Dml.Operation.DO_INSERT, records);
		request.accessLevel = accessLevel;
		request.asyncSaveCallback = callback;
		request.isOperationAsync = true;
		return (List<Database.SaveResult>) request?.process();
	}

	global List<Database.SaveResult> doInsertAsync(List<SObject> records, DataSource.AsyncSaveCallback callback) {
		return this.doInsertAsync(records, callback, DEFAULT_ACCESS_LEVEL);
	}

	global List<Database.SaveResult> doInsertAsync(List<SObject> records, System.AccessLevel accessLevel) {
		return this.doInsertAsync(records, DEFAULT_SAVE_CALLBACK, accessLevel);
	}

	global List<Database.SaveResult> doInsertAsync(List<SObject> records) {
		return this.doInsertAsync(records, DEFAULT_ACCESS_LEVEL);
	}

	global Database.SaveResult doInsertAsync(
		SObject record,
		DataSource.AsyncSaveCallback callback,
		System.AccessLevel accessLevel
	) {
		return this.doInsertAsync(new List<SObject>{ record }, callback, accessLevel)?.get(0);
	}

	global Database.SaveResult doInsertAsync(SObject record, DataSource.AsyncSaveCallback callback) {
		return this.doInsertAsync(new List<SObject>{ record }, callback)?.get(0);
	}

	global Database.SaveResult doInsertAsync(SObject record, System.AccessLevel accessLevel) {
		return this.doInsertAsync(new List<SObject>{ record }, accessLevel)?.get(0);
	}

	global Database.SaveResult doInsertAsync(SObject record) {
		return this.doInsertAsync(new List<SObject>{ record })?.get(0);
	}

	// ** InsertImmediate Methods
	global List<Database.SaveResult> doInsertImmediate(List<SObject> records, System.AccessLevel accessLevel) {
		Dml.Request request = this.initRequest(Dml.Operation.DO_INSERT, records);
		request.accessLevel = accessLevel;
		request.isOperationImmediate = true;
		return (List<Database.SaveResult>) request?.process();
	}

	global List<Database.SaveResult> doInsertImmediate(List<SObject> records) {
		return this.doInsertImmediate(records, DEFAULT_ACCESS_LEVEL);
	}

	global Database.SaveResult doInsertImmediate(SObject record, System.AccessLevel accessLevel) {
		return this.doInsertImmediate(new List<SObject>{ record }, accessLevel)?.get(0);
	}

	global Database.SaveResult doInsertImmediate(SObject record) {
		return this.doInsertImmediate(new List<SObject>{ record })?.get(0);
	}

	// ** Publish Methods
	global List<Database.SaveResult> doPublish(List<SObject> events) {
		// Callback: "An Apex class that implements the EventPublishFailureCallback Interface or EventPublishSuccessCallback Interface."
		// https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_class_System_eventbus.htm#apex_System_eventbus_publish_4
		return (List<Database.SaveResult>) this.initRequest(Dml.Operation.DO_PUBLISH, events)?.process();
	}

	global Database.SaveResult doPublish(SObject event) {
		return this.doPublish(new List<SObject>{ event })?.get(0);
	}

	// ** Undelete Methods
	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global List<Database.UndeleteResult> doUndelete(
		List<SObject> records,
		Boolean allOrNone,
		System.AccessLevel accessLevel
	) {
		Dml.Request request = this.initRequest(Dml.Operation.DO_UNDELETE, records);
		request.accessLevel = accessLevel;
		request.allOrNone = allOrNone;
		return (List<Database.UndeleteResult>) request?.process();
	}

	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global List<Database.UndeleteResult> doUndelete(List<SObject> records, Boolean allOrNone) {
		return this.doUndelete(records, allOrNone, DEFAULT_ACCESS_LEVEL);
	}

	global List<Database.UndeleteResult> doUndelete(List<SObject> records, System.AccessLevel accessLevel) {
		return this.doUndelete(records, true, accessLevel);
	}

	global List<Database.UndeleteResult> doUndelete(List<SObject> records) {
		return this.doUndelete(records, DEFAULT_ACCESS_LEVEL);
	}

	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global List<Database.UndeleteResult> doUndelete(
		List<Id> recordIds,
		Boolean allOrNone,
		System.AccessLevel accessLevel
	) {
		List<SObject> records = this.initRecordsFromIds(recordIds);
		return this.doUndelete(records, allOrNone, accessLevel);
	}

	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global List<Database.UndeleteResult> doUndelete(List<Id> recordIds, Boolean allOrNone) {
		return this.doUndelete(recordIds, allOrNone, DEFAULT_ACCESS_LEVEL);
	}

	global List<Database.UndeleteResult> doUndelete(List<Id> recordIds, System.AccessLevel accessLevel) {
		return this.doUndelete(recordIds, true, accessLevel);
	}

	global List<Database.UndeleteResult> doUndelete(List<Id> recordIds) {
		return this.doUndelete(recordIds, DEFAULT_ACCESS_LEVEL);
	}

	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global Database.UndeleteResult doUndelete(SObject record, Boolean allOrNone, System.AccessLevel accessLevel) {
		return this.doUndelete(new List<SObject>{ record }, allOrNone, accessLevel)?.get(0);
	}

	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global Database.UndeleteResult doUndelete(SObject record, Boolean allOrNone) {
		return this.doUndelete(new List<SObject>{ record }, allOrNone)?.get(0);
	}

	global Database.UndeleteResult doUndelete(SObject record, System.AccessLevel accessLevel) {
		return this.doUndelete(new List<SObject>{ record }, accessLevel)?.get(0);
	}

	global Database.UndeleteResult doUndelete(SObject record) {
		return this.doUndelete(new List<SObject>{ record })?.get(0);
	}

	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global Database.UndeleteResult doUndelete(Id recordId, Boolean allOrNone, System.AccessLevel accessLevel) {
		return this.doUndelete(new List<Id>{ recordId }, allOrNone, accessLevel)?.get(0);
	}

	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global Database.UndeleteResult doUndelete(Id recordId, Boolean allOrNone) {
		return this.doUndelete(new List<Id>{ recordId }, allOrNone)?.get(0);
	}

	global Database.UndeleteResult doUndelete(Id recordId, System.AccessLevel accessLevel) {
		return this.doUndelete(new List<Id>{ recordId }, accessLevel)?.get(0);
	}

	global Database.UndeleteResult doUndelete(Id recordId) {
		return this.doUndelete(new List<Id>{ recordId })?.get(0);
	}

	// ** Update Methods
	global List<Database.SaveResult> doUpdate(
		List<SObject> records,
		Database.DmlOptions options,
		System.AccessLevel accessLevel
	) {
		Dml.Request request = this.initRequest(Dml.Operation.DO_UPDATE, records);
		request.accessLevel = accessLevel;
		request.options = options;
		return (List<Database.SaveResult>) request?.process();
	}

	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global List<Database.SaveResult> doUpdate(
		List<SObject> records,
		Boolean allOrNone,
		System.AccessLevel accessLevel
	) {
		return this.doUpdate(records, Dml.initDmlOptions(allOrNone), accessLevel);
	}

	global List<Database.SaveResult> doUpdate(List<SObject> records, Database.DmlOptions options) {
		return this.doUpdate(records, options, DEFAULT_ACCESS_LEVEL);
	}

	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global List<Database.SaveResult> doUpdate(List<SObject> records, Boolean allOrNone) {
		return this.doUpdate(records, allOrNone, DEFAULT_ACCESS_LEVEL);
	}

	global List<Database.SaveResult> doUpdate(List<SObject> records, System.AccessLevel accessLevel) {
		return this.doUpdate(records, true, accessLevel);
	}

	global List<Database.SaveResult> doUpdate(List<SObject> records) {
		return this.doUpdate(records, DEFAULT_ACCESS_LEVEL);
	}

	global Database.SaveResult doUpdate(SObject record, Database.DmlOptions options, System.AccessLevel accessLevel) {
		return this.doUpdate(new List<SObject>{ record }, options, accessLevel)?.get(0);
	}

	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global Database.SaveResult doUpdate(SObject record, Boolean allOrNone, System.AccessLevel accessLevel) {
		return this.doUpdate(new List<SObject>{ record }, allOrNone, accessLevel)?.get(0);
	}

	global Database.SaveResult doUpdate(SObject record, Database.DmlOptions options) {
		return this.doUpdate(new List<SObject>{ record }, options)?.get(0);
	}

	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global Database.SaveResult doUpdate(SObject record, Boolean allOrNone) {
		return this.doUpdate(new List<SObject>{ record }, allOrNone)?.get(0);
	}

	global Database.SaveResult doUpdate(SObject record, System.AccessLevel accessLevel) {
		return this.doUpdate(new List<SObject>{ record }, accessLevel)?.get(0);
	}

	global Database.SaveResult doUpdate(SObject record) {
		return this.doUpdate(new List<SObject>{ record })?.get(0);
	}

	// ** UpdateAsync Methods
	global List<Database.SaveResult> doUpdateAsync(
		List<SObject> records,
		DataSource.AsyncSaveCallback callback,
		System.AccessLevel accessLevel
	) {
		Dml.Request request = this.initRequest(Dml.Operation.DO_UPDATE, records);
		request.accessLevel = accessLevel;
		request.asyncSaveCallback = callback;
		request.isOperationAsync = true;
		return (List<Database.SaveResult>) request?.process();
	}

	global List<Database.SaveResult> doUpdateAsync(List<SObject> records, DataSource.AsyncSaveCallback callback) {
		return this.doUpdateAsync(records, callback, DEFAULT_ACCESS_LEVEL);
	}

	global List<Database.SaveResult> doUpdateAsync(List<SObject> records, System.AccessLevel accessLevel) {
		return this.doUpdateAsync(records, DEFAULT_SAVE_CALLBACK, accessLevel);
	}

	global List<Database.SaveResult> doUpdateAsync(List<SObject> records) {
		return this.doUpdateAsync(records, DEFAULT_ACCESS_LEVEL);
	}

	global Database.SaveResult doUpdateAsync(
		SObject record,
		DataSource.AsyncSaveCallback callback,
		System.AccessLevel accessLevel
	) {
		return this.doUpdateAsync(new List<SObject>{ record }, callback, accessLevel)?.get(0);
	}

	global Database.SaveResult doUpdateAsync(SObject record, DataSource.AsyncSaveCallback callback) {
		return this.doUpdateAsync(new List<SObject>{ record }, callback)?.get(0);
	}

	global Database.SaveResult doUpdateAsync(SObject record, System.AccessLevel accessLevel) {
		return this.doUpdateAsync(new List<SObject>{ record }, accessLevel)?.get(0);
	}

	global Database.SaveResult doUpdateAsync(SObject record) {
		return this.doUpdateAsync(new List<SObject>{ record })?.get(0);
	}

	// ** UpdateImmediate Methods
	global List<Database.SaveResult> doUpdateImmediate(List<SObject> records, System.AccessLevel accessLevel) {
		Dml.Request request = this.initRequest(Dml.Operation.DO_UPDATE, records);
		request.accessLevel = accessLevel;
		request.isOperationImmediate = true;
		return (List<Database.SaveResult>) request?.process();
	}

	global List<Database.SaveResult> doUpdateImmediate(List<SObject> records) {
		return this.doUpdateImmediate(records, DEFAULT_ACCESS_LEVEL);
	}

	global Database.SaveResult doUpdateImmediate(SObject record, System.AccessLevel accessLevel) {
		return this.doUpdateImmediate(new List<SObject>{ record }, accessLevel)?.get(0);
	}

	global Database.SaveResult doUpdateImmediate(SObject record) {
		return this.doUpdateImmediate(new List<SObject>{ record })?.get(0);
	}

	// ** Upsert Methods
	@SuppressWarnings('PMD.AvoidBooleanMethodParameters,PMD.ExcessiveParameterList')
	global List<Database.UpsertResult> doUpsert(
		List<SObject> records,
		SObjectField externalIdField,
		Boolean allOrNone,
		System.AccessLevel accessLevel
	) {
		Dml.Request request = this.initRequest(Dml.Operation.DO_UPSERT, records);
		request.accessLevel = accessLevel;
		request.allOrNone = allOrNone;
		request.externalIdField = externalIdField;
		return (List<Database.UpsertResult>) request?.process();
	}

	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global List<Database.UpsertResult> doUpsert(
		List<SObject> records,
		SObjectField externalIdField,
		Boolean allOrNone
	) {
		return this.doUpsert(records, externalIdField, allOrNone, DEFAULT_ACCESS_LEVEL);
	}

	global List<Database.UpsertResult> doUpsert(
		List<SObject> records,
		SObjectField externalIdField,
		System.AccessLevel accessLevel
	) {
		return this.doUpsert(records, externalIdField, true, accessLevel);
	}

	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global List<Database.UpsertResult> doUpsert(
		List<SObject> records,
		Boolean allOrNone,
		System.AccessLevel accessLevel
	) {
		return this.doUpsert(records, null, allOrNone, accessLevel);
	}

	global List<Database.UpsertResult> doUpsert(List<SObject> records, SObjectField externalIdField) {
		return this.doUpsert(records, externalIdField, DEFAULT_ACCESS_LEVEL);
	}

	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global List<Database.UpsertResult> doUpsert(List<SObject> records, Boolean allOrNone) {
		return this.doUpsert(records, allOrNone, DEFAULT_ACCESS_LEVEL);
	}

	global List<Database.UpsertResult> doUpsert(List<SObject> records, System.AccessLevel accessLevel) {
		return this.doUpsert(records, true, accessLevel);
	}

	global List<Database.UpsertResult> doUpsert(List<SObject> records) {
		return this.doUpsert(records, DEFAULT_ACCESS_LEVEL);
	}

	@SuppressWarnings('PMD.AvoidBooleanMethodParameters,PMD.ExcessiveParameterList')
	global Database.UpsertResult doUpsert(
		SObject record,
		SObjectField externalIdField,
		Boolean allOrNone,
		System.AccessLevel accessLevel
	) {
		return this.doUpsert(new List<SObject>{ record }, externalIdField, allOrNone, accessLevel)?.get(0);
	}

	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global Database.UpsertResult doUpsert(SObject record, SObjectField externalIdField, Boolean allOrNone) {
		return this.doUpsert(new List<SObject>{ record }, externalIdField, allOrNone)?.get(0);
	}

	global Database.UpsertResult doUpsert(
		SObject record,
		SObjectField externalIdField,
		System.AccessLevel accessLevel
	) {
		return this.doUpsert(new List<SObject>{ record }, externalIdField, accessLevel)?.get(0);
	}

	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global Database.UpsertResult doUpsert(SObject record, Boolean allOrNone, System.AccessLevel accessLevel) {
		return this.doUpsert(new List<SObject>{ record }, allOrNone, accessLevel)?.get(0);
	}

	global Database.UpsertResult doUpsert(SObject record, SObjectField externalIdField) {
		return this.doUpsert(new List<SObject>{ record }, externalIdField)?.get(0);
	}

	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global Database.UpsertResult doUpsert(SObject record, Boolean allOrNone) {
		return this.doUpsert(new List<SObject>{ record }, allOrNone)?.get(0);
	}

	global Database.UpsertResult doUpsert(SObject record, System.AccessLevel accessLevel) {
		return this.doUpsert(new List<SObject>{ record }, accessLevel)?.get(0);
	}

	global Database.UpsertResult doUpsert(SObject record) {
		return this.doUpsert(new List<SObject>{ record })?.get(0);
	}

	// ** EmptyRecycleBin Methods
	global List<Database.EmptyRecycleBinResult> emptyRecycleBin(List<SObject> records) {
		Dml.Request request = this.initRequest(Dml.Operation.DO_PURGE, records);
		return (List<Database.EmptyRecycleBinResult>) request?.process();
	}

	global List<Database.EmptyRecycleBinResult> emptyRecycleBin(List<Id> recordIds) {
		List<SObject> records = this.initRecordsFromIds(recordIds);
		return this.emptyRecycleBin(records);
	}

	global Database.EmptyRecycleBinResult emptyRecycleBin(SObject record) {
		return this.emptyRecycleBin(new List<SObject>{ record })?.get(0);
	}

	global Database.EmptyRecycleBinResult emptyRecycleBin(Id recordId) {
		return this.emptyRecycleBin(new List<Id>{ recordId })?.get(0);
	}

	// ** Savepoint Methods
	/**
	 * These System.Savepoint methods mirror the Database class's static methods
	 * The benefit of calling these methods is largely to gain access to MockDml methods
	 * to assert if/which savepoints were set, rolled back, released, etc.
	 */
	global virtual void releaseSavepoint(System.Savepoint savepoint) {
		Database.releaseSavepoint(savepoint);
	}

	global virtual void rollback(System.Savepoint savepoint) {
		Database.rollback(savepoint);
	}

	global virtual System.Savepoint setSavepoint() {
		return Database.setSavepoint();
	}

	// **** PRIVATE **** //
	@TestVisible
	protected virtual Dml.Request initRequest(Dml.Operation operation, List<Object> records) {
		// Initialize a Dml.Request; mocks can override this method to return their own implementation which does not perform DML
		return new Dml.Request(operation, records);
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

	@TestVisible
	private void initPlugins() {
		// Initializes plugins based on the related custom metadata record
		// In production use cases, this will only happen once per transaction
		// In @IsTest uses cases, this happens every time the caller switches from Dml/MockDml
		// Test callers can also call this method directly to recalculate the plugins after injecting mock metadata:
		Dml.Plugin = (Dml.PreAndPostProcessor) DatabaseLayer.Utils?.Plugins?.initPlugin(PLUGIN_FIELD);
		// ... may add more plugins here in the future!
	}

	// **** STATIC **** //
	private static Database.DmlOptions initDmlOptions(Boolean allOrNone) {
		Database.DmlOptions options = new Database.DmlOptions();
		options.OptAllOrNone = allOrNone;
		return options;
	}

	// **** INNER **** //
	@TestVisible
	private class EmptyDeleteCallback extends DataSource.AsyncDeleteCallback {
		/**
		 *  If a callback isn't defined, doDeleteAsync() will use this class to gracefully handle callbacks
		 **/
		@SuppressWarnings('PMD.EmptyStatementBlock')
		public override void processDelete(Database.DeleteResult result) {
			// Do nothing
		}
	}

	@TestVisible
	private class EmptySaveCallback extends DataSource.AsyncSaveCallback {
		/**
		 * If a callback isn't defined, doInsertAsync() & doUpdateAsync will use this class to gracefully handle callbacks
		 **/
		@SuppressWarnings('PMD.EmptyStatementBlock')
		public override void processSave(Database.SaveResult result) {
			// Do nothing
		}
	}

	global enum Operation {
		DO_CONVERT,
		DO_DELETE,
		DO_INSERT,
		DO_PUBLISH,
		DO_PURGE,
		DO_UNDELETE,
		DO_UPDATE,
		DO_UPSERT
	}

	global interface PreAndPostProcessor {
		void processPreDml(Dml.Request request);
		void processPostDml(Dml.Request request, List<Object> databaseResults);
		void processDmlError(Dml.Request request, Exception error);
	}

	global inherited sharing virtual class Request {
		/**
		 * Represents a single call to one of the above DML methods, plus all its parameters
		 * Centralizing this information allows us to output information about the operation taking place
		 */
		// ** Always Required:
		global Dml.Operation operation { get; protected set; }
		// ** Conditionally Required:
		global transient List<SObject> records { get; protected set; }
		global transient List<Database.LeadConvert> leadsToConvert { get; protected set; }
		// ** Optional Parameters:
		global transient System.AccessLevel accessLevel { get; protected set; }
		global transient DataSource.AsyncDeleteCallback asyncDeleteCallback { get; protected set; }
		global transient DataSource.AsyncSaveCallback asyncSaveCallback { get; protected set; }
		global transient SObjectField externalIdField { get; protected set; }
		global Boolean isMockDml { get; protected set; }
		global Boolean isOperationAsync { get; protected set; }
		global Boolean isOperationImmediate { get; protected set; }
		global Database.DmlOptions options { get; protected set; }
		// ** Getters
		// These properties are read-only, and are used for JSON/output purposes,
		// ex., since some of the main class properties are not JSON-serializable
		global transient Boolean allOrNone {
			get {
				// Is not actually stored as a value; mirrors the DmlOptions' OptAllOrNone value
				this.options = this.options ?? Dml.initDmlOptions(true);
				return this.options?.OptAllOrNone;
			}
			protected set {
				// Ensure the DmlOptions' OptAllOrNone value matches:
				this.options.OptAllOrNone = value;
			}
		}
		global Integer numRecords {
			// Output the number of records being operated on:
			get {
				return this.getNumRecords();
			}
		}

		global String sObjectType {
			// Output the name of the SObjectType being operated on, if known:
			get {
				return this.getSObjectTypeName();
			}
		}
		private String accessLevelName {
			// System.AccessLevel is not JSON serializable
			// Unlike other enums, it does not have a name() property, and toString() does not output its name either:
			get {
				return (this.accessLevel == System.AccessLevel.SYSTEM_MODE) ? 'SYSTEM_MODE' : 'USER_MODE';
			}
		}
		private String deleteCallback {
			// The DataSource.AsyncDeleteCallback may/may not be serializable, based on its implementation
			// Prevent serialization errors by outputting the raw toString() value for logs:
			get {
				return String.valueOf(this.asyncDeleteCallback);
			}
		}
		private String externalIdFieldName {
			// SObjectFields are not JSON-serializable
			get {
				return this.externalIdField?.toString();
			}
		}
		private String saveCallback {
			// The DataSource.AsyncSaveCallback may/may not be serializable, based on its implementation
			// Prevent serialization errors by outputting the raw toString() value for logs:
			get {
				return String.valueOf(this.asyncSaveCallback);
			}
		}

		// ** Methods:
		protected Request(Dml.Operation operation, List<Object> records) {
			this.operation = operation;
			this.accessLevel = DEFAULT_ACCESS_LEVEL;
			this.asyncDeleteCallback = DEFAULT_DELETE_CALLBACK;
			this.isMockDml = false;
			this.isOperationAsync = false;
			this.isOperationImmediate = false;
			this.options = Dml.initDmlOptions(true);
			this.asyncSaveCallback = DEFAULT_SAVE_CALLBACK;
			this.setRecordCollection(records);
		}

		protected List<Object> process() {
			// Main method called by the Dml class; processes DML, and calls the Pre/Post DML plugins:
			try {
				Dml.Plugin?.processPreDml(this);
				List<Object> results = this.doDml();
				Dml.Plugin?.processPostDml(this, results);
				return results;
			} catch (Exception error) {
				// Allow the plugin to act on DML exceptions, ex., for logging
				// The error will still be thrown anyways:
				Dml.Plugin?.processDmlError(this, error);
				throw error;
			}
		}

		protected List<Object> doDml() {
			// Perform the correct DML method based on the Dml.Operation
			List<Object> results;
			if (this.operation == Dml.Operation.DO_CONVERT) {
				results = this.doConvert();
			} else if (this.operation == Dml.Operation.DO_DELETE) {
				results = this.doDelete();
			} else if (this.operation == Dml.Operation.DO_INSERT) {
				results = this.doInsert();
			} else if (this.operation == Dml.Operation.DO_PUBLISH) {
				results = this.doPublish();
			} else if (this.operation == Dml.Operation.DO_PURGE) {
				results = this.emptyRecycleBin();
			} else if (this.operation == Dml.Operation.DO_UNDELETE) {
				results = this.doUndelete();
			} else if (this.operation == Dml.Operation.DO_UPDATE) {
				results = this.doUpdate();
			} else if (this.operation == Dml.Operation.DO_UPSERT) {
				results = this.doUpsert();
			}
			return results;
		}

		// ** Virtual:
		protected virtual List<Database.LeadConvertResult> doConvert() {
			return Database.convertLead(this.leadsToConvert, this.options, this.accessLevel);
		}

		protected virtual List<Database.DeleteResult> doDelete() {
			if (this.isOperationAsync == true) {
				return Database.deleteAsync(this.records, this.asyncDeleteCallback, this.accessLevel);
			} else if (this.isOperationImmediate == true) {
				return Database.deleteImmediate(this.records, this.accessLevel);
			} else {
				return Database.delete(this.records, this.allOrNone, this.accessLevel);
			}
		}

		protected virtual List<Database.SaveResult> doInsert() {
			if (this.isOperationAsync == true) {
				return Database.insertAsync(this.records, this.asyncSaveCallback, this.accessLevel);
			} else if (this.isOperationImmediate == true) {
				return Database.insertImmediate(this.records, this.accessLevel);
			} else {
				return Database.insert(this.records, this.allOrNone, this.accessLevel);
			}
		}

		protected virtual List<Database.SaveResult> doPublish() {
			return EventBus.publish(this.records);
		}

		protected virtual List<Database.UndeleteResult> doUndelete() {
			return Database.undelete(this.records, this.allOrNone, this.accessLevel);
		}

		protected virtual List<Database.SaveResult> doUpdate() {
			if (this.isOperationAsync == true) {
				return Database.updateAsync(this.records, this.asyncSaveCallback, this.accessLevel);
			} else if (this.isOperationImmediate == true) {
				return Database.updateImmediate(this.records, this.accessLevel);
			} else {
				return Database.update(this.records, this.allOrNone, this.accessLevel);
			}
		}

		protected virtual List<Database.UpsertResult> doUpsert() {
			// Note: Supplying a null ExternalIdField value to Database.upsert will result in an Exception
			// To avoid this, call the correct overload depending on the supplied field value
			if (this.externalIdField != null) {
				return Database.upsert(this.records, this.externalIdField, this.allOrNone, this.accessLevel);
			} else {
				return Database.upsert(this.records, this.allOrNone, this.accessLevel);
			}
		}

		protected virtual List<Database.EmptyRecycleBinResult> emptyRecycleBin() {
			return Database.emptyRecycleBin(this.records);
		}

		// ** Private:
		private Integer getNumRecords() {
			Integer num = (this.operation == Dml.Operation.DO_CONVERT)
				? this.leadsToConvert?.size()
				: this.records?.size();
			return num ?? 0;
		}

		private String getSObjectTypeName() {
			// Output the name of the SObjectType, if known:
			if (this.operation == Dml.Operation.DO_CONVERT) {
				return Database.LeadConvert.class.getName();
			} else if (this.records?.size() == 1) {
				// Single records are always passed to a generic List<SObject>
				// Multiple records shouldn't use this method, since they could contain multiple SObjectTypes
				return this.records?.get(0)?.getSObjectType()?.toString();
			} else {
				// Return the List type, or "SObject" if unknown:
				return this.records?.toString() ?? SObject.class.getName();
			}
		}

		private void setRecordCollection(List<Object> objs) {
			// Set the appropriate record collection, based on the operation:
			if (this.operation == Dml.Operation.DO_CONVERT) {
				this.leadsToConvert = (List<Database.LeadConvert>) objs;
			} else {
				this.records = (List<SObject>) objs;
			}
		}
	}
}
