/**
 * @description Mock implementation of DML operations for testing. Provides comprehensive mocking capabilities with configurable success/failure scenarios and operation history tracking.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier,PMD.CognitiveComplexity,PMD.CyclomaticComplexity')
@IsTest
global class MockDml extends Dml {
	// **** CONSTANT **** //
	global static final List<MockDml.ConditionalFailure> FAILURES;
	global static final MockDml.SavepointHistory SAVEPOINTS;
	private static final String EVENT_UUID_FIELD;

	// **** STATIC **** //
	/**
	 * @description Mock database instance for tracking DML operations.
	 */
	@SuppressWarnings('PMD.PropertyNamingConventions')
	global static MockDml.Database MockDatabase { get; private set; }

	/**
	 * @description History of all lead conversion operations.
	 */
	@SuppressWarnings('PMD.PropertyNamingConventions')
	global static final MockDml.RecordHistory CONVERTED {
		get {
			return MockDml.MockDatabase?.converted;
		}
	}
	/**
	 * @description History of all delete operations.
	 */
	@SuppressWarnings('PMD.PropertyNamingConventions')
	global static final MockDml.RecordHistory DELETED {
		get {
			return MockDml.MockDatabase?.deleted;
		}
	}
	/**
	 * @description History of all insert operations.
	 */
	@SuppressWarnings('PMD.PropertyNamingConventions')
	global static final MockDml.RecordHistory INSERTED {
		get {
			return MockDml.MockDatabase?.inserted;
		}
	}
	/**
	 * @description History of all platform event publish operations.
	 */
	@SuppressWarnings('PMD.PropertyNamingConventions')
	global static MockDml.PlatformEventHistory PUBLISHED {
		get {
			return MockDml.MockDatabase?.published;
		}
	}
	/**
	 * @description History of all recycle bin purge operations.
	 */
	@SuppressWarnings('PMD.PropertyNamingConventions')
	global static final MockDml.RecordHistory PURGED {
		get {
			return MockDml.MockDatabase?.purged;
		}
	}
	/**
	 * @description History of all undelete operations.
	 */
	@SuppressWarnings('PMD.PropertyNamingConventions')
	global static final MockDml.RecordHistory UNDELETED {
		get {
			return MockDml.MockDatabase?.undeleted;
		}
	}
	/**
	 * @description History of all update operations.
	 */
	@SuppressWarnings('PMD.PropertyNamingConventions')
	global static final MockDml.RecordHistory UPDATED {
		get {
			return MockDml.MockDatabase?.updated;
		}
	}
	/**
	 * @description History of all upsert operations.
	 */
	@SuppressWarnings('PMD.PropertyNamingConventions')
	global static final MockDml.RecordHistory UPSERTED {
		get {
			return MockDml.MockDatabase?.upserted;
		}
	}

	static {
		EVENT_UUID_FIELD = 'EventUuid';
		FAILURES = new List<MockDml.ConditionalFailure>{};
		SAVEPOINTS = new MockDml.SavepointHistory();
		MockDatabase = new MockDml.Database();
	}

	/**
	 * @description Resets all DML operation histories to their original state.
	 */
	global static void eraseAllHistories() {
		MockDml.MockDatabase = new MockDml.Database();
	}
	
	/**
	 * @description Configures all DML operations to fail.
	 */
	global static void shouldFail() {
		MockDml.shouldSucceed();
		MockDml.ConditionalFailure failure = new MockDml.BaseFailure();
		MockDml.shouldFailIf(failure);
	}

	/**
	 * @description Adds a conditional failure rule to the mock DML operations.
	 * @param failure The conditional failure implementation that determines when operations should fail
	 */
	global static void shouldFailIf(MockDml.ConditionalFailure failure) {
		MockDml.FAILURES?.add(failure);
	}

	/**
	 * @description Clears all failure conditions, allowing all DML operations to succeed.
	 */
	global static void shouldSucceed() {
		MockDml.FAILURES?.clear();
	}

	// **** MEMBER **** //
	/**
	 * @description Constructor for MockDml instance.
	 * @param factory The DatabaseLayer factory instance
	 */
	public MockDml(DatabaseLayer factory) {
		super(factory);
	}

	public override Dml.Request initRequest(Dml.Operation operation, List<Object> records) {
		// Initialize a request object that will not actually perform DML:
		return new MockDml.Request(operation, records);
	}

	public override void releaseSavepoint(System.Savepoint savepoint) {
		MockDml.SAVEPOINTS.get(savepoint)?.release();
		super.releaseSavepoint(savepoint);
	}

	public override void rollback(System.Savepoint savepoint) {
		MockDml.SAVEPOINTS.get(savepoint)?.rollback();
		super.rollback(savepoint);
	}

	public override System.Savepoint setSavepoint() {
		System.Savepoint savepoint = super.setSavepoint();
		// Now register the savepoint in the mock database:
		MockDml.SAVEPOINTS?.add(savepoint);
		return savepoint;
	}

	// **** INNER: PUBLIC **** //
	/**
	 * @description Interface for defining conditional DML failure logic.
	 */
	global interface ConditionalFailure {
		/**
		 * @description Determines whether a DML operation should fail for a specific record.
		 * @param operation The DML operation being performed
		 * @param record The record being processed
		 * @return Exception to throw if operation should fail, null if it should succeed
		 */
		Exception checkFailure(Dml.Operation operation, SObject record);
	}

	/**
	 * @description Represents a mock Salesforce database that tracks all DML operations and their history.
	 */
	global class Database {
		/**
		 * @description Whether to reset mock database state on rollback operations.
		 * When this configuration flag is true (default), MockDml will mimic a real Database when a rollback occurs.
		 */
		@SuppressWarnings('PMD.AvoidBooleanMethodParameters')
		global Boolean resetOnRollback { get; set; }
		/**
		 * @description History of lead conversion operations.
		 */
		global MockDml.RecordHistory converted { get; private set; }
		/**
		 * @description History of delete operations.
		 */
		global MockDml.RecordHistory deleted { get; private set; }
		/**
		 * @description History of insert operations.
		 */
		global MockDml.RecordHistory inserted { get; private set; }
		/**
		 * @description History of platform event publish operations.
		 */
		global MockDml.PlatformEventHistory published { get; private set; }
		/**
		 * @description History of recycle bin purge operations.
		 */
		global MockDml.RecordHistory purged { get; private set; }
		/**
		 * @description History of undelete operations.
		 */
		global MockDml.RecordHistory undeleted { get; private set; }
		/**
		 * @description History of update operations.
		 */
		global MockDml.RecordHistory updated { get; private set; }
		/**
		 * @description History of upsert operations.
		 */
		global MockDml.RecordHistory upserted { get; private set; }

		private Database() {
			this.converted = new MockDml.RecordHistory(Dml.Operation.DO_CONVERT);
			this.deleted = new MockDml.RecordHistory(Dml.Operation.DO_DELETE);
			this.inserted = new MockDml.RecordHistory(Dml.Operation.DO_INSERT);
			this.published = new MockDml.PlatformEventHistory();
			this.purged = new MockDml.RecordHistory(Dml.Operation.DO_PURGE);
			this.undeleted = new MockDml.RecordHistory(Dml.Operation.DO_UNDELETE);
			this.updated = new MockDml.RecordHistory(Dml.Operation.DO_UPDATE);
			this.upserted = new MockDml.RecordHistory(Dml.Operation.DO_UPSERT);
			this.resetOnRollback = true;
		}

		/**
		 * @description Creates a snapshot of the current mock database state.
		 * Note: This operation uses JSON serialization/deserialization for deep copying,
		 * which may be expensive for large datasets. Consider the resetOnRollback flag setting
		 * when using this in performance-critical scenarios.
		 * @return A deep copy of the current database state
		 */
		global Database snapshot() {
			return (MockDml.Database) JSON.deserialize(JSON.serialize(this), MockDml.Database.class);
		}

		/**
		 * @description Represents the total number of DML statements in the transaction; similar to Limits.getDmlStatements()
		 * @return The cumulative total of all History objects' numDmlStatements property
		 */
		global Integer getTotalDmlStatements() {
			Integer total = 0;
			for (MockDml.History history : this.getAllHistories()) {
				total += history?.numDmlStatements ?? 0;
			}
			return total;
		}

		private List<MockDml.History> getAllHistories() {
			return new List<MockDml.History>{
				this.converted,
				this.deleted,
				this.inserted,
				this.published,
				this.purged,
				this.undeleted,
				this.updated,
				this.upserted
			};
		}
	}

	/**
	 * @description Base class for tracking DML operation history and providing assertion capabilities.
	 */
	global abstract class History {
		/**
		 * @description Indicates the number of times this particular DML statement was called in a mock context
		 * Allows callers to verify the number of times a specific DML operation was processed, 
		 * since Limits.getDmlDmlStatements() cannot track mock DML statements
		 */
		public Integer numDmlStatements { get; protected set; }
		protected Dml.Operation operation;
		protected Map<String, Map<String, SObject>> recordMap;

		protected History(Dml.Operation operation) {
			this.numDmlStatements = 0;
			this.operation = operation;
			this.recordMap = new Map<String, Map<String, SObject>>();
		}

		// **** ABSTRACT **** //
		/**
		 * @description Adds a record to the internal record map for tracking.
		 * @param record The record to add
		 * @param records The map to add the record to
		 */
		global abstract void addRecordToMap(SObject record, Map<String, Object> records);
		/**
		 * @description Sets or generates an ID for the record.
		 * @param record The record to set ID for
		 * @return The record with ID set
		 */
		global abstract SObject setRecordId(SObject record);

		/**
		 * @description Retrieves all records processed by the current operation, grouped by SObjectType.
		 * @return Map of SObjectType to List of processed records
		 */
		global Map<SObjectType, List<SObject>> getAll() {
			// Retrieve all records processed by the current operation, grouped by SObjectType
			Map<SObjectType, List<SObject>> allRecords = new Map<SObjectType, List<SObject>>();
			for (String objectApiName : this.recordMap?.keySet()) {
				SObjectType objectType = ((SObject) Type.forName(objectApiName)?.newInstance())?.getSObjectType();
				List<SObject> recordList = this.getRecordMap(objectType)?.values();
				allRecords?.put(objectType, recordList);
			}
			return allRecords;
		}

		/**
		 * @description Retrieves all records of the specified SObjectType.
		 * @param objectType The SObjectType to retrieve records for
		 * @return List of records for the specified type
		 */
		global List<SObject> getRecords(SObjectType objectType) {
			// Retrieves all records of the specified SObjectType
			return this.getRecordMap(objectType)?.values();
		}

		/**
		 * @description Retrieves a specific record by SObjectType and ID/UUID.
		 * @param objectType The SObjectType of the record
		 * @param idOrUuuid The record ID or UUID (for platform events)
		 * @return The matching record or null if not found
		 */
		global SObject get(SObjectType objectType, String idOrUuuid) {
			// Retrieves a specific record that was processed
			// Use this method with platform events, who have a UUID but not a traditional Record ID with a reference to the SObjectType
			return this.getRecordMap(objectType)?.get(idOrUuuid);
		}

		/**
		 * @description Retrieves a specific record by ID.
		 * @param recordId The record ID to retrieve
		 * @return The matching record or null if not found
		 */
		global SObject get(Id recordId) {
			// Retrieves a specific record that was processed
			SObjectType objectType = recordId?.getSObjectType();
			return this.get(objectType, recordId);
		}

		/**
		 * @description Retrieves a specific record by SObject reference.
		 * @param record The SObject to find (uses its Id)
		 * @return The matching record or null if not found
		 */
		global SObject get(SObject record) {
			return this.get(record?.Id);
		}

		/**
		 * @desceription Increments the numDmlStatements counter
		 */
		global void incrementDmlStatements() {
			this.numDmlStatements++;
		}

		/**
		 * @description Checks if a record was processed for DML by SObjectType and ID/UUID.
		 * @param objectType The SObjectType of the record
		 * @param idOrUuid The record ID or UUID
		 * @return True if the record was processed, false otherwise
		 */
		global Boolean wasProcessed(SObjectType objectType, String idOrUuid) {
			// Returns true if the record was processed for DML, else returns false
			return this.get(objectType, idOrUuid) != null;
		}

		/**
		 * @description Checks if a record was processed for DML by ID.
		 * @param recordId The record ID to check
		 * @return True if the record was processed, false otherwise
		 */
		global Boolean wasProcessed(Id recordId) {
			// Returns true if the record was processed for DML, else returns false
			SObjectType objectType = recordId?.getSObjectType();
			return this.wasProcessed(objectType, recordId);
		}

		/**
		 * @description Checks if a record was processed for DML by SObject reference.
		 * @param record The SObject to check (uses its Id)
		 * @return True if the record was processed, false otherwise
		 */
		global Boolean wasProcessed(SObject record) {
			return this.wasProcessed(record?.Id);
		}

		// **** PRIVATE **** //
		protected void deregisterDml(SObject record) {
			// Removes the specified record from the History
			SObjectType objectType = record?.getSObjectType();
			Map<String, Object> recordMap = this.getRecordMap(objectType);
			recordMap?.remove(record?.Id);
		}

		protected Dml.Operation getOperation() {
			return this.operation;
		}

		protected Map<String, SObject> getRecordMap(SObjectType objectType) {
			String objectApiName = objectType?.toString();
			return this.recordMap?.get(objectApiName) ?? new Map<String, SObject>();
		}

		protected MockDml.Result handleDmlError(SObject record, Exception error, Boolean allOrNone) {
			// Handles an error during DML, according to the defined allOrNone logic, mirroring standard functionality
			MockError dmlError = new MockError(error);
			if (allOrNone == true) {
				throw dmlError?.toDmlException();
			} else if (this.operation == Dml.Operation.DO_CONVERT) {
				Lead lead = (Lead) record;
				return new MockDml.LeadConvertResult(lead)?.addError(dmlError);
			} else if (this.operation == Dml.Operation.DO_INSERT) {
				// Note: When a record fails to be inserted, the resulting Database.SaveResult should have a null Id value
				return new MockDml.RecordResult(record)?.clearId()?.addError(dmlError);
			} else {
				return new MockDml.RecordResult(record)?.addError(dmlError);
			}
		}

		protected MockDml.Result registerDml(SObject record) {
			// This method registers that the records were operated on,
			// and store them in a way that's easy for callers to get & perform asserts
			record = this.setRecordId(record);
			SObjectType objectType = record?.getSObjectType();
			String objectApiName = objectType?.toString();
			Map<String, SObject> records = this.getRecordMap(objectType);
			this.addRecordToMap(record, records);
			this.recordMap?.put(objectApiName, records);
			return new MockDml.RecordResult(record);
		}
	}

	/**
	 * @description Mock implementation of DML request that simulates database operations without actual DML.
	 */
	public class Request extends Dml.Request {
		private Request(Dml.Operation operation, List<Object> records) {
			super(operation, records);
			this.isMockDml = true;
		}

		// ** OVERRIDES
		protected override List<Database.LeadConvertResult> doConvert() {
			MockDml.CONVERTED.incrementDmlStatements();
			List<MockDml.Result> mockResults = new List<MockDml.Result>();
			for (Database.LeadConvert leadToConvert : this.leadsToConvert) {
				MockDml.Result result = this.generateMockResult(leadToConvert, this.options?.OptAllOrNone);
				mockResults?.add(result);
			}
			return this.toConvertResults(mockResults);
		}

		protected override List<Database.DeleteResult> doDelete() {
			MockDml.DELETED.incrementDmlStatements();
			List<MockDml.Result> mockResults = new List<MockDml.Result>();
			for (SObject record : this.records) {
				MockDml.Result result = this.generateMockResult(MockDml.DELETED, record, this.allOrNone);
				mockResults?.add(result);
			}
			List<Database.DeleteResult> results = this.toDeleteResults(mockResults);
			this.runDeleteCallbackIfAsync(results);
			return results;
		}

		protected override List<Database.SaveResult> doInsert() {
			MockDml.INSERTED.incrementDmlStatements();
			List<MockDml.Result> mockResults = new List<MockDml.Result>();
			for (SObject record : this.records) {
				MockDml.Result result = this.generateMockResult(MockDml.INSERTED, record, this.options?.OptAllOrNone);
				mockResults?.add(result);
			}
			List<Database.SaveResult> results = this.toSaveResults(mockResults);
			this.runSaveCallbackIfAsync(results);
			return results;
		}

		protected override List<Database.SaveResult> doPublish() {
			// Ensure the callback is set; if null, use the default value
			MockDml.PUBLISHED.incrementDmlStatements();
			List<MockDml.Result> mockResults = new List<MockDml.Result>();
			for (SObject event : this.records) {
				// Note: EventBus.publish() always runs in allOrNone=false context
				MockDml.Result result = this.generateMockResult(MockDml.PUBLISHED, event, false);
				mockResults?.add(result);
			}
			return this.toSaveResults(mockResults);
		}

		protected override List<Database.UndeleteResult> doUndelete() {
			MockDml.UNDELETED.incrementDmlStatements();
			List<MockDml.Result> mockResults = new List<MockDml.Result>();
			for (SObject record : records) {
				MockDml.Result result = this.generateMockResult(MockDml.UNDELETED, record, allOrNone);
				mockResults?.add(result);
			}
			return this.toUndeleteResults(mockResults);
		}

		protected override List<Database.SaveResult> doUpdate() {
			MockDml.UPDATED.incrementDmlStatements();
			List<MockDml.Result> mockResults = new List<MockDml.Result>();
			for (SObject record : this.records) {
				MockDml.Result result = this.generateMockResult(MockDml.UPDATED, record, this.options?.OptAllOrNone);
				mockResults?.add(result);
			}
			List<Database.SaveResult> results = this.toSaveResults(mockResults);
			this.runSaveCallbackIfAsync(results);
			return results;
		}

		protected override List<Database.UpsertResult> doUpsert() {
			MockDml.UPSERTED.incrementDmlStatements();
			List<MockDml.Result> mockResults = new List<MockDml.Result>();
			for (SObject record : this.records) {
				MockDml.Result result = this.generateMockResult(MockDml.UPSERTED, record, this.allOrNone);
				mockResults?.add(result);
			}
			return this.toUpsertResults(mockResults);
		}

		protected override List<Database.EmptyRecycleBinResult> emptyRecycleBin() {
			MockDml.PURGED.incrementDmlStatements();
			List<MockDml.Result> mockResults = new List<MockDml.Result>();
			for (SObject record : this.records) {
				MockDml.Result result = this.generateMockResult(MockDml.PURGED, record, true);
				mockResults?.add(result);
			}
			return this.toEmptyRecycleBinResults(mockResults);
		}

		// ** PRIVATE
		private void checkFailures(Dml.Operation operation, SObject record) {
			// Runs all ConditionalFailures defined the current instance against each record.
			for (MockDml.ConditionalFailure failure : MockDml.FAILURES) {
				Exception error = failure?.checkFailure(operation, record);
				if (error != null) {
					throw error;
				}
			}
		}

		private MockDml.Result generateMockResult(MockDml.History history, SObject record, Boolean allOrNone) {
			// Simulates a DML operation for a single record, returning a MockDml.Result,
			// which calling methods can de/serialize into a Database.Save/Upsert/etc. Result.
			try {
				Dml.Operation operation = history?.getOperation();
				// Determine if the operation should fail for the specific record
				this.checkFailures(operation, record);
				// Simulate successful dml, return a MockDml.Result w/out errors
				return history?.registerDml(record);
			} catch (System.DmlException error) {
				// Return a MockDml.Result w/errors
				return history?.handleDmlError(record, error, allOrNone);
			}
		}

		private MockDml.LeadConvertResult generateMockResult(Database.LeadConvert leadToConvert, Boolean allOrNone) {
			// Simulate a Lead Conversion, which typically also involves inserting Account/Contact/Opportunity records
			Lead leadRecord = new Lead(Id = leadToConvert?.getLeadId());
			Account accountRecord = new Account(Id = leadToConvert?.getAccountId());
			Contact contactRecord = new Contact(Id = leadToConvert?.getContactId());
			Opportunity opportunityRecord = leadToConvert?.isDoNotCreateOpportunity() == false
				? new Opportunity(Id = leadToConvert?.getOpportunityId())
				: null;
			try {
				// Note: Process resulting records using allOrNone=true, regardless of its original value
				// This allows injected errors for Accounts/Contacts/Opps to be caught and handled appropriately
				// 1. Simulate converting the lead
				this.validateConvertedLead(leadToConvert);
				// 2. Simulate creating an Account/Contact/Opportunity, if their Id wasn't already provided
				this.simulateInsertIfNew(accountRecord);
				this.simulateInsertIfNew(contactRecord);
				this.simulateInsertIfNew(opportunityRecord);
				// 3. Set the converted record id fields on the Lead, which are normally read-only:
				Lead convertedLead = (Lead) new MockRecord(leadRecord)
					?.setField(Lead.ConvertedAccountId, accountRecord?.Id)
					?.setField(Lead.ConvertedContactId, contactRecord?.Id)
					?.setField(Lead.ConvertedOpportunityId, opportunityRecord?.Id)
					?.setField(Lead.IsConverted, true)
					?.setField(Lead.Status, leadToConvert?.getConvertedStatus())
					?.toSObject();
				this.generateMockResult(MockDml.CONVERTED, convertedLead, true);
				// 4. Build & return the LeadConvertResult w/the resulting record ids
				return (MockDml.LeadConvertResult) new MockDml.LeadConvertResult(convertedLead)
					?.setId(accountRecord)
					?.setId(contactRecord)
					?.setId(opportunityRecord);
			} catch (System.DmlException error) {
				// Deregister any of successful related records up to this point
				MockDml.INSERTED?.deregisterDml(accountRecord);
				MockDml.INSERTED?.deregisterDml(contactRecord);
				MockDml.INSERTED?.deregisterDml(opportunityRecord);
				MockDml.CONVERTED?.deregisterDml(leadRecord);
				return (MockDml.LeadConvertResult) MockDml.CONVERTED?.handleDmlError(leadRecord, error, allOrNone);
			}
		}

		private void runDeleteCallbackIfAsync(List<Database.DeleteResult> results) {
			if (this.isOperationAsync == true) {
				for (Database.DeleteResult result : results) {
					this.asyncDeleteCallback?.processDelete(result);
				}
			}
		}

		private void runSaveCallbackIfAsync(List<Database.SaveResult> results) {
			if (this.isOperationAsync == true) {
				for (Database.SaveResult result : results) {
					this.asyncSaveCallback?.processSave(result);
				}
			}
		}

		private void simulateInsertIfNew(SObject record) {
			// If the provided record does not already have an Id, simulate an insert operation
			if (record != null && record?.Id == null) {
				SObjectType objectType = record?.getSObjectType();
				record.Id = MockRecord.initRecordId(objectType);
				this.generateMockResult(MockDml.INSERTED, record, true);
			}
		}

		private List<Database.LeadConvertResult> toConvertResults(List<MockDml.Result> results) {
			return (List<Database.LeadConvertResult>) this.toDatabaseResults(
				results,
				List<Database.LeadConvertResult>.class
			);
		}

		private List<Database.EmptyRecycleBinResult> toEmptyRecycleBinResults(List<MockDml.Result> results) {
			Type returnType = List<Database.EmptyRecycleBinResult>.class;
			return (List<Database.EmptyRecycleBinResult>) this.toDatabaseResults(results, returnType);
		}

		private List<Database.DeleteResult> toDeleteResults(List<MockDml.Result> results) {
			Type returnType = List<Database.DeleteResult>.class;
			return (List<Database.DeleteResult>) this.toDatabaseResults(results, returnType);
		}

		private List<Database.SaveResult> toSaveResults(List<MockDml.Result> results) {
			Type returnType = List<Database.SaveResult>.class;
			return (List<Database.SaveResult>) this.toDatabaseResults(results, returnType);
		}

		private List<Database.UndeleteResult> toUndeleteResults(List<MockDml.Result> results) {
			// Note: For some reason, we can't directly deserialize into a List<Database.UndeleteResult> like the other methods.
			// Attempting to do so will result in the "success" parameter always being set to false.
			// Don't ask me why -- but deserializing to an untyped Object first solves this issue.
			Object untyped = JSON.deserializeUntyped(JSON.serialize(results));
			Type returnType = List<Database.UndeleteResult>.class;
			return (List<Database.UndeleteResult>) JSON.deserialize(JSON.serialize(untyped), returnType);
		}

		private List<Database.UpsertResult> toUpsertResults(List<MockDml.Result> results) {
			Type returnType = List<Database.UpsertResult>.class;
			return (List<Database.UpsertResult>) this.toDatabaseResults(results, returnType);
		}

		private Object toDatabaseResults(List<MockDml.Result> results, Type returnType) {
			return JSON.deserialize(JSON.serialize(results), returnType);
		}

		private void validateConvertedLead(Database.LeadConvert leadToConvert) {
			// Mimicks the stock behavior of Database.LeadConvert objects.
			// These will always throw an error if you are missing a leadId or converted status.
			if (leadToConvert?.getLeadId() == null) {
				throw new System.DmlException('valid leadId is required');
			} else if (leadToConvert?.getConvertedStatus() == null) {
				throw new System.DmlException('convertedStatus is required');
			}
		}
	}

	/**
	 * @description Specialized history tracking for platform events, which use EventUuid instead of Id.
	 */
	global virtual class PlatformEventHistory extends MockDml.History {
		private PlatformEventHistory() {
			super(Dml.Operation.DO_PUBLISH);
		}

		global override void addRecordToMap(SObject record, Map<String, Object> records) {
			String uuid = this.getUuid(record);
			records?.put(uuid, record);
		}

		global override SObject setRecordId(SObject record) {
			// Note: Platform Events technically have an Id field, but it's not writeable, nor is it transformed after publish.
			// Instead, the platform populates the "EventUuid" field with a unique identifier
			// It's better to refer to platform events by their EventUuid value, which is unique.
			return new MockRecord(record)?.setField(EVENT_UUID_FIELD, Uuid.randomUuid())?.toSObject();
		}

		private String getUuid(SObject record) {
			return (String) record?.get(EVENT_UUID_FIELD);
		}
	}

	/**
	 * @description Standard history tracking for regular SObject records using Id field.
	 */
	global virtual class RecordHistory extends MockDml.History {
		private RecordHistory(Dml.Operation operation) {
			super(operation);
		}

		global override void addRecordToMap(SObject record, Map<String, Object> records) {
			records?.put(record?.Id, record);
		}

		global override SObject setRecordId(SObject record) {
			// If the record does not have an Id value, generate a mock one
			if (record?.Id == null) {
				SObjectType objectType = record?.getSObjectType();
				record.Id = MockRecord.initRecordId(objectType);
			}
			return record;
		}
	}

	/**
	 * @description Manages mock savepoint history and provides access to savepoint information.
	 */
	global class SavepointHistory {
		private Map<Integer, MockDml.Savepoint> savepointMap;

		private SavepointHistory() {
			this.savepointMap = new Map<Integer, MockDml.Savepoint>();
		}

		/**
		 * @description Returns all registered MockDml.Savepoints.
		 * @return List of all MockDml.Savepoint objects
		 */
		global List<MockDml.Savepoint> getAll() {
			// Returns all registered MockDml.Savepoints:
			return this.savepointMap?.values();
		}

		/**
		 * @description Retrieves a MockDml.Savepoint by its index.
		 * @param index The index of the savepoint to retrieve
		 * @return The MockDml.Savepoint at the specified index
		 */
		global MockDml.Savepoint get(Integer index) {
			return this.savepointMap?.get(index);
		}

		/**
		 * @description Retrieves a System.Savepoint's MockDml.Savepoint wrapper.
		 * @param savepoint The System.Savepoint to get the wrapper for
		 * @return The corresponding MockDml.Savepoint wrapper
		 */
		global MockDml.Savepoint get(System.Savepoint savepoint) {
			Integer index = this.getIndexFrom(savepoint);
			return this.get(index);
		}

		private void add(System.Savepoint savepoint) {
			// Generate a MockDml.SystemSavepoint for the System.Savepoint, and map it by its index:
			Integer index = this.getIndexFrom(savepoint);
			MockDml.Savepoint savepointInfo = new MockDml.Savepoint(savepoint, index);
			this.savepointMap?.put(index, savepointInfo);
		}

		private Integer getIndexFrom(System.Savepoint savepoint) {
			// Note: System.Savepoints don't have any known properties or methods,
			// but printing them toString() reveals a hidden name: "SavepointValueX"
			// where X is the ordered index of created savepoints in the transaction
			// This method extracts that index, so that test callers can identify a particular savepoint if desired:
			return Integer.valueOf(savepoint?.toString()?.replaceAll('[^0-9]', ''));
		}
	}

	/**
	 * @description Decorates a System.Savepoint object with mock database state management.
	 */
	global class Savepoint {
		/**
		 * This class decorates a System.Savepoint object
		 * Test callers can use the class's methods to determine if the savepoint was saved, released, or rolled back
		 * This also stores a shallow copy of the mock database at the time the savepoint was generated,
		 * in the event of a rollback, the mock database will be reverted back to this point
		 */
		/**
		 * @description The index of this savepoint in the transaction.
		 */
		global Integer index { get; private set; }
		/**
		 * @description The name of this savepoint.
		 */
		global String name { get; private set; }
		/**
		 * @description Whether this savepoint was released.
		 */
		global Boolean wasReleased { get; private set; }
		/**
		 * @description Whether this savepoint was rolled back.
		 */
		global Boolean wasRolledBack { get; private set; }
		private transient MockDml.Database savepointState { get; private set; }

		private Savepoint(System.Savepoint savepoint, Integer index) {
			this.index = index;
			this.name = 'SavepointValue' + index;
			this.wasReleased = false;
			this.wasRolledBack = false;
			this.captureCurrentState();
		}

		private void captureCurrentState() {
			// Stores a copy of the mock database at the time the savepoint was initialized, if configured to do so
			// If not configured to do so, returns null,
			// which means that subsuquent rollbacks will not affect the current MockDml.Database
			if (MockDml.MockDatabase.resetOnRollback == true) {
				this.savepointState = MockDml.MockDatabase.snapshot();
			}
		}

		private void release() {
			// Release the current savepoint's state
			// Subsuquent calls to rollback should not affect the mock database
			this.wasReleased = true;
			this.savepointState = null;
		}

		private void rollback() {
			// Revert the mock database to what it was when the Savepoint was generated
			MockDml.MockDatabase = this.savepointState ?? MockDml.MockDatabase;
			this.wasRolledBack = true;
		}
	}

	// **** INNER: PRIVATE **** //
	/**
	 * @description Default failure implementation that always fails operations.
	 */
	private class BaseFailure implements MockDml.ConditionalFailure {
		/**
		 * The `MockDml` class ships with one concrete implementation of the `ConditionalFailure` interface.
		 * This one is simple -- it always returns an error to be thrown.
		 * Callers can inject this error by calling the `MockDml.shouldFail()` method.
		 **/
		/**
		 * @description Always returns a DML exception to simulate failure.
		 * @param operation The DML operation (unused)
		 * @param record The record being processed (unused)
		 * @return A DmlException to be thrown
		 */
		public Exception checkFailure(Dml.Operation operation, SObject record) {
			return new System.DmlException();
		}
	}

	/**
	 * @description Mocks Database.LeadConvertResult for lead conversion operations.
	 */
	private virtual class LeadConvertResult extends MockDml.Result {
		/**
		 * Mocks `Database.LeadConvertResult` objects
		 * Unlike most Database result objects, `Database.LeadConvertResult` does not have a singular id field.
		 * Instead, it stores the ids of the lead that is being converted,
		 * and the account/contact/opportunity that it links to
		 **/
		private Id accountid;
		private Id contactid;
		private Id leadid;
		private Id opportunityid;

		private LeadConvertResult(Lead lead) {
			super(lead);
		}

		protected override Result setId(SObject record) {
			SObjectType objectType = record?.getSObjectType();
			if (objectType == Account.SObjectType) {
				this.accountid = record?.Id;
			} else if (objectType == Contact.SObjectType) {
				this.contactid = record?.Id;
			} else if (objectType == Lead.SObjectType) {
				this.leadid = record?.Id;
			} else if (objectType == Opportunity.SObjectType) {
				this.opportunityid = record?.Id;
			}
			return this;
		}
	}

	/**
	 * @description Mocks standard Database result types (SaveResult, DeleteResult, etc.).
	 */
	private virtual class RecordResult extends MockDml.Result {
		/**
		 * Mocks most Database result types; ex., `Database.SaveResult`, `Database.DeleteResult`, etc.
		 * Only `Database.LeadConvertResult` deviates from this type's structure.
		 **/
		private Id id;

		private RecordResult(SObject record) {
			super(record);
		}

		private Result clearId() {
			this.id = null;
			return this;
		}

		protected override Result setId(SObject record) {
			if (record?.Id != null) {
				// Set the Id of the Dml result with the record's Id
				this.id = record?.Id;
			} else if (this.success == true) {
				// Likely a Platform Event, which doesn't have a "normal" Id field...
				// But an Id value matching the Event's SObjectType still gets assigned to the DmlResult.
				this.id = MockRecord.initRecordId(record?.getSObjectType());
			}
			return this;
		}
	}

	/**
	 * @description Abstract base class for all Database result mock objects.
	 */
	private abstract class Result {
		/**
		 * Abstract type which serves as the building block for mocking all Database result classes.
		 * These objects cannot be manually constructed, but they can easily be converted to their desired type via JSON de/serialization.
		 * All types share two parameters: errors and success
		 **/
		protected List<MockError> errors = new List<MockError>();
		/**
		 * @description Whether the operation succeeded (no errors).
		 */
		protected Boolean success {
			get {
				return this.errors?.isEmpty() != false;
			}
		}

		protected abstract Result setId(SObject record);

		protected Result(SObject record) {
			this.setId(record);
		}

		protected Result addError(MockError error) {
			this.errors?.add(error);
			return this;
		}
	}
}
