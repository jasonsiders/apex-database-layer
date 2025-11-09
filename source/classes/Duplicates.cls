/**
 * @description Handles Datacloud duplicate detection operations with mockable API abstraction.
 * Provides wrapper classes that abstract Datacloud duplicate detection APIs for testability.
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
		 * @description Executes the duplicate detection request against native Datacloud APIs.
		 * @return List of FindDuplicatesResult wrapping native Datacloud results
		 */
		protected virtual List<Duplicates.FindDuplicatesResult> execute() {
			if (this.input == null) {
				return new List<Duplicates.FindDuplicatesResult>();
			}

			List<Object> nativeResults;
			if (this.input instanceof List<SObject>) {
				nativeResults = (List<Object>) Datacloud.FindDuplicates.findDuplicates((List<SObject>) this.input);
			} else if (this.input instanceof Iterable<Id>) {
				List<Id> recordIds = new List<Id>();
				for (Id recordId : (Iterable<Id>) this.input) {
					recordIds.add(recordId);
				}
				// Query the records by ID to get SObjects for the API call
				String sObjectType = recordIds[0].getSObjectType().getDescribe().getName();
				String query = 'SELECT Id FROM ' + sObjectType + ' WHERE Id IN :recordIds';
				List<SObject> records = Database.query(query);
				nativeResults = (List<Object>) Datacloud.FindDuplicates.findDuplicates(records);
			} else {
				return new List<Duplicates.FindDuplicatesResult>();
			}

			return this.wrapResults(nativeResults);
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
					String jsonString = JSON.serialize(nativeResult);
					Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
					wrappedResults.add(new Duplicates.FindDuplicatesResult(resultMap));
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
		 * @description Constructor wrapping a native duplicate detection result via JSON deserialization.
		 * @param resultMap Deserialized JSON map of the native result
		 */
		protected FindDuplicatesResult(Map<String, Object> resultMap) {
			if (resultMap != null) {
				this.success = (Boolean) resultMap.get('success');
				this.errors = this.wrapErrors((List<Object>) resultMap.get('errors'));
				this.duplicateResults = this.wrapDuplicateResults((List<Object>) resultMap.get('duplicateResults'));
			} else {
				this.success = false;
				this.errors = new List<Duplicates.Error>();
				this.duplicateResults = new List<Duplicates.DuplicateResult>();
			}
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
					wrappedErrors.add(new Duplicates.Error((Map<String, Object>) nativeError));
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
					wrappedResults.add(new Duplicates.DuplicateResult((Map<String, Object>) nativeDuplicateResult));
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
		 * @description Constructor wrapping a native error via JSON deserialization.
		 * @param errorMap Deserialized JSON map of the native error
		 */
		protected Error(Map<String, Object> errorMap) {
			if (errorMap != null) {
				this.fields = (List<String>) errorMap.get('fields');
				this.message = (String) errorMap.get('message');
				this.statusCode = (String) errorMap.get('statusCode');
			} else {
				this.fields = new List<String>();
				this.message = null;
				this.statusCode = null;
			}
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
		 * @description Constructor wrapping a native duplicate result via JSON deserialization.
		 * @param resultMap Deserialized JSON map of the native result
		 */
		protected DuplicateResult(Map<String, Object> resultMap) {
			if (resultMap != null) {
				Object sObjectData = resultMap.get('sObject');
				if (sObjectData != null) {
					this.record = (SObject) JSON.deserialize(JSON.serialize(sObjectData), SObject.class);
				}
				this.matchResults = this.wrapMatchResults((List<Object>) resultMap.get('matchResults'));
			} else {
				this.record = null;
				this.matchResults = new List<Duplicates.MatchResult>();
			}
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
					wrappedResults.add(new Duplicates.MatchResult((Map<String, Object>) nativeMatchResult));
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
		 * @description Constructor wrapping a native match result via JSON deserialization.
		 * @param resultMap Deserialized JSON map of the native result
		 */
		protected MatchResult(Map<String, Object> resultMap) {
			if (resultMap != null) {
				this.rule = (String) resultMap.get('rule');
				this.size = (Integer) resultMap.get('size');
				this.matchRecords = this.wrapMatchRecords((List<Object>) resultMap.get('matchRecords'));
			} else {
				this.rule = null;
				this.size = 0;
				this.matchRecords = new List<Duplicates.MatchRecord>();
			}
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
					wrappedRecords.add(new Duplicates.MatchRecord((Map<String, Object>) nativeMatchRecord));
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
		 * @description Constructor wrapping a native match record via JSON deserialization.
		 * @param recordMap Deserialized JSON map of the native record
		 */
		protected MatchRecord(Map<String, Object> recordMap) {
			if (recordMap != null) {
				Object sObjectData = recordMap.get('sObject');
				if (sObjectData != null) {
					this.record = (SObject) JSON.deserialize(JSON.serialize(sObjectData), SObject.class);
				}
				this.fieldDiffs = this.wrapFieldDiffs((List<Object>) recordMap.get('fieldDiffs'));
			} else {
				this.record = null;
				this.fieldDiffs = new List<Duplicates.FieldDiff>();
			}
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
					wrappedDiffs.add(new Duplicates.FieldDiff((Map<String, Object>) nativeFieldDiff));
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
		 * @description Constructor wrapping a native field difference via JSON deserialization.
		 * @param diffMap Deserialized JSON map of the native field diff
		 */
		protected FieldDiff(Map<String, Object> diffMap) {
			if (diffMap != null) {
				this.fieldName = (String) diffMap.get('fieldName');
				this.compareValue = diffMap.get('compareValue');
			} else {
				this.fieldName = null;
				this.compareValue = null;
			}
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
