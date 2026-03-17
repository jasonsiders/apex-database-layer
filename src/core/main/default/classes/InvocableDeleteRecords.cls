public abstract class InvocableDeleteRecords {
    @InvocableMethod(category='Database Layer' label='Delete Record(s)' iconName='slds:standard:record_delete')
    public static List<InvocableDml.BaseOutput> invoke(List<InvocableDml.DeleteInput> inputs) {
        return new List<InvocableDml.BaseOutput>{};
    } 
}