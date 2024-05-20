@IsTest
public class MockDml extends Dml {
    // **** STATIC **** //
    public static MockDml.History Converted = new MockDml.History(Dml.Operation.DO_CONVERT);
    public static MockDml.History Deleted = new MockDml.History(Dml.Operation.DO_DELETE);
    public static MockDml.History Inserted = new MockDml.History(Dml.Operation.DO_INSERT);
    public static MockDml.History Published = new MockDml.History(Dml.Operation.DO_PUBLISH);
    public static MockDml.History Undeleted = new MockDml.History(Dml.Operation.DO_UNDELETE);
    public static MockDml.History Updated = new MockDml.History(Dml.Operation.DO_UPDATE);
    public static MockDml.History Upserted = new MockDml.History(Dml.Operation.DO_UPSERT);

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
            this.setRecordId(record);
            history?.registerDml(record);
            return new MockDml.Result(record);
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

    private void setRecordId(SObject record) {
        // If the record does not have an Id value, generate a mock one
        if (record?.Id == null) {
            SObjectType objectType = record?.getSObjectType();
            record.Id = SObjectUtils.generateMockId(objectType);
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

    public class History {
        private Dml.Operation operation;
        private Map<Id, SObject> recordsById;
        private Map<SObjectType, Set<Id>> recordIdsBySObjectType;

        private History(Dml.Operation operation) {
            this.operation = operation;
            this.recordsById = new Map<Id, SObject>();
            this.recordIdsBySObjectType = new Map<SObjectType, Set<Id>>();
        }

        public List<SObject> getAll() {
            return this.recordsById?.values();
        }

        public Dml.Operation getOperation() {
            return this.operation;
        }

        public List<SObject> getRecords(SObjectType objectType) {
            List<SObject> results = new List<SObject>();
            Set<Id> recordIds = this.recordIdsBySObjectType?.get(objectType) ?? new Set<Id>();
            for (Id recordId : recordIds) {
                SObject record = this.recordsById?.get(recordId);
                results?.add(record);
            }
            return results;
        }

        public SObject getRecord(Id recordId) {
            return this.recordsById?.get(recordId);
        }
        
        public SObject getRecord(SObject record) {
            return this.getRecord(record?.Id);
        }

        public History eraseHistory() {
            this.recordsById?.clear();
            this.recordIdsBySObjectType?.clear();
            return this; 
        }

        public Boolean wasProcessed(Id recordId) {
            return this.recordsById?.containsKey(recordId) == true; 
        }

        public Boolean wasProcessed(SObject record) {
            return this.wasProcessed(record?.Id);
        }

        public History unregisterDml(Set<Id> recordIds) {
            // Remove record(s) from the dml history maps
            for (Id recordId : recordIds) {
                SObjectType objectType = recordId?.getSObjectType();
                this.recordIdsBySObjectType?.get(objectType)?.remove(recordId);
                this.recordsById?.remove(recordId);
            }
            return this;
        }

        public History unregisterDml(Id recordId) {
            return this.unregisterDml(new Set<Id>{ recordId });
        }

        public History unregisterDml(List<SObject> records) {
            Set<Id> recordIds = new Map<Id, SObject>(records)?.keySet();
            return this.unregisterDml(recordIds);
        }

        public History unregisterDml(SObject record) {
            return this.unregisterDml(record?.Id);
        }

        private History registerDml(SObject record) {
            // This method registers that the records were operated on, 
            // and store them in a way that's easy for callers to get & perform asserts
            SObjectType objectType = record?.getSObjectType();
            Set<Id> matchingIds = this.recordIdsBySObjectType?.get(objectType) ?? new Set<Id>();
            matchingIds?.add(record?.Id);
            this.recordIdsBySObjectType?.put(objectType, matchingIds);
            this.recordsById?.put(record?.Id, record);
            return this;
        }
    }

    private class LeadConvertResult extends Result {
        private Id accountId { get; private set; }
        private Id contactId { get; private set; }
        private Id leadId { get; private set; }
        private Id opportunityId { get; private set; } 
        private Id personAccountId { get; private set; }

        private LeadConvertResult(Id recordId) {
            super(recordId);
        }

        private LeadConvertResult(Lead lead) {
            this(lead?.Id);
        }

        public override void setId(Id recordId) {
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
    
        protected Result(Id recordId) {
            // Creates a record that simulates a successful DML operation
            this.errors = new List<MockDml.Error>();
            this.setId(recordId);
            this.setIsSuccess(true);
        }
        
        protected Result(SObject record) {
            this(record?.Id);
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

        protected virtual void setId(Id recordId) {
            this.id = recordId;
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