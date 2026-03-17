public class FlowDmlDuplicateRule {
    @AuraEnabled
    public Boolean allowSave;

    @AuraEnabled
    public Boolean runAsCurrentUser;

    public FlowDmlDuplicateRule() {
        this.allowSave = false;
        this.runAsCurrentUser = false;
    }
}
