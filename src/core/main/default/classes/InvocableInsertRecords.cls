public abstract class InvocableInsertRecords {
    @InvocableMethod(category='Database Layer' label='Insert Record(s)' iconName='slds:standard:record_create')
    public static List<InvocableDml.BaseOutput> invoke(List<InvocableDml.BaseInput> inputs) {
        return new List<InvocableDml.BaseOutput>{};
    } 
}