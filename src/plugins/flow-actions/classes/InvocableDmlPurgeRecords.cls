public abstract class InvocableDmlPurgeRecords {
    @InvocableMethod(category='Database Layer' label='Empty Recycle Bin' iconName='slds:standard:recycle_bin')
    public static List<InvocableDml.BaseOutput> invoke(List<InvocableDml.DeleteInput> inputs) {
        return new List<InvocableDml.BaseOutput>{};
    } 
}