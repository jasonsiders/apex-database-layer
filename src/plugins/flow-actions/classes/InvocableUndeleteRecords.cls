public abstract class InvocableUndeleteRecords {
    @InvocableMethod(category='Database Layer' label='Undelete Record(s)' iconName='slds:standard:recall' configurationEditor='c-flow-dml-property-editor')
    public static List<FlowDmlBaseOutput> invoke(List<FlowDmlDeleteInput> inputs) {
        return new List<FlowDmlBaseOutput>{};
    } 
}