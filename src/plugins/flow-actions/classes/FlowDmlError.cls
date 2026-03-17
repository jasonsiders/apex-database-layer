public class FlowDmlError {
    @AuraEnabled
    public String fields;

    @AuraEnabled
    public String message;

    @AuraEnabled
    public String statusCode;

    @SuppressWarnings('PMD.EmptyStatementBlock')
    public FlowDmlError() {
        // A 0-arg constructor is required for use in flows
    }

    public FlowDmlError(Database.Error error) {
        this();
        this.fields = error?.getFields()?.toString();
        this.message = error?.getMessage();
        this.statusCode = error?.getStatusCode()?.name();
    }

    public static List<FlowDmlError> wrap(List<Database.Error> databaseErrors) {
        List<FlowDmlError> errors = new List<FlowDmlError>{};
        for (Database.Error databaseError : databaseErrors) {
            errors.add(new FlowDmlError(databaseError));
        }
        return errors;
    }
}
