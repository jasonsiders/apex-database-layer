/**
 * @description Flow can't read Database.SaveResult, so this Apex-defined type carries its outcome in plain fields
 */
public class InvocableDmlResult {
	/** @description Formatted as `STATUS_CODE: Message (Field1, Field2)`, since Flow can't read Database.Error **/
	@AuraEnabled
	public List<String> errors;
	/** @description Null when an insert fails, matching Database.SaveResult **/
	@AuraEnabled
	public Id id;
	/** @description Lets flows branch on partial success without inspecting the errors **/
	@AuraEnabled
	public Boolean isSuccess;

	// **** PUBLIC **** //
	/** @description Apex-defined types need a no-arg constructor for Flow to create them **/
	public InvocableDmlResult() {
		this.errors = new List<String>{};
		this.isSuccess = false;
	}

	/**
	 * @description Copies a Database.SaveResult into fields Flow can read
	 * @param result The result of an insert or update operation
	 */
	public InvocableDmlResult(Database.SaveResult result) {
		this();
		List<Database.Error> databaseErrors = result?.getErrors();
		this.errors = InvocableDmlResult.formatErrors(databaseErrors);
		this.id = result?.getId();
		this.isSuccess = result?.isSuccess();
	}

	// **** PRIVATE **** //
	/**
	 * @description Keeps the status code and fields, which a bare message would lose
	 * @param error The error to format
	 * @return The error, as `STATUS_CODE: Message (Field1, Field2)`
	 */
	private static String formatError(Database.Error error) {
		List<String> fields = error?.getFields() ?? new List<String>{};
		String fieldList = String.join(fields, ', ');
		String suffix = fields?.isEmpty() == true ? '' : ' (' + fieldList + ')';
		return error?.getStatusCode() + ': ' + error?.getMessage() + suffix;
	}

	/**
	 * @description Flow can't read Database.Error, so each one becomes text
	 * @param databaseErrors The errors to format
	 * @return The formatted errors, in the same order
	 */
	private static List<String> formatErrors(List<Database.Error> databaseErrors) {
		List<String> errors = new List<String>{};
		for (Database.Error databaseError : databaseErrors) {
			String error = InvocableDmlResult.formatError(databaseError);
			errors?.add(error);
		}
		return errors;
	}
}
