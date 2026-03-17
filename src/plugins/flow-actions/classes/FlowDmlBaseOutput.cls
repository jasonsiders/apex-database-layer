public class FlowDmlBaseOutput {
    @InvocableVariable(label='Records')
    public List<SObject> records;

    @InvocableVariable(label='Results')
    public List<FlowDmlBaseResult> results;

    public FlowDmlBaseOutput() {
        this.records = new List<SObject>{};
        this.results = new List<FlowDmlBaseResult>{};
    }
}
