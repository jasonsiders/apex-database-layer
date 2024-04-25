public virtual class MockDml extends Dml {
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

    public virtual MockDml resetHistory() {
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
}