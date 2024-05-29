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
    private List<MockDml.ConditionalFailure> failures = new List<MockDml.ConditionalFailure>();

    public MockDml() {
        super();
    }
     
    public MockDml clearFailures() {
        this.failures?.clear();
        return this; 
    }

    public MockDml failIf(MockDml.ConditionalFailure failure) {
        this.failures?.add(failure);
        return this; 
    }

    public MockDml fail() {
        MockDml.ConditionalFailure failure = new MockDml.BaseFailure();
        return this.failIf(failure);
    }

    // **** OVERRIDES **** //
    public override List<Database.LeadConvertResult> doConvert(List<Database.LeadConvert> leadsToConvert) {
        List<MockDml.Result> results = new List<MockDml.Result>();
        for (Database.LeadConvert leadToConvert : leadsToConvert) {
            MockDml.Result result = this.generateMockResult(leadToConvert);
            results?.add(result);
        }
        return this.toConvertResults(results);
    }

    public override List<Database.DeleteResult> doDelete(List<Id> recordIds) {
        List<MockDml.Result> results = new List<MockDml.Result>();
        for (Id recordId : recordIds) {
            SObject record = recordId?.getSObjectType()?.newSObject(recordId);
            MockDml.Result result = this.generateMockResult(MockDml.Deleted, record);
            results?.add(result);
        }
        return this.toDeleteResults(results);
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
        List<MockDml.Result> results = new List<MockDml.Result>();
        for (SObject record : records) {
            MockDml.Result result = this.generateMockResult(MockDml.Inserted, record);
            results?.add(result);
        }
        return this.toSaveResults(results);
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
        List<MockDml.Result> results = new List<MockDml.Result>();
        for (SObject event : events) {
            MockDml.Result result = this.generateMockResult(MockDml.Published, event);
            results?.add(result);
        }
        return this.toSaveResults(results);
    }
    
    public override List<Database.UndeleteResult> doUndelete(List<Id> recordIds) {
        List<MockDml.Result> results = new List<MockDml.Result>();
        for (Id recordId : recordIds) {
            SObject record = recordId?.getSObjectType()?.newSObject(recordId);
            MockDml.Result result = this.generateMockResult(MockDml.Undeleted, record);
            results?.add(result);
        }
        return this.toUndeleteResults(results);
    }

    public override List<Database.SaveResult> doUpdate(List<SObject> records) {
        List<MockDml.Result> results = new List<MockDml.Result>();
        for (SObject record : records) {
            MockDml.Result result = this.generateMockResult(MockDml.Updated, record);
            results?.add(result);
        }
        return this.toSaveResults(results);
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
        List<MockDml.Result> results = new List<MockDml.Result>();
        for (SObject record : records) {
            MockDml.Result result = this.generateMockResult(MockDml.Upserted, record);
            results?.add(result);
        }
        return this.toUpsertResults(results);
    }

    // **** PRIVATE **** //
    private void checkFailures(Dml.Operation operation, SObject record) {
        // Runs the ConditionalFailure defined the current instance against each record.
        for (MockDml.ConditionalFailure failure : this.failures) {
            Exception error = failure?.checkFailure(operation, record);
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
            return this.handleDmlError(history, record, error);
        }
    }

    private MockDml.LeadConvertResult generateMockResult(Database.LeadConvert leadToConvert) {
        // Simulate a Lead Conversion, which typically also involves inserting Account/Contact/Opportunity records
        Lead leadRecord = new Lead(Id = leadToConvert?.getLeadId());
        Account accountRecord = new Account(Id = leadToConvert?.getAccountId());
        Contact contactRecord = new Contact(Id = leadToConvert?.getContactId());
        Opportunity opportunityRecord = new Opportunity(Id = leadToConvert?.getOpportunityId());
        // Note: Temporarily set the allOrNone behavior to true, regardless of its original value
        // This allows injected errors for Accounts/Contacts/Opps to be captured and handled appropriately
        final Boolean originalAllOrNone = this.getAllOrNone();
        this.setAllOrNone(true);
        try {
            // Simulate converting the lead
            this.validateConvertedLead(leadToConvert);
            this.generateMockResult(MockDml.Converted, leadRecord);
            // Simulate creating an Account/Contact/Opportunity, if their Id wasn't already provided
            this.simulateInsertIfNew(accountRecord);
            this.simulateInsertIfNew(contactRecord);
            this.simulateInsertIfNew(opportunityRecord);
            // Success! Safe to revert to original allOrNone behavior
            this.setAllOrNone(originalAllOrNone);
            // Build & return the LeadConvertResult
            return (MockDml.LeadConvertResult) new MockDml.LeadConvertResult(leadRecord)
                ?.setId(accountRecord)
                ?.setId(contactRecord)
                ?.setId(opportunityRecord);
        } catch (System.DmlException error) {
            // Unregister any of successful related records up to this point
            MockDml.Inserted?.unregisterDml(accountRecord);
            MockDml.Inserted?.unregisterDml(contactRecord);
            MockDml.Inserted?.unregisterDml(opportunityRecord);
            MockDml.Converted?.unregisterDml(leadRecord);
            // Respect the originally defined allOrNone behavior when handling the error 
            this.setAllOrNone(originalAllOrNone);
            return (MockDml.LeadConvertResult) this.handleDmlError(MockDml.Converted, leadRecord, error);
        }
    }

    private MockDml.Result handleDmlError(MockDml.History history, SObject record, Exception error) {
        // Handles an error during DML, according to the defined allOrNone logic, mirroring standard functionality
        MockDml.Error dmlError = new MockDml.Error(error);
        if (this.getAllOrNone() == true) {
            throw dmlError?.toDmlException();
        } else if (history?.operation == Dml.Operation.DO_CONVERT) {
            Lead lead = (Lead) record;
            return new MockDml.LeadConvertResult(lead)?.addError(dmlError);
        } else if (history?.operation == Dml.Operation.DO_INSERT) {
            // Note: When a record fails to be inserted, the resulting Database.SaveResult should have a null Id value
            return new MockDml.RecordResult(record)?.clearId()?.addError(dmlError);
        } else {
            return new MockDml.RecordResult(record)?.addError(dmlError);
        }
    }

    private void simulateInsertIfNew(SObject record) {
        // If the provided record does not already have an Id, simulate an insert operation
        if (record?.Id == null) {
            SObjectType objectType = record?.getSObjectType();
            record.Id = SObjectUtils.mockRecordId(objectType);
            this.generateMockResult(MockDml.Inserted, record);
        }
    }

    private List<Database.LeadConvertResult> toConvertResults(List<MockDml.Result> results) {
        return (List<Database.LeadConvertResult>) this.toDatabaseResults(results, List<Database.LeadConvertResult>.class);
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
        // Don't ask me why -- but deserializing untyped first solves the issue.
        Object untyped = JSON.deserializeUntyped(JSON.serialize(results));
        return (List<Database.UndeleteResult>) JSON.deserialize(JSON.serialize(untyped), List<Database.UndeleteResult>.class);
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

    // **** INNER - PUBLIC **** // 
    public interface ConditionalFailure {
        // Interface logic determines if a DML failure should be simulated for the given record.
        // If so, the method returns a an error to be thrown by the MockDml class during DML.
        Exception checkFailure(Dml.Operation operation, SObject record);
    }

    public abstract class History {
        protected Dml.Operation operation;
        protected Map<SObjectType, Map<String, SObject>> recordMap;

        protected History(Dml.Operation operation) {
            this.operation = operation; 
            this.recordMap = new Map<SObjectType, Map<String, SObject>>();
        }

        // **** ABSTRACT **** //
        protected abstract void addRecordToMap(SObject record, Map<String, Object> records);
        protected abstract SObject setRecordId(SObject record);
        
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
            return new MockDml.RecordResult(record);
        }

        public void unregisterDml(SObject record) {
            // Removes the specified record from the History
            SObjectType objectType = record?.getSObjectType();
            Map<String, Object> recordMap = this.getRecordMap(objectType);
            recordMap?.remove(record?.Id);
        }

        protected Map<String, SObject> getRecordMap(SObjectType objectType) {
            return this.recordMap?.get(objectType) ?? new Map<String, SObject>(); 
        }
    }

    public class PlatformEventHistory extends History {
        private Map<String, SObjectType> objectTypesByUuid;

        private PlatformEventHistory() {
            super(Dml.Operation.DO_PUBLISH);
            this.objectTypesByUuid = new Map<String, SObjectType>();
        }

        public override void addRecordToMap(SObject record, Map<String, Object> records) {
            String uuid = this.getUuid(record);
            records?.put(uuid, record);
            this.objectTypesByUuid?.put(uuid, record?.getSObjectType());
        }

        public override SObject setRecordId(SObject record) {
            // Note: Platform Events technically have an Id field, but it's not writeable, nor is it transformed after publish. 
            // Instead, the platform populates the "EventUuid" field with a unique identifier 
            // It's better to refer to platform events by their EventUuid value, which is unique.
            return SObjectUtils.setReadOnlyFields(record, EVENT_UUID_FIELD, Uuid.randomUuid());
        }

        private String getUuid(SObject record) {
            return (String) record?.get(EVENT_UUID_FIELD);
        }
    }
    
    public class RecordHistory extends History {
        private RecordHistory(Dml.Operation operation) {
            super(operation);
        }

        public override void addRecordToMap(SObject record, Map<String, Object> records) {
            records?.put(record?.Id, record);
        }

        public SObject getRecord(Id recordId) {
            SObjectType objectType = recordId?.getSObjectType();
            return this.getRecordMap(objectType)?.get(recordId);
        }

        public SObject getRecord(SObject record) {
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

        public Boolean wasProcessed(Id recordId) {
            return this.getRecord(recordId) != null;
        }

        public Boolean wasProcessed(SObject record) {
            return this.wasProcessed(record?.Id);
        }
    }

    // **** INNER - PRIVATE **** // 
    private class BaseFailure implements ConditionalFailure {
        // Base implementation always returns an error
        public Exception checkFailure(Dml.Operation operation, SObject record) {
            return new System.DmlException();
        }
    }

    private class Error {
        // Wraps the Database.Error class, to be used for mocking in @IsTest context
        private String message { get; set; }
        private String statusCode { get; set; }

        private Error(String message, String statusCode) {
            this.message = message;
            this.statusCode = statusCode;
        }

        private Error(Exception error) {
            this(error?.getMessage(), 'MOCK_DML');
        }

        private System.DmlException toDmlException() {
            // De-converts the Error to a DmlException to be thrown in DML Operations
            System.DmlException error = new System.DmlException();
            error?.setMessage('DML failed. First exception on row X; first error: ' + this.statusCode + ', ' + this.message + ': []');
            return error; 
        }
    }

    private class LeadConvertResult extends Result {
        private Id accountid { get; private set; }
        private Id contactid { get; private set; }
        private Id leadid { get; private set; }
        private Id opportunityid { get; private set; } 

        private LeadConvertResult(Lead lead) {
            super(lead);
        }

        public override Result setId(SObject record) {
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

    private class RecordResult extends Result {
        private Id id;

        private RecordResult(SObject record) {
            super(record);
        }

        private Result clearId() {
            this.id = null;
            return this; 
        }

        public override Result setId(SObject record) {
            if (record?.Id != null) {
                // Set the Id of the Dml result with the record's Id
                this.id = record?.Id;
            } else if (this.success == true) { 
                // Likely a Platform Event -- this should have a static/not unique Id
                this.id = SObjectUtils.mockPlatformEventId(record?.getSObjectType());
            }
            return this; 
        }
    }
    
    private abstract class Result {
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