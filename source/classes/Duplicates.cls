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
		return this.initRequest(records)?.execute();
	}

	/**
	 * @description Executes duplicate detection on a list of record IDs.
	 * @param recordIds The record IDs to check for duplicates
	 * @return List of FindDuplicatesResult wrapping Datacloud results
	 */
	global List<Duplicates.FindDuplicatesResult> findDuplicates(Iterable<Id> recordIds) {
		List<SObject> records = DatabaseLayer.Utils.SObjects.newSObjects(recordIds);
		return this.initRequest(records)?.execute();
	}

	/**
	 * @description Virtual hook for MockDuplicates to override request creation.
	 * @param input The input (either List<SObject> or Iterable<Id>)
	 * @return A configured Request instance
	 */
	protected virtual Duplicates.Request initRequest(List<SObject> records) {
		return new Duplicates.Request(records);
	}

	// **** INNER **** //
	/**
	 * @description Wrapper for duplicate detection result for a specific record.
	 */
	global virtual class DuplicateResult {
		private transient Datacloud.DuplicateResult nativeResult;
		global Boolean allowSave {
			get {
				return this.allowSave ?? this.nativeResult?.allowSave;
			}
			protected set;
		}
		global String duplicateRule {
			get {
				return this.duplicateRule ?? this.nativeResult?.duplicateRule;
			}
			protected set;
		}
		global String duplicateRuleEntityType {
			get {
				return this.duplicateRuleEntityType ?? this.nativeResult?.duplicateRuleEntityType;
			}
			protected set;
		}
		global String errorMessage {
			get {
				return this.errorMessage ?? this.nativeResult?.errorMessage;
			}
			protected set;
		}
		global List<Duplicates.MatchResult> matchResults {
			get {
				return this.matchResults ?? this.wrapMatchResults();
			}
			protected set;
		}
		global SObject record {
			get {
				return this.record ?? this.nativeResult?.record;
			}
			protected set;
		}

		/**
		 * @description Constructor wrapping a native duplicate result via JSON deserialization.
		 * @param resultMap Deserialized JSON map of the native result
		 */
		protected DuplicateResult(Datacloud.DuplicateResult nativeResult) {
			this();
			this.nativeResult = nativeResult;
		}

		/**
		 * @description Returns whether the duplicate detection allows saving the record.
		 * @return Boolean indicating if save is allowed
		 */
		global Boolean getAllowSave() {
			return this.allowSave;
		}

		/**
		 * @description Returns the name of the duplicate rule that was evaluated.
		 * @return Duplicate rule name
		 */
		global String getDuplicateRule() {
			return this.duplicateRule;
		}

		/**
		 * @description Returns the entity type of the duplicate rule.
		 * @return Duplicate rule entity type
		 */
		global String getDuplicateRuleEntityType() {
			return this.duplicateRuleEntityType;
		}

		/**
		 * @description Returns any error message from the duplicate detection.
		 * @return Error message string
		 */
		global String getErrorMessage() {
			return this.errorMessage;
		}

		/**
		 * @description Returns the match results for this record.
		 * @return List of MatchResult wrappers
		 */
		global List<Duplicates.MatchResult> getMatchResults() {
			return this.matchResults;
		}

		/**
		 * @description Returns the record being checked for duplicates.
		 * @return The SObject record
		 */
		global SObject getRecord() {
			return this.record;
		}

		/**
		 * @description Wraps native match result objects.
		 * @param nativeMatchResults The native result list
		 * @return List of wrapped MatchResult objects
		 */
		private List<Duplicates.MatchResult> wrapMatchResults() {
			List<Duplicates.MatchResult> wrappedResults = new List<Duplicates.MatchResult>{};
			List<Datacloud.MatchResult> nativeResults = this.nativeResult?.matchResults ?? new List<Datacloud.MatchResult>{};
			for (Datacloud.MatchResult nativeResult : nativeMatchResults) {
				Duplicates.MatchResult wrappedResult = new Duplicates.MatchResult(nativeResult);
				wrappedResults?.add(wrappedResult);
			}
			return wrappedResults;
		}
	}

	/**
	 * @description Wrapper for field difference information.
	 */
	global virtual class FieldDiff {
		private transient Datacloud.FieldDiff nativeResult;
		global Object compareValue {
			get {
				return this.compareValue ?? this.nativeResult?.compareValue;
			}
			protected set;
		}
		global String fieldName {
			get {
				return this.fieldName ?? this.nativeResult?.fieldName;
			}
			protected set;
		}

		/**
		 * @description Constructor wrapping a native field difference via JSON deserialization.
		 * @param diffMap Deserialized JSON map of the native field diff
		 */
		protected FieldDiff(Datacloud.FieldDiff nativeResult) {
			if (diffMap != null) {
				this.fieldName = (String) diffMap.get('name');
				this.compareValue = diffMap.get('difference');
			} else {
				this.fieldName = null;
				this.compareValue = null;
			}
		}

		/**
		 * @description Returns the comparison value for this field.
		 * @return Field value object
		 */
		global Object getCompareValue() {
			return this.compareValue;
		}

		/**
		 * @description Returns the field name that differs.
		 * @return Field name string
		 */
		global String getFieldName() {
			return this.fieldName;
		}
	}

	/**
	 * @description Mockable wrapper for duplicate detection results.
	 */
	global virtual class FindDuplicatesResult {
		private transient Datacloud.FindDuplicatesResult nativeResult;
		global List<Duplicates.DuplicateResult> duplicateResults {
			get {
				this.duplicateResults ?? this.wrapDuplicateResults();
			}
			protected set;
		}
		global List<Database.Error> errors {
			get {
				return this.errors ?? this.nativeResult?.errors; 
			}
			protected set;
		}
		global Boolean success {
			get {
				return this.success ?? this.nativeResult?.success;
			}
			protected set;
		}

		/**
		 * @description Constructor wrapping a native duplicate detection result via JSON deserialization.
		 * @param resultMap Deserialized JSON map of the native result
		 */
		protected FindDuplicatesResult(Datacloud.FindDuplicatesResult nativeResult) {
			this();
			this.nativeResult = nativeResult;
		}

		/**
		 * @description Returns the duplicate detection results.
		 * @return List of DuplicateResult wrappers
		 */
		global List<Duplicates.DuplicateResult> getDuplicateResults() {
			return this.duplicateResults;
		}

		/**
		 * @description Returns any errors that occurred during the operation.
		 * @return List of Error wrappers
		 */
		global List<Database.Error> getErrors() {
			return this.nativeResult;
		}

		/**
		 * @description Returns whether the operation was successful.
		 * @return Boolean indicating success
		 */
		global Boolean getSuccess() {
			return this.success;
		}

		/**
		 * @description Wraps native duplicate result objects.
		 * @param nativeDuplicateResults The native result list
		 * @return List of wrapped DuplicateResult objects
		 */
		private List<Duplicates.DuplicateResult> wrapDuplicateResults() {
			List<Duplicates.DuplicateResult> wrappedResults = new List<Duplicates.DuplicateResult>{};
			List<Datacloud.DuplicateResult> nativeResults = this.nativeResult?.getDuplicateResults() ?? new List<Datacloud.DuplicateResult>{};
			for (Datacloud.DuplicateResult nativeResult : nativeResults) {
				Duplicates.DuplicateResult wrappedResult = new Duplicates.DuplicateResult(nativeResult);
				wrappedResults.add(wrappedResult);
			}
			return wrappedResults;
		}
	}

	/**
	 * @description Wrapper for a specific matched record and its field differences.
	 */
	global virtual class MatchRecord {
		private transient Datacloud.MatchRecord nativeResult;
		global List<Datacloud.AdditionalInformationMap> additionalInformation {
			get {
				return this.additionalInformation ?? this.wrapAdditionalInformation();
			}
			protected set;
		}
		global List<Duplicates.FieldDiff> fieldDiffs {
			get {
				return this.fieldDiffs ?? this.wrapFieldDiffs();
			}
			protected set;
		}
		global Decimal matchConfidence {
			get {
				return this.matchConfidence ?? this.nativeResult?.matchConfidence;
			}
			protected set;
		}
		global SObject record {
			get {
				return this.record ?? this.nativeResult?.record;
			} 
			protected set;
		}

		/**
		 * @description Constructor wrapping a native match record via JSON deserialization.
		 * @param recordMap Deserialized JSON map of the native record
		 */
		protected MatchRecord(Datacloud.MatchRecord nativeResult) {
			this.nativeResult = nativeResult;
		}

		/**
		 * @description Returns additional information about the match.
		 * @return List of additional information objects
		 */
		global List<Object> getAdditionalInformation() {
			return this.additionalInformation;
		}

		/**
		 * @description Returns the field differences between original and matching record.
		 * @return List of FieldDiff wrappers
		 */
		global List<Duplicates.FieldDiff> getFieldDiffs() {
			return this.fieldDiffs;
		}

		/**
		 * @description Returns the match confidence score.
		 * @return Match confidence as Decimal
		 */
		global Decimal getMatchConfidence() {
			return this.matchConfidence;
		}

		/**
		 * @description Returns the matching record.
		 * @return The SObject record
		 */
		global SObject getRecord() {
			return this.record;
		}

		private List<Duplicates.AdditionalInformationMap> wrapAdditionalInformation() {
			List<Duplicates.AdditionalInformationMap> wrappedResults = new List<Duplicates.AdditionalInformationMap>{};
			List<Datacloud.AdditionalInformationMap> nativeResults = this.nativeResult?.additionalinformation ?? new List<Datacloud.AdditionalInformationMap>{};
			for (Datacloud.AdditionalInformationMap nativeResult : nativeResults) {
				Duplicates.AdditionalInformationMap wrappedResult = new Duplicates.AdditionalInformationMap(nativeResult); 
				wrappedResults?.add(wrappedResult);
			}
			return wrappedResults;
		}

		/**
		 * @description Wraps native field difference objects.
		 * @param nativeFieldDiffs The native field diff list
		 * @return List of wrapped FieldDiff objects
		 */
		private List<Duplicates.FieldDiff> wrapFieldDiffs() {
			List<Duplicates.FieldDiff> wrappedDiffs = new List<Duplicates.FieldDiff>{};
			List<Datacloud.FieldDiff> nativeDiffs = this.nativeRecord?.fieldDiffs ?? new List<Datacloud.FieldDiff>{};
			for (Datacloud.FieldDiff nativeDiff : nativeDiffs) {
				Duplicates.FieldDiff wrappedDiff = new Duplicates.FieldDiff(nativeDiff);
				wrappedDiffs?.add(wrappedDiff);
			}
			return wrappedDiffs;
		}
	}

	/**
	 * @description Wrapper for match results from a specific duplicate rule.
	 */
	global virtual class MatchResult {
		private transient Datacloud.MatchResult nativeResult;
		global String entityType {
			get {
				return this.entityType ?? this.nativeResult?.entityType;
			} 
			protected set;
		}
		global List<Database.Error> errors {
			get {
				return this.errors ?? this.nativeResult?.errors;
			}
			protected set;
		}
		global String matchEngine {
			get {
				return this.matchEngine ?? this.nativeResult?.matchEngine;
			}
			protected set;
		}
		global List<Duplicates.MatchRecord> matchRecords {
			get {
				return this.matchRecords ?? this.wrapMatchRecords();
			}
			protected set;
		}
		global String rule {
			get {
				return this.rule ?? this.nativeResult?.rule;
			}
			protected set; 
		}
		global Integer size {
			get {
				return this.size ?? this.nativeResult?.size();
			}
			protected set;
		}
		global Boolean success {
			get {
				return this.success ?? this.nativeResult?.success;
			}
			protected set;
		}

		/**
		 * @description Constructor wrapping a native match result via JSON deserialization.
		 * @param resultMap Deserialized JSON map of the native result
		 */
		protected MatchResult(Datacloud.MatchResult nativeResult) {
			this.nativeResult = nativeResult;
		}

		/**
		 * @description Returns the entity type for this match result.
		 * @return Entity type string
		 */
		global String getEntityType() {
			return this.entityType;
		}

		/**
		 * @description Returns any errors that occurred during matching.
		 * @return List of Error wrappers
		 */
		global List<Database.Error> getErrors() {
			return this.errors;
		}

		/**
		 * @description Returns the match engine used for this result.
		 * @return Match engine name
		 */
		global String getMatchEngine() {
			return this.matchEngine;
		}

		/**
		 * @description Returns the matching records.
		 * @return List of MatchRecord wrappers
		 */
		global List<Duplicates.MatchRecord> getMatchRecords() {
			return this.matchRecords;
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
		 * @description Returns whether the match operation was successful.
		 * @return Boolean indicating success
		 */
		global Boolean getSuccess() {
			return this.success;
		}

		/**
		 * @description Wraps native match record objects.
		 * @param nativeMatchRecords The native record list
		 * @return List of wrapped MatchRecord objects
		 */
		private List<Duplicates.MatchRecord> wrapMatchRecords() {
			List<Duplicates.MatchRecord> wrappedRecords = new List<Duplicates.MatchRecord>{};
			List<Datacloud.MatchRecord> nativeRecords = this.nativeResult?.matchRecords ?? new List<Datacloud.MatchRecord>{};
			for (Datacloud.MatchRecord nativeRecord : nativeRecord) {
				Duplicates.MatchRecord wrappedRecord = new Duplicates.MatchRecord(nativeRecord);
				wrappedRecords?.add(wrappedRecord);
			}
			return wrappedRecords;
		}
	}

	/**
	 * @description Handles execution of duplicate detection requests against the native Datacloud APIs.
	 */
	protected inherited sharing virtual class Request {
		protected List<SObject> records { get; private set; }

		/**
		 * @description Constructor for Request with input data.
		 * @param input The input (either List<SObject> or Iterable<Id>)
		 */
		protected Request(List<SObject> records) {
			this.records = records;
		}

		/**
		 * @description Executes the duplicate detection request against native Datacloud APIs.
		 * @return List of FindDuplicatesResult wrapping native Datacloud results
		 */
		protected virtual List<Duplicates.FindDuplicatesResult> execute() {
			List<Datacloud.FindDuplicatesResult> nativeResults = Datacloud.FindDuplicates.findDuplicates(this.records);
			List<Duplicates.FindDuplicatesResult> wrappedResults = this.wrap(nativeResults);
			return wrappedResults;
		}

		/**
		 * @description Wraps native results in mockable wrapper classes.
		 * @param nativeResults The native result list (if available)
		 * @return List of wrapped FindDuplicatesResult objects
		 */
		private List<Duplicates.FindDuplicatesResult> wrap(List<Datacloud.FindDuplicatesResult> nativeResults) {
			List<Duplicates.FindDuplicatesResult> wrappedResults = new List<Duplicates.FindDuplicatesResult>{};
			for (Datacloud.FindDuplicatesResult nativeResult : nativeResults) {
				Duplicates.FindDuplicatesResult wrappedResult = new Duplicates.FindDuplicatesResult(nativeResult);
				wrappedResults?.add(wrappedResult);
			}
			return wrappedResults;
		}
	}
}
