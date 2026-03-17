public class DmlResultRepresentation {
    @AuraEnabled
    public List<DmlErrorRepresentation> errors; 

    @AuraEnabled
    public String id;

    @AuraEnabled
    public Boolean isSuccess;

    @AuraEnabled
    public SObject record;

    public DmlResultRepresentation() {
        this.errors = new List<DmlErrorRepresentation>{};
        this.isSuccess = false;
    }

    public DmlResultRepresentation(Database.DeleteResult result) {
        this();
        List<Database.Error> errors = result?.getErrors();
        this.errors = this.wrapErrors(errors);
        this.id = result?.getId();
        this.isSuccess = result?.isSuccess();
        this.record = record;
    }

    public DmlResultRepresentation(SObject record, Database.SaveResult result) {
        this();
        List<Database.Error> errors = result?.getErrors();
        this.errors = this.wrapErrors(errors);
        this.id = result?.getId();
        this.isSuccess = result?.isSuccess();
        this.record = record;
    }

    public DmlResultRepresentation(Database.UndeleteResult result) {
        this();
        List<Database.Error> errors = result?.getErrors();
        this.errors = this.wrapErrors(errors);
        this.id = result?.getId();
        this.isSuccess = result?.isSuccess();
        this.record = record;
    }

    public DmlResultRepresentation(SObject record, Database.UpsertResult result) {
        this();
        List<Database.Error> errors = result?.getErrors();
        this.errors = this.wrapErrors(errors);
        this.id = result?.getId();
        this.isSuccess = result?.isSuccess();
        this.record = record;
    }

    private List<DmlErrorRepresentation> wrapErrors(List<Database.Error> databaseErrors) {
        List<DmlErrorRepresentation> errors = new List<DmlErrorRepresentation>{};
        for (Database.Error databaseError: databaseErrors) {
            DmlErrorRepresentation error = new DmlErrorRepresentation(databaseError);
            errors?.add(error);
        }
        return errors;
    }
}