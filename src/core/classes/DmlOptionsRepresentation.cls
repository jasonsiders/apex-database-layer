public class DmlOptionsRepresentation {
    @AuraEnabled
    public Boolean allowFieldTruncation;

    @AuraEnabled
    public DmlAssignmentRuleRepresentation assignmentRuleHeader;

    @AuraEnabled 
    public DmlDuplicateRuleRepresentation duplicateRuleHeader;

    @AuraEnabled 
    public DmlEmailHeaderRepresentation emailHeader;

    @AuraEnabled 
    public String localeOptions;

    public DmlOptionsRepresentation() {
        this.allowFieldTruncation = false;
    }
}