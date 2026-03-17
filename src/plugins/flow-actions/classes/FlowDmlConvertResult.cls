public class FlowDmlConvertResult {
    @AuraEnabled
    public List<FlowDmlError> errors;
    @AuraEnabled
    public Boolean isSuccess;
    // TODO: Add more properties from Database.LeadConvertResult:
    // https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_class_database_leadconvertresult.htm

    public FlowDmlConvertResult() {
        this.errors = new List<FlowDmlError>{};
        this.isSuccess = false;
    }

    public FlowDmlConvertResult(Database.LeadConvert leadConvert) {
        this();
        // TODO!
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
