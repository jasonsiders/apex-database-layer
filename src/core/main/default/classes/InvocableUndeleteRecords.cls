public abstract class InvocableUndeleteRecords {
    @InvocableMethod(category='Database Layer' label='Undelete Record(s)' iconName='slds:standard:recall')
    public static List<InvocableDml.BaseOutput> invoke(List<InvocableDml.DeleteInput> inputs) {
        return new List<InvocableDml.BaseOutput>{};
    } 
}