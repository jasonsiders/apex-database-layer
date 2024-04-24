public with sharing virtual class Dml {
    static final System.AccessLevel DEFAULT_ACCESS_LEVEL = System.AccessLevel.USER_MODE;

    protected System.AccessLevel accessLevel = System.AccessLevel.USER_MODE;
    protected Object callback; 
    protected Database.DmlOptions dmlOptions;
    protected SObjectField externalIdField;

    public Dml() {
        this.reset();
    }

    // **** VIRTUAL **** //
    public virtual List<Database.LeadConvertResult> doConvert(List<Database.LeadConvert> leadsToConvert) {
        return Database.convertLead(leadsToConvert, this.getDmlOptions(), this.getAccessLevel());
    }

    public virtual List<Database.DeleteResult> doDelete(List<Id> recordIds) {
        return Database.delete(recordIds, this.getAllOrNone(), this.getAccessLevel());
    }

    public virtual List<Database.DeleteResult> doDeleteAsync(List<SObject> records) {
        return Database.deleteAsync(records, this.getDeleteCallback(), this.getAccessLevel());
    }

    public virtual List<Database.DeleteResult> doDeleteImmediate(List<SObject> records) {
        return Database.deleteImmediate(records, this.getAccessLevel());
    }

    public virtual List<Database.SaveResult> doInsert(List<SObject> records) {
        return Database.insert(records, this.getDmlOptions(), this.getAccessLevel());
    }

    public virtual List<Database.SaveResult> doInsertAsync(List<SObject> records) {
        return Database.insertAsync(records, this.getSaveCallback(), this.getAccessLevel());
    }

    public virtual List<Database.SaveResult> doInsertImmediate(List<SObject> records) {
        return Database.insertImmediate(records, this.getAccessLevel());
    }

    public virtual List<Database.SaveResult> doPublish(List<SObject> events) {
        return EventBus.publish(events);
    }
    
    public virtual List<Database.UndeleteResult> doUndelete(List<Id> recordIds) {
        return Database.undelete(recordIds, this.getAllOrNone(), this.getAccessLevel());
    }

    public virtual List<Database.SaveResult> doUpdate(List<SObject> records) {
        return Database.update(records, this.getDmlOptions(), this.getAccessLevel());
    }
    
    public virtual List<Database.SaveResult> doUpdateAsync(List<SObject> records) {
        return Database.updateAsync(records, this.getSaveCallback(), this.getAccessLevel());
    }

    public virtual List<Database.SaveResult> doUpdateImmediate(List<SObject> records) {
        return Database.updateImmediate(records, this.getAccessLevel());
    }

    public virtual List<Database.UpsertResult> doUpsert(List<SObject> records) {
        // Note: Supplying a null ExternalIdField value to Database.upsert will result in an Exception
        // To avoid this, call the correct overload depending on the supplied field value
        return (this.externalIdField != null) 
            ? Database.upsert(records, this.externalIdField, this.getAllOrNone(), this.getAccessLevel())
            : Database.upsert(records, this.getAllOrNone(), this.getAccessLevel());
    }

    // **** PUBLIC **** //
    public List<Object> doDml(Operation operation, List<SObject> records) {
        if (operation == Dml.Operation.DO_DELETE) {
            return this.doDelete(records);
        } else if (operation == Dml.Operation.DO_DELETE_ASYNC) {
            return this.doDeleteAsync(records); 
        } else if (operation == Dml.Operation.DO_DELETE_IMMEDIATE) {
            return this.doDeleteImmediate(records); 
        } else if (operation == Dml.Operation.DO_HARD_DELETE) {
            return this.doHardDelete(records); 
        } else if (operation == Dml.Operation.DO_INSERT) {
            return this.doInsert(records); 
        } else if (operation == Dml.Operation.DO_INSERT_ASYNC) {
            return this.doInsertAsync(records);
        } else if (operation == Dml.Operation.DO_INSERT_IMMEDIATE) {
            return this.doInsertImmediate(records); 
        } else if (operation == Dml.Operation.DO_PUBLISH) {
            return this.doPublish(records); 
        } else if (operation == Dml.Operation.DO_UNDELETE) {
            return this.doUndelete(records); 
        } else if (operation == Dml.Operation.DO_UPDATE) {
            return this.doUpdate(records); 
        } else if (operation == Dml.Operation.DO_UPDATE_ASYNC) {
            return this.doUpdateAsync(records); 
        } else if (operation == Dml.Operation.DO_UPDATE_IMMEDIATE) {
            return this.doUpdateImmediate(records); 
        } else if (operation == Dml.Operation.DO_UPSERT) {
            return this.doUpsert(records); 
        } else {
            throw new System.DmlException('Unsupported Dml.Operation: ' + operation);
        } 
    }

    public Object doDml(Operation operation, SObject record) {
        List<SObject> records = new List<SObject>{ record };
        return this.doDml(operation, records)[0];
    }

    public Database.LeadConvertResult doConvert(Database.LeadConvert leadToConvert) {
        return this.doConvert(new List<Database.LeadConvert>{ leadToConvert })[0];
    }

    public Database.DeleteResult doDelete(Id recordId) {
        return this.doDelete(new List<Id>{ recordId })[0];
    }

    public Database.DeleteResult doDelete(SObject record) {
        return this.doDelete(record?.Id);
    }

    public List<Database.DeleteResult> doDelete(List<SObject> records) {
        List<Id> recordIds = this.getListOfIds(records);
        return this.doDelete(recordIds);
    }

    public List<Database.DeleteResult> doDeleteAsync(List<Id> recordIds) {
        List<SObject> records = this.getListOfRecords(recordIds);
        return this.doDeleteAsync(records);
    }

    public Database.DeleteResult doDeleteAsync(Id recordId) {
        return this.doDeleteAsync(new List<Id>{ recordId })[0];
    }

    public Database.DeleteResult doDeleteAsync(SObject record) {
        return this.doDeleteAsync(record?.Id);
    }

    public List<Database.DeleteResult> doDeleteImmediate(List<Id> recordIds) {
        List<SObject> records = this.getListOfRecords(recordIds);
        return this.doDeleteImmediate(records);
    }

    public Database.DeleteResult doDeleteImmediate(Id recordId) {
        return this.doDeleteImmediate(new List<Id>{ recordId })[0];
    }

    public Database.DeleteResult doDeleteImmediate(SObject record) {
        return this.doDeleteImmediate(record?.Id);
    }

    public List<Database.DeleteResult> doHardDelete(List<Id> recordIds) {
        List<Database.DeleteResult> results = this.doDelete(recordIds);
        Database.emptyRecycleBin(recordIds);
        return results;
    }

    public Database.DeleteResult doHardDelete(Id recordId) {
        return this.doHardDelete(new List<Id>{ recordId })[0];
    } 

    public List<Database.DeleteResult> doHardDelete(List<SObject> records) {
        List<Id> recordIds = this.getListOfIds(records); 
        return this.doHardDelete(recordIds);
    }

    public Database.DeleteResult doHardDelete(SObject record) {
        return this.doHardDelete(record?.Id);
    }

    public Database.SaveResult doInsert(SObject record) {
        return this.doInsert(new List<SObject>{ record })[0];
    }

    public Database.SaveResult doInsertAsync(SObject record) {
        return this.doInsertAsync(new List<SObject>{ record })[0];
    }

    public Database.SaveResult doInsertImmediate(SObject record) {
        return this.doInsertImmediate(new List<SObject>{ record })[0];
    }

    public Database.SaveResult doPublish(SObject event) {
        return this.doPublish(new List<SObject>{ event })[0];
    }

    public Database.UndeleteResult doUndelete(Id recordId) {
        return this.doUndelete(new List<Id>{ recordId })[0];
    }

    public Database.UndeleteResult doUndelete(SObject record) {
        return this.doUndelete(record?.Id);
    }

    public List<Database.UndeleteResult> doUndelete(List<SObject> records) {
        List<Id> recordIds = this.getListOfIds(records);
        return this.doUndelete(recordIds);
    }

    public Database.SaveResult doUpdate(SObject record) {
        return this.doUpdate(new List<SObject>{ record })[0];
    }

    public Database.SaveResult doUpdateAsync(SObject record) {
        return this.doUpdateImmediate(new List<SObject>{ record })[0];
    }

    public Database.SaveResult doUpdateImmediate(SObject record) {
        return this.doUpdateImmediate(new List<SObject>{ record })[0];
    }

    public Database.UpsertResult doUpsert(SObject record) {
        return this.doUpsert(new List<SObject>{ record })[0];
    }

    // **** BUILDER **** //
    public System.AccessLevel getAccessLevel() {
        return this.accessLevel ?? DEFAULT_ACCESS_LEVEL;
    }

    public Boolean getAllOrNone() {
        // Default to `true` to mirror the behavior of Database.Dml methods 
        return this.getDmlOptions()?.OptAllOrNone ?? true;
    }

    public DataSource.AsyncDeleteCallback getDeleteCallback() {
        return (this.callback != null && this.callback instanceOf DataSource.AsyncDeleteCallback)
            ? (DataSource.AsyncDeleteCallback) this.callback 
            : new Dml.DefaultDeleteCallback();
    }

    public DataSource.AsyncSaveCallback getSaveCallback() {
        return (this.callback != null && this.callback instanceOf DataSource.AsyncSaveCallback)
            ? (DataSource.AsyncSaveCallback) this.callback 
            : new Dml.DefaultSaveCallback();
    }

    public Database.DmlOptions getDmlOptions() {
        return this.dmlOptions ?? new Database.DmlOptions();
    }

    public SObjectField getExternalIdField() {
        return this.externalIdField;
    }

    public Dml reset() {
        this.setAccessLevel(DEFAULT_ACCESS_LEVEL);
        this.setDmlOptions(new Database.DmlOptions());
        this.setExternalIdField(null);
        return this;
    }

    public Dml setAccessLevel(System.AccessLevel level) {
        this.accessLevel = level;
        return this; 
    }

    public Dml setAllOrNone(Boolean value) {
        this.getDmlOptions().OptAllOrNone = value;
        return this; 
    }

    public Dml setCallback(DataSource.AsyncDeleteCallback deleteCallback) {
        this.callback = deleteCallback; 
        return this; 
    }

    public Dml setCallback(DataSource.AsyncSaveCallback saveCallback) {
        this.callback = saveCallback; 
        return this; 
    }

    public Dml setDmlOptions(Database.DmlOptions dmlOptions) {
        this.dmlOptions = dmlOptions;
        return this; 
    }

    public Dml setExternalIdField(SObjectField field) {
        this.externalIdField = field;
        return this;
    }

    // **** PRIVATE **** //
    private List<Id> getListOfIds(List<SObject> records) {
        return new List<Id>(new Map<Id, SObject>(records)?.keySet());
    }

    private List<SObject> getListOfRecords(List<Id> recordIds) {
        List<SObject> records = new List<SObject>();
        for (Id recordId : recordIds) {
            SObject record = recordId?.getSObjectType()?.newSObject(recordId);
            records?.add(record);
        }
        return records;
    }

    // **** INNER **** //
    private class DefaultDeleteCallback extends DataSource.AsyncDeleteCallback {
        // If a callback isn't defined, doDeleteAsync() will use this class to gracefully handle callbacks
        public override void processDelete(Database.DeleteResult result) {
            // Nothing needed here
        }
    }

    private class DefaultSaveCallback extends DataSource.AsyncSaveCallback {
        // If a callback isn't defined, doInsertAsync() & doUpdateAsync will use this class to gracefully handle callbacks
        public override void processSave(Database.SaveResult result) {
            // Nothing needed here
        }
    }
    
    public enum Operation {
        DO_DELETE,
        DO_DELETE_ASYNC,
		DO_DELETE_IMMEDIATE,
        DO_HARD_DELETE,
		DO_INSERT,
        DO_INSERT_ASYNC,
		DO_INSERT_IMMEDIATE,
        DO_PUBLISH,
        DO_UNDELETE,
		DO_UPDATE,
        DO_UPDATE_ASYNC,
		DO_UPDATE_IMMEDIATE,
		DO_UPSERT
    }
}