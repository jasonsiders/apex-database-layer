public class FlowDmlUpsertResult {
	@AuraEnabled
	public FlowDmlBaseResult baseResult;

	@AuraEnabled
	public Boolean isCreated;

	public FlowDmlUpsertResult() {
		this.baseResult = new FlowDmlBaseResult();
		this.isCreated = false;
	}

	public FlowDmlUpsertResult(SObject record, Database.UpsertResult result) {
		this();
		this.baseResult = new FlowDmlBaseResult(record, result);
		this.isCreated = result?.isCreated();
	}
}
