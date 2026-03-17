public class DmlEmailHeaderRepresentation {
    @AuraEnabled 
    public Boolean triggerAutoResponseEmail;

    @AuraEnabled 
    public Boolean triggerOtherEmail;

    @AuraEnabled 
    public Boolean triggerUserEmail;

    public DmlEmailHeaderRepresentation() {
        this.triggerAutoResponseEmail = false;
        this.triggerOtherEmail = false;
        this.triggerUserEmail = false;
    }
}