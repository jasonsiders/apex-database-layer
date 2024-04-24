public virtual class MockDml extends Dml {
    // **** STATIC **** //
    public static MockDml.History Converted = new MockDml.History(Dml.Operation.DO_CONVERT);
    public static MockDml.History Deleted = new MockDml.History(Dml.Operation.DO_DELETE);
    public static MockDml.History Inserted = new MockDml.History(Dml.Operation.DO_INSERT);
    public static MockDml.History Published = new MockDml.History(Dml.Operation.DO_PUBLISH);
    public static MockDml.History Undeleted = new MockDml.History(Dml.Operation.DO_UNDELETE);
    public static MockDml.History Updated = new MockDml.History(Dml.Operation.DO_UPDATE);
    public static MockDml.History Upserted = new MockDml.History(Dml.Operation.DO_UPSERT);

    // **** MEMBER **** // 
    Exception errorToThrow; 

    @TestVisible
    protected MockDml() {
        super();
    }

    public virtual MockDml injectException(Exception error) {
        this.errorToThrow = error; 
        return this; 
    }
    
    public virtual MockDml injectException() {
        return this.injectException(new System.DmlException());
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
        // TODO!
        return new List<Database.DeleteResult>(); 
    }

    public virtual override List<Database.DeleteResult> doDeleteImmediate(List<SObject> records) {
        // TODO!
        return new List<Database.DeleteResult>(); 
    }

    public virtual override List<Database.SaveResult> doInsert(List<SObject> records) {
        // TODO!
        return new List<Database.SaveResult>(); 
    }

    public virtual override List<Database.SaveResult> doInsertAsync(List<SObject> records) {
        // TODO!
        return new List<Database.SaveResult>(); 
    }

    public virtual override List<Database.SaveResult> doInsertImmediate(List<SObject> records) {
        // TODO!
        return new List<Database.SaveResult>(); 
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
        // TODO!
        return new List<Database.SaveResult>(); 
    }

    public virtual override List<Database.SaveResult> doUpdateImmediate(List<SObject> records) {
        // TODO!
        return new List<Database.SaveResult>(); 
    }

    public virtual override List<Database.UpsertResult> doUpsert(List<SObject> records) {
        // TODO!
        return new List<Database.UpsertResult>(); 
    }

    // **** INNER **** // 
    @TestVisible
    private class History {
        Dml.Operation operation; 
        Map<Id, SObject> records;
        Map<SObjectType, Set<Id>> recordIdsBySObjectType;

        private History(Dml.Operation operation) {
            this.operation = operation;
            this.records = new Map<Id, SObject>();
            this.recordIdsBySObjectType = new Map<SObjectType, Set<Id>>();
        }

        public History add(List<SObject> records) {
            // Add the record to the id map
            this.records?.putAll(new Map<Id, SObject>(records));
            // Add the record to the sobjecttype map
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

        public List<SObject> getAll() {
            return this.records?.values();
        }

        public List<SObject> getRecords(SObjectType objectType) {
            List<SObject> results = new List<SObject>();
            Set<Id> recordIds = this.recordIdsBySObjectType?.get(objectType) ?? new Set<Id>();
            for (Id recordId : recordIds) {
                SObject record = this.records?.get(recordId);
                results?.add(record);
            }
            return results;
        }

        public SObject getRecord(Id recordId) {
            return this.records?.get(recordId);
        }
        
        public SObject getRecord(SObject record) {
            return this.getRecord(record?.Id);
        }

        public History reset() {
            this.records?.clear();
            this.recordIdsBySObjectType?.clear();
            return this; 
        }

        public Boolean wasProcessed(Id recordId) {
            return this.records?.containsKey(recordId) == true; 
        }

        public Boolean wasProcessed(SObject record) {
            return this.wasProcessed(record?.Id);
        }
    }
}