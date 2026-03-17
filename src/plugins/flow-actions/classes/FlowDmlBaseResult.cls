public class FlowDmlBaseResult {
    @AuraEnabled
    public List<FlowDmlError> errors;
    @AuraEnabled
    public String id;
    @AuraEnabled
    public Boolean isSuccess;
    @AuraEnabled
    public SObject record;

    public FlowDmlBaseResult() {
        this.errors = new List<FlowDmlError>{};
        this.isSuccess = false;
    }

    public FlowDmlBaseResult(Database.DeleteResult result) {
        this();
        List<Database.Error> errors = result?.getErrors();
        this.errors = this.wrapErrors(errors);
        this.id = result?.getId();
        this.isSuccess = result?.isSuccess();
        this.record = record;
    }

    public FlowDmlBaseResult(SObject record, Database.SaveResult result) {
        this();
        List<Database.Error> errors = result?.getErrors();
        this.errors = this.wrapErrors(errors);
        this.id = result?.getId();
        this.isSuccess = result?.isSuccess();
        this.record = record;
    }

    public FlowDmlBaseResult(Database.UndeleteResult result) {
        this();
        List<Database.Error> errors = result?.getErrors();
        this.errors = this.wrapErrors(errors);
        this.id = result?.getId();
        this.isSuccess = result?.isSuccess();
        this.record = record;
    }

    public FlowDmlBaseResult(SObject record, Database.UpsertResult result) {
        this();
        List<Database.Error> errors = result?.getErrors();
        this.errors = this.wrapErrors(errors);
        this.id = result?.getId();
        this.isSuccess = result?.isSuccess();
        this.record = record;
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
