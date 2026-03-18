public abstract class InvocableDmlInsertRecords {
    @InvocableMethod(category='Database Layer' label='Insert Record(s)' iconName='slds:standard:record_create' configurationEditor='c-flow-dml-property-editor')
    public static List<FlowDmlBaseOutput> invoke(List<FlowDmlBaseInput> inputs) {
        return new List<FlowDmlBaseOutput>{};
    }
}
