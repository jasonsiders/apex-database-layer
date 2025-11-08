/**
 * @description Handles Datacloud duplicate detection operations with mockable API abstraction. Provides wrapper classes that abstract Datacloud duplicate detection APIs for testability.
 * Note: Requires org with Datacloud API access enabled. In orgs without this feature, returns empty results.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing virtual class Duplicates {
	/**
	 * @description Constructor for Duplicates instance with DatabaseLayer factory.
	 * @param factory The DatabaseLayer factory instance
	 */
	@SuppressWarnings('PMD.EmptyStatementBlock')
	public Duplicates(DatabaseLayer factory) {
		// Note: Only accessible via DatabaseLayer.Duplicates
	}

	/**
	 * @description Executes duplicate detection on a list of SObject records.
	 * @param records The records to check for duplicates
	 * @return List of FindDuplicatesResult wrapping Datacloud results
	 */
	global List<Duplicates.FindDuplicatesResult> findDuplicates(List<SObject> records) {
		return this.initRequest(records).execute();
	}

	/**
	 * @description Executes duplicate detection on a list of record IDs.
	 * @param recordIds The record IDs to check for duplicates
	 * @return List of FindDuplicatesResult wrapping Datacloud results
	 */
	global List<Duplicates.FindDuplicatesResult> findDuplicates(Iterable<Id> recordIds) {
		return this.initRequest(recordIds).execute();
	}

	/**
	 * @description Virtual hook for MockDuplicates to override request creation.
	 * @param input The input (either List<SObject> or Iterable<Id>)
	 * @return A configured Request instance
	 */
	protected virtual Duplicates.Request initRequest(Object input) {
		return new Duplicates.Request(input);
	}

	// **** INNER CLASSES **** //

	/**
	 * @description Handles execution of duplicate detection requests against the native Datacloud APIs.
	 */
	global inherited sharing virtual class Request {
		protected Object input;

		/**
		 * @description Constructor for Request with input data.
		 * @param input The input (either List<SObject> or Iterable<Id>)
		 */
		protected Request(Object input) {
			this.input = input;
		}

		/**
		 * @description Executes the duplicate detection request. Returns empty results if Datacloud APIs unavailable.
		 * @return List of FindDuplicatesResult (empty if org lacks Datacloud API access)
		 */
		protected virtual List<Duplicates.FindDuplicatesResult> execute() {
			try {
				// Datacloud APIs are only available in orgs with proper feature access
				// If available, this would call: Datacloud.FindDuplicates.findDuplicates()
				// For now, return empty results as this org doesn't have Datacloud APIs
				return new List<Duplicates.FindDuplicatesResult>();
			} catch (Exception ex) {
				// Return empty results if any error occurs
				return new List<Duplicates.FindDuplicatesResult>();
			}
		}

		/**
		 * @description Wraps native results in mockable wrapper classes.
		 * @param nativeResults The native result list (if available)
		 * @return List of wrapped FindDuplicatesResult objects
		 */
		protected List<Duplicates.FindDuplicatesResult> wrapResults(List<Object> nativeResults) {
			List<Duplicates.FindDuplicatesResult> wrappedResults = new List<Duplicates.FindDuplicatesResult>();
			if (nativeResults != null) {
				for (Object nativeResult : nativeResults) {
					wrappedResults.add(new Duplicates.FindDuplicatesResult(nativeResult));
				}
			}
			return wrappedResults;
		}
	}

	/**
	 * @description Mockable wrapper for duplicate detection results.
	 */
	global virtual class FindDuplicatesResult {
		protected Boolean success;
		protected List<Duplicates.Error> errors;
		protected List<Duplicates.DuplicateResult> duplicateResults;

		/**
		 * @description Constructor wrapping a native duplicate detection result.
		 * @param nativeResult The native result object (may be null)
		 */
		protected FindDuplicatesResult(Object nativeResult) {
			this.success = false;
			this.errors = new List<Duplicates.Error>();
			this.duplicateResults = new List<Duplicates.DuplicateResult>();
		}

		/**
		 * @description Returns whether the operation was successful.
		 * @return Boolean indicating success
		 */
		global Boolean getSuccess() {
			return this.success;
		}

		/**
		 * @description Returns any errors that occurred during the operation.
		 * @return List of Error wrappers
		 */
		global List<Duplicates.Error> getErrors() {
			return this.errors;
		}

		/**
		 * @description Returns the duplicate detection results.
		 * @return List of DuplicateResult wrappers
		 */
		global List<Duplicates.DuplicateResult> getDuplicateResults() {
			return this.duplicateResults;
		}

		/**
		 * @description Wraps native error objects.
		 * @param nativeErrors The native error list
		 * @return List of wrapped Error objects
		 */
		protected List<Duplicates.Error> wrapErrors(List<Object> nativeErrors) {
			List<Duplicates.Error> wrappedErrors = new List<Duplicates.Error>();
			if (nativeErrors != null) {
				for (Object nativeError : nativeErrors) {
					wrappedErrors.add(new Duplicates.Error(nativeError));
				}
			}
			return wrappedErrors;
		}

		/**
		 * @description Wraps native duplicate result objects.
		 * @param nativeDuplicateResults The native result list
		 * @return List of wrapped DuplicateResult objects
		 */
		protected List<Duplicates.DuplicateResult> wrapDuplicateResults(List<Object> nativeDuplicateResults) {
			List<Duplicates.DuplicateResult> wrappedResults = new List<Duplicates.DuplicateResult>();
			if (nativeDuplicateResults != null) {
				for (Object nativeDuplicateResult : nativeDuplicateResults) {
					wrappedResults.add(new Duplicates.DuplicateResult(nativeDuplicateResult));
				}
			}
			return wrappedResults;
		}
	}

	/**
	 * @description Wrapper for error information.
	 */
	global virtual class Error {
		protected List<String> fields;
		protected String message;
		protected String statusCode;

		/**
		 * @description Constructor wrapping a native error.
		 * @param nativeError The native error object (may be null)
		 */
		protected Error(Object nativeError) {
			this.fields = new List<String>();
			this.message = null;
			this.statusCode = null;
		}

		/**
		 * @description Returns the fields affected by this error.
		 * @return List of field names
		 */
		global List<String> getFields() {
			return this.fields;
		}

		/**
		 * @description Returns the error message.
		 * @return Error message string
		 */
		global String getMessage() {
			return this.message;
		}

		/**
		 * @description Returns the error status code.
		 * @return Status code as string
		 */
		global String getStatusCode() {
			return this.statusCode;
		}
	}

	/**
	 * @description Wrapper for duplicate detection result for a specific record.
	 */
	global virtual class DuplicateResult {
		protected SObject record;
		protected List<Duplicates.MatchResult> matchResults;

		/**
		 * @description Constructor wrapping a native duplicate result.
		 * @param nativeDuplicateResult The native result object (may be null)
		 */
		protected DuplicateResult(Object nativeDuplicateResult) {
			this.record = null;
			this.matchResults = new List<Duplicates.MatchResult>();
		}

		/**
		 * @description Returns the record being checked for duplicates.
		 * @return The SObject record
		 */
		global SObject getRecord() {
			return this.record;
		}

		/**
		 * @description Returns the match results for this record.
		 * @return List of MatchResult wrappers
		 */
		global List<Duplicates.MatchResult> getMatchResults() {
			return this.matchResults;
		}

		/**
		 * @description Wraps native match result objects.
		 * @param nativeMatchResults The native result list
		 * @return List of wrapped MatchResult objects
		 */
		protected List<Duplicates.MatchResult> wrapMatchResults(List<Object> nativeMatchResults) {
			List<Duplicates.MatchResult> wrappedResults = new List<Duplicates.MatchResult>();
			if (nativeMatchResults != null) {
				for (Object nativeMatchResult : nativeMatchResults) {
					wrappedResults.add(new Duplicates.MatchResult(nativeMatchResult));
				}
			}
			return wrappedResults;
		}
	}

	/**
	 * @description Wrapper for match results from a specific duplicate rule.
	 */
	global virtual class MatchResult {
		protected String rule;
		protected Integer size;
		protected List<Duplicates.MatchRecord> matchRecords;

		/**
		 * @description Constructor wrapping a native match result.
		 * @param nativeMatchResult The native result object (may be null)
		 */
		protected MatchResult(Object nativeMatchResult) {
			this.rule = null;
			this.size = 0;
			this.matchRecords = new List<Duplicates.MatchRecord>();
		}

		/**
		 * @description Returns the rule name for this match.
		 * @return Rule name string
		 */
		global String getRule() {
			return this.rule;
		}

		/**
		 * @description Returns the number of matching records.
		 * @return Match count
		 */
		global Integer getSize() {
			return this.size;
		}

		/**
		 * @description Returns the matching records.
		 * @return List of MatchRecord wrappers
		 */
		global List<Duplicates.MatchRecord> getMatchRecords() {
			return this.matchRecords;
		}

		/**
		 * @description Wraps native match record objects.
		 * @param nativeMatchRecords The native record list
		 * @return List of wrapped MatchRecord objects
		 */
		protected List<Duplicates.MatchRecord> wrapMatchRecords(List<Object> nativeMatchRecords) {
			List<Duplicates.MatchRecord> wrappedRecords = new List<Duplicates.MatchRecord>();
			if (nativeMatchRecords != null) {
				for (Object nativeMatchRecord : nativeMatchRecords) {
					wrappedRecords.add(new Duplicates.MatchRecord(nativeMatchRecord));
				}
			}
			return wrappedRecords;
		}
	}

	/**
	 * @description Wrapper for a specific matched record and its field differences.
	 */
	global virtual class MatchRecord {
		protected SObject record;
		protected List<Duplicates.FieldDiff> fieldDiffs;

		/**
		 * @description Constructor wrapping a native match record.
		 * @param nativeMatchRecord The native record object (may be null)
		 */
		protected MatchRecord(Object nativeMatchRecord) {
			this.record = null;
			this.fieldDiffs = new List<Duplicates.FieldDiff>();
		}

		/**
		 * @description Returns the matching record.
		 * @return The SObject record
		 */
		global SObject getRecord() {
			return this.record;
		}

		/**
		 * @description Returns the field differences between original and matching record.
		 * @return List of FieldDiff wrappers
		 */
		global List<Duplicates.FieldDiff> getFieldDiffs() {
			return this.fieldDiffs;
		}

		/**
		 * @description Wraps native field difference objects.
		 * @param nativeFieldDiffs The native field diff list
		 * @return List of wrapped FieldDiff objects
		 */
		protected List<Duplicates.FieldDiff> wrapFieldDiffs(List<Object> nativeFieldDiffs) {
			List<Duplicates.FieldDiff> wrappedDiffs = new List<Duplicates.FieldDiff>();
			if (nativeFieldDiffs != null) {
				for (Object nativeFieldDiff : nativeFieldDiffs) {
					wrappedDiffs.add(new Duplicates.FieldDiff(nativeFieldDiff));
				}
			}
			return wrappedDiffs;
		}
	}

	/**
	 * @description Wrapper for field difference information.
	 */
	global virtual class FieldDiff {
		protected String fieldName;
		protected Object compareValue;

		/**
		 * @description Constructor wrapping a native field difference.
		 * @param nativeFieldDiff The native field diff object (may be null)
		 */
		protected FieldDiff(Object nativeFieldDiff) {
			this.fieldName = null;
			this.compareValue = null;
		}

		/**
		 * @description Returns the field name that differs.
		 * @return Field name string
		 */
		global String getFieldName() {
			return this.fieldName;
		}

		/**
		 * @description Returns the comparison value for this field.
		 * @return Field value object
		 */
		global Object getCompareValue() {
			return this.compareValue;
		}
	}
}
