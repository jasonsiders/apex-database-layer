@IsTest
public class MockDmlResult {
    public List<MockDmlResult.Error> errors { get; set; }
    public Id id { get; set; }
    public Boolean success { get; set; }

    public MockDmlResult(Id recordId) {
        // Creates a record that simulates a successful DML operation
        this.errors = new List<MockDmlResult.Error>();
        this.id = recordId;
        this.success = true;
    }

    public MockDmlResult(SObject record) {
        this(record?.Id);
    }

    public MockDmlResult(Id recordId, List<MockDmlResult.Error> errors) {
        this(recordId);
        this.addErrors(errors);
    }

    public MockDmlResult(Id recordId, MockDmlResult.Error error) {
        this(recordId, new List<MockDmlResult.Error>{ error });
    }

    public MockDmlResult(SObject record, List<MockDmlResult.Error> errors) {
        this(record?.Id, errors);
    }

    public MockDmlResult(SObject record, MockDmlResult.Error error) {
        this(record, new List<MockDmlResult.Error>{error});
    }

    public MockDmlResult addErrors(List<MockDmlResult.Error> errors) {
        this.errors?.addAll(errors);
        this.success = false;
        return this; 
    }

    public MockDmlResult addErrors(MockDmlResult.Error error) {
        return this.addErrors(new List<MockDmlResult.Error>{ error });
    }

    public MockDmlResult addErrors() {
        return this.addErrors(new MockDmlResult.Error());
    }

    public Database.SaveResult toSaveResult() {
        return (Database.SaveResult) this.toDatabaseResult(Database.SaveResult.class);
    }

    public Database.UpsertResult toUpsertResult() {
        return (Database.UpsertResult) this.toDatabaseResult(Database.UpsertResult.class);
    }

    public Database.DeleteResult toDeleteResult() {
        return (Database.DeleteResult) this.toDatabaseResult(Database.DeleteResult.class);
    }

    public Database.UndeleteResult toUndeleteResult() {
        return (Database.UndeleteResult) this.toDatabaseResult(Database.UndeleteResult.class);
    }

    private Object toDatabaseResult(Type resultType) {
        // Returns a Database.Save/Upsert/Delete/UndeleteResult object
        // Unfortunately, these do not share a common interface
        return JSON.deserialize(JSON.serialize(this), resultType);
    }

    // **** STATIC **** // 
    public static List<Database.LeadConvertResult> toConvertResults(List<MockDmlResult> mockResults) {
        return (List<Database.LeadConvertResult>) JSON.deserialize(JSON.serialize(mockResults), List<Database.LeadConvertResult>.class);
    }

    public static List<Database.DeleteResult> toDeleteResults(List<MockDmlResult> mockResults) {
        return (List<Database.DeleteResult>) JSON.deserialize(JSON.serialize(mockResults), List<Database.DeleteResult>.class);
    }

    public static List<MockDmlResult> toMockResults(List<Object> databaseResults) {
        return (List<MockDmlResult>) JSON.deserialize(JSON.serialize(databaseResults), List<MockDmlResult>.class);
    }

    public static List<Database.SaveResult> toSaveResults(List<MockDmlResult> mockResults) {
        return (List<Database.SaveResult>) JSON.deserialize(JSON.serialize(mockResults), List<Database.SaveResult>.class);
    }

    public static List<Database.UpsertResult> toUpsertResults(List<MockDmlResult> mockResults) {
        return (List<Database.UpsertResult>) JSON.deserialize(JSON.serialize(mockResults), List<Database.UpsertResult>.class);
    }

    public static List<Database.UndeleteResult> toUndeleteResults(List<MockDmlResult> mockResults) {
        return (List<Database.UndeleteResult>) JSON.deserialize(JSON.serialize(mockResults), List<Database.UndeleteResult>.class);
    }

    // **** INNER **** //
    public class Error {
        // Wraps the Database.Error class, to be used for mocking in @IsTest context
        public String message;
        public String statusCode; 

        public Error(String message, String statusCode) {
            this.message = message;
            this.statusCode = statusCode; 
        }

        public Error() {
            // Initialize an error with a default message & status code
            this('Test Error', 'TEST_ERROR');
        }

        public Database.Error toDatabaseError() {
            return (Database.Error) JSON.deserialize(JSON.serialize(this), Database.Error.class);
        }
    }
}