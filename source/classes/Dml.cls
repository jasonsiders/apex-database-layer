/**
 * @description Handles all DML operations with the Salesforce database. Provides a mockable interface for CRUD operations, plugins, and comprehensive parameter support.
 */
@SuppressWarnings(
	'PMD.AvoidGlobalModifier,PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.ExcessiveClassLength,PMD.ExcessivePublicCount'
)
global inherited sharing virtual class Dml {
	private static final System.AccessLevel DEFAULT_ACCESS_LEVEL = System.AccessLevel.USER_MODE;
	private static final DataSource.AsyncDeleteCallback DEFAULT_DELETE_CALLBACK = new Dml.EmptyDeleteCallback();
	private static final DataSource.AsyncSaveCallback DEFAULT_SAVE_CALLBACK = new Dml.EmptySaveCallback();
	private static final SObjectField PLUGIN_FIELD = DatabaseLayerSetting__mdt.DmlPreAndPostProcessor__c;

	/**
	 * @description Constructor for Dml instance.
	 * Note: Should not be called directly - use DatabaseLayer.Dml property instead.
	 * @param factory The DatabaseLayer factory instance
	 */
	@SuppressWarnings('PMD.EmptyStatementBlock')
	public Dml(DatabaseLayer factory) {
		// Access this class method's via the `DatabaseLayer.Dml` static property
	}

	/**
	 * @description Converts leads using the specified options and access level.
	 * @param leadsToConvert List of Database.LeadConvert objects to process
	 * @param options DML options for the conversion operation
	 * @param accessLevel System access level for the operation
	 * @return List of Database.LeadConvertResult objects
	 */
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

	/**
	 * @description Converts leads using the specified all-or-none setting and access level.
	 * @param leadsToConvert List of Database.LeadConvert objects to process
	 * @param allOrNone Whether all operations must succeed or all fail
	 * @param accessLevel System access level for the operation
	 * @return List of Database.LeadConvertResult objects
	 */
	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global List<Database.LeadConvertResult> doConvert(
		List<Database.LeadConvert> leadsToConvert,
		Boolean allOrNone,
		System.AccessLevel accessLevel
	) {
		return this.doConvert(leadsToConvert, Dml.initDmlOptions(allOrNone), accessLevel);
	}

	/**
	 * @description Converts leads using the specified options and default access level.
	 * @param leadsToConvert List of Database.LeadConvert objects to process
	 * @param options DML options for the conversion operation
	 * @return List of Database.LeadConvertResult objects
	 */
	global List<Database.LeadConvertResult> doConvert(
		List<Database.LeadConvert> leadsToConvert,
		Database.DmlOptions options
	) {
		return this.doConvert(leadsToConvert, options, DEFAULT_ACCESS_LEVEL);
	}

	/**
	 * @description Converts leads using the specified access level and default all-or-none setting.
	 * @param leadsToConvert List of Database.LeadConvert objects to process
	 * @param level System access level for the operation
	 * @return List of Database.LeadConvertResult objects
	 */
	global List<Database.LeadConvertResult> doConvert(
		List<Database.LeadConvert> leadsToConvert,
		System.AccessLevel level
	) {
		return this.doConvert(leadsToConvert, true, level);
	}

	/**
	 * @description Converts leads using the specified all-or-none setting and default access level.
	 * @param leadsToConvert List of Database.LeadConvert objects to process
	 * @param allOrNone Whether all operations must succeed or all fail
	 * @return List of Database.LeadConvertResult objects
	 */
	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global List<Database.LeadConvertResult> doConvert(List<Database.LeadConvert> leadsToConvert, Boolean allOrNone) {
		return this.doConvert(leadsToConvert, Dml.initDmlOptions(allOrNone));
	}

	/**
	 * @description Converts leads using default settings (all-or-none true, user mode access).
	 * @param leadsToConvert List of Database.LeadConvert objects to process
	 * @return List of Database.LeadConvertResult objects
	 */
	global List<Database.LeadConvertResult> doConvert(List<Database.LeadConvert> leadsToConvert) {
		return this.doConvert(leadsToConvert, true);
	}

	/**
	 * @description Converts a single lead using the specified options and access level.
	 * @param leadToConvert Database.LeadConvert object to process
	 * @param options DML options for the conversion operation
	 * @param accessLevel System access level for the operation
	 * @return Database.LeadConvertResult object
	 */
	global Database.LeadConvertResult doConvert(
		Database.LeadConvert leadToConvert,
		Database.DmlOptions options,
		System.AccessLevel accessLevel
	) {
		return this.doConvert(new List<Database.LeadConvert>{ leadToConvert }, options, accessLevel)?.get(0);
	}

	/**
	 * @description Converts a single lead using the specified all-or-none setting and access level.
	 * @param leadToConvert Database.LeadConvert object to process
	 * @param allOrNone Whether all operations must succeed or all fail
	 * @param accessLevel System access level for the operation
	 * @return Database.LeadConvertResult object
	 */
	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global Database.LeadConvertResult doConvert(
		Database.LeadConvert leadToConvert,
		Boolean allOrNone,
		System.AccessLevel accessLevel
	) {
		return this.doConvert(new List<Database.LeadConvert>{ leadToConvert }, allOrNone, accessLevel)?.get(0);
	}

	/**
	 * @description Converts a single lead using the specified options and default access level.
	 * @param leadToConvert Database.LeadConvert object to process
	 * @param options DML options for the conversion operation
	 * @return Database.LeadConvertResult object
	 */
	global Database.LeadConvertResult doConvert(Database.LeadConvert leadToConvert, Database.DmlOptions options) {
		return this.doConvert(new List<Database.LeadConvert>{ leadToConvert }, options)?.get(0);
	}

	/**
	 * @description Converts a single lead using the specified all-or-none setting and default access level.
	 * @param leadToConvert Database.LeadConvert object to process
	 * @param allOrNone Whether all operations must succeed or all fail
	 * @return Database.LeadConvertResult object
	 */
	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global Database.LeadConvertResult doConvert(Database.LeadConvert leadToConvert, Boolean allOrNone) {
		return this.doConvert(new List<Database.LeadConvert>{ leadToConvert }, allOrNone)?.get(0);
	}

	/**
	 * @description Converts a single lead using the specified access level and default all-or-none setting.
	 * @param leadToConvert Database.LeadConvert object to process
	 * @param level System access level for the operation
	 * @return Database.LeadConvertResult object
	 */
	global Database.LeadConvertResult doConvert(Database.LeadConvert leadToConvert, System.AccessLevel level) {
		return this.doConvert(new List<Database.LeadConvert>{ leadToConvert }, level)?.get(0);
	}

	/**
	 * @description Converts a single lead using default settings (all-or-none true, user mode access).
	 * @param leadToConvert Database.LeadConvert object to process
	 * @return Database.LeadConvertResult object
	 */
	global Database.LeadConvertResult doConvert(Database.LeadConvert leadToConvert) {
		return this.doConvert(new List<Database.LeadConvert>{ leadToConvert })?.get(0);
	}

	// ** Delete Methods
	/**
	 * @description Deletes a list of records using the specified all-or-none setting and access level.
	 * @param records List of SObject records to delete
	 * @param allOrNone Whether all operations must succeed or all fail
	 * @param accessLevel System access level for the operation
	 * @return List of Database.DeleteResult objects
	 */
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

	/**
	 * @description Deletes a list of records using the specified all-or-none setting and default access level.
	 * @param records List of SObject records to delete
	 * @param allOrNone Whether all operations must succeed or all fail
	 * @return List of Database.DeleteResult objects
	 */
	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global List<Database.DeleteResult> doDelete(List<SObject> records, Boolean allOrNone) {
		return this.doDelete(records, allOrNone, DEFAULT_ACCESS_LEVEL);
	}

	/**
	 * @description Deletes a list of records using the specified access level and default all-or-none setting.
	 * @param records List of SObject records to delete
	 * @param accessLevel System access level for the operation
	 * @return List of Database.DeleteResult objects
	 */
	global List<Database.DeleteResult> doDelete(List<SObject> records, System.AccessLevel accessLevel) {
		return this.doDelete(records, true, accessLevel);
	}

	/**
	 * @description Deletes a list of records using default settings (all-or-none true, user mode access).
	 * @param records List of SObject records to delete
	 * @return List of Database.DeleteResult objects
	 */
	global List<Database.DeleteResult> doDelete(List<SObject> records) {
		return this.doDelete(records, DEFAULT_ACCESS_LEVEL);
	}

	/**
	 * @description Deletes records by IDs using the specified all-or-none setting and access level.
	 * @param recordIds List of record IDs to delete
	 * @param allOrNone Whether all operations must succeed or all fail
	 * @param accessLevel System access level for the operation
	 * @return List of Database.DeleteResult objects
	 */
	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global List<Database.DeleteResult> doDelete(List<Id> recordIds, Boolean allOrNone, System.AccessLevel accessLevel) {
		List<SObject> records = DatabaseLayer.Utils.SObjects.newSObjects(recordIds);
		return this.doDelete(records, allOrNone, accessLevel);
	}

	/**
	 * @description Deletes records by IDs using the specified all-or-none setting and default access level.
	 * @param recordIds List of record IDs to delete
	 * @param allOrNone Whether all operations must succeed or all fail
	 * @return List of Database.DeleteResult objects
	 */
	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global List<Database.DeleteResult> doDelete(List<Id> recordIds, Boolean allOrNone) {
		return this.doDelete(recordIds, allOrNone, DEFAULT_ACCESS_LEVEL);
	}

	/**
	 * @description Deletes records by IDs using the specified access level and default all-or-none setting.
	 * @param recordIds List of record IDs to delete
	 * @param accessLevel System access level for the operation
	 * @return List of Database.DeleteResult objects
	 */
	global List<Database.DeleteResult> doDelete(List<Id> recordIds, System.AccessLevel accessLevel) {
		return this.doDelete(recordIds, true, accessLevel);
	}

	/**
	 * @description Deletes records by IDs using default settings (all-or-none true, user mode access).
	 * @param recordIds List of record IDs to delete
	 * @return List of Database.DeleteResult objects
	 */
	global List<Database.DeleteResult> doDelete(List<Id> recordIds) {
		return this.doDelete(recordIds, DEFAULT_ACCESS_LEVEL);
	}

	/**
	 * @description Deletes a single record using the specified all-or-none setting and access level.
	 * @param record SObject record to delete
	 * @param allOrNone Whether all operations must succeed or all fail
	 * @param accessLevel System access level for the operation
	 * @return Database.DeleteResult object
	 */
	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global Database.DeleteResult doDelete(SObject record, Boolean allOrNone, System.AccessLevel accessLevel) {
		return this.doDelete(new List<SObject>{ record }, allOrNone, accessLevel)?.get(0);
	}

	/**
	 * @description Deletes a single record using the specified all-or-none setting and default access level.
	 * @param record SObject record to delete
	 * @param allOrNone Whether all operations must succeed or all fail
	 * @return Database.DeleteResult object
	 */
	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global Database.DeleteResult doDelete(SObject record, Boolean allOrNone) {
		return this.doDelete(new List<SObject>{ record }, allOrNone)?.get(0);
	}

	/**
	 * @description Deletes a single record using the specified access level and default all-or-none setting.
	 * @param record SObject record to delete
	 * @param accessLevel System access level for the operation
	 * @return Database.DeleteResult object
	 */
	global Database.DeleteResult doDelete(SObject record, System.AccessLevel accessLevel) {
		return this.doDelete(new List<SObject>{ record }, accessLevel)?.get(0);
	}

	/**
	 * @description Deletes a single record using default settings (all-or-none true, user mode access).
	 * @param record SObject record to delete
	 * @return Database.DeleteResult object
	 */
	global Database.DeleteResult doDelete(SObject record) {
		return this.doDelete(new List<SObject>{ record })?.get(0);
	}

	/**
	 * @description Deletes a single record by ID using the specified all-or-none setting and access level.
	 * @param recordId ID of the record to delete
	 * @param allOrNone Whether all operations must succeed or all fail
	 * @param accessLevel System access level for the operation
	 * @return Database.DeleteResult object
	 */
	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global Database.DeleteResult doDelete(Id recordId, Boolean allOrNone, System.AccessLevel accessLevel) {
		return this.doDelete(new List<Id>{ recordId }, allOrNone, accessLevel)?.get(0);
	}

	/**
	 * @description Deletes a single record by ID using the specified all-or-none setting and default access level.
	 * @param recordId ID of the record to delete
	 * @param allOrNone Whether all operations must succeed or all fail
	 * @return Database.DeleteResult object
	 */
	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global Database.DeleteResult doDelete(Id recordId, Boolean allOrNone) {
		return this.doDelete(new List<Id>{ recordId }, allOrNone)?.get(0);
	}

	/**
	 * @description Deletes a single record by ID using the specified access level and default all-or-none setting.
	 * @param recordId ID of the record to delete
	 * @param accessLevel System access level for the operation
	 * @return Database.DeleteResult object
	 */
	global Database.DeleteResult doDelete(Id recordId, System.AccessLevel accessLevel) {
		return this.doDelete(new List<Id>{ recordId }, accessLevel)?.get(0);
	}

	/**
	 * @description Deletes a single record by ID using default settings (all-or-none true, user mode access).
	 * @param recordId ID of the record to delete
	 * @return Database.DeleteResult object
	 */
	global Database.DeleteResult doDelete(Id recordId) {
		return this.doDelete(new List<Id>{ recordId })?.get(0);
	}

	// ** DeleteAsync Methods
	/**
	 * @description Asynchronously deletes a list of records using the specified callback and access level.
	 * @param records List of SObject records to delete
	 * @param callback Callback to handle async delete results
	 * @param accessLevel System access level for the operation
	 * @return List of Database.DeleteResult objects
	 */
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

	/**
	 * @description Asynchronously deletes a list of records using the specified callback and default access level.
	 * @param records List of SObject records to delete
	 * @param callback Callback to handle async delete results
	 * @return List of Database.DeleteResult objects
	 */
	global List<Database.DeleteResult> doDeleteAsync(List<SObject> records, DataSource.AsyncDeleteCallback callback) {
		return this.doDeleteAsync(records, callback, DEFAULT_ACCESS_LEVEL);
	}

	/**
	 * @description Asynchronously deletes a list of records using the specified access level and default callback.
	 * @param records List of SObject records to delete
	 * @param accessLevel System access level for the operation
	 * @return List of Database.DeleteResult objects
	 */
	global List<Database.DeleteResult> doDeleteAsync(List<SObject> records, System.AccessLevel accessLevel) {
		return this.doDeleteAsync(records, DEFAULT_DELETE_CALLBACK, accessLevel);
	}

	/**
	 * @description Asynchronously deletes a list of records using default settings (default callback, user mode access).
	 * @param records List of SObject records to delete
	 * @return List of Database.DeleteResult objects
	 */
	global List<Database.DeleteResult> doDeleteAsync(List<SObject> records) {
		return this.doDeleteAsync(records, DEFAULT_ACCESS_LEVEL);
	}

	/**
	 * @description Asynchronously deletes a single record using the specified callback and access level.
	 * @param record SObject record to delete
	 * @param callback Callback to handle async delete results
	 * @param accessLevel System access level for the operation
	 * @return Database.DeleteResult object
	 */
	global Database.DeleteResult doDeleteAsync(
		SObject record,
		DataSource.AsyncDeleteCallback callback,
		System.AccessLevel accessLevel
	) {
		return this.doDeleteAsync(new List<SObject>{ record }, callback, accessLevel)?.get(0);
	}

	/**
	 * @description Asynchronously deletes a single record using the specified callback and default access level.
	 * @param record SObject record to delete
	 * @param callback Callback to handle async delete results
	 * @return Database.DeleteResult object
	 */
	global Database.DeleteResult doDeleteAsync(SObject record, DataSource.AsyncDeleteCallback callback) {
		return this.doDeleteAsync(new List<SObject>{ record }, callback)?.get(0);
	}

	/**
	 * @description Asynchronously deletes a single record using the specified access level and default callback.
	 * @param record SObject record to delete
	 * @param accessLevel System access level for the operation
	 * @return Database.DeleteResult object
	 */
	global Database.DeleteResult doDeleteAsync(SObject record, System.AccessLevel accessLevel) {
		return this.doDeleteAsync(new List<SObject>{ record }, accessLevel)?.get(0);
	}

	/**
	 * @description Asynchronously deletes a single record using default settings (default callback, user mode access).
	 * @param record SObject record to delete
	 * @return Database.DeleteResult object
	 */
	global Database.DeleteResult doDeleteAsync(SObject record) {
		return this.doDeleteAsync(new List<SObject>{ record })?.get(0);
	}

	// ** DeleteImmediate Methods
	/**
	 * @description Immediately deletes a list of records using the specified access level.
	 * @param records List of SObject records to delete
	 * @param accessLevel System access level for the operation
	 * @return List of Database.DeleteResult objects
	 */
	global List<Database.DeleteResult> doDeleteImmediate(List<SObject> records, System.AccessLevel accessLevel) {
		Dml.Request request = this.initRequest(Dml.Operation.DO_DELETE, records);
		request.accessLevel = accessLevel;
		request.isOperationImmediate = true;
		return (List<Database.DeleteResult>) request?.process();
	}

	/**
	 * @description Immediately deletes a list of records using default access level (user mode).
	 * @param records List of SObject records to delete
	 * @return List of Database.DeleteResult objects
	 */
	global List<Database.DeleteResult> doDeleteImmediate(List<SObject> records) {
		return this.doDeleteImmediate(records, DEFAULT_ACCESS_LEVEL);
	}

	/**
	 * @description Immediately deletes a single record using the specified access level.
	 * @param record SObject record to delete
	 * @param accessLevel System access level for the operation
	 * @return Database.DeleteResult object
	 */
	global Database.DeleteResult doDeleteImmediate(SObject record, System.AccessLevel accessLevel) {
		return this.doDeleteImmediate(new List<SObject>{ record }, accessLevel)?.get(0);
	}

	/**
	 * @description Immediately deletes a single record using default access level (user mode).
	 * @param record SObject record to delete
	 * @return Database.DeleteResult object
	 */
	global Database.DeleteResult doDeleteImmediate(SObject record) {
		return this.doDeleteImmediate(new List<SObject>{ record })?.get(0);
	}

	// ** Insert Methods
	/**
	 * @description Inserts a list of records using the specified options and access level.
	 * @param records List of SObject records to insert
	 * @param options DML options for the insert operation
	 * @param accessLevel System access level for the operation
	 * @return List of Database.SaveResult objects
	 */
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

	/**
	 * @description Inserts a list of records using the specified all-or-none setting and access level.
	 * @param records List of SObject records to insert
	 * @param allOrNone Whether all operations must succeed or all fail
	 * @param accessLevel System access level for the operation
	 * @return List of Database.SaveResult objects
	 */
	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global List<Database.SaveResult> doInsert(
		List<SObject> records,
		Boolean allOrNone,
		System.AccessLevel accessLevel
	) {
		return this.doInsert(records, Dml.initDmlOptions(allOrNone), accessLevel);
	}

	/**
	 * @description Inserts a list of records using the specified options and default access level.
	 * @param records List of SObject records to insert
	 * @param options DML options for the insert operation
	 * @return List of Database.SaveResult objects
	 */
	global List<Database.SaveResult> doInsert(List<SObject> records, Database.DmlOptions options) {
		return this.doInsert(records, options, DEFAULT_ACCESS_LEVEL);
	}

	/**
	 * @description Inserts a list of records using the specified all-or-none setting and default access level.
	 * @param records List of SObject records to insert
	 * @param allOrNone Whether all operations must succeed or all fail
	 * @return List of Database.SaveResult objects
	 */
	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global List<Database.SaveResult> doInsert(List<SObject> records, Boolean allOrNone) {
		return this.doInsert(records, allOrNone, DEFAULT_ACCESS_LEVEL);
	}

	/**
	 * @description Inserts a list of records using the specified access level and default all-or-none setting.
	 * @param records List of SObject records to insert
	 * @param accessLevel System access level for the operation
	 * @return List of Database.SaveResult objects
	 */
	global List<Database.SaveResult> doInsert(List<SObject> records, System.AccessLevel accessLevel) {
		return this.doInsert(records, true, accessLevel);
	}

	/**
	 * @description Inserts a list of records using default settings (all-or-none true, user mode access).
	 * @param records List of SObject records to insert
	 * @return List of Database.SaveResult objects
	 */
	global List<Database.SaveResult> doInsert(List<SObject> records) {
		return this.doInsert(records, DEFAULT_ACCESS_LEVEL);
	}

	/**
	 * @description Inserts a single record using the specified options and access level.
	 * @param record SObject record to insert
	 * @param options DML options for the insert operation
	 * @param accessLevel System access level for the operation
	 * @return Database.SaveResult object
	 */
	global Database.SaveResult doInsert(SObject record, Database.DmlOptions options, System.AccessLevel accessLevel) {
		return this.doInsert(new List<SObject>{ record }, options, accessLevel)?.get(0);
	}

	/**
	 * @description Inserts a single record using the specified all-or-none setting and access level.
	 * @param record SObject record to insert
	 * @param allOrNone Whether all operations must succeed or all fail
	 * @param accessLevel System access level for the operation
	 * @return Database.SaveResult object
	 */
	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global Database.SaveResult doInsert(SObject record, Boolean allOrNone, System.AccessLevel accessLevel) {
		return this.doInsert(new List<SObject>{ record }, allOrNone, accessLevel)?.get(0);
	}

	/**
	 * @description Inserts a single record using the specified options and default access level.
	 * @param record SObject record to insert
	 * @param options DML options for the insert operation
	 * @return Database.SaveResult object
	 */
	global Database.SaveResult doInsert(SObject record, Database.DmlOptions options) {
		return this.doInsert(new List<SObject>{ record }, options)?.get(0);
	}

	/**
	 * @description Inserts a single record using the specified all-or-none setting and default access level.
	 * @param record SObject record to insert
	 * @param allOrNone Whether all operations must succeed or all fail
	 * @return Database.SaveResult object
	 */
	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global Database.SaveResult doInsert(SObject record, Boolean allOrNone) {
		return this.doInsert(new List<SObject>{ record }, allOrNone)?.get(0);
	}

	/**
	 * @description Inserts a single record using the specified access level and default all-or-none setting.
	 * @param record SObject record to insert
	 * @param accessLevel System access level for the operation
	 * @return Database.SaveResult object
	 */
	global Database.SaveResult doInsert(SObject record, System.AccessLevel accessLevel) {
		return this.doInsert(new List<SObject>{ record }, accessLevel)?.get(0);
	}

	/**
	 * @description Inserts a single record using default settings (all-or-none true, user mode access).
	 * @param record SObject record to insert
	 * @return Database.SaveResult object
	 */
	global Database.SaveResult doInsert(SObject record) {
		return this.doInsert(new List<SObject>{ record })?.get(0);
	}

	// ** InsertAsync Methods
	/**
	 * @description Asynchronously inserts a list of records using the specified callback and access level.
	 * @param records List of SObject records to insert
	 * @param callback Callback to handle async save results
	 * @param accessLevel System access level for the operation
	 * @return List of Database.SaveResult objects
	 */
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

	/**
	 * @description Asynchronously inserts a list of records using the specified callback and default access level.
	 * @param records List of SObject records to insert
	 * @param callback Callback to handle async save results
	 * @return List of Database.SaveResult objects
	 */
	global List<Database.SaveResult> doInsertAsync(List<SObject> records, DataSource.AsyncSaveCallback callback) {
		return this.doInsertAsync(records, callback, DEFAULT_ACCESS_LEVEL);
	}

	/**
	 * @description Asynchronously inserts a list of records using the specified access level and default callback.
	 * @param records List of SObject records to insert
	 * @param accessLevel System access level for the operation
	 * @return List of Database.SaveResult objects
	 */
	global List<Database.SaveResult> doInsertAsync(List<SObject> records, System.AccessLevel accessLevel) {
		return this.doInsertAsync(records, DEFAULT_SAVE_CALLBACK, accessLevel);
	}

	/**
	 * @description Asynchronously inserts a list of records using default settings (default callback, user mode access).
	 * @param records List of SObject records to insert
	 * @return List of Database.SaveResult objects
	 */
	global List<Database.SaveResult> doInsertAsync(List<SObject> records) {
		return this.doInsertAsync(records, DEFAULT_ACCESS_LEVEL);
	}

	/**
	 * @description Asynchronously inserts a single record using the specified callback and access level.
	 * @param record SObject record to insert
	 * @param callback Callback to handle async save results
	 * @param accessLevel System access level for the operation
	 * @return Database.SaveResult object
	 */
	global Database.SaveResult doInsertAsync(
		SObject record,
		DataSource.AsyncSaveCallback callback,
		System.AccessLevel accessLevel
	) {
		return this.doInsertAsync(new List<SObject>{ record }, callback, accessLevel)?.get(0);
	}

	/**
	 * @description Asynchronously inserts a single record using the specified callback and default access level.
	 * @param record SObject record to insert
	 * @param callback Callback to handle async save results
	 * @return Database.SaveResult object
	 */
	global Database.SaveResult doInsertAsync(SObject record, DataSource.AsyncSaveCallback callback) {
		return this.doInsertAsync(new List<SObject>{ record }, callback)?.get(0);
	}

	/**
	 * @description Asynchronously inserts a single record using the specified access level and default callback.
	 * @param record SObject record to insert
	 * @param accessLevel System access level for the operation
	 * @return Database.SaveResult object
	 */
	global Database.SaveResult doInsertAsync(SObject record, System.AccessLevel accessLevel) {
		return this.doInsertAsync(new List<SObject>{ record }, accessLevel)?.get(0);
	}

	/**
	 * @description Asynchronously inserts a single record using default settings (default callback, user mode access).
	 * @param record SObject record to insert
	 * @return Database.SaveResult object
	 */
	global Database.SaveResult doInsertAsync(SObject record) {
		return this.doInsertAsync(new List<SObject>{ record })?.get(0);
	}

	// ** InsertImmediate Methods
	/**
	 * @description Immediately inserts a list of records using the specified access level.
	 * @param records List of SObject records to insert
	 * @param accessLevel System access level for the operation
	 * @return List of Database.SaveResult objects
	 */
	global List<Database.SaveResult> doInsertImmediate(List<SObject> records, System.AccessLevel accessLevel) {
		Dml.Request request = this.initRequest(Dml.Operation.DO_INSERT, records);
		request.accessLevel = accessLevel;
		request.isOperationImmediate = true;
		return (List<Database.SaveResult>) request?.process();
	}

	/**
	 * @description Immediately inserts a list of records using default access level (user mode).
	 * @param records List of SObject records to insert
	 * @return List of Database.SaveResult objects
	 */
	global List<Database.SaveResult> doInsertImmediate(List<SObject> records) {
		return this.doInsertImmediate(records, DEFAULT_ACCESS_LEVEL);
	}

	/**
	 * @description Immediately inserts a single record using the specified access level.
	 * @param record SObject record to insert
	 * @param accessLevel System access level for the operation
	 * @return Database.SaveResult object
	 */
	global Database.SaveResult doInsertImmediate(SObject record, System.AccessLevel accessLevel) {
		return this.doInsertImmediate(new List<SObject>{ record }, accessLevel)?.get(0);
	}

	/**
	 * @description Immediately inserts a single record using default access level (user mode).
	 * @param record SObject record to insert
	 * @return Database.SaveResult object
	 */
	global Database.SaveResult doInsertImmediate(SObject record) {
		return this.doInsertImmediate(new List<SObject>{ record })?.get(0);
	}

	// ** Publish Methods
	/**
	 * @description Publishes a list of platform events.
	 * @param events List of platform event SObjects to publish
	 * @return List of Database.SaveResult objects
	 */
	global List<Database.SaveResult> doPublish(List<SObject> events) {
		// Callback: "An Apex class that implements the EventPublishFailureCallback Interface or EventPublishSuccessCallback Interface."
		// https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_class_System_eventbus.htm#apex_System_eventbus_publish_4
		return (List<Database.SaveResult>) this.initRequest(Dml.Operation.DO_PUBLISH, events)?.process();
	}

	/**
	 * @description Publishes a single platform event.
	 * @param event Platform event SObject to publish
	 * @return Database.SaveResult object
	 */
	global Database.SaveResult doPublish(SObject event) {
		return this.doPublish(new List<SObject>{ event })?.get(0);
	}

	// ** Undelete Methods
	/**
	 * @description Undeletes a list of records using the specified all-or-none setting and access level.
	 * @param records List of SObject records to undelete
	 * @param allOrNone Whether all operations must succeed or all fail
	 * @param accessLevel System access level for the operation
	 * @return List of Database.UndeleteResult objects
	 */
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

	/**
	 * @description Undeletes a list of records using the specified all-or-none setting and default access level.
	 * @param records List of SObject records to undelete
	 * @param allOrNone Whether all operations must succeed or all fail
	 * @return List of Database.UndeleteResult objects
	 */
	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global List<Database.UndeleteResult> doUndelete(List<SObject> records, Boolean allOrNone) {
		return this.doUndelete(records, allOrNone, DEFAULT_ACCESS_LEVEL);
	}

	/**
	 * @description Undeletes a list of records using the specified access level and default all-or-none setting.
	 * @param records List of SObject records to undelete
	 * @param accessLevel System access level for the operation
	 * @return List of Database.UndeleteResult objects
	 */
	global List<Database.UndeleteResult> doUndelete(List<SObject> records, System.AccessLevel accessLevel) {
		return this.doUndelete(records, true, accessLevel);
	}

	/**
	 * @description Undeletes a list of records using default settings (all-or-none true, user mode access).
	 * @param records List of SObject records to undelete
	 * @return List of Database.UndeleteResult objects
	 */
	global List<Database.UndeleteResult> doUndelete(List<SObject> records) {
		return this.doUndelete(records, DEFAULT_ACCESS_LEVEL);
	}

	/**
	 * @description Undeletes records by IDs using the specified all-or-none setting and access level.
	 * @param recordIds List of record IDs to undelete
	 * @param allOrNone Whether all operations must succeed or all fail
	 * @param accessLevel System access level for the operation
	 * @return List of Database.UndeleteResult objects
	 */
	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global List<Database.UndeleteResult> doUndelete(
		List<Id> recordIds,
		Boolean allOrNone,
		System.AccessLevel accessLevel
	) {
		List<SObject> records = DatabaseLayer.Utils.SObjects.newSObjects(recordIds);
		return this.doUndelete(records, allOrNone, accessLevel);
	}

	/**
	 * @description Undeletes records by IDs using the specified all-or-none setting and default access level.
	 * @param recordIds List of record IDs to undelete
	 * @param allOrNone Whether all operations must succeed or all fail
	 * @return List of Database.UndeleteResult objects
	 */
	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global List<Database.UndeleteResult> doUndelete(List<Id> recordIds, Boolean allOrNone) {
		return this.doUndelete(recordIds, allOrNone, DEFAULT_ACCESS_LEVEL);
	}

	/**
	 * @description Undeletes records by IDs using the specified access level and default all-or-none setting.
	 * @param recordIds List of record IDs to undelete
	 * @param accessLevel System access level for the operation
	 * @return List of Database.UndeleteResult objects
	 */
	global List<Database.UndeleteResult> doUndelete(List<Id> recordIds, System.AccessLevel accessLevel) {
		return this.doUndelete(recordIds, true, accessLevel);
	}

	/**
	 * @description Undeletes records by IDs using default settings (all-or-none true, user mode access).
	 * @param recordIds List of record IDs to undelete
	 * @return List of Database.UndeleteResult objects
	 */
	global List<Database.UndeleteResult> doUndelete(List<Id> recordIds) {
		return this.doUndelete(recordIds, DEFAULT_ACCESS_LEVEL);
	}

	/**
	 * @description Undeletes a single record using the specified all-or-none setting and access level.
	 * @param record SObject record to undelete
	 * @param allOrNone Whether all operations must succeed or all fail
	 * @param accessLevel System access level for the operation
	 * @return Database.UndeleteResult object
	 */
	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global Database.UndeleteResult doUndelete(SObject record, Boolean allOrNone, System.AccessLevel accessLevel) {
		return this.doUndelete(new List<SObject>{ record }, allOrNone, accessLevel)?.get(0);
	}

	/**
	 * @description Undeletes a single record using the specified all-or-none setting and default access level.
	 * @param record SObject record to undelete
	 * @param allOrNone Whether all operations must succeed or all fail
	 * @return Database.UndeleteResult object
	 */
	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global Database.UndeleteResult doUndelete(SObject record, Boolean allOrNone) {
		return this.doUndelete(new List<SObject>{ record }, allOrNone)?.get(0);
	}

	/**
	 * @description Undeletes a single record using the specified access level and default all-or-none setting.
	 * @param record SObject record to undelete
	 * @param accessLevel System access level for the operation
	 * @return Database.UndeleteResult object
	 */
	global Database.UndeleteResult doUndelete(SObject record, System.AccessLevel accessLevel) {
		return this.doUndelete(new List<SObject>{ record }, accessLevel)?.get(0);
	}

	/**
	 * @description Undeletes a single record using default settings (all-or-none true, user mode access).
	 * @param record SObject record to undelete
	 * @return Database.UndeleteResult object
	 */
	global Database.UndeleteResult doUndelete(SObject record) {
		return this.doUndelete(new List<SObject>{ record })?.get(0);
	}

	/**
	 * @description Undeletes a single record by ID using the specified all-or-none setting and access level.
	 * @param recordId ID of the record to undelete
	 * @param allOrNone Whether all operations must succeed or all fail
	 * @param accessLevel System access level for the operation
	 * @return Database.UndeleteResult object
	 */
	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global Database.UndeleteResult doUndelete(Id recordId, Boolean allOrNone, System.AccessLevel accessLevel) {
		return this.doUndelete(new List<Id>{ recordId }, allOrNone, accessLevel)?.get(0);
	}

	/**
	 * @description Undeletes a single record by ID using the specified all-or-none setting and default access level.
	 * @param recordId ID of the record to undelete
	 * @param allOrNone Whether all operations must succeed or all fail
	 * @return Database.UndeleteResult object
	 */
	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global Database.UndeleteResult doUndelete(Id recordId, Boolean allOrNone) {
		return this.doUndelete(new List<Id>{ recordId }, allOrNone)?.get(0);
	}

	/**
	 * @description Undeletes a single record by ID using the specified access level and default all-or-none setting.
	 * @param recordId ID of the record to undelete
	 * @param accessLevel System access level for the operation
	 * @return Database.UndeleteResult object
	 */
	global Database.UndeleteResult doUndelete(Id recordId, System.AccessLevel accessLevel) {
		return this.doUndelete(new List<Id>{ recordId }, accessLevel)?.get(0);
	}

	/**
	 * @description Undeletes a single record by ID using default settings (all-or-none true, user mode access).
	 * @param recordId ID of the record to undelete
	 * @return Database.UndeleteResult object
	 */
	global Database.UndeleteResult doUndelete(Id recordId) {
		return this.doUndelete(new List<Id>{ recordId })?.get(0);
	}

	// ** Update Methods
	/**
	 * @description Updates a list of records using the specified options and access level.
	 * @param records List of SObject records to update
	 * @param options DML options for the update operation
	 * @param accessLevel System access level for the operation
	 * @return List of Database.SaveResult objects
	 */
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

	/**
	 * @description Updates a list of records using the specified all-or-none setting and access level.
	 * @param records List of SObject records to update
	 * @param allOrNone Whether all operations must succeed or all fail
	 * @param accessLevel System access level for the operation
	 * @return List of Database.SaveResult objects
	 */
	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global List<Database.SaveResult> doUpdate(
		List<SObject> records,
		Boolean allOrNone,
		System.AccessLevel accessLevel
	) {
		return this.doUpdate(records, Dml.initDmlOptions(allOrNone), accessLevel);
	}

	/**
	 * @description Updates a list of records using the specified options and default access level.
	 * @param records List of SObject records to update
	 * @param options DML options for the update operation
	 * @return List of Database.SaveResult objects
	 */
	global List<Database.SaveResult> doUpdate(List<SObject> records, Database.DmlOptions options) {
		return this.doUpdate(records, options, DEFAULT_ACCESS_LEVEL);
	}

	/**
	 * @description Updates a list of records using the specified all-or-none setting and default access level.
	 * @param records List of SObject records to update
	 * @param allOrNone Whether all operations must succeed or all fail
	 * @return List of Database.SaveResult objects
	 */
	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global List<Database.SaveResult> doUpdate(List<SObject> records, Boolean allOrNone) {
		return this.doUpdate(records, allOrNone, DEFAULT_ACCESS_LEVEL);
	}

	/**
	 * @description Updates a list of records using the specified access level and default all-or-none setting.
	 * @param records List of SObject records to update
	 * @param accessLevel System access level for the operation
	 * @return List of Database.SaveResult objects
	 */
	global List<Database.SaveResult> doUpdate(List<SObject> records, System.AccessLevel accessLevel) {
		return this.doUpdate(records, true, accessLevel);
	}

	/**
	 * @description Updates a list of records using default settings (all-or-none true, user mode access).
	 * @param records List of SObject records to update
	 * @return List of Database.SaveResult objects
	 */
	global List<Database.SaveResult> doUpdate(List<SObject> records) {
		return this.doUpdate(records, DEFAULT_ACCESS_LEVEL);
	}

	/**
	 * @description Updates a single record using the specified options and access level.
	 * @param record SObject record to update
	 * @param options DML options for the update operation
	 * @param accessLevel System access level for the operation
	 * @return Database.SaveResult object
	 */
	global Database.SaveResult doUpdate(SObject record, Database.DmlOptions options, System.AccessLevel accessLevel) {
		return this.doUpdate(new List<SObject>{ record }, options, accessLevel)?.get(0);
	}

	/**
	 * @description Updates a single record using the specified all-or-none setting and access level.
	 * @param record SObject record to update
	 * @param allOrNone Whether all operations must succeed or all fail
	 * @param accessLevel System access level for the operation
	 * @return Database.SaveResult object
	 */
	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global Database.SaveResult doUpdate(SObject record, Boolean allOrNone, System.AccessLevel accessLevel) {
		return this.doUpdate(new List<SObject>{ record }, allOrNone, accessLevel)?.get(0);
	}

	/**
	 * @description Updates a single record using the specified options and default access level.
	 * @param record SObject record to update
	 * @param options DML options for the update operation
	 * @return Database.SaveResult object
	 */
	global Database.SaveResult doUpdate(SObject record, Database.DmlOptions options) {
		return this.doUpdate(new List<SObject>{ record }, options)?.get(0);
	}

	/**
	 * @description Updates a single record using the specified all-or-none setting and default access level.
	 * @param record SObject record to update
	 * @param allOrNone Whether all operations must succeed or all fail
	 * @return Database.SaveResult object
	 */
	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global Database.SaveResult doUpdate(SObject record, Boolean allOrNone) {
		return this.doUpdate(new List<SObject>{ record }, allOrNone)?.get(0);
	}

	/**
	 * @description Updates a single record using the specified access level and default all-or-none setting.
	 * @param record SObject record to update
	 * @param accessLevel System access level for the operation
	 * @return Database.SaveResult object
	 */
	global Database.SaveResult doUpdate(SObject record, System.AccessLevel accessLevel) {
		return this.doUpdate(new List<SObject>{ record }, accessLevel)?.get(0);
	}

	/**
	 * @description Updates a single record using default settings (all-or-none true, user mode access).
	 * @param record SObject record to update
	 * @return Database.SaveResult object
	 */
	global Database.SaveResult doUpdate(SObject record) {
		return this.doUpdate(new List<SObject>{ record })?.get(0);
	}

	// ** UpdateAsync Methods
	/**
	 * @description Asynchronously updates a list of records using the specified callback and access level.
	 * @param records List of SObject records to update
	 * @param callback Callback to handle async save results
	 * @param accessLevel System access level for the operation
	 * @return List of Database.SaveResult objects
	 */
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

	/**
	 * @description Asynchronously updates a list of records using the specified callback and default access level.
	 * @param records List of SObject records to update
	 * @param callback Callback to handle async save results
	 * @return List of Database.SaveResult objects
	 */
	global List<Database.SaveResult> doUpdateAsync(List<SObject> records, DataSource.AsyncSaveCallback callback) {
		return this.doUpdateAsync(records, callback, DEFAULT_ACCESS_LEVEL);
	}

	/**
	 * @description Asynchronously updates a list of records using the specified access level and default callback.
	 * @param records List of SObject records to update
	 * @param accessLevel System access level for the operation
	 * @return List of Database.SaveResult objects
	 */
	global List<Database.SaveResult> doUpdateAsync(List<SObject> records, System.AccessLevel accessLevel) {
		return this.doUpdateAsync(records, DEFAULT_SAVE_CALLBACK, accessLevel);
	}

	/**
	 * @description Asynchronously updates a list of records using default settings (default callback, user mode access).
	 * @param records List of SObject records to update
	 * @return List of Database.SaveResult objects
	 */
	global List<Database.SaveResult> doUpdateAsync(List<SObject> records) {
		return this.doUpdateAsync(records, DEFAULT_ACCESS_LEVEL);
	}

	/**
	 * @description Asynchronously updates a single record using the specified callback and access level.
	 * @param record SObject record to update
	 * @param callback Callback to handle async save results
	 * @param accessLevel System access level for the operation
	 * @return Database.SaveResult object
	 */
	global Database.SaveResult doUpdateAsync(
		SObject record,
		DataSource.AsyncSaveCallback callback,
		System.AccessLevel accessLevel
	) {
		return this.doUpdateAsync(new List<SObject>{ record }, callback, accessLevel)?.get(0);
	}

	/**
	 * @description Asynchronously updates a single record using the specified callback and default access level.
	 * @param record SObject record to update
	 * @param callback Callback to handle async save results
	 * @return Database.SaveResult object
	 */
	global Database.SaveResult doUpdateAsync(SObject record, DataSource.AsyncSaveCallback callback) {
		return this.doUpdateAsync(new List<SObject>{ record }, callback)?.get(0);
	}

	/**
	 * @description Asynchronously updates a single record using the specified access level and default callback.
	 * @param record SObject record to update
	 * @param accessLevel System access level for the operation
	 * @return Database.SaveResult object
	 */
	global Database.SaveResult doUpdateAsync(SObject record, System.AccessLevel accessLevel) {
		return this.doUpdateAsync(new List<SObject>{ record }, accessLevel)?.get(0);
	}

	/**
	 * @description Asynchronously updates a single record using default settings (default callback, user mode access).
	 * @param record SObject record to update
	 * @return Database.SaveResult object
	 */
	global Database.SaveResult doUpdateAsync(SObject record) {
		return this.doUpdateAsync(new List<SObject>{ record })?.get(0);
	}

	// ** UpdateImmediate Methods
	/**
	 * @description Immediately updates a list of records using the specified access level.
	 * @param records List of SObject records to update
	 * @param accessLevel System access level for the operation
	 * @return List of Database.SaveResult objects
	 */
	global List<Database.SaveResult> doUpdateImmediate(List<SObject> records, System.AccessLevel accessLevel) {
		Dml.Request request = this.initRequest(Dml.Operation.DO_UPDATE, records);
		request.accessLevel = accessLevel;
		request.isOperationImmediate = true;
		return (List<Database.SaveResult>) request?.process();
	}

	/**
	 * @description Immediately updates a list of records using default access level (user mode).
	 * @param records List of SObject records to update
	 * @return List of Database.SaveResult objects
	 */
	global List<Database.SaveResult> doUpdateImmediate(List<SObject> records) {
		return this.doUpdateImmediate(records, DEFAULT_ACCESS_LEVEL);
	}

	/**
	 * @description Immediately updates a single record using the specified access level.
	 * @param record SObject record to update
	 * @param accessLevel System access level for the operation
	 * @return Database.SaveResult object
	 */
	global Database.SaveResult doUpdateImmediate(SObject record, System.AccessLevel accessLevel) {
		return this.doUpdateImmediate(new List<SObject>{ record }, accessLevel)?.get(0);
	}

	/**
	 * @description Immediately updates a single record using default access level (user mode).
	 * @param record SObject record to update
	 * @return Database.SaveResult object
	 */
	global Database.SaveResult doUpdateImmediate(SObject record) {
		return this.doUpdateImmediate(new List<SObject>{ record })?.get(0);
	}

	// ** Upsert Methods
	/**
	 * @description Upserts a list of records using the specified external ID field, all-or-none setting, and access level.
	 * @param records List of SObject records to upsert
	 * @param externalIdField External ID field to use for matching existing records
	 * @param allOrNone Whether all operations must succeed or all fail
	 * @param accessLevel System access level for the operation
	 * @return List of Database.UpsertResult objects
	 */
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

	/**
	 * @description Upserts a list of records using the specified external ID field, all-or-none setting, and default access level.
	 * @param records List of SObject records to upsert
	 * @param externalIdField External ID field to use for matching existing records
	 * @param allOrNone Whether all operations must succeed or all fail
	 * @return List of Database.UpsertResult objects
	 */
	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global List<Database.UpsertResult> doUpsert(
		List<SObject> records,
		SObjectField externalIdField,
		Boolean allOrNone
	) {
		return this.doUpsert(records, externalIdField, allOrNone, DEFAULT_ACCESS_LEVEL);
	}

	/**
	 * @description Upserts a list of records using the specified external ID field, access level, and default all-or-none setting.
	 * @param records List of SObject records to upsert
	 * @param externalIdField External ID field to use for matching existing records
	 * @param accessLevel System access level for the operation
	 * @return List of Database.UpsertResult objects
	 */
	global List<Database.UpsertResult> doUpsert(
		List<SObject> records,
		SObjectField externalIdField,
		System.AccessLevel accessLevel
	) {
		return this.doUpsert(records, externalIdField, true, accessLevel);
	}

	/**
	 * @description Upserts a list of records using the specified all-or-none setting and access level.
	 * @param records List of SObject records to upsert
	 * @param allOrNone Whether all operations must succeed or all fail
	 * @param accessLevel System access level for the operation
	 * @return List of Database.UpsertResult objects
	 */
	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global List<Database.UpsertResult> doUpsert(
		List<SObject> records,
		Boolean allOrNone,
		System.AccessLevel accessLevel
	) {
		return this.doUpsert(records, null, allOrNone, accessLevel);
	}

	/**
	 * @description Upserts a list of records using the specified external ID field and default settings.
	 * @param records List of SObject records to upsert
	 * @param externalIdField External ID field to use for matching existing records
	 * @return List of Database.UpsertResult objects
	 */
	global List<Database.UpsertResult> doUpsert(List<SObject> records, SObjectField externalIdField) {
		return this.doUpsert(records, externalIdField, DEFAULT_ACCESS_LEVEL);
	}

	/**
	 * @description Upserts a list of records using the specified all-or-none setting and default settings.
	 * @param records List of SObject records to upsert
	 * @param allOrNone Whether all operations must succeed or all fail
	 * @return List of Database.UpsertResult objects
	 */
	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global List<Database.UpsertResult> doUpsert(List<SObject> records, Boolean allOrNone) {
		return this.doUpsert(records, allOrNone, DEFAULT_ACCESS_LEVEL);
	}

	/**
	 * @description Upserts a list of records using the specified access level and default settings.
	 * @param records List of SObject records to upsert
	 * @param accessLevel System access level for the operation
	 * @return List of Database.UpsertResult objects
	 */
	global List<Database.UpsertResult> doUpsert(List<SObject> records, System.AccessLevel accessLevel) {
		return this.doUpsert(records, true, accessLevel);
	}

	/**
	 * @description Upserts a list of records using default settings (all-or-none true, user mode access).
	 * @param records List of SObject records to upsert
	 * @return List of Database.UpsertResult objects
	 */
	global List<Database.UpsertResult> doUpsert(List<SObject> records) {
		return this.doUpsert(records, DEFAULT_ACCESS_LEVEL);
	}

	/**
	 * @description Upserts a single record using the specified external ID field, all-or-none setting, and access level.
	 * @param record SObject record to upsert
	 * @param externalIdField External ID field to use for matching existing records
	 * @param allOrNone Whether all operations must succeed or all fail
	 * @param accessLevel System access level for the operation
	 * @return Database.UpsertResult object
	 */
	@SuppressWarnings('PMD.AvoidBooleanMethodParameters,PMD.ExcessiveParameterList')
	global Database.UpsertResult doUpsert(
		SObject record,
		SObjectField externalIdField,
		Boolean allOrNone,
		System.AccessLevel accessLevel
	) {
		return this.doUpsert(new List<SObject>{ record }, externalIdField, allOrNone, accessLevel)?.get(0);
	}

	/**
	 * @description Upserts a single record using the specified external ID field, all-or-none setting, and default access level.
	 * @param record SObject record to upsert
	 * @param externalIdField External ID field to use for matching existing records
	 * @param allOrNone Whether all operations must succeed or all fail
	 * @return Database.UpsertResult object
	 */
	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global Database.UpsertResult doUpsert(SObject record, SObjectField externalIdField, Boolean allOrNone) {
		return this.doUpsert(new List<SObject>{ record }, externalIdField, allOrNone)?.get(0);
	}

	/**
	 * @description Upserts a single record using the specified external ID field, access level, and default all-or-none setting.
	 * @param record SObject record to upsert
	 * @param externalIdField External ID field to use for matching existing records
	 * @param accessLevel System access level for the operation
	 * @return Database.UpsertResult object
	 */
	global Database.UpsertResult doUpsert(
		SObject record,
		SObjectField externalIdField,
		System.AccessLevel accessLevel
	) {
		return this.doUpsert(new List<SObject>{ record }, externalIdField, accessLevel)?.get(0);
	}

	/**
	 * @description Upserts a single record using the specified all-or-none setting and access level.
	 * @param record SObject record to upsert
	 * @param allOrNone Whether all operations must succeed or all fail
	 * @param accessLevel System access level for the operation
	 * @return Database.UpsertResult object
	 */
	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global Database.UpsertResult doUpsert(SObject record, Boolean allOrNone, System.AccessLevel accessLevel) {
		return this.doUpsert(new List<SObject>{ record }, allOrNone, accessLevel)?.get(0);
	}

	/**
	 * @description Upserts a single record using the specified external ID field and default settings.
	 * @param record SObject record to upsert
	 * @param externalIdField External ID field to use for matching existing records
	 * @return Database.UpsertResult object
	 */
	global Database.UpsertResult doUpsert(SObject record, SObjectField externalIdField) {
		return this.doUpsert(new List<SObject>{ record }, externalIdField)?.get(0);
	}

	/**
	 * @description Upserts a single record using the specified all-or-none setting and default settings.
	 * @param record SObject record to upsert
	 * @param allOrNone Whether all operations must succeed or all fail
	 * @return Database.UpsertResult object
	 */
	@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
	global Database.UpsertResult doUpsert(SObject record, Boolean allOrNone) {
		return this.doUpsert(new List<SObject>{ record }, allOrNone)?.get(0);
	}

	/**
	 * @description Upserts a single record using the specified access level and default settings.
	 * @param record SObject record to upsert
	 * @param accessLevel System access level for the operation
	 * @return Database.UpsertResult object
	 */
	global Database.UpsertResult doUpsert(SObject record, System.AccessLevel accessLevel) {
		return this.doUpsert(new List<SObject>{ record }, accessLevel)?.get(0);
	}

	/**
	 * @description Upserts a single record using default settings (all-or-none true, user mode access).
	 * @param record SObject record to upsert
	 * @return Database.UpsertResult object
	 */
	global Database.UpsertResult doUpsert(SObject record) {
		return this.doUpsert(new List<SObject>{ record })?.get(0);
	}

	// ** EmptyRecycleBin Methods
	/**
	 * @description Permanently deletes records from the recycle bin.
	 * @param records List of SObject records to permanently delete
	 * @return List of Database.EmptyRecycleBinResult objects
	 */
	global List<Database.EmptyRecycleBinResult> emptyRecycleBin(List<SObject> records) {
		Dml.Request request = this.initRequest(Dml.Operation.DO_PURGE, records);
		return (List<Database.EmptyRecycleBinResult>) request?.process();
	}

	/**
	 * @description Permanently deletes records from the recycle bin by record IDs.
	 * @param recordIds List of record IDs to permanently delete
	 * @return List of Database.EmptyRecycleBinResult objects
	 */
	global List<Database.EmptyRecycleBinResult> emptyRecycleBin(List<Id> recordIds) {
		List<SObject> records = DatabaseLayer.Utils.SObjects.newSObjects(recordIds);
		return this.emptyRecycleBin(records);
	}

	/**
	 * @description Permanently deletes a single record from the recycle bin.
	 * @param record SObject record to permanently delete
	 * @return Database.EmptyRecycleBinResult object
	 */
	global Database.EmptyRecycleBinResult emptyRecycleBin(SObject record) {
		return this.emptyRecycleBin(new List<SObject>{ record })?.get(0);
	}

	/**
	 * @description Permanently deletes a single record from the recycle bin by record ID.
	 * @param recordId ID of the record to permanently delete
	 * @return Database.EmptyRecycleBinResult object
	 */
	global Database.EmptyRecycleBinResult emptyRecycleBin(Id recordId) {
		return this.emptyRecycleBin(new List<Id>{ recordId })?.get(0);
	}

	// ** Savepoint Methods
	/**
	 * These System.Savepoint methods mirror the Database class's static methods
	 * The benefit of calling these methods is largely to gain access to MockDml methods
	 * to assert if/which savepoints were set, rolled back, released, etc.
	 */
	/**
	 * @description Releases a savepoint, making it no longer available for rollback.
	 * @param savepoint The savepoint to release
	 */
	global virtual void releaseSavepoint(System.Savepoint savepoint) {
		Database.releaseSavepoint(savepoint);
	}

	/**
	 * @description Rolls back the database to the specified savepoint.
	 * @param savepoint The savepoint to roll back to
	 */
	global virtual void rollback(System.Savepoint savepoint) {
		Database.rollback(savepoint);
	}

	/**
	 * @description Creates a savepoint that can be used for rollback operations.
	 * @return System.Savepoint object representing the current database state
	 */
	global virtual System.Savepoint setSavepoint() {
		return Database.setSavepoint();
	}

	// **** PRIVATE **** //
	/**
	 * @description Initializes a DML request object for the specified operation.
	 * @param operation The DML operation to perform
	 * @param records List of records to operate on
	 * @return A configured Dml.Request object
	 */
	@TestVisible
	protected virtual Dml.Request initRequest(Dml.Operation operation, List<Object> records) {
		return new Dml.Request(operation, records);
	}

	// **** STATIC **** //
	private static Database.DmlOptions initDmlOptions(Boolean allOrNone) {
		Database.DmlOptions options = new Database.DmlOptions();
		options.OptAllOrNone = allOrNone;
		return options;
	}

	// **** INNER **** //
	/**
	 * @description Default callback implementation for async delete operations when no callback is specified.
	 */
	@TestVisible
	private class EmptyDeleteCallback extends DataSource.AsyncDeleteCallback {
		@SuppressWarnings('PMD.EmptyStatementBlock')
		public override void processDelete(Database.DeleteResult result) {
			// Do nothing
		}
	}

	/**
	 * @description Default callback implementation for async save operations when no callback is specified.
	 */
	@TestVisible
	private class EmptySaveCallback extends DataSource.AsyncSaveCallback {
		@SuppressWarnings('PMD.EmptyStatementBlock')
		public override void processSave(Database.SaveResult result) {
			// Do nothing
		}
	}

	/**
	 * @description Enumeration of all supported DML operations.
	 */
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

	/**
	 * @description Interface for plugins that process DML operations before and after execution.
	 */
	global interface PreAndPostProcessor {
		/**
		 * @description Called before executing a DML operation.
		 * @param request The DML request to be processed
		 */
		void processPreDml(Dml.Request request);
		/**
		 * @description Called after successfully executing a DML operation.
		 * @param request The DML request that was processed
		 * @param databaseResults The results returned from the DML operation
		 */
		void processPostDml(Dml.Request request, List<Object> databaseResults);
		/**
		 * @description Called when a DML operation encounters an error.
		 * @param request The DML request that encountered an error
		 * @param error The exception that was thrown
		 */
		void processDmlError(Dml.Request request, Exception error);
	}

	/**
	 * @description Encapsulates a single DML operation with all its parameters and execution logic.
	 */
	global inherited sharing virtual class Request {
		// ** Always Required:
		/**
		 * @description The DML operation to be performed.
		 */
		global Dml.Operation operation { get; protected set; }
		// ** Conditionally Required:
		/**
		 * @description List of SObject records to operate on (for most operations).
		 */
		global transient List<SObject> records { get; protected set; }
		/**
		 * @description List of lead conversion objects (for convert operations only).
		 */
		global transient List<Database.LeadConvert> leadsToConvert { get; protected set; }
		// ** Optional Parameters:
		/**
		 * @description System access level for the operation (USER_MODE or SYSTEM_MODE).
		 */
		global transient System.AccessLevel accessLevel { get; protected set; }
		/**
		 * @description Callback for asynchronous delete operations.
		 */
		global transient DataSource.AsyncDeleteCallback asyncDeleteCallback { get; protected set; }
		/**
		 * @description Callback for asynchronous save operations.
		 */
		global transient DataSource.AsyncSaveCallback asyncSaveCallback { get; protected set; }
		/**
		 * @description External ID field for upsert operations.
		 */
		global transient SObjectField externalIdField { get; protected set; }
		/**
		 * @description Whether this request is being executed by mock DML.
		 */
		global Boolean isMockDml { get; protected set; }
		/**
		 * @description Whether this operation should be executed asynchronously.
		 */
		global Boolean isOperationAsync { get; protected set; }
		/**
		 * @description Whether this operation should be executed immediately.
		 */
		global Boolean isOperationImmediate { get; protected set; }
		/**
		 * @description DML options for the operation.
		 */
		global Database.DmlOptions options { get; protected set; }
		// ** Getters
		// These properties are read-only, and are used for JSON/output purposes,
		// ex., since some of the main class properties are not JSON-serializable
		/**
		 * @description Whether all operations must succeed or all fail.
		 */
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
		/**
		 * @description The number of records being operated on.
		 */
		global Integer numRecords {
			// Output the number of records being operated on:
			get {
				return this.getNumRecords();
			}
		}

		/**
		 * @description The name of the SObjectType being operated on.
		 */
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
				DatabaseLayer.Utils.Plugins.Dml?.processPreDml(this);
				List<Object> results = this.doDml();
				DatabaseLayer.Utils.Plugins.Dml?.processPostDml(this, results);
				return results;
			} catch (Exception error) {
				// Allow the plugin to act on DML exceptions, ex., for logging
				// The error will still be thrown anyways:
				DatabaseLayer.Utils.Plugins.Dml?.processDmlError(this, error);
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
