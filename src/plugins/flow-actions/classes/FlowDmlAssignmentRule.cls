public class FlowDmlAssignmentRule {
    @AuraEnabled
    public String assignmentRuleId;

    @AuraEnabled
    public Boolean useDefaultRule;

    public FlowDmlAssignmentRule() {
        this.useDefaultRule = false;
    }
}
