public with sharing virtual class Dml {
    static final System.AccessLevel DEFAULT_ACCESS_LEVEL = System.AccessLevel.USER_MODE;

    protected System.AccessLevel accessLevel;
    protected Database.DmlOptions dmlOptions;
    protected SObjectField externalIdField;

    public Dml() {
        this.toDefaultState();
    }

    // **** VIRTUAL **** //
    public virtual List<Object> doDml(
        Operation operation, 
        List<SObject> records 
    ) {
        if (operation == Dml.Operation.DO_INSERT) {
            return this.doInsert(records);
        } else if (operation == Dml.Operation.DO_UPDATE) {
            return this.doUpdate(records);
        } else if (operation == Dml.Operation.DO_UPSERT) {
            return this.doUpsert(records);
        } else if (operation == Dml.Operation.DO_DELETE) {
            return this.doDelete(records);
        } else if (operation == Dml.Operation.DO_UNDELETE) {
            return this.doUndelete(records);
        } else {
            throw new System.DmlException('Unsupported Dml.Operation: ' + operation);
        }
    }

    public virtual List<Database.SaveResult> doInsert(List<SObject> records) {
        return Database.insert(records, this.getDmlOptions(), this.getAccessLevel());
    }

    public virtual List<Database.SaveResult> doUpdate(List<SObject> records) {
        return Database.update(records, this.getDmlOptions(), this.getAccessLevel());
    }

    public virtual List<Database.UpsertResult> doUpsert(List<SObject> records) {
        // Note: Supplying a null ExternalIdField value to Database.upsert will result in an Exception
        // To avoid this, call the correct overload depending on the supplied field value
        return (this.externalIdField != null) 
            ? Database.upsert(records, this.externalIdField, this.getAllOrNone(), this.getAccessLevel())
            : Database.upsert(records, this.getAllOrNone(), this.getAccessLevel());
    }

    public virtual List<Database.DeleteResult> doDelete(List<Id> recordIds) {
        return Database.delete(recordIds, this.getAllOrNone(), this.getAccessLevel());
    }

    public virtual List<Database.UndeleteResult> doUndelete(List<Id> recordIds) {
        return Database.undelete(recordIds, this.getAllOrNone(), this.getAccessLevel());
    }

    // **** PUBLIC **** //
    public Object doDml(Operation operation, SObject record) {
        List<SObject> records = new List<SObject>{ record };
        return this.doDml(operation, records)[0];
    }

    public Database.SaveResult doInsert(SObject record) {
        return this.doInsert(new List<SObject>{ record })[0];
    }

    public Database.SaveResult doUpdate(SObject record) {
        return this.doUpdate(new List<SObject>{ record })[0];
    }

    public Database.UpsertResult doUpsert(SObject record) {
        return this.doUpsert(new List<SObject>{ record })[0];
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

    public System.AccessLevel getAccessLevel() {
        return this.accessLevel ?? DEFAULT_ACCESS_LEVEL;
    }

    public Boolean getAllOrNone() {
        // Default to `true` to mirror the behavior of Database.Dml methods 
        return this.getDmlOptions()?.OptAllOrNone ?? true;
    }

    public Database.DmlOptions getDmlOptions() {
        return this.dmlOptions ?? new Database.DmlOptions();
    }

    public SObjectField getExternalIdField() {
        return this.externalIdField;
    }

    public Dml setAccessLevel(System.AccessLevel level) {
        this.accessLevel = level;
        return this; 
    }

    public Dml setAllOrNone(Boolean value) {
        this.getDmlOptions().OptAllOrNone = value;
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

    public Dml toDefaultState() {
        this.setAccessLevel(DEFAULT_ACCESS_LEVEL);
        this.setDmlOptions(new Database.DmlOptions());
        this.setExternalIdField(null);
        return this;
    }

    // **** PRIVATE **** //
    private List<Id> getListOfIds(List<SObject> records) {
        return new List<Id>(new Map<Id, SObject>(records)?.keySet());
    }

    // **** INNER **** //
    public enum Operation {
        DO_INSERT,
        DO_UPDATE,
        DO_UPSERT,
        DO_DELETE,
        DO_UNDELETE
    }
}