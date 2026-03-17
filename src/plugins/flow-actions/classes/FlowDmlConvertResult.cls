public class FlowDmlConvertResult {
    @AuraEnabled
    public String accountId;
    @AuraEnabled
    public String contactId;
    @AuraEnabled
    public List<FlowDmlError> errors;
    @AuraEnabled
    public Boolean isSuccess;
    @AuraEnabled
    public String leadId;
    @AuraEnabled
    public String opportunityId;

    public FlowDmlConvertResult() {
        this.errors = new List<FlowDmlError>{};
        this.isSuccess = false;
    }

    public FlowDmlConvertResult(Database.LeadConvertResult result) {
        this();
        this.accountId = result?.getAccountId();
        this.contactId = result?.getContactId();
        this.errors = this.wrapErrors(result?.getErrors());
        this.isSuccess = result?.isSuccess();
        this.leadId = result?.getLeadId();
        this.opportunityId = result?.getOpportunityId();
    }

    private List<FlowDmlError> wrapErrors(List<Database.Error> databaseErrors) {
        List<FlowDmlError> errors = new List<FlowDmlError>{};
        for (Database.Error databaseError: databaseErrors) {
            FlowDmlError error = new FlowDmlError(databaseError);
            errors?.add(error);
        }
        return errors;
    }
}
