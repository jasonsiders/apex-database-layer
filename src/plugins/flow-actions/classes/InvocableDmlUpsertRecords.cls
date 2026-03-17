public abstract class InvocableDmlUpsertRecords {
    @InvocableMethod(category='Database Layer' label='Upsert Record(s)' iconName='slds:standard:replace')
    public static List<InvocableDml.UpsertOutput> invoke(List<InvocableDmlUpsertRecords.Input> inputs) {
        return new List<InvocableDml.UpsertOutput>{};
    }

    public class Input {
        @InvocableVariable(label='Base Input')
        public InvocableDml.BaseInput baseInput;

        @InvocableVariable(label='External ID Field' description='The API Name of the field to use as the upsert primary key')
        public String externalIdField;
    }
}
