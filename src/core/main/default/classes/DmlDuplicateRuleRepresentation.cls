public class DmlDuplicateRuleRepresentation {
    @AuraEnabled 
    public Boolean allowSave;

    @AuraEnabled 
    public Boolean runAsCurrentUser;

    public DmlDuplicateRuleRepresentation() {
        this.allowSave = false;
        this.runAsCurrentUser = false;
    }
}