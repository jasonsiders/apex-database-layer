public virtual class MockDml extends Dml {
    // Note: @IsTest classes cannot be virtual/abstract

    // **** STATIC **** //
    @TestVisible 
    static MockDml.History Converted = new MockDml.History();
    @TestVisible 
    static MockDml.History Deleted = new MockDml.History();
    @TestVisible 
    static MockDml.History Inserted = new MockDml.History();
    @TestVisible 
    static MockDml.History Published = new MockDml.History();
    @TestVisible 
    static MockDml.History Undeleted = new MockDml.History();
    @TestVisible 
    static MockDml.History Updated = new MockDml.History();
    @TestVisible 
    static MockDml.History Upserted = new MockDml.History();

    // **** STATIC **** // 
    @TestVisible
    static List<Database.LeadConvertResult> toConvertResults(List<MockDml.Result> mockResults) {
        return (List<Database.LeadConvertResult>) JSON.deserialize(JSON.serialize(mockResults), List<Database.LeadConvertResult>.class);
    }

    @TestVisible
    static List<Database.DeleteResult> toDeleteResults(List<MockDml.Result> mockResults) {
        return (List<Database.DeleteResult>) JSON.deserialize(JSON.serialize(mockResults), List<Database.DeleteResult>.class);
    }

    @TestVisible
    static List<MockDml.Result> toMockResults(List<Object> databaseResults) {
        return (List<MockDml.Result>) JSON.deserialize(JSON.serialize(databaseResults), List<MockDml.Result>.class);
    }

    @TestVisible
    static List<Database.SaveResult> toSaveResults(List<MockDml.Result> mockResults) {
        return (List<Database.SaveResult>) JSON.deserialize(JSON.serialize(mockResults), List<Database.SaveResult>.class);
    }

    @TestVisible
    static List<Database.UpsertResult> toUpsertResults(List<MockDml.Result> mockResults) {
        return (List<Database.UpsertResult>) JSON.deserialize(JSON.serialize(mockResults), List<Database.UpsertResult>.class);
    }

    @TestVisible
    static List<Database.UndeleteResult> toUndeleteResults(List<MockDml.Result> mockResults) {
        return (List<Database.UndeleteResult>) JSON.deserialize(JSON.serialize(mockResults), List<Database.UndeleteResult>.class);
    }

    // **** MEMBER **** // 
    Exception errorToThrow; 

    @TestVisible
    protected MockDml() {
        super();
    }

    public MockDml injectException(Exception error) {
        this.errorToThrow = error; 
        return this; 
    }
    
    public MockDml injectException() {
        return this.injectException(new System.DmlException());
    }

    public MockDml resetHistory() {
        // Reset all of the history objects to their original state
        // Useful for isolating the actual changes being tested, ie., after test setup
        MockDml.Converted?.resetHistory();
        MockDml.Deleted?.resetHistory();
        MockDml.Inserted?.resetHistory();
        MockDml.Published?.resetHistory();
        MockDml.Undeleted?.resetHistory();
        MockDml.Updated?.resetHistory();
        MockDml.Upserted?.resetHistory();
        return this;
    }

    // **** OVERRIDES **** //
    public virtual override List<Database.LeadConvertResult> doConvert(List<Database.LeadConvert> leadsToConvert) {
        // TODO!
        return new List<Database.LeadConvertResult>(); 
    }

    public virtual override List<Database.DeleteResult> doDelete(List<Id> recordIds) {
        // TODO!
        return new List<Database.DeleteResult>(); 
    }

    public virtual override List<Database.DeleteResult> doDeleteAsync(List<SObject> records) {
        // For mocking purposes, process the same as a normal delete operation, but w/callbacks
        List<Database.DeleteResult> results = this.doDelete(records);
        for (Database.DeleteResult result : results) {
            this.getDeleteCallback()?.processDelete(result);
        }
        return results;
    }

    public virtual override List<Database.DeleteResult> doDeleteImmediate(List<SObject> records) {
        // For mocking purposes, process the same as a normal delete operation
        return this.doDelete(records);
    }

    public virtual override List<Database.DeleteResult> doHardDelete(List<Id> recordIds) {
        // For mocking purposes, process the same as a normal delete operation
        return this.doDelete(recordIds);
    }

    public virtual override List<Database.SaveResult> doInsert(List<SObject> records) {
        // TODO!
        return new List<Database.SaveResult>(); 
    }

    public virtual override List<Database.SaveResult> doInsertAsync(List<SObject> records) {
        // For mocking purposes, process the same as a normal insert operation, but w/callbacks
        List<Database.SaveResult> results = this.doInsert(records);
        for (Database.SaveResult result : results) {
            this.getSaveCallback()?.processSave(result);
        }
        return results; 
    }

    public virtual override List<Database.SaveResult> doInsertImmediate(List<SObject> records) {
        // For mocking purposes, process the same as a normal insert operation
        return this.doInsert(records);
    }

    public virtual override List<Database.SaveResult> doPublish(List<SObject> events) {
        // TODO!
        return new List<Database.SaveResult>(); 
    }
    
    public virtual override List<Database.UndeleteResult> doUndelete(List<Id> recordIds) {
        // TODO!
        return new List<Database.UndeleteResult>(); 
    }

    public virtual override List<Database.SaveResult> doUpdate(List<SObject> records) {
        // TODO!
        return new List<Database.SaveResult>(); 
    }
    
    public virtual override List<Database.SaveResult> doUpdateAsync(List<SObject> records) {
        // For mocking purposes, process the same as a normal update operation, but w/callbacks
        List<Database.SaveResult> results = this.doUpdate(records);
        for (Database.SaveResult result : results) {
            this.getSaveCallback()?.processSave(result);
        }
        return results; 
    }

    public virtual override List<Database.SaveResult> doUpdateImmediate(List<SObject> records) {
        // For mocking purposes, process the same as a normal update operation
        return this.doUpdate(records);
    }

    public virtual override List<Database.UpsertResult> doUpsert(List<SObject> records) {
        // TODO!
        return new List<Database.UpsertResult>(); 
    }

    // **** INNER **** // 
    @TestVisible
    private class History {
        Map<Id, SObject> recordsById;
        Map<SObjectType, Set<Id>> recordIdsBySObjectType;

        private History() {
            this.recordsById = new Map<Id, SObject>();
            this.recordIdsBySObjectType = new Map<SObjectType, Set<Id>>();
        }

        public List<SObject> getAll() {
            return this.recordsById?.values();
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

        public History resetHistory() {
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

        private History registerDml(List<SObject> records) {
            // * This method registers that the records were operated on, 
            // and store them in a way that's easy for callers to get & perform asserts
            // * Add the record to the id map
            this.recordsById?.putAll(new Map<Id, SObject>(records));
            // * Add the record to the sobjecttype map
            if (records?.getSObjectType() != null) {
                // No need to manually iterate through all the records!
                SObjectType objectType = records?.getSObjectType();
                Set<Id> matchingIds = this.recordIdsBySObjectType?.get(objectType) ?? new Set<Id>();
                Set<Id> newRecordIds = new Map<Id, SObject>(records)?.keySet();
                matchingIds?.addAll(newRecordIds);
                this.recordIdsBySObjectType?.put(objectType, matchingIds);
            } else {
                // Manually iterate through each record and check its SObjectType
                for (SObject record : records) {
                    SObjectType objectType = record?.getSObjectType();
                    Set<Id> matchingIds = this.recordIdsBySObjectType?.get(objectType) ?? new Set<Id>();
                    matchingIds?.add(record?.Id);
                    this.recordIdsBySObjectType?.put(objectType, matchingIds);
                }
            }
            return this; 
        }
    }

    @TestVisible
    private abstract class AbstractResult {
        public List<MockDml.Error> errors { get; set; }
        public Boolean success { get; set; }

        public AbstractResult addErrors(List<MockDml.Error> errors) {
            this.errors?.addAll(errors);
            this.success = false;
            return this; 
        }
    
        public AbstractResult addErrors(MockDml.Error error) {
            return this.addErrors(new List<MockDml.Error>{ error });
        }
    
        public AbstractResult addErrors() {
            return this.addErrors(new MockDml.Error());
        }

        protected Object toDatabaseResult(Type resultType) {
            // Returns a Database.Save/Upsert/Delete/UndeleteResult object
            // Unfortunately, these do not share a common interface
            return JSON.deserialize(JSON.serialize(this), resultType);
        }
    }

    @TestVisible 
    private class ConvertResult extends AbstractResult {
        public Id accountId { get; set; }
        public Id contactId { get; set; }
        public Id leadId { get; set; }
        public Id opportunityId { get; set; } 
        public Id personAccountId { get; set; }

        public ConvertResult(Id recordId) {
            // Creates a record that simulates a successful LeadConvert operation
            this.errors = new List<MockDml.Error>();
            this.leadId = leadId;
            this.success = true;
        }
    
        public ConvertResult(Lead lead) {
            this(lead?.Id);
        }
    
        public ConvertResult(Id leadId, List<MockDml.Error> errors) {
            this(leadId);
            this.addErrors(errors);
        }
    
        public ConvertResult(Id leadId, MockDml.Error error) {
            this(leadId, new List<MockDml.Error>{ error });
        }
    
        public ConvertResult(Lead lead, List<MockDml.Error> errors) {
            this(lead?.Id, errors);
        }
    
        public ConvertResult(Lead lead, MockDml.Error error) {
            this(lead, new List<MockDml.Error>{error});
        }

        public Database.LeadConvertResult toConvertResult() {
            return (Database.LeadConvertResult) this.toDatabaseResult(Database.LeadConvertResult.class);
        }
    }

    @TestVisible
    private class Result extends AbstractResult {
        public Id id { get; set; }
    
        public Result(Id recordId) {
            // Creates a record that simulates a successful DML operation
            this.errors = new List<MockDml.Error>();
            this.id = recordId;
            this.success = true;
        }
    
        public Result(SObject record) {
            this(record?.Id);
        }
    
        public Result(Id recordId, List<MockDml.Error> errors) {
            this(recordId);
            this.addErrors(errors);
        }
    
        public Result(Id recordId, MockDml.Error error) {
            this(recordId, new List<MockDml.Error>{ error });
        }
    
        public Result(SObject record, List<MockDml.Error> errors) {
            this(record?.Id, errors);
        }
    
        public Result(SObject record, MockDml.Error error) {
            this(record, new List<MockDml.Error>{error});
        }
    
        public Database.SaveResult toSaveResult() {
            return (Database.SaveResult) this.toDatabaseResult(Database.SaveResult.class);
        }
    
        public Database.UpsertResult toUpsertResult() {
            return (Database.UpsertResult) this.toDatabaseResult(Database.UpsertResult.class);
        }
    
        public Database.DeleteResult toDeleteResult() {
            return (Database.DeleteResult) this.toDatabaseResult(Database.DeleteResult.class);
        }
    
        public Database.UndeleteResult toUndeleteResult() {
            return (Database.UndeleteResult) this.toDatabaseResult(Database.UndeleteResult.class);
        }
    }

    @TestVisible
    private class Error {
        // Wraps the Database.Error class, to be used for mocking in @IsTest context
        public String message;
        public String statusCode; 

        public Error(String message, String statusCode) {
            this.message = message;
            this.statusCode = statusCode; 
        }

        public Error() {
            // Initialize an error with a default message & status code
            this('Test Error', 'TEST_ERROR');
        }

        public Database.Error toDatabaseError() {
            return (Database.Error) JSON.deserialize(JSON.serialize(this), Database.Error.class);
        }
    }
}