public virtual class MockDml extends Dml {
    // Note: Normally this would be marked as @IsTest, but these classes cannot be virtual/abstract.
    // To prevent accidental production use, its constructor and any statics are private/@TestVisible

    // **** STATIC **** //
    @TestVisible 
    static MockDml.History Converted = new MockDml.History(Dml.Operation.DO_CONVERT);
    @TestVisible 
    static MockDml.History Deleted = new MockDml.History(Dml.Operation.DO_DELETE);
    @TestVisible 
    static MockDml.History Inserted = new MockDml.History(Dml.Operation.DO_INSERT);
    @TestVisible 
    static MockDml.History Published = new MockDml.History(Dml.Operation.DO_PUBLISH);
    @TestVisible 
    static MockDml.History Undeleted = new MockDml.History(Dml.Operation.DO_UNDELETE);
    @TestVisible 
    static MockDml.History Updated = new MockDml.History(Dml.Operation.DO_UPDATE);
    @TestVisible 
    static MockDml.History Upserted = new MockDml.History(Dml.Operation.DO_UPSERT);

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
    protected Exception errorToThrow; 
    protected Set<Id> failedRecordIds = new Set<Id>();

    @TestVisible
    protected MockDml() {
        super();
    }

    // **** OVERRIDES **** //
    public virtual override List<Database.LeadConvertResult> doConvert(List<Database.LeadConvert> leadsToConvert) {
        List<Database.LeadConvertResult> results = new List<Database.LeadConvertResult>();
        /* TODO!
        for (Id recordId : recordIds) {
            SObject record = recordId?.getSObjectType()?.newSObject(recordId);
            Database.DeleteResult result = this.generateMockResult(MockDml.Deleted, record)?.toDeleteResult();
            results?.add(result);
        } */
        return results;
    }

    public virtual override List<Database.DeleteResult> doDelete(List<Id> recordIds) {
        List<Database.DeleteResult> results = new List<Database.DeleteResult>();
        for (Id recordId : recordIds) {
            SObject record = recordId?.getSObjectType()?.newSObject(recordId);
            Database.DeleteResult result = this.generateMockResult(MockDml.Deleted, record)?.toDeleteResult();
            results?.add(result);
        }
        return results;
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
        List<Database.SaveResult> results = new List<Database.SaveResult>();
        for (SObject record : records) {
            Database.SaveResult result = this.generateMockResult(MockDml.Inserted, record)?.toSaveResult();
            results?.add(result);
        }
        return results;
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
        List<Database.SaveResult> results = new List<Database.SaveResult>();
        for (SObject event : events) {
            Database.SaveResult result = this.generateMockResult(MockDml.Published, event)?.toSaveResult();
            results?.add(result);
        }
        return results;
    }
    
    public virtual override List<Database.UndeleteResult> doUndelete(List<Id> recordIds) {
        List<Database.UndeleteResult> results = new List<Database.UndeleteResult>();
        for (Id recordId : recordIds) {
            SObject record = recordId?.getSObjectType()?.newSObject(recordId);
            Database.UndeleteResult result = this.generateMockResult(MockDml.Undeleted, record)?.toUndeleteResult();
            results?.add(result);
        }
        return results;
    }

    public virtual override List<Database.SaveResult> doUpdate(List<SObject> records) {
        List<Database.SaveResult> results = new List<Database.SaveResult>();
        for (SObject record : records) {
            Database.SaveResult result = this.generateMockResult(MockDml.Updated, record)?.toSaveResult();
            results?.add(result);
        }
        return results;
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
        List<Database.UpsertResult> results = new List<Database.UpsertResult>();
        for (SObject record : records) {
            Database.UpsertResult result = this.generateMockResult(MockDml.Upserted, record)?.toUpsertResult();
            results?.add(result);
        }
        return results;
    }

    public virtual override Dml reset() {
        super.reset();
        this.errorToThrow = null;
        this.failedRecordIds?.clear();
        return this;
    }

    // **** PUBLIC **** // 
    public MockDml injectException(Exception error) {
        this.errorToThrow = error; 
        return this; 
    }
    
    public MockDml injectException() {
        return this.injectException(new System.DmlException());
    }

    public MockDml injectFailedRecords(Set<Id> recordIds) {
        this.failedRecordIds?.addAll(recordIds);
        return this;
    }

    public MockDml injectFailedRecords(Id recordId) {
        return this.injectFailedRecords(new Set<Id>{ recordId });
    }

    public MockDml injectFailedRecords(List<SObject> records) {
        Set<Id> recordIds = new Map<Id, SObject>(records)?.keySet();
        return this.injectFailedRecords(recordIds);
    }

    public MockDml injectFailedRecords(SObject record) {
        return this.injectFailedRecords(record?.Id);
    }

    public MockDml eraseHistory() {
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
        return this;
    }

    protected MockDml.Result generateMockResult(MockDml.History history, SObject record) {
        Dml.Operation operation = history?.getOperation();
        if (this.shouldSucceed(operation, record)) {
            // Simulate successful dml
            this.setRecordId(record);
            history?.registerDml(record);
            return new MockDml.Result(record);
        } else {
            // Simulate an "allOrNone=false" silent failure
            return new MockDml.Result(record)?.addErrors();
        }
    }

    protected void setRecordId(SObject record) {
        // If the record does not have an Id value, generate a mock one
        if (record?.Id == null) {
            SObjectType objectType = record?.getSObjectType();
            record.Id = SObjectUtils.generateMockId(objectType);
        }
    }

    protected virtual Boolean shouldSucceed(Dml.Operation baseOperation, SObject record) {
        // Indicates if the DML result should be marked as isSuccess=true.
        Boolean hasError = (this.errorToThrow != null || this.failedRecordIds?.contains(record?.Id) == true);
        if (this.getAllOrNone() == true && hasError == true) {
            // w/AllOrNone behavior, an exception should be thrown
            throw this.errorToThrow ?? new System.DmlException();
        } else {
            // Return true, unless an exception was added via injectException(),
            // or if the record was marked as failed via injectFailedRecords().
            return (hasError == false);
        }
    }

    // **** INNER **** // 
    @TestVisible
    private class ConvertResult extends Result {
        public Id accountId { get; private set; }
        public Id contactId { get; private set; }
        public Id leadId { get; private set; }
        public Id opportunityId { get; private set; } 
        public Id personAccountId { get; private set; }

        public ConvertResult(Id recordId) {
            super(recordId);
        }

        public ConvertResult(Lead lead) {
            this(lead?.Id);
        }

        public override Id getId() {
            return this.leadId;
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

        public void setPersonAccountId(Id accountId) {
            this.personAccountId = accountId;
        }

        public Database.LeadConvertResult toConvertResult() {
            return (Database.LeadConvertResult) this.toDatabaseResult(Database.LeadConvertResult.class);
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
            this('Mock Error', 'MOCK_ERROR');
        }

        public Database.Error toDatabaseError() {
            return (Database.Error) JSON.deserialize(JSON.serialize(this), Database.Error.class);
        }
    }

    @TestVisible
    private class History {
        Dml.Operation operation;
        Map<Id, SObject> recordsById;
        Map<SObjectType, Set<Id>> recordIdsBySObjectType;

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

    @TestVisible
    private virtual class Result {
        public List<MockDml.Error> errors { get; private set; }
        public Id id { get; private set; }
        public Boolean success { get; private set; }
    
        public Result(Id recordId) {
            // Creates a record that simulates a successful DML operation
            this.errors = new List<MockDml.Error>();
            this.setId(recordId);
            this.setIsSuccess(true);
        }
    
        public Result(SObject record) {
            this(record?.Id);
        }

        public Result addErrors(List<MockDml.Error> errors) {
            this.errors?.addAll(errors);
            this.setIsSuccess(false);
            return this; 
        }
    
        public Result addErrors(MockDml.Error error) {
            return this.addErrors(new List<MockDml.Error>{ error });
        }
    
        public Result addErrors() {
            return this.addErrors(new MockDml.Error());
        }

        public List<MockDml.Error> getErrors() {
            return this.errors;
        }

        public virtual Id getId() {
            return this.id; 
        }

        public Boolean isSuccess() {
            return this.success;
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
            // Note: For some reason, we can't directly deserialize into a Database.UndeleteResult like the other methods.
            // Attempting to do so will result in the "success" parameter always being set to false.
            // Don't ask me why -- but deserializing untyped first solves the issue.
            Object params = JSON.deserializeUntyped(JSON.serialize(this));
            return (Database.UndeleteResult) JSON.deserialize(JSON.serialize(params), Database.UndeleteResult.class);
        }

        public virtual void setId(Id recordId) {
            this.id = recordId;
        }

        public void setIsSuccess(Boolean value) {
            this.success = value;
        }

        protected Object toDatabaseResult(Type resultType) {
            // Returns a Database.Save/Upsert/Delete/UndeleteResult object -- unfortunately, these do not share a common interface
            return JSON.deserialize(JSON.serialize(this), resultType);
        }
    }
}