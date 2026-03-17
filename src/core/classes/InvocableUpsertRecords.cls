public abstract class InvocableUpsertRecords {
    @InvocableMethod(category='Database Layer' label='Upsert Record(s)' iconName='slds:standard:change_record_type')
    public static List<InvocableDml.BaseOutput> invoke(List<InvocableDml.UpsertInput> inputs) {
        return new List<InvocableDml.BaseOutput>{};
    } 
}