public abstract class InvocableDml {
    public class BaseInput {
        @InvocableVariable(label='Access Level' defaultValue='USER_MODE' description='Specifies whether the method runs in SYSTEM_MODE or USER_MODE [default]. In system mode, the object and field-level permissions of the current user are ignored, and the record sharing rules are controlled the flow. In user mode, the object permissions, field-level security, and sharing rules of the current user are enforced.')
        public String accessLevelName;
        
        @InvocableVariable(label='All Or None' defaultValue='true' description='Specifies whether the operation allows partial success. If set to false and any record fails, the remainder of the DML operation can still succeed. If true [default] and any record fails, an exception is thrown.')
        public Boolean allOrNone; 

        @InvocableVariable(label='DML Options' description='Specifies additional data for the transaction')
        public InvocableDml.Options dmlOptions; 

        @InvocableVariable(label='SObject Record [single]' description='A single SObject record to be processed.')
        public SObject record; 

        @InvocableVariable(label='SObject Records [collection]' description='A collection of SObject records to be processed')
        public List<SObject> records;

        public BaseInput() {
            this.accessLevelName = System.AccessLevel.USER_MODE.toString();
            this.allOrNone = true; 
            this.records = new List<SObject>{};
        }
    }

    public class BaseOutput {
        @InvocableVariable(label='Results')
        public List<InvocableDml.BaseResult> results;

        public BaseOutput() {
            this.results = new List<InvocableDml.BaseResult>{};
        }
    }

    public class BaseResult {
        @InvocableVariable(label='Error(s)' description='Contains the raw ')
        public List<InvocableDml.Error> errors; 

        @InvocableVariable(label='Record ID' description='The ID of the SObject record or Platform Event that was processed')
        public String id;

        @InvocableVariable(label='Is Success?' defaultValue='false' description='Indicates if the DML operation succeeded for this record')
        public Boolean isSuccess;

        @InvocableVariable(label='Record' description='The SObject record that was processed')
        public SObject record;

        public BaseResult() {
            this.errors = new List<InvocableDml.Error>{};
            this.isSuccess = false;
        }

        public BaseResult(Database.DeleteResult result) {
            this();
            List<Database.Error> errors = result?.getErrors();
            this.errors = this.wrapErrors(errors);
            this.id = result?.getId();
            this.isSuccess = result?.isSuccess();
            this.record = record;
        }

        public BaseResult(SObject record, Database.SaveResult result) {
            this();
            List<Database.Error> errors = result?.getErrors();
            this.errors = this.wrapErrors(errors);
            this.id = result?.getId();
            this.isSuccess = result?.isSuccess();
            this.record = record;
        }

        public BaseResult(Database.UndeleteResult result) {
            this();
            List<Database.Error> errors = result?.getErrors();
            this.errors = this.wrapErrors(errors);
            this.id = result?.getId();
            this.isSuccess = result?.isSuccess();
            this.record = record;
        }

        public BaseResult(SObject record, Database.UpsertResult result) {
            this();
            List<Database.Error> errors = result?.getErrors();
            this.errors = this.wrapErrors(errors);
            this.id = result?.getId();
            this.isSuccess = result?.isSuccess();
            this.record = record;
        }

        private List<InvocableDml.Error> wrapErrors(List<Database.Error> databaseErrors) {
            List<InvocableDml.Error> errors = new List<InvocableDml.Error>{};
            for (Database.Error databaseError: databaseErrors) {
                InvocableDml.Error error = new InvocableDml.Error(databaseError);
                errors?.add(error);
            }
            return errors;
        }
    }

    public class DeleteInput {
        @InvocableVariable(label='Hard Delete' description='When set to true, deleted records will be purged from the recycle bin')
        public Boolean doHardDelete; 

        @InvocableVariable(label='Record ID [single]' description='The ID of the SObject record to delete')
        public Id recordId;

        @InvocableVariable(label='Record ID [collection]' description='A collection of IDs representing SObject records to delete')
        public List<Id> recordIds; 

        // Note: These properties will display as flattened by the CPE
        // This is to make up for a current limitation of @InvocableVariable classes, which don't implement proper inheritance
        @InvocableVariable
        public InvocableDml.BaseInput baseInput;

        public DeleteInput() {
            this.baseInput = new InvocableDml.BaseInput();
            this.doHardDelete = false;
            this.recordIds = new List<Id>{};
        }
    }

    public class Error {
        @InvocableVariable(label='Field(s)' description='The field(s) impacted by the error')
        public String fields;

        @InvocableVariable(label='Message' description='The text of the error message')
        public String message;

        @InvocableVariable(label='Status Code' description='')
        public String statusCode;

        @SuppressWarnings('PMD.EmptyStatementBlock')
        public Error() {
            // A 0-arg constructor is required for use in flows
        }

        public Error(Database.Error error) {
            this();
            this.fields = error?.getFields()?.toString();
            this.message = error?.getMessage();
            this.statusCode = error?.getStatusCode()?.name();
        }
    }

    public class Options {
        @InvocableVariable(label='Allow Field Truncation' defaultValue='false' description='Specifies the truncation behavior of large strings.')
        public Boolean allowFieldTruncation;

        public Options() {
            this.allowFieldTruncation = false;
        }
    }

    public class UpsertInput {
        // Note: These properties will display as flattened by the CPE
        // This is to make up for a current limitation of @InvocableVariable classes, which don't implement proper inheritance
        @InvocableVariable
        public InvocableDml.BaseInput baseInput;

        @InvocableVariable(label='External ID Field API Name' description='The field to use as the upsert key')
        public String externalIdField;
    }
}