public class FlowDmlDeleteInput {
    @InvocableVariable(label='Base Input')
    public FlowDmlBaseInput baseInput;

    @InvocableVariable(label='Record Id [single]' description='The Id of a single SObject record to be processed.')
    public Id recordId;

    @InvocableVariable(label='Record Ids [collection]' description='A collection of SObject record Ids to be processed.')
    public List<Id> recordIds;

    public FlowDmlDeleteInput() {
        this.baseInput = new FlowDmlBaseInput();
        this.recordIds = new List<Id>{};
    }
}
