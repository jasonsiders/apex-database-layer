global with sharing virtual class Dml {
    // **** CORE/VIRTUAL METHODS **** //
    global virtual List<Object> doDml(
        Operation operation, 
        List<SObject> records, 
        Options options
    ) {
        if (operation == Dml.Operation.DO_INSERT) {
            return this.doInsert(records, options);
        } else if (operation == Dml.Operation.DO_UPDATE) {
            return this.doUpdate(records, options);
        } else if (operation == Dml.Operation.DO_UPSERT) {
            return this.doUpsert(records, options);
        } else if (operation == Dml.Operation.DO_DELETE) {
            return this.doDelete(records, options);
        } else if (operation == Dml.Operation.DO_UNDELETE) {
            return this.doUndelete(records, options);
        } else {
            throw new System.DmlException('Unsupported Dml.Operation: ' + operation);
        }
    }

    global virtual List<Database.SaveResult> doInsert(List<SObject> records, Options options) {
        Database.DmlOptions dmlOptions = options?.getDmlOptions();
        System.AccessLevel accessLevel = options?.getAccessLevel();
        return Database.insert(records, dmlOptions, accessLevel);
    }

    global virtual List<Database.SaveResult> doUpdate(List<SObject> records, Options options) {
        Database.DmlOptions dmlOptions = options?.getDmlOptions();
        System.AccessLevel accessLevel = options?.getAccessLevel();
        return Database.update(records, dmlOptions, accessLevel);
    }

    global virtual List<Database.UpsertResult> doUpsert(List<SObject> records, Options options) {
        try {
            UpsertOptions upsertOptions = (UpsertOptions) options; 
            return this.doUpsert(records, upsertOptions);
        } catch (System.TypeException error) {
            // Not an UpsertOptions object; use vanilla DmlOptions
            Boolean allOrNone = options?.getDmlOptions()?.OptAllOrNone ?? true;
            System.AccessLevel accessLevel = options?.getAccessLevel();
            return Database.upsert(records, allOrNone, accessLevel);
        }
    }

    global virtual List<Database.UpsertResult> doUpsert(List<SObject> records, UpsertOptions options) {
        Boolean allOrNone = options?.getDmlOptions()?.OptAllOrNone ?? true;
        System.AccessLevel accessLevel = options?.getAccessLevel();
        SObjectField field = options?.getExternalIdField();
        // Note: Supplying a null ExternalIdField value to Database.upsert will result in an Exception
        // To avoid this, call the correct overload depending on the supplied field value
        return (field != null) 
            ? Database.upsert(records, field, allOrNone, accessLevel)
            : Database.upsert(records, allOrNone, accessLevel);
    }

    global virtual List<Database.DeleteResult> doDelete(List<Id> recordIds, Options options) {
        Boolean allOrNone = options?.getAllOrNone();
        System.AccessLevel accessLevel = options?.getAccessLevel();
        return Database.delete(recordIds, allOrNone, accessLevel);
    }

    global virtual List<Database.UndeleteResult> doUndelete(List<Id> recordIds, Options options) {
        Boolean allOrNone = options?.getAllOrNone();
        System.AccessLevel accessLevel = options?.getAccessLevel();
        return Database.undelete(recordIds, allOrNone, accessLevel);
    }

    // **** OVERLOADS **** //
    global List<Object> doDml(Operation operation, List<SObject> records) {
        Options options = new Options();
        return this.doDml(operation, records, options);
    }

    global Object doDml(Operation operation, SObject record, Options options) {
        List<SObject> records = new List<SObject>{ record };
        return this.doDml(operation, records, options)[0];
    }

    global Object doDml(Operation operation, SObject record) {
        Options options = new Options();
        return this.doDml(operation, record, options);
    }

    global List<Database.SaveResult> doInsert(List<SObject> records) {
        return (List<Database.SaveResult>) this.doDml(Dml.Operation.DO_INSERT, records);
    }

    global Database.SaveResult doInsert(SObject record, Options options) {
        return (Database.SaveResult) this.doDml(Dml.Operation.DO_INSERT, record, options);
    }

    global Database.SaveResult doInsert(SObject record) {
        return (Database.SaveResult) this.doDml(Dml.Operation.DO_INSERT, record);
    }

    global List<Database.SaveResult> doUpdate(List<SObject> records) {
        return (List<Database.SaveResult>) this.doDml(Dml.Operation.DO_UPDATE, records);
    }

    global Database.SaveResult doUpdate(SObject record, Options options) {
        return (Database.SaveResult) this.doDml(Dml.Operation.DO_UPDATE, record, options);
    }

    global Database.SaveResult doUpdate(SObject record) {
        return (Database.SaveResult) this.doDml(Dml.Operation.DO_UPDATE, record);
    }

    global List<Database.UpsertResult> doUpsert(List<SObject> records) {
        return (List<Database.UpsertResult>) this.doDml(Dml.Operation.DO_UPSERT, records);
    }

    global Database.UpsertResult doUpsert(SObject record, Options options) {
        return (Database.UpsertResult) this.doDml(Dml.Operation.DO_UPSERT, record, options);
    }

    global Database.UpsertResult doUpsert(SObject record) {
        return (Database.UpsertResult) this.doDml(Dml.Operation.DO_UPSERT, record);
    }

    global List<Database.DeleteResult> doDelete(List<SObject> records, Options options) {
        List<Id> recordIds = new List<Id>(new Map<Id, SObject>(records)?.keySet());
        return this.doDelete(recordIds, options);
    }

    global List<Database.DeleteResult> doDelete(List<SObject> records) {
        return (List<Database.DeleteResult>) this.doDml(Dml.Operation.DO_DELETE, records);
    }

    global Database.DeleteResult doDelete(SObject record, Options options) {
        return (Database.DeleteResult) this.doDml(Dml.Operation.DO_DELETE, record, options);
    }

    global Database.DeleteResult doDelete(SObject record) {
        return (Database.DeleteResult) this.doDml(Dml.Operation.DO_DELETE, record);
    }

    global List<Database.UndeleteResult> doUndelete(List<SObject> records, Options options) {
        List<Id> recordIds = new List<Id>(new Map<Id, SObject>(records)?.keySet());
        return this.doUndelete(recordIds, options);
    }

    global List<Database.UndeleteResult> doUndelete(List<SObject> records) {
        return (List<Database.UndeleteResult>) this.doDml(Dml.Operation.DO_UNDELETE, records);
    }

    global Database.UndeleteResult doUndelete(SObject record, Options options) {
        return (Database.UndeleteResult) this.doDml(Dml.Operation.DO_UNDELETE, record, options);
    }

    global Database.UndeleteResult doUndelete(SObject record) {
        return (Database.UndeleteResult) this.doDml(Dml.Operation.DO_UNDELETE, record);
    }

    // **** INNER **** //
    global enum Operation {
        DO_INSERT,
        DO_UPDATE,
        DO_UPSERT,
        DO_DELETE,
        DO_UNDELETE
    }

    global virtual class Options {
        // This object wraps the Database.DmlOptions class
        // Frustratingly, this class is not universally used across all Database DML methods
        // It also promotes the System.AccessLevel to a first-class class citizen
        global System.AccessLevel accessLevel { get; private set; }
        global Database.DmlOptions dmlOptions { get; private set; }

        global Options() {
            // 0-arg constructor is always available
            this.accessLevel = System.AccessLevel.USER_MODE;
            this.dmlOptions = new Database.DmlOptions();
        }

        global System.AccessLevel getAccessLevel() {
            return this.accessLevel ?? System.AccessLevel.SYSTEM_MODE;
        }

        global Boolean getAllOrNone() {
            return this.getDmlOptions()?.OptAllOrNone ?? true; 
        }

        global Database.DmlOptions getDmlOptions() {
            return this.dmlOptions ?? new Database.DmlOptions();
        }

        global Options setAccessLevel(System.AccessLevel level) {
            this.accessLevel = level; 
            return this; 
        }

        global Options setAllOrNone(Boolean value) {
            this.getDmlOptions().OptAllOrNone = value;
            return this; 
        }

        global Options setAssignmentRuleHeader(Database.DmlOptions.AssignmentRuleHeader header) {
            this.getDmlOptions().AssignmentRuleHeader = header;
            return this; 
        }

        global Options setDmlOptions(Database.DmlOptions dmlOptions) {
            this.dmlOptions = dmlOptions;
            return this; 
        }

        global Options setEmailHeader(Database.DmlOptions.EmailHeader header) {
            this.getDmlOptions().EmailHeader = header;
            return this; 
        }

        global Options setFieldTruncation(Boolean value) {
            this.getDmlOptions().AllowFieldTruncation = value; 
            return this; 
        }

        global Options setLocaleOptions(String locale) {
            this.getDmlOptions().LocaleOptions = locale;
            return this; 
        }
    }

    global class UpsertOptions extends Options {
        SObjectField externalIdField { get; set; }

        global SObjectField getExternalIdField() {
            return this.externalIdField;
        }

        global UpsertOptions setExternalIdField(SObjectField field) {
            this.externalIdField = field; 
            return this; 
        }
    }
}