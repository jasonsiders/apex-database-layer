@IsTest
public class MockDml extends Dml {
    // **** STATIC **** //
    public static MockDml.RecordHistory Converted = new MockDml.RecordHistory(Dml.Operation.DO_CONVERT);
    public static MockDml.RecordHistory Deleted = new MockDml.RecordHistory(Dml.Operation.DO_DELETE);
    public static MockDml.RecordHistory Inserted = new MockDml.RecordHistory(Dml.Operation.DO_INSERT);
    public static MockDml.RecordHistory Undeleted = new MockDml.RecordHistory(Dml.Operation.DO_UNDELETE);
    public static MockDml.RecordHistory Updated = new MockDml.RecordHistory(Dml.Operation.DO_UPDATE);
    public static MockDml.RecordHistory Upserted = new MockDml.RecordHistory(Dml.Operation.DO_UPSERT);
    public static MockDml.PlatformEventHistory Published = new MockDml.PlatformEventHistory();
    static final String EVENT_UUID_FIELD = 'EventUuid';

    public static void eraseAllHistories() {
        // Reset all of the history objects to their original state
        // Useful for isolating the actual changes being tested, ie., after test setup
        for (MockDml.History history : new List<MockDml.History>{
            MockDml.Converted,
            MockDml.Deleted,
            MockDml.Inserted,
            MockDml.Published,
            MockDml.Undeleted,
            MockDml.Updated,
            MockDml.Upserted
        }) {
            history?.eraseHistory();
        }
    }

    // **** MEMBER **** // 
    private List<MockDml.FailureLogic> failures = new List<MockDml.FailureLogic>();

    public MockDml() {
        super();
    }

    // **** OVERRIDES **** //
    public override List<Database.LeadConvertResult> doConvert(List<Database.LeadConvert> leadsToConvert) {
        List<Database.LeadConvertResult> results = new List<Database.LeadConvertResult>();
        /* TODO!
        for (Id recordId : recordIds) {
            SObject record = recordId?.getSObjectType()?.newSObject(recordId);
            Database.DeleteResult result = this.generateMockResult(MockDml.Deleted, record)?.toDeleteResult();
            results?.add(result);
        } */
        return results;
    }

    public override List<Database.DeleteResult> doDelete(List<Id> recordIds) {
        List<Database.DeleteResult> results = new List<Database.DeleteResult>();
        for (Id recordId : recordIds) {
            SObject record = recordId?.getSObjectType()?.newSObject(recordId);
            Database.DeleteResult result = this.generateMockResult(MockDml.Deleted, record)?.toDeleteResult();
            results?.add(result);
        }
        return results;
    }

    public override List<Database.DeleteResult> doDeleteAsync(List<SObject> records) {
        // For mocking purposes, process the same as a normal delete operation, but w/callbacks
        List<Database.DeleteResult> results = this.doDelete(records);
        for (Database.DeleteResult result : results) {
            this.getDeleteCallback()?.processDelete(result);
        }
        return results;
    }

    public override List<Database.DeleteResult> doDeleteImmediate(List<SObject> records) {
        // For mocking purposes, process the same as a normal delete operation
        return this.doDelete(records);
    }

    public override List<Database.DeleteResult> doHardDelete(List<Id> recordIds) {
        // For mocking purposes, process the same as a normal delete operation
        return this.doDelete(recordIds);
    }

    public override List<Database.SaveResult> doInsert(List<SObject> records) {
        List<Database.SaveResult> results = new List<Database.SaveResult>();
        for (SObject record : records) {
            Database.SaveResult result = this.generateMockResult(MockDml.Inserted, record)?.toSaveResult();
            results?.add(result);
        }
        return results;
    }

    public override List<Database.SaveResult> doInsertAsync(List<SObject> records) {
        // For mocking purposes, process the same as a normal insert operation, but w/callbacks
        List<Database.SaveResult> results = this.doInsert(records);
        for (Database.SaveResult result : results) {
            this.getSaveCallback()?.processSave(result);
        }
        return results; 
    }

    public override List<Database.SaveResult> doInsertImmediate(List<SObject> records) {
        // For mocking purposes, process the same as a normal insert operation
        return this.doInsert(records);
    }

    public override List<Database.SaveResult> doPublish(List<SObject> events) {
        List<Database.SaveResult> results = new List<Database.SaveResult>();
        for (SObject event : events) {
            Database.SaveResult result = this.generateMockResult(MockDml.Published, event)?.toSaveResult();
            results?.add(result);
        }
        return results;
    }
    
    public override List<Database.UndeleteResult> doUndelete(List<Id> recordIds) {
        List<Database.UndeleteResult> results = new List<Database.UndeleteResult>();
        for (Id recordId : recordIds) {
            SObject record = recordId?.getSObjectType()?.newSObject(recordId);
            Database.UndeleteResult result = this.generateMockResult(MockDml.Undeleted, record)?.toUndeleteResult();
            results?.add(result);
        }
        return results;
    }

    public override List<Database.SaveResult> doUpdate(List<SObject> records) {
        List<Database.SaveResult> results = new List<Database.SaveResult>();
        for (SObject record : records) {
            Database.SaveResult result = this.generateMockResult(MockDml.Updated, record)?.toSaveResult();
            results?.add(result);
        }
        return results;
    }
    
    public override List<Database.SaveResult> doUpdateAsync(List<SObject> records) {
        // For mocking purposes, process the same as a normal update operation, but w/callbacks
        List<Database.SaveResult> results = this.doUpdate(records);
        for (Database.SaveResult result : results) {
            this.getSaveCallback()?.processSave(result);
        }
        return results; 
    }

    public override List<Database.SaveResult> doUpdateImmediate(List<SObject> records) {
        // For mocking purposes, process the same as a normal update operation
        return this.doUpdate(records);
    }

    public override List<Database.UpsertResult> doUpsert(List<SObject> records) {
        List<Database.UpsertResult> results = new List<Database.UpsertResult>();
        for (SObject record : records) {
            Database.UpsertResult result = this.generateMockResult(MockDml.Upserted, record)?.toUpsertResult();
            results?.add(result);
        }
        return results;
    }

    // **** PUBLIC **** // 
    public MockDml addFailure(MockDml.FailureLogic failure) {
        this.failures?.add(failure);
        return this; 
    }
    
    public MockDml clearFailures() {
        this.failures?.clear();
        return this; 
    }

    // **** PRIVATE **** //
    private void checkFailures(Dml.Operation operation, SObject record) {
        // Runs the FailureLogic defined the current instance against each record.
        for (MockDml.FailureLogic failure : this.failures) {
            System.DmlException error = failure?.checkFailure(operation, record)?.toDmlException();
            if (error != null) {
                throw error;
            }
        }
    }

    private MockDml.Result generateMockResult(MockDml.History history, SObject record) {
        try {
            Dml.Operation operation = history?.getOperation();
            // Determine if the operation should fail for the specific record
            this.checkFailures(operation, record);
            // Simulate successful dml
            return history?.registerDml(record);
        } catch (System.DmlException error) {
            return this.handleDmlError(record, error);
        }
    }

    private MockDml.Result handleDmlError(SObject record, System.DmlException error) {
        // Handle allOrNone logic, according to standard DML functionality
        if (this.getAllOrNone() == true) {
            throw error;
        } else {
            MockDml.Error dmlError = new MockDml.Error(error); 
            return new MockDml.Result(record)?.addError(dmlError);
        }
    }

    // **** INNER **** // 
    public class Error {
        // Wraps the Database.Error class, to be used for mocking in @IsTest context
        public String message { get; set; }
        public String statusCode { get; set; }

        public Error(String message, System.StatusCode statusCode) {
            this.message = message;
            this.statusCode = statusCode?.name();
        }

        public Error(Exception error) {
            this.message = error?.getMessage();
            this.statusCode = 'MOCK_DML';
        }

        public Error() {
            // Initialize an error with a default message & status code
            this(new System.DmlException());
        }

        private Database.Error toDatabaseError() {
            return (Database.Error) JSON.deserialize(JSON.serialize(this), Database.Error.class);
        }

        private System.DmlException toDmlException() {
            // De-converts the Error to a DmlException to be thrown in DML Operations
            System.DmlException error = new System.DmlException();
            error?.setMessage('DML failed. First exception on row X; first error: ' + this.statusCode + ', ' + this.message + ': []');
            return error; 
        }
    }

    public interface FailureLogic {
        // Interface logic determines if a DML failure should be simulated for the given record.
        // If so, the method returns a an error to be thrown by the MockDml class during DML.
        MockDml.Error checkFailure(Dml.Operation operation, SObject record);
    }

    public abstract class History {
        protected Dml.Operation operation;
        protected Map<SObjectType, Map<String, SObject>> recordMap;

        public History(Dml.Operation operation) {
            this.operation = operation; 
            this.recordMap = new Map<SObjectType, Map<String, SObject>>();
        }

        // **** ABSTRACT **** //
        public abstract void addRecordToMap(SObject record, Map<String, Object> records);
        public abstract SObject getRecord(SObject record);
        public abstract SObject setRecordId(SObject record);
        public abstract Boolean wasProcessed(SObject record);
        
        // **** PUBLIC **** //
        public History eraseHistory() {
            this.recordMap?.clear();
            return this; 
        }

        public List<SObject> getAll() {
            List<SObject> allRecords = new List<SObject>();
            for (SObjectType objectType : this.recordMap?.keySet()) {
                List<SObject> records = this.getRecords(objectType);
                allRecords?.addAll(records);
            }
            return allRecords;
        }

        public List<SObject> getRecords(SObjectType objectType) {
            return this.getRecordMap(objectType)?.values();
        }

        public Dml.Operation getOperation() {
            return this.operation;
        }

        public MockDml.Result registerDml(SObject record) {
            // This method registers that the records were operated on, 
            // and store them in a way that's easy for callers to get & perform asserts
            record = this.setRecordId(record);
            SObjectType objectType = record?.getSObjectType();
            Map<String, SObject> records = this.getRecordMap(objectType);
            this.addRecordToMap(record, records);
            this.recordMap?.put(objectType, records);
            return new MockDml.Result(record);
        }

        protected Map<String, SObject> getRecordMap(SObjectType objectType) {
            return this.recordMap?.get(objectType) ?? new Map<String, SObject>(); 
        }
    }
    
    public class RecordHistory extends History {
        private RecordHistory(Dml.Operation operation) {
            super(operation);
        }

        // **** OVERRIDES **** //
        public override void addRecordToMap(SObject record, Map<String, Object> records) {
            records?.put(record?.Id, record);
        }

        public override SObject getRecord(SObject record) {
            return this.getRecord(record?.Id);
        }

        public override SObject setRecordId(SObject record) {
            // If the record does not have an Id value, generate a mock one
            if (record?.Id == null) {
                SObjectType objectType = record?.getSObjectType();
                record.Id = SObjectUtils.mockRecordId(objectType);
            }
            return record;
        }

        public override Boolean wasProcessed(SObject record) {
            return this.wasProcessed(record?.Id);
        }

        // **** PUBLIC **** //
        public SObject getRecord(Id recordId) {
            SObjectType objectType = recordId?.getSObjectType();
            return this.getRecordMap(objectType)?.get(recordId);
        }

        public Boolean wasProcessed(Id recordId) {
            return this.getRecord(recordId) != null;
        }
    }

    public class PlatformEventHistory extends History {
        private Map<String, SObjectType> objectTypesByUuid;

        public PlatformEventHistory() {
            super(Dml.Operation.DO_PUBLISH);
            this.objectTypesByUuid = new Map<String, SObjectType>();
        }

        // **** OVERRIDES **** //
        public override void addRecordToMap(SObject record, Map<String, Object> records) {
            String uuid = this.getUuid(record);
            records?.put(uuid, record);
            this.objectTypesByUuid?.put(uuid, record?.getSObjectType());
        }

        public override SObject getRecord(SObject record) {
            SObjectType objectType = record?.getSObjectType();
            String uuid = this.getUuid(record);
            return this.getRecordMap(objectType)?.get(uuid);
        }

        public override SObject setRecordId(SObject record) {
            // Note: Platform Events technically have an Id field, but it's not writeable, nor is it transformed after publish. 
            // Instead, the platform populates the "EventUuid" field with a unique identifier 
            // It's better to refer to platform events by their EventUuid value, which is unique.
            return SObjectUtils.setReadOnlyFields(record, EVENT_UUID_FIELD, Uuid.randomUuid());
        }

        public override Boolean wasProcessed(SObject record) {
            return this.getRecord(record) != null;
        }

        // **** PUBLIC **** //
        public SObject getRecord(String uuid) {
            SObjectType objectType = this.objectTypesByUuid?.get(uuid);
            return this.getRecordMap(objectType)?.get(uuid);
        }

        public Boolean wasProcessed(String uuid) {
            return this.getRecord(uuid) != null;
        }

        // **** PRIVATE **** //
        private String getUuid(SObject record) {
            return (String) record?.get(EVENT_UUID_FIELD);
        }
    }

    private class LeadConvertResult extends Result {
        private Id accountId { get; private set; }
        private Id contactId { get; private set; }
        private Id leadId { get; private set; }
        private Id opportunityId { get; private set; } 
        private Id personAccountId { get; private set; }

        private LeadConvertResult(Lead lead) {
            this(lead);
        }

        public override void setId(SObject record) {
            this.setId(record?.Id);
        }

        public void setId(Id recordId) {
            SObjectType objectType = recordId?.getSObjectType();
            if (objectType == Account.SObjectType) {
                this.accountId = recordId;
            } else if (objectType == Contact.SObjectType) {
                this.contactId = recordId;
            } else if (objectType == Lead.SObjectType) {
                this.leadId = recordId;
            } else if (objectType == Opportunity.SObjectType) {
                this.opportunityId = recordId;
            }
        }

        private void setPersonAccountId(Id accountId) {
            this.personAccountId = accountId;
        }

        private Database.LeadConvertResult toConvertResult() {
            return (Database.LeadConvertResult) this.toDatabaseResult(Database.LeadConvertResult.class);
        }
    }

    private virtual class Result {
        protected List<MockDml.Error> errors;
        protected Id id;
        protected Boolean success;
    
        protected Result(SObject record) {
            // Creates a record that simulates a successful DML operation
            this.errors = new List<MockDml.Error>();
            this.setId(record);
            this.setIsSuccess(true);
        }
    
        protected Result addError(MockDml.Error error) {
            this.errors?.add(error);
            this.setIsSuccess(false);
            return this; 
        }
    
        protected Database.SaveResult toSaveResult() {
            return (Database.SaveResult) this.toDatabaseResult(Database.SaveResult.class);
        }
    
        protected Database.UpsertResult toUpsertResult() {
            return (Database.UpsertResult) this.toDatabaseResult(Database.UpsertResult.class);
        }
    
        protected Database.DeleteResult toDeleteResult() {
            return (Database.DeleteResult) this.toDatabaseResult(Database.DeleteResult.class);
        }
    
        protected Database.UndeleteResult toUndeleteResult() {
            // Note: For some reason, we can't directly deserialize into a Database.UndeleteResult like the other methods.
            // Attempting to do so will result in the "success" parameter always being set to false.
            // Don't ask me why -- but deserializing untyped first solves the issue.
            Object untyped = JSON.deserializeUntyped(JSON.serialize(this));
            return (Database.UndeleteResult) JSON.deserialize(JSON.serialize(untyped), Database.UndeleteResult.class);
        }

        protected virtual void setId(SObject record) {
            // Set the Id of the Dml result with the record's Id
            // ! Note: Only in some select instances (ex., platform events), this Id will be null
            this.id = record?.Id ?? SObjectUtils.mockPlatformEventId(record?.getSObjectType());
        }

        protected void setIsSuccess(Boolean value) {
            this.success = value;
        }

        protected Object toDatabaseResult(Type resultType) {
            // Returns a Database.Save/Upsert/Delete/UndeleteResult object -- unfortunately, these do not share a common interface
            return JSON.deserialize(JSON.serialize(this), resultType);
        }
    }
}