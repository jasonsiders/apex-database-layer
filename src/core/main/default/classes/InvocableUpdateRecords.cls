public abstract class InvocableUpdateRecords {
    @InvocableMethod(category='Database Layer' label='Update Record(s)' iconName='slds:standard:record_update')
    public static List<InvocableDml.BaseOutput> invoke(List<InvocableDml.BaseInput> inputs) {
        return new List<InvocableDml.BaseOutput>{};
    } 
}