/**
 * @description Flow can't read Database result types, so this Apex-defined type carries their outcome in plain fields
 */
public class InvocableDmlResult {
	// **** MEMBER **** //
	/** @description Formatted as `STATUS_CODE: Message (Field1, Field2)`, since Flow can't read Database.Error **/
	@AuraEnabled
	public List<String> errors;
	/** @description Null when an insert fails, matching Database.SaveResult; the lead's Id for conversions **/
	@AuraEnabled
	public Id id;
	/** @description Set by upserts only, since the other operations' results can't tell **/
	@AuraEnabled
	public Boolean isCreated;
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
	 * @description Copies a Database.DeleteResult into fields Flow can read
	 * @param result The result of a delete operation
	 */
	public InvocableDmlResult(Database.DeleteResult result) {
		this(result?.getId(), result?.isSuccess(), result?.getErrors());
	}

	/**
	 * @description Copies a Database.EmptyRecycleBinResult into fields Flow can read
	 * @param result The result of an empty recycle bin operation
	 */
	public InvocableDmlResult(Database.EmptyRecycleBinResult result) {
		this(result?.getId(), result?.isSuccess(), result?.getErrors());
	}

	/**
	 * @description Copies a Database.LeadConvertResult into fields Flow can read; its Id is the lead's
	 * @param result The result of a lead conversion
	 */
	public InvocableDmlResult(Database.LeadConvertResult result) {
		this(result?.getLeadId(), result?.isSuccess(), result?.getErrors());
	}

	/**
	 * @description Copies a Database.SaveResult into fields Flow can read
	 * @param result The result of an insert or update operation
	 */
	public InvocableDmlResult(Database.SaveResult result) {
		this(result?.getId(), result?.isSuccess(), result?.getErrors());
	}

	/**
	 * @description Copies a Database.UndeleteResult into fields Flow can read
	 * @param result The result of an undelete operation
	 */
	public InvocableDmlResult(Database.UndeleteResult result) {
		this(result?.getId(), result?.isSuccess(), result?.getErrors());
	}

	/**
	 * @description Copies a Database.UpsertResult into fields Flow can read, including whether it created the record
	 * @param result The result of an upsert operation
	 */
	public InvocableDmlResult(Database.UpsertResult result) {
		this(result?.getId(), result?.isSuccess(), result?.getErrors());
		this.isCreated = result?.isCreated();
	}

	/**
	 * @description Database result types share no interface, so each gets its own overload; this one takes
	 * a delete operation's results
	 * @param deleteResults The results to convert
	 * @return The converted results, in the same order
	 */
	public static List<InvocableDmlResult> fromList(List<Database.DeleteResult> deleteResults) {
		List<InvocableDmlResult> results = new List<InvocableDmlResult>{};
		for (Database.DeleteResult deleteResult : deleteResults) {
			InvocableDmlResult result = new InvocableDmlResult(deleteResult);
			results?.add(result);
		}
		return results;
	}

	/**
	 * @description Database result types share no interface, so each gets its own overload; this one takes
	 * an empty recycle bin operation's results
	 * @param purgeResults The results to convert
	 * @return The converted results, in the same order
	 */
	public static List<InvocableDmlResult> fromList(List<Database.EmptyRecycleBinResult> purgeResults) {
		List<InvocableDmlResult> results = new List<InvocableDmlResult>{};
		for (Database.EmptyRecycleBinResult purgeResult : purgeResults) {
			InvocableDmlResult result = new InvocableDmlResult(purgeResult);
			results?.add(result);
		}
		return results;
	}

	/**
	 * @description Database result types share no interface, so each gets its own overload; this one takes
	 * an insert or update operation's results
	 * @param saveResults The results to convert
	 * @return The converted results, in the same order
	 */
	public static List<InvocableDmlResult> fromList(List<Database.SaveResult> saveResults) {
		List<InvocableDmlResult> results = new List<InvocableDmlResult>{};
		for (Database.SaveResult saveResult : saveResults) {
			InvocableDmlResult result = new InvocableDmlResult(saveResult);
			results?.add(result);
		}
		return results;
	}

	/**
	 * @description Database result types share no interface, so each gets its own overload; this one takes
	 * an undelete operation's results
	 * @param undeleteResults The results to convert
	 * @return The converted results, in the same order
	 */
	public static List<InvocableDmlResult> fromList(List<Database.UndeleteResult> undeleteResults) {
		List<InvocableDmlResult> results = new List<InvocableDmlResult>{};
		for (Database.UndeleteResult undeleteResult : undeleteResults) {
			InvocableDmlResult result = new InvocableDmlResult(undeleteResult);
			results?.add(result);
		}
		return results;
	}

	/**
	 * @description Database result types share no interface, so each gets its own overload; this one takes
	 * an upsert operation's results
	 * @param upsertResults The results to convert
	 * @return The converted results, in the same order
	 */
	public static List<InvocableDmlResult> fromList(List<Database.UpsertResult> upsertResults) {
		List<InvocableDmlResult> results = new List<InvocableDmlResult>{};
		for (Database.UpsertResult upsertResult : upsertResults) {
			InvocableDmlResult result = new InvocableDmlResult(upsertResult);
			results?.add(result);
		}
		return results;
	}

	// **** PRIVATE **** //
	/**
	 * @description Every Database result type has these, but they share no interface
	 * @param recordId The record's Id
	 * @param isSuccess Whether the operation succeeded for the record
	 * @param databaseErrors The record's errors
	 */
	private InvocableDmlResult(Id recordId, Boolean isSuccess, List<Database.Error> databaseErrors) {
		this.errors = InvocableDmlResult.formatErrors(databaseErrors);
		this.id = recordId;
		this.isSuccess = isSuccess;
	}

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
	 * @param databaseErrors The errors to format; null for a successful EmptyRecycleBinResult
	 * @return The formatted errors, in the same order
	 */
	private static List<String> formatErrors(List<Database.Error> databaseErrors) {
		List<String> errors = new List<String>{};
		for (Database.Error databaseError : databaseErrors ?? new List<Database.Error>{}) {
			String error = InvocableDmlResult.formatError(databaseError);
			errors?.add(error);
		}
		return errors;
	}
}
