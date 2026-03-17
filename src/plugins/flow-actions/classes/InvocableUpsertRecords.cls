public abstract class InvocableUpsertRecords {
    @InvocableMethod(category='Database Layer' label='Upsert Record(s)' iconName='slds:standard:record')
    public static List<InvocableDml.BaseOutput> invoke(List<InvocableUpsertRecords.Input> inputs) {
        return new List<InvocableDml.BaseOutput>{};
    } 

    public class Input {
        @InvocableVariable(label='Base Input')
        public InvocableDml.BaseInput baseInput;

        @InvocableVariable(label='External ID Field' description='The API Name of the field to use as the upsert primary key')
        public String externalIdField;
    }
}