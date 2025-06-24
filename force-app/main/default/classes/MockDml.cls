@SuppressWarnings(
	'PMD.ApexDoc, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.FieldNamingConventions, PMD.PropertyNamingConventions'
)
@IsTest
public class MockDml extends Dml {
	/**
	 * This class mocks CRUD operations, with minimal setup required from end users.
	 * By default, all operations will succeed. If desired, users can specify
	 * conditions in which operations should fail, via the `fail()` method,
	 * or the `failIf()` method and the `ConditionalLogic` interface.
	 **/

	// **** CONSTANT **** //
	public static final MockDml.SavepointHistory SAVEPOINTS;
	private static final String EVENT_UUID_FIELD;
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
		MOCK_STATUS_CODE = 'MOCK_DML';
		SAVEPOINTS = new MockDml.SavepointHistory();
		MockDatabase = new MockDml.Database();
	}

	public static void eraseAllHistories() {
		// Reset all of the history objects to their original state
		// Useful for isolating the actual changes being tested, ie., after test setup
		MockDml.MockDatabase = new MockDml.Database();
	}

	// **** MEMBER **** //
	private List<MockDml.ConditionalFailure> failures;

	public MockDml(DatabaseLayer factory) {
		super(factory);
		this.failures = new List<MockDml.ConditionalFailure>();
	}

	public MockDml clearFailures() {
		// Clears the list of failures from the current instance.
		// As a result, all mock DML operations should now succeed.
		this.failures?.clear();
		return this;
	}

	public MockDml fail() {
		// Adds a BaseFailure to the current instance; all DML operations will now fail.
		MockDml.ConditionalFailure failure = new MockDml.BaseFailure();
		return this.failIf(failure);
	}

	public MockDml failIf(MockDml.ConditionalFailure failure) {
		// Adds the ConditionalFailure object to a list of failures.
		// The ConditionalLogic interface defines if/when an error should be thrown during a DML operation.
		// Each dml operation will iterate through the list of failures and call its interface method for each record.
		this.failures?.add(failure);
		return this;
	}

	// **** OVERRIDES **** //
	public override List<Database.LeadConvertResult> doConvert(
		List<Database.LeadConvert> leadsToConvert,
		Database.DmlOptions options,
		System.AccessLevel accessLevel
	) {
		List<MockDml.Result> results = new List<MockDml.Result>();
		for (Database.LeadConvert leadToConvert : leadsToConvert) {
			MockDml.Result result = this.generateMockResult(leadToConvert, options?.OptAllOrNone);
			results?.add(result);
		}
		return this.toConvertResults(results);
	}

	public override List<Database.DeleteResult> doDelete(
		List<Id> recordIds,
		Boolean allOrNone,
		System.AccessLevel accessLevel
	) {
		List<MockDml.Result> results = new List<MockDml.Result>();
		for (Id recordId : recordIds) {
			SObject record = recordId?.getSObjectType()?.newSObject(recordId);
			MockDml.Result result = this.generateMockResult(MockDml.DELETED, record, allOrNone);
			results?.add(result);
		}
		return this.toDeleteResults(results);
	}

	public override List<Database.DeleteResult> doDeleteAsync(
		List<SObject> records,
		DataSource.AsyncDeleteCallback callback,
		System.AccessLevel accessLevel
	) {
		// For mocking purposes, process the same as a "normal" doDelete operation, but w/callbacks
		List<Database.DeleteResult> results = this.doDelete(records, accessLevel);
		for (Database.DeleteResult result : results) {
			callback?.processDelete(result);
		}
		return results;
	}

	public override List<Database.DeleteResult> doDeleteImmediate(
		List<SObject> records,
		System.AccessLevel accessLevel
	) {
		// For mocking purposes, process the same as a "normal" doDelete operation,
		return this.doDelete(records, accessLevel);
	}

	public override List<Database.EmptyRecycleBinResult> emptyRecycleBin(List<Id> recordIds) {
		List<MockDml.Result> results = new List<MockDml.Result>();
		for (Id recordId : recordIds) {
			SObject record = recordId?.getSObjectType()?.newSObject(recordId);
			MockDml.Result result = this.generateMockResult(MockDml.PURGED, record, true);
			results?.add(result);
		}
		return this.toEmptyRecycleBinResults(results);
	}

	public override List<Database.SaveResult> doInsert(
		List<SObject> records,
		Database.DmlOptions options,
		System.AccessLevel accessLevel
	) {
		List<MockDml.Result> results = new List<MockDml.Result>();
		for (SObject record : records) {
			MockDml.Result result = this.generateMockResult(MockDml.INSERTED, record, options?.OptAllOrNone);
			results?.add(result);
		}
		return this.toSaveResults(results);
	}

	public override List<Database.SaveResult> doInsertAsync(
		List<SObject> records,
		DataSource.AsyncSaveCallback callback,
		System.AccessLevel accessLevel
	) {
		// For mocking purposes, process the same as a "normal" doInsert operation, but w/callbacks
		List<Database.SaveResult> results = this.doInsert(records, accessLevel);
		for (Database.SaveResult result : results) {
			callback?.processSave(result);
		}
		return results;
	}

	public override List<Database.SaveResult> doInsertImmediate(List<SObject> records, System.AccessLevel accessLevel) {
		// For mocking purposes, process the same as a "normal" doInsert operation
		return this.doInsert(records, accessLevel);
	}

	public override List<Database.SaveResult> doPublish(List<SObject> events) {
		// Ensure the callback is set; if null, use the default value
		List<MockDml.Result> results = new List<MockDml.Result>();
		for (SObject event : events) {
			// Note: EventBus.publish() always runs in allOrNone=false context
			MockDml.Result result = this.generateMockResult(MockDml.PUBLISHED, event, false);
			results?.add(result);
		}
		return this.toSaveResults(results);
	}

	public override List<Database.UndeleteResult> doUndelete(
		List<Id> recordIds,
		Boolean allOrNone,
		System.AccessLevel accessLevel
	) {
		List<MockDml.Result> results = new List<MockDml.Result>();
		for (Id recordId : recordIds) {
			SObject record = recordId?.getSObjectType()?.newSObject(recordId);
			MockDml.Result result = this.generateMockResult(MockDml.UNDELETED, record, allOrNone);
			results?.add(result);
		}
		return this.toUndeleteResults(results);
	}

	public override List<Database.SaveResult> doUpdate(
		List<SObject> records,
		Database.DmlOptions options,
		System.AccessLevel accessLevel
	) {
		List<MockDml.Result> results = new List<MockDml.Result>();
		for (SObject record : records) {
			MockDml.Result result = this.generateMockResult(MockDml.UPDATED, record, options?.OptAllOrNone);
			results?.add(result);
		}
		return this.toSaveResults(results);
	}

	public override List<Database.SaveResult> doUpdateAsync(
		List<SObject> records,
		DataSource.AsyncSaveCallback callback,
		System.AccessLevel accessLevel
	) {
		// For mocking purposes, process the same as a "normal" doUpdate operation, but w/callbacks
		List<Database.SaveResult> results = this.doUpdate(records, accessLevel);
		for (Database.SaveResult result : results) {
			callback?.processSave(result);
		}
		return results;
	}

	public override List<Database.SaveResult> doUpdateImmediate(List<SObject> records, System.AccessLevel accessLevel) {
		// For mocking purposes, process the same as a "normal" doUpdate operation
		return this.doUpdate(records, accessLevel);
	}

	public override List<Database.UpsertResult> doUpsert(
		List<SObject> records,
		SObjectField externalIdField,
		Boolean allOrNone,
		System.AccessLevel accessLevel
	) {
		List<MockDml.Result> results = new List<MockDml.Result>();
		for (SObject record : records) {
			MockDml.Result result = this.generateMockResult(MockDml.UPSERTED, record, allOrNone);
			results?.add(result);
		}
		return this.toUpsertResults(results);
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

	// **** PRIVATE **** //
	private void checkFailures(MockDml.Operation operation, SObject record) {
		// Runs all ConditionalFailures defined the current instance against each record.
		for (MockDml.ConditionalFailure failure : this.failures) {
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
			MockDml.Operation operation = history?.getOperation();
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
		return (List<Database.EmptyRecycleBinResult>) this.toDatabaseResults(
			results,
			List<Database.EmptyRecycleBinResult>.class
		);
	}

	private List<Database.DeleteResult> toDeleteResults(List<MockDml.Result> results) {
		return (List<Database.DeleteResult>) this.toDatabaseResults(results, List<Database.DeleteResult>.class);
	}

	private List<Database.SaveResult> toSaveResults(List<MockDml.Result> results) {
		return (List<Database.SaveResult>) this.toDatabaseResults(results, List<Database.SaveResult>.class);
	}

	private List<Database.UndeleteResult> toUndeleteResults(List<MockDml.Result> results) {
		// Note: For some reason, we can't directly deserialize into a List<Database.UndeleteResult> like the other methods.
		// Attempting to do so will result in the "success" parameter always being set to false.
		// Don't ask me why -- but deserializing to an untyped Object first solves this issue.
		Object untyped = JSON.deserializeUntyped(JSON.serialize(results));
		return (List<Database.UndeleteResult>) JSON.deserialize(
			JSON.serialize(untyped),
			List<Database.UndeleteResult>.class
		);
	}

	private List<Database.UpsertResult> toUpsertResults(List<MockDml.Result> results) {
		return (List<Database.UpsertResult>) this.toDatabaseResults(results, List<Database.UpsertResult>.class);
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

	// **** INNER: PUBLIC **** //
	public interface ConditionalFailure {
		/**
		 * This interface defines whether a DML failure should be simulated for the given record.
		 * Its method should return an exception to be thrown in case of a DML failure, or null in case of success.
		 * Pass objects that implement this interface to MockDml's `failIf()` method.
		 **/
		Exception checkFailure(MockDml.Operation operation, SObject record);
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
			this.converted = new MockDml.RecordHistory(MockDml.Operation.DO_CONVERT);
			this.deleted = new MockDml.RecordHistory(MockDml.Operation.DO_DELETE);
			this.inserted = new MockDml.RecordHistory(MockDml.Operation.DO_INSERT);
			this.published = new MockDml.PlatformEventHistory();
			this.purged = new MockDml.RecordHistory(MockDml.Operation.DO_PURGE);
			this.undeleted = new MockDml.RecordHistory(MockDml.Operation.DO_UNDELETE);
			this.updated = new MockDml.RecordHistory(MockDml.Operation.DO_UPDATE);
			this.upserted = new MockDml.RecordHistory(MockDml.Operation.DO_UPSERT);
			this.resetOnRollback = true;
		}

		public Database snapshot() {
			// Captures the state of the mock database at the current point in time:
			// https://salesforce.stackexchange.com/questions/162765/object-clone-does-not-work-as-expected
			return (MockDml.Database) JSON.deserialize(JSON.serialize(this), MockDml.Database.class);
		}
	}

	public abstract class History {
		/**
		 * Responsible for recording records that were processed by a given DML operation.
		 * It provides several methods that callers can use to assert if DML actually occurred.
		 **/
		protected MockDml.Operation operation;
		protected Map<String, Map<String, SObject>> recordMap;

		protected History(MockDml.Operation operation) {
			this.operation = operation;
			this.recordMap = new Map<String, Map<String, SObject>>();
		}

		// **** ABSTRACT **** //
		protected abstract void addRecordToMap(SObject record, Map<String, Object> records);
		protected abstract SObject setRecordId(SObject record);

		// **** PUBLIC **** //
		public History eraseHistory() {
			this.recordMap?.clear();
			return this;
		}

		public Map<String, List<SObject>> getAll() {
			// Retrieve all records processed by the current operation, grouped by SObjectType
			Map<String, List<SObject>> allRecords = new Map<String, List<SObject>>();
			for (String objectName : this.recordMap?.keySet()) {
				List<SObject> recordList = this.recordMap?.get(objectName)?.values();
				allRecords?.put(objectName, recordList);
			}
			return allRecords;
		}

		public List<SObject> getRecords(SObjectType objectType) {
			// Retrieves all records of the specified SObjectType
			return this.getRecordMap(objectType)?.values();
		}

		// **** PRIVATE **** //
		protected void deregisterDml(SObject record) {
			// Removes the specified record from the History
			SObjectType objectType = record?.getSObjectType();
			Map<String, Object> recordMap = this.getRecordMap(objectType);
			recordMap?.remove(record?.Id);
		}

		protected MockDml.Operation getOperation() {
			return this.operation;
		}

		protected Map<String, SObject> getRecordMap(SObjectType objectType) {
			return this.recordMap?.get(objectType?.toString()) ?? new Map<String, SObject>();
		}

		protected MockDml.Result handleDmlError(SObject record, Exception error, Boolean allOrNone) {
			// Handles an error during DML, according to the defined allOrNone logic, mirroring standard functionality
			MockDml.Error dmlError = new MockDml.Error(error);
			if (allOrNone == true) {
				throw dmlError?.toDmlException();
			} else if (this.operation == MockDml.Operation.DO_CONVERT) {
				Lead lead = (Lead) record;
				return new MockDml.LeadConvertResult(lead)?.addError(dmlError);
			} else if (this.operation == MockDml.Operation.DO_INSERT) {
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
			Map<String, SObject> records = this.getRecordMap(objectType);
			this.addRecordToMap(record, records);
			this.recordMap?.put(objectType?.toString(), records);
			return new MockDml.RecordResult(record);
		}
	}

	public enum Operation {
		DO_CONVERT,
		DO_DELETE,
		DO_INSERT,
		DO_PUBLISH,
		DO_PURGE,
		DO_UNDELETE,
		DO_UPDATE,
		DO_UPSERT
	}

	public virtual class PlatformEventHistory extends History {
		/**
		 * This class tracks platform events that were mock published.
		 * Necessary since platform events' unique identifier is the `EventUuid` field - not `Id`
		 **/
		private PlatformEventHistory() {
			super(MockDml.Operation.DO_PUBLISH);
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

	public virtual class RecordHistory extends History {
		/**
		 * This class is responsible for tracking DML made against most SObject types
		 **/
		private RecordHistory(MockDml.Operation operation) {
			super(operation);
		}

		public SObject getRecord(Id recordId) {
			// Retrieve a specific SObject from the History tracking
			SObjectType objectType = recordId?.getSObjectType();
			return this.getRecordMap(objectType)?.get(recordId);
		}

		public SObject getRecord(SObject record) {
			return this.getRecord(record?.Id);
		}

		public Boolean wasProcessed(Id recordId) {
			// Returns true if the provided recordId was processed by the DML operation
			return this.getRecord(recordId) != null;
		}

		public Boolean wasProcessed(SObject record) {
			return this.wasProcessed(record?.Id);
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
			return this.savepointMap?.get(index);
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
	private class BaseFailure implements ConditionalFailure {
		/**
		 * The `MockDml` class ships with one concrete implementation of the `ConditionalFailure` interface.
		 * This one is simple -- it always returns an error to be thrown.
		 * Callers can inject this error by calling the MockDml's `fail()` method.
		 **/
		public Exception checkFailure(MockDml.Operation operation, SObject record) {
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

	private virtual class LeadConvertResult extends Result {
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

	private virtual class RecordResult extends Result {
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
