@SuppressWarnings('PMD.EmptyStatementBlock, PMD.ExcessiveParameterList, PMD.ExcessivePublicCount')
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

	// **** VIRTUAL **** //
	// * All of these methods point to an underlying Database method to perform DML
	// Each may have one or more overloads, for convenience
	// Each may be overridden, ex., for DML mocking
	public virtual List<Database.LeadConvertResult> doConvert(
		List<Database.LeadConvert> leadsToConvert,
		Database.DmlOptions options,
		System.AccessLevel accessLevel
	) {
		return Database.convertLead(leadsToConvert, options, accessLevel);
	}

	public virtual List<Database.DeleteResult> doDelete(
		List<Id> recordIds,
		Boolean allOrNone,
		System.AccessLevel accessLevel
	) {
		return Database.delete(recordIds, allOrNone, accessLevel);
	}

	public virtual List<Database.DeleteResult> doDeleteAsync(
		List<SObject> records,
		DataSource.AsyncDeleteCallback callback,
		System.AccessLevel accessLevel
	) {
		return Database.deleteAsync(records, callback, accessLevel);
	}

	public virtual List<Database.DeleteResult> doDeleteImmediate(
		List<SObject> records,
		System.AccessLevel accessLevel
	) {
		return Database.deleteImmediate(records, accessLevel);
	}

	public virtual List<Database.DeleteResult> doHardDelete(
		List<Id> recordIds,
		Boolean allOrNone,
		System.AccessLevel accessLevel
	) {
		List<Database.DeleteResult> results = this.doDelete(recordIds, allOrNone, accessLevel);
		Database.emptyRecycleBin(recordIds);
		return results;
	}

	public virtual List<Database.SaveResult> doInsert(
		List<SObject> records,
		Database.DmlOptions options,
		System.AccessLevel accessLevel
	) {
		return Database.insert(records, options, accessLevel);
	}

	public virtual List<Database.SaveResult> doInsertAsync(
		List<SObject> records,
		DataSource.AsyncSaveCallback callback,
		System.AccessLevel accessLevel
	) {
		return Database.insertAsync(records, callback, accessLevel);
	}

	public virtual List<Database.SaveResult> doInsertImmediate(List<SObject> records, System.AccessLevel accessLevel) {
		return Database.insertImmediate(records, accessLevel);
	}

	public virtual List<Database.SaveResult> doPublish(List<SObject> events, Object callback) {
		// Callback: "An Apex class that implements the EventPublishFailureCallback Interface or EventPublishSuccessCallback Interface."
		// https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_class_System_eventbus.htm#apex_System_eventbus_publish_4
		return EventBus.publish(events, callback);
	}

	public virtual List<Database.UndeleteResult> doUndelete(
		List<Id> recordIds,
		Boolean allOrNone,
		System.AccessLevel accessLevel
	) {
		return Database.undelete(recordIds, allOrNone, accessLevel);
	}

	public virtual List<Database.SaveResult> doUpdate(
		List<SObject> records,
		Database.DmlOptions options,
		System.AccessLevel accessLevel
	) {
		return Database.update(records, options, accessLevel);
	}

	public virtual List<Database.SaveResult> doUpdateAsync(
		List<SObject> records,
		DataSource.AsyncSaveCallback callback,
		System.AccessLevel accessLevel
	) {
		return Database.updateAsync(records, callback, accessLevel);
	}

	public virtual List<Database.SaveResult> doUpdateImmediate(List<SObject> records, System.AccessLevel accessLevel) {
		return Database.updateImmediate(records, accessLevel);
	}

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
