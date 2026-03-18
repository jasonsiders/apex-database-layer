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
		this.errors = this.wrapErrors(result);
		this.isSuccess = result?.isSuccess();
		this.leadId = result?.getLeadId();
		this.opportunityId = result?.getOpportunityId();
	}

	private List<FlowDmlError> wrapErrors(Database.LeadConvertResult result) {
		List<Database.Error> errors = result?.getErrors();
		return FlowDmlError.wrap(errors);
	}
}
