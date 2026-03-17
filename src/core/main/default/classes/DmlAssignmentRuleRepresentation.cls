public class DmlAssignmentRuleRepresentation {
    @AuraEnabled 
    public String assignmentRuleId;

    @AuraEnabled 
    public Boolean useDefaultRule;
    
    public DmlAssignmentRuleRepresentation() {
        this.useDefaultRule = false; 
    }
}