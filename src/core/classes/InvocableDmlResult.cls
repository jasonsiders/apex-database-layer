/**
 * @description Flow-friendly outcome of a DML operation on a single record.
 */
public class InvocableDmlResult {
	/**
	 * @description Errors that prevented the operation, formatted as `STATUS_CODE: Message (Field1, Field2)`.
	 */
	@AuraEnabled
	public List<String> errors;
	/**
	 * @description The Id of the record that was operated on. Null when an insert fails.
	 */
	@AuraEnabled
	public Id id;
	/**
	 * @description Whether the operation succeeded for this record.
	 */
	@AuraEnabled
	public Boolean isSuccess;

	/**
	 * @description No-arg constructor, required for use as an Apex-defined type in Flow.
	 */
	public InvocableDmlResult() {
		this.errors = new List<String>();
		this.isSuccess = false;
	}

	/**
	 * @description Creates a result from a `Database.SaveResult`.
	 * @param result The result of an insert or update operation
	 */
	public InvocableDmlResult(Database.SaveResult result) {
		this();
		List<Database.Error> databaseErrors = result?.getErrors();
		this.errors = InvocableDmlResult.formatErrors(databaseErrors);
		this.id = result?.getId();
		this.isSuccess = result?.isSuccess();
	}

	// **** STATIC **** //
	/**
	 * @description Formats a single `Database.Error` as `STATUS_CODE: Message (Field1, Field2)`.
	 * @param error The error to format
	 * @return The formatted error
	 */
	private static String formatError(Database.Error error) {
		List<String> fields = error?.getFields() ?? new List<String>();
		String fieldList = String.join(fields, ', ');
		String suffix = fields?.isEmpty() ? '' : ' (' + fieldList + ')';
		return error?.getStatusCode() + ': ' + error?.getMessage() + suffix;
	}

	/**
	 * @description Formats each `Database.Error` in the list.
	 * @param databaseErrors The errors to format
	 * @return The formatted errors, in the same order
	 */
	private static List<String> formatErrors(List<Database.Error> databaseErrors) {
		List<String> errors = new List<String>();
		for (Database.Error databaseError : databaseErrors) {
			String error = InvocableDmlResult.formatError(databaseError);
			errors?.add(error);
		}
		return errors;
	}
}
