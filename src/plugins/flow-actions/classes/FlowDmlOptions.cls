public class FlowDmlOptions {
    @AuraEnabled
    public Boolean allowFieldTruncation;

    @AuraEnabled
    public FlowDmlAssignmentRule assignmentRuleHeader;

    @AuraEnabled
    public FlowDmlDuplicateRule duplicateRuleHeader;

    @AuraEnabled
    public FlowDmlEmailHeader emailHeader;

    @AuraEnabled
    public String localeOptions;

    public FlowDmlOptions() {
        this.allowFieldTruncation = false;
    }
}
