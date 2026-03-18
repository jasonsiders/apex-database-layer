public abstract class InvocableDmlPurgeRecords {
    @InvocableMethod(category='Database Layer' label='Empty Recycle Bin' iconName='slds:standard:recycle_bin' configurationEditor='c-flow-dml-property-editor')
    public static List<FlowDmlBaseOutput> invoke(List<FlowDmlDeleteInput> inputs) {
        return new List<FlowDmlBaseOutput>{};
    } 
}