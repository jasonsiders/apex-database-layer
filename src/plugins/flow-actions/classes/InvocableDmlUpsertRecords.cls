public abstract class InvocableDmlUpsertRecords {
    @InvocableMethod(category='Database Layer' label='Upsert Record(s)' iconName='slds:standard:replace')
    public static List<InvocableDmlUpsertRecords.Output> invoke(List<InvocableDmlUpsertRecords.Input> inputs) {
        return new List<InvocableDmlUpsertRecords.Output>{};
    }

    public class Input {
        @InvocableVariable(label='Base Input' required='true')
        public FlowDmlBaseInput baseInput;

        @InvocableVariable(label='External ID Field' description='The API Name of the field to use as the upsert primary key')
        public String externalIdField;
    }

    public class Output {
        @InvocableVariable(label='Records')
        public List<SObject> records;

        @InvocableVariable(label='Results')
        public List<FlowDmlUpsertResult> results;

        public Output() {
            this.records = new List<SObject>{};
            this.results = new List<FlowDmlUpsertResult>{};
        }
    }
}
