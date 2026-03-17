public class FlowDmlEmailHeader {
    @AuraEnabled
    public Boolean triggerAutoResponseEmail;

    @AuraEnabled
    public Boolean triggerOtherEmail;

    @AuraEnabled
    public Boolean triggerUserEmail;

    public FlowDmlEmailHeader() {
        this.triggerAutoResponseEmail = false;
        this.triggerOtherEmail = false;
        this.triggerUserEmail = false;
    }
}
