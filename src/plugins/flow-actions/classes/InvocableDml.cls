public abstract class InvocableDml {
    // **** INPUTS **** //
    public class BaseInput {
        @InvocableVariable(label='Access Level' defaultValue='USER_MODE' description='Specifies whether the method runs in SYSTEM_MODE or USER_MODE [default]. In system mode, the object and field-level permissions of the current user are ignored, and the record sharing rules are controlled the flow. In user mode, the object permissions, field-level security, and sharing rules of the current user are enforced.')
        public String accessLevelName;
        
        @InvocableVariable(label='All Or None' defaultValue='true' description='Specifies whether the operation allows partial success. If set to false and any record fails, the remainder of the DML operation can still succeed. If true [default] and any record fails, an exception is thrown.')
        public Boolean allOrNone; 

        @InvocableVariable(label='DML Options' description='Specifies additional data for the transaction')
        public FlowDmlOptions dmlOptions;

        @InvocableVariable(label='SObject Record' description='A single SObject record to be processed.')
        public SObject record; 

        @InvocableVariable(label='SObject Records [collection]' description='A collection of SObject records to be processed')
        public List<SObject> records;

        public BaseInput() {
            this.accessLevelName = System.AccessLevel.USER_MODE.toString();
            this.allOrNone = true; 
            this.records = new List<SObject>{};
        }
    }

    public class ConvertInput {
        @InvocableVariable(label='Lead ID' description='The ID of the Lead to be converted')
        public Id leadId;
        
        // TODO: Add more inputs from Database.LeadConvert:
        // https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_dml_convertLead.htm
    }

    public class DeleteInput {
        @InvocableVariable(label='Base Input')
        public InvocableDml.BaseInput baseInput;

        @InvocableVariable(label='Record Id [single]' description='The Id of a single SObject record to be processed.')
        public Id recordId;

        @InvocableVariable(label='Record Ids [collection]' description='A collection of SObject record Ids to be processed.')
        public List<Id> recordIds;

        public DeleteInput() {
            this.baseInput = new InvocableDml.BaseInput();
            this.recordIds = new List<Id>{};
        }
    }

    // **** OUTPUTS **** //
    public class BaseOutput {
        @InvocableVariable(label='Records')
        public List<SObject> records;

        @InvocableVariable(label='Results')
        public List<FlowDmlBaseResult> results;

        public BaseOutput() {
            this.records = new List<SObject>{};
            this.results = new List<FlowDmlBaseResult>{};
        }
    }

    public class ConvertOutput {
        @InvocableVariable(label='Leads')
        public List<Lead> leads;

        @InvocableVariable(label='Results')
        public List<FlowDmlConvertResult> results; 

        public ConvertOutput() {
            this.leads = new List<Lead>{};
            this.results = new List<FlowDmlUpsertResult>{};
        }
    }

    public class UpsertOutput {
        @InvocableVariable(label='Records')
        public List<SObject> records;

        @InvocableVariable(label='Results')
        public List<FlowDmlUpsertResult> results;

        public UpsertOutput() {
            this.records = new List<SObject>{};
            this.results = new List<FlowDmlUpsertResult>{};
        }
    }
}