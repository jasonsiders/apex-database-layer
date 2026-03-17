public abstract class InvocableDml {
    public class BaseInput {
        @InvocableVariable(label='Access Level' defaultValue='USER_MODE' description='Specifies whether the method runs in SYSTEM_MODE or USER_MODE [default]. In system mode, the object and field-level permissions of the current user are ignored, and the record sharing rules are controlled the flow. In user mode, the object permissions, field-level security, and sharing rules of the current user are enforced.')
        public String accessLevelName;
        
        @InvocableVariable(label='All Or None' defaultValue='true' description='Specifies whether the operation allows partial success. If set to false and any record fails, the remainder of the DML operation can still succeed. If true [default] and any record fails, an exception is thrown.')
        public Boolean allOrNone; 

        @InvocableVariable(label='DML Options' description='Specifies additional data for the transaction')
        public DmlOptionsRepresentation dmlOptions; 

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
        public List<DmlResultRepresentation> results;

        public BaseOutput() {
            this.results = new List<DmlResultRepresentation>{};
        }
    }
}