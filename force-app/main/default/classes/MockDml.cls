@SuppressWarnings(
	'PMD.ApexDoc,PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.ExcessiveParameterList,PMD.FieldNamingConventions,PMD.PropertyNamingConventions'
)
@IsTest
public class MockDml extends Dml {
	/**
	 * This class mocks CRUD operations, with minimal setup required from end users.
	 * By default, all operations will succeed. If desired, users can specify
	 * conditions in which operations should fail, via the `MockDml.shouldFail` method,
	 * or the `MockDml.shouldFailIf` method and the `ConditionalLogic` interface.
	 **/

	// **** CONSTANT **** //
	public static final MockDml.SavepointHistory SAVEPOINTS;
	private static final String EVENT_UUID_FIELD;
	public static List<MockDml.ConditionalFailure> FAILURES;
	private static final String MOCK_STATUS_CODE;

	// **** STATIC **** //
	public static MockDml.Database MockDatabase { get; private set; }

	public static final MockDml.RecordHistory CONVERTED {
		get {
			return MockDml.MockDatabase?.converted;
		}
	}
	public static final MockDml.RecordHistory DELETED {
		get {
			return MockDml.MockDatabase?.deleted;
		}
	}
	public static final MockDml.RecordHistory INSERTED {
		get {
			return MockDml.MockDatabase?.inserted;
		}
	}
	public static MockDml.PlatformEventHistory PUBLISHED {
		get {
			return MockDml.MockDatabase?.published;
		}
	}
	public static final MockDml.RecordHistory PURGED {
		get {
			return MockDml.MockDatabase?.purged;
		}
	}
	public static final MockDml.RecordHistory UNDELETED {
		get {
			return MockDml.MockDatabase?.undeleted;
		}
	}
	public static final MockDml.RecordHistory UPDATED {
		get {
			return MockDml.MockDatabase?.updated;
		}
	}
	public static final MockDml.RecordHistory UPSERTED {
		get {
			return MockDml.MockDatabase?.upserted;
		}
	}

	static {
		EVENT_UUID_FIELD = 'EventUuid';
		FAILURES = new List<MockDml.ConditionalFailure>{};
		MOCK_STATUS_CODE = 'MOCK_DML';
		SAVEPOINTS = new MockDml.SavepointHistory();
		MockDatabase = new MockDml.Database();
	}

	public static void eraseAllHistories() {
		// Reset all of the history objects to their original state
		// Useful for isolating the actual changes being tested, ie., after test setup
		MockDml.MockDatabase = new MockDml.Database();
	}

	public static void shouldFail() {
		// Adds a BaseFailure the list of failures - all DML operations will now fail.
		MockDml.shouldSucceed();
		MockDml.ConditionalFailure failure = new MockDml.BaseFailure();
		MockDml.shouldFailIf(failure);
	}

	public static void shouldFailIf(MockDml.ConditionalFailure failure) {
		// Adds the ConditionalFailure object to a list of failures.
		// The ConditionalLogic interface defines if/when an error should be thrown during a DML operation.
		// Each dml operation will iterate through the list of failures and call its interface method for each record.
		MockDml.FAILURES?.add(failure);
	}

	public static void shouldSucceed() {
		// Clears the list of failures - all mock DML operations should now succeed.
		MockDml.FAILURES?.clear();
	}

	// **** MEMBER **** //
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
	public interface ConditionalFailure {
		/**
		 * This interface defines whether a DML failure should be simulated for the given record.
		 * Its method should return an exception to be thrown in case of a DML failure, or null in case of success.
		 * Pass objects that implement this interface to `MockDml.shouldFailIf` method.
		 **/
		Exception checkFailure(Dml.Operation operation, SObject record);
	}

	public class Database {
		/**
		 * This class represents a mock Salesforce Database. It stores all DML Methods' corresponding History objects
		 */
		public MockDml.RecordHistory converted { get; private set; }
		public MockDml.RecordHistory deleted { get; private set; }
		public MockDml.RecordHistory inserted { get; private set; }
		public MockDml.PlatformEventHistory published { get; private set; }
		public MockDml.RecordHistory purged { get; private set; }
		public MockDml.RecordHistory undeleted { get; private set; }
		public MockDml.RecordHistory updated { get; private set; }
		public MockDml.RecordHistory upserted { get; private set; }
		/**
		 * When this configuration flag is "true", MockDml will mimic a real Database when a rollback occurs
		 * This is "false" by default, for performance reasons (heap, cpu time, etc).
		 * Only override this if your testing use case truly warrants it!
		 **/
		public Boolean resetOnRollback { get; set; }

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

		public Database snapshot() {
			// Captures the state of the mock database at the current point in time
			// Note: Object.clone() retains the original reference, must use serialization to keep the snapshot separate:
			// https://salesforce.stackexchange.com/questions/162765/object-clone-does-not-work-as-expected
			return (MockDml.Database) JSON.deserialize(JSON.serialize(this), MockDml.Database.class);
		}
	}

	public abstract class History {
		/**
		 * Responsible for recording records that were processed by a given DML operation.
		 * It provides several methods that callers can use to assert if DML actually occurred.
		 **/
		protected Dml.Operation operation;
		protected Map<String, Map<String, SObject>> recordMap;

		protected History(Dml.Operation operation) {
			this.operation = operation;
			this.recordMap = new Map<String, Map<String, SObject>>();
		}

		// **** ABSTRACT **** //
		protected abstract void addRecordToMap(SObject record, Map<String, Object> records);
		protected abstract SObject setRecordId(SObject record);

		// **** PUBLIC **** //
		public Map<SObjectType, List<SObject>> getAll() {
			// Retrieve all records processed by the current operation, grouped by SObjectType
			Map<SObjectType, List<SObject>> allRecords = new Map<SObjectType, List<SObject>>();
			for (String objectApiName : this.recordMap?.keySet()) {
				SObjectType objectType = ((SObject) Type.forName(objectApiName)?.newInstance())?.getSObjectType();
				List<SObject> recordList = this.getRecordMap(objectType)?.values();
				allRecords?.put(objectType, recordList);
			}
			return allRecords;
		}

		public List<SObject> getRecords(SObjectType objectType) {
			// Retrieves all records of the specified SObjectType
			return this.getRecordMap(objectType)?.values();
		}

		public SObject get(SObjectType objectType, String idOrUuuid) {
			// Retrieves a specific record that was processed
			// Use this method with platform events, who have a UUID but not a traditional Record ID with a reference to the SObjectType
			return this.getRecordMap(objectType)?.get(idOrUuuid);
		}

		public SObject get(Id recordId) {
			// Retrieves a specific record that was processed
			SObjectType objectType = recordId?.getSObjectType();
			return this.get(objectType, recordId);
		}

		public SObject get(SObject record) {
			return this.get(record?.Id);
		}

		public Boolean wasProcessed(SObjectType objectType, String idOrUuid) {
			// Returns true if the record was processed for DML, else returns false
			return this.get(objectType, idOrUuid) != null;
		}

		public Boolean wasProcessed(Id recordId) {
			// Returns true if the record was processed for DML, else returns false
			SObjectType objectType = recordId?.getSObjectType();
			return this.wasProcessed(objectType, recordId);
		}

		public Boolean wasProcessed(SObject record) {
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
			MockDml.Error dmlError = new MockDml.Error(error);
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

	public enum Operation {
		// ! Deprecated: This will be removed in a future release
		// ! Replace all uses of this enum with the Dml.Operation enum
		DO_CONVERT,
		DO_DELETE,
		DO_INSERT,
		DO_PUBLISH,
		DO_PURGE,
		DO_UNDELETE,
		DO_UPDATE,
		DO_UPSERT
	}

	public class Request extends Dml.Request {
		/**
		 * Contains overrides for each DML operation, and is responsible for mocking DML
		 * An instance of this class (instead of the super type)
		 * is initialized via the overridden `initRequest` method
		 */
		private Request(Dml.Operation operation, List<Object> records) {
			super(operation, records);
			this.isMockDml = true;
		}

		// ** OVERRIDES
		protected override List<Database.LeadConvertResult> doConvert() {
			List<MockDml.Result> mockResults = new List<MockDml.Result>();
			for (Database.LeadConvert leadToConvert : this.leadsToConvert) {
				MockDml.Result result = this.generateMockResult(leadToConvert, this.options?.OptAllOrNone);
				mockResults?.add(result);
			}
			return this.toConvertResults(mockResults);
		}

		protected override List<Database.DeleteResult> doDelete() {
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
			List<MockDml.Result> mockResults = new List<MockDml.Result>();
			for (SObject event : this.records) {
				// Note: EventBus.publish() always runs in allOrNone=false context
				MockDml.Result result = this.generateMockResult(MockDml.PUBLISHED, event, false);
				mockResults?.add(result);
			}
			return this.toSaveResults(mockResults);
		}

		protected override List<Database.UndeleteResult> doUndelete() {
			List<MockDml.Result> mockResults = new List<MockDml.Result>();
			for (SObject record : records) {
				MockDml.Result result = this.generateMockResult(MockDml.UNDELETED, record, allOrNone);
				mockResults?.add(result);
			}
			return this.toUndeleteResults(mockResults);
		}

		protected override List<Database.SaveResult> doUpdate() {
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
			List<MockDml.Result> mockResults = new List<MockDml.Result>();
			for (SObject record : this.records) {
				MockDml.Result result = this.generateMockResult(MockDml.UPSERTED, record, this.allOrNone);
				mockResults?.add(result);
			}
			return this.toUpsertResults(mockResults);
		}

		protected override List<Database.EmptyRecycleBinResult> emptyRecycleBin() {
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
			Opportunity opportunityRecord = new Opportunity(Id = leadToConvert?.getOpportunityId());
			try {
				// Note: Process resulting records using allOrNone=true, regardless of its original value
				// This allows injected errors for Accounts/Contacts/Opps to be caught and handled appropriately
				// 1. Simulate converting the lead
				this.validateConvertedLead(leadToConvert);
				this.generateMockResult(MockDml.CONVERTED, leadRecord, true);
				// 2. Simulate creating an Account/Contact/Opportunity, if their Id wasn't already provided
				this.simulateInsertIfNew(accountRecord);
				this.simulateInsertIfNew(contactRecord);
				this.simulateInsertIfNew(opportunityRecord);
				// 3. Build & return the LeadConvertResult w/the resulting record ids
				return (MockDml.LeadConvertResult) new MockDml.LeadConvertResult(leadRecord)
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
			if (record?.Id == null) {
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

	public virtual class PlatformEventHistory extends MockDml.History {
		/**
		 * This class tracks platform events that were mock published.
		 * Necessary since platform events' unique identifier is the `EventUuid` field - not `Id`
		 **/
		private PlatformEventHistory() {
			super(Dml.Operation.DO_PUBLISH);
		}

		protected override void addRecordToMap(SObject record, Map<String, Object> records) {
			String uuid = this.getUuid(record);
			records?.put(uuid, record);
		}

		protected override SObject setRecordId(SObject record) {
			// Note: Platform Events technically have an Id field, but it's not writeable, nor is it transformed after publish.
			// Instead, the platform populates the "EventUuid" field with a unique identifier
			// It's better to refer to platform events by their EventUuid value, which is unique.
			return new MockRecord(record)?.setField(EVENT_UUID_FIELD, Uuid.randomUuid())?.toSObject();
		}

		private String getUuid(SObject record) {
			return (String) record?.get(EVENT_UUID_FIELD);
		}
	}

	public virtual class RecordHistory extends MockDml.History {
		/**
		 * This class is responsible for tracking DML made against most SObject types
		 **/
		private RecordHistory(Dml.Operation operation) {
			super(operation);
		}

		protected override void addRecordToMap(SObject record, Map<String, Object> records) {
			records?.put(record?.Id, record);
		}

		protected override SObject setRecordId(SObject record) {
			// If the record does not have an Id value, generate a mock one
			if (record?.Id == null) {
				SObjectType objectType = record?.getSObjectType();
				record.Id = MockRecord.initRecordId(objectType);
			}
			return record;
		}
	}

	public class SavepointHistory {
		/**
		 * This class maintains a map of MockDml.Savepoints,
		 * and provides methods to easily get a particular savepoint by their index or by the object itself
		 */
		private Map<Integer, MockDml.Savepoint> savepointMap;

		private SavepointHistory() {
			this.savepointMap = new Map<Integer, MockDml.Savepoint>();
		}

		public List<MockDml.Savepoint> getAll() {
			// Returns all registered MockDml.Savepoints:
			return this.savepointMap?.values();
		}

		public MockDml.Savepoint get(Integer index) {
			// Retrieves a MockDml.Savepoint by its index:
			return this.savepointMap?.get(index);
		}

		public MockDml.Savepoint get(System.Savepoint savepoint) {
			// Retrieves a System.Savepoint's MockDml.Savepoint wrapper:
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

	public class Savepoint {
		/**
		 * This class decorates a System.Savepoint object
		 * Test callers can use the class's methods to determine if the savepoint was saved, released, or rolled back
		 * This also stores a shallow copy of the mock database at the time the savepoint was generated,
		 * in the event of a rollback, the mock database will be reverted back to this point
		 */
		public Integer index { get; private set; }
		public String name { get; private set; }
		public Boolean wasReleased { get; private set; }
		public Boolean wasRolledBack { get; private set; }
		private transient MockDml.Database savepointState;

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
	private class BaseFailure implements MockDml.ConditionalFailure {
		/**
		 * The `MockDml` class ships with one concrete implementation of the `ConditionalFailure` interface.
		 * This one is simple -- it always returns an error to be thrown.
		 * Callers can inject this error by calling the `MockDml.shouldFail()` method.
		 **/
		public Exception checkFailure(Dml.Operation operation, SObject record) {
			return new System.DmlException();
		}
	}

	private class Error {
		/**
		 *  Mocks the `Database.Error` class, since this type cannot be manually constructed.
		 **/
		private String message;
		private String statusCode;

		private Error(Exception error) {
			// Note: It's not possible to retrieve the actual status code
			// of an Exception outside of an actual DML context.
			// This class will always use a dummy status code
			this.message = error?.getMessage();
			this.statusCode = MOCK_STATUS_CODE;
		}

		private System.DmlException toDmlException() {
			// De-converts the Error to a DmlException to be thrown in DML Operations
			System.DmlException error = new System.DmlException();
			error
				?.setMessage(
					'DML failed. First exception on row X; first error: ' +
						this.statusCode +
						', ' +
						this.message +
						': []'
				);
			return error;
		}
	}

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

	private abstract class Result {
		/**
		 * Abstract type which serves as the building block for mocking all Database result classes.
		 * These objects cannot be manually constructed, but they can easily be converted to their desired type via JSON de/serialization.
		 * All types share two parameters: errors and success
		 **/
		protected List<MockDml.Error> errors = new List<MockDml.Error>();
		protected Boolean success {
			get {
				return this.errors?.isEmpty() != false;
			}
		}

		protected abstract Result setId(SObject record);

		protected Result(SObject record) {
			this.setId(record);
		}

		protected Result addError(MockDml.Error error) {
			this.errors?.add(error);
			return this;
		}
	}
}
