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
		return this.initRequest(records)?.process();
	}

	/**
	 * @description Executes duplicate detection on a list of record IDs.
	 * @param recordIds The record IDs to check for duplicates
	 * @return List of FindDuplicatesResult wrapping Datacloud results
	 */
	global List<Duplicates.FindDuplicatesResult> findDuplicates(Iterable<Id> recordIds) {
		List<SObject> records = DatabaseLayer.Utils.SObjects.newSObjects(recordIds);
		return this.initRequest(records)?.process();
	}

	/**
	 * @description Executes duplicate detection on a single SObject record.
	 * @param record The record to check for duplicates
	 * @return FindDuplicatesResult wrapping Datacloud result
	 */
	global Duplicates.FindDuplicatesResult findDuplicates(SObject record) {
		return this.findDuplicates(new List<SObject>{ record })?.get(0);
	}

	/**
	 * @description Executes duplicate detection on a single record ID.
	 * @param recordId The record ID to check for duplicates
	 * @return FindDuplicatesResult wrapping Datacloud result
	 */
	global Duplicates.FindDuplicatesResult findDuplicates(Id recordId) {
		return this.findDuplicates(new List<Id>{ recordId })?.get(0);
	}

	/**
	 * @description Virtual hook for MockDuplicates to override request creation.
	 * @param records The list of SObject records to check for duplicates
	 * @return A configured Request instance
	 */
	protected virtual Duplicates.Request initRequest(List<SObject> records) {
		return new Duplicates.Request(records);
	}

	// **** INNER **** //
	/**
	 * @description Wrapper for additional information maps returned during duplicate detection.
	 * Provides name-value pairs with supplemental matching data.
	 */
	global virtual class AdditionalInformationMap {
		private transient Datacloud.AdditionalInformationMap nativeResult;
		/**
		 * @description The name of the additional information field.
		 */
		global String name {
			get {
				this.name = this.name ?? this.nativeResult?.name;
				return this.name;
			}
			protected set;
		}
		/**
		 * @description The value of the additional information field.
		 */
		global String value {
			get {
				this.value = this.value ?? this.nativeResult?.value;
				return this.value;
			}
			protected set;
		}

		/**
		 * @description Constructor wrapping a native additional information map.
		 * @param nativeResult The native Datacloud additional information map
		 */
		protected AdditionalInformationMap(Datacloud.AdditionalInformationMap nativeResult) {
			this.nativeResult = nativeResult;
		}

		/**
		 * @description Returns the name of the additional information field.
		 * @return The field name
		 */
		global String getName() {
			return this.name;
		}

		/**
		 * @description Returns the value of the additional information field.
		 * @return The field value
		 */
		global String getValue() {
			return this.value;
		}

		/**
		 * @description Returns the underlying native Datacloud additional information map.
		 * @return The wrapped Datacloud.AdditionalInformationMap instance
		 */
		global Datacloud.AdditionalInformationMap toDatacloudType() {
			return this.nativeResult;
		}
	}

	/**
	 * @description Wrapper for duplicate detection result for a specific record.
	 */
	global virtual class DuplicateResult {
		private transient Datacloud.DuplicateResult nativeResult;
		/**
		 * @description Indicates whether saving the record is allowed despite duplicates.
		 */
		global Boolean allowSave {
			get {
				this.allowSave = this.allowSave ?? this.nativeResult?.allowSave;
				return this.allowSave;
			}
			protected set;
		}
		/**
		 * @description The name of the duplicate rule that was evaluated.
		 */
		global String duplicateRule {
			get {
				this.duplicateRule = this.duplicateRule ?? this.nativeResult?.duplicateRule;
				return this.duplicateRule;
			}
			protected set;
		}
		/**
		 * @description The entity type of the duplicate rule.
		 */
		global String duplicateRuleEntityType {
			get {
				this.duplicateRuleEntityType = this.duplicateRuleEntityType ??
					this.nativeResult?.duplicateRuleEntityType;
				return this.duplicateRuleEntityType;
			}
			protected set;
		}
		/**
		 * @description Any error message from the duplicate detection operation.
		 */
		global String errorMessage {
			get {
				this.errorMessage = this.errorMessage ?? this.nativeResult?.errorMessage;
				return this.errorMessage;
			}
			protected set;
		}
		/**
		 * @description List of match results containing matching records and their details.
		 */
		global List<Duplicates.MatchResult> matchResults {
			get {
				this.matchResults = this.matchResults ?? this.wrapMatchResults();
				return this.matchResults;
			}
			protected set;
		}

		/**
		 * @description Returns the underlying native Datacloud duplicate result.
		 * @return The wrapped Datacloud.DuplicateResult instance
		 */
		global Datacloud.DuplicateResult toDatacloudType() {
			return this.nativeResult;
		}

		/**
		 * @description Constructor wrapping a native duplicate result.
		 * @param nativeResult The native Datacloud duplicate result
		 */
		protected DuplicateResult(Datacloud.DuplicateResult nativeResult) {
			this.nativeResult = nativeResult;
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
		 * @description Returns whether the duplicate detection allows saving the record.
		 * @return Boolean indicating if save is allowed
		 */
		global Boolean isAllowSave() {
			return this.allowSave;
		}

		/**
		 * @description Retrieves native match results from the wrapped Datacloud result.
		 * @return List of native Datacloud match results or empty list if null
		 */
		private List<Datacloud.MatchResult> getNativeMatchResults() {
			return this.nativeResult?.matchResults ?? new List<Datacloud.MatchResult>{};
		}

		/**
		 * @description Wraps native match result objects.
		 * @return List of wrapped MatchResult objects
		 */
		private List<Duplicates.MatchResult> wrapMatchResults() {
			List<Duplicates.MatchResult> results = new List<Duplicates.MatchResult>{};
			for (Datacloud.MatchResult result : this.getNativeMatchResults()) {
				results?.add(new Duplicates.MatchResult(result));
			}
			return results;
		}
	}

	/**
	 * @description Wrapper for field difference information.
	 */
	global virtual class FieldDiff {
		private transient Datacloud.FieldDiff nativeResult;
		/**
		 * @description The comparison value showing the difference for this field.
		 */
		global Object difference {
			get {
				this.difference = this.difference ?? this.nativeResult?.difference;
				return this.difference;
			}
			protected set;
		}
		/**
		 * @description The name of the field that differs.
		 */
		global String name {
			get {
				this.name = this.name ?? this.nativeResult?.name;
				return this.name;
			}
			protected set;
		}

		/**
		 * @description Constructor wrapping a native field difference.
		 * @param nativeResult The native Datacloud field diff
		 */
		protected FieldDiff(Datacloud.FieldDiff nativeResult) {
			this.nativeResult = nativeResult;
		}

		/**
		 * @description Returns the comparison value for this field.
		 * @return Field value object
		 */
		global Object getDifference() {
			return this.difference;
		}

		/**
		 * @description Returns the field name that differs.
		 * @return Field name string
		 */
		global String getName() {
			return this.name;
		}

		/**
		 * @description Returns the underlying native Datacloud field diff.
		 * @return The wrapped Datacloud.FieldDiff instance
		 */
		global Datacloud.FieldDiff toDatacloudType() {
			return this.nativeResult;
		}
	}

	/**
	 * @description Mockable wrapper for duplicate detection results.
	 */
	global virtual class FindDuplicatesResult {
		private transient Datacloud.FindDuplicatesResult nativeResult;
		/**
		 * @description List of duplicate results for each record that was checked.
		 */
		global List<Duplicates.DuplicateResult> duplicateResults {
			get {
				this.duplicateResults = this.duplicateResults ?? this.wrapDuplicateResults();
				return this.duplicateResults;
			}
			protected set;
		}
		/**
		 * @description List of errors that occurred during the duplicate detection operation.
		 */
		global List<Database.Error> errors {
			get {
				this.errors = this.errors ?? this.nativeResult?.errors;
				return this.errors;
			}
			protected set;
		}
		/**
		 * @description Indicates whether the duplicate detection operation was successful.
		 */
		global Boolean success {
			get {
				return this.nativeResult?.success ?? this.errors?.isEmpty() != false;
			}
		}

		/**
		 * @description Constructor wrapping a native duplicate detection result.
		 * @param nativeResult The native Datacloud find duplicates result
		 */
		protected FindDuplicatesResult(Datacloud.FindDuplicatesResult nativeResult) {
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
			return this.errors;
		}

		/**
		 * @description Returns whether the operation was successful.
		 * @return Boolean indicating success
		 */
		global Boolean isSuccess() {
			return this.success;
		}

		/**
		 * @description Returns the underlying native Datacloud find duplicates result.
		 * @return The wrapped Datacloud.FindDuplicatesResult instance
		 */
		global Datacloud.FindDuplicatesResult toDatacloudType() {
			return this.nativeResult;
		}

		/**
		 * @description Retrieves native duplicate results from the wrapped Datacloud result.
		 * @return List of native Datacloud duplicate results or empty list if null
		 */
		private List<Datacloud.DuplicateResult> getNativeDuplicateResults() {
			return this.nativeResult?.getDuplicateResults() ?? new List<Datacloud.DuplicateResult>{};
		}

		/**
		 * @description Wraps native duplicate result objects.
		 * @return List of wrapped DuplicateResult objects
		 */
		private List<Duplicates.DuplicateResult> wrapDuplicateResults() {
			List<Duplicates.DuplicateResult> results = new List<Duplicates.DuplicateResult>{};
			for (Datacloud.DuplicateResult result : this.getNativeDuplicateResults()) {
				results?.add(new Duplicates.DuplicateResult(result));
			}
			return results;
		}
	}

	/**
	 * @description Wrapper for a specific matched record and its field differences.
	 */
	global virtual class MatchRecord {
		private transient Datacloud.MatchRecord nativeResult;
		/**
		 * @description Additional information about the match as name-value pairs.
		 */
		global List<Duplicates.AdditionalInformationMap> additionalInformation {
			get {
				this.additionalInformation = this.additionalInformation ?? this.wrapAdditionalInformation();
				return this.additionalInformation;
			}
			protected set;
		}
		/**
		 * @description List of field differences between the original and matching record.
		 */
		global List<Duplicates.FieldDiff> fieldDiffs {
			get {
				this.fieldDiffs = this.fieldDiffs ?? this.wrapFieldDiffs();
				return this.fieldDiffs;
			}
			protected set;
		}
		/**
		 * @description The confidence score for this match.
		 */
		global Decimal matchConfidence {
			get {
				this.matchConfidence = this.matchConfidence ?? this.nativeResult?.matchConfidence;
				return this.matchConfidence;
			}
			protected set;
		}
		/**
		 * @description The matching SObject record.
		 */
		global SObject record {
			get {
				this.record = this.record ?? this.nativeResult?.record;
				return this.record;
			}
			protected set;
		}

		/**
		 * @description Constructor wrapping a native match record.
		 * @param nativeResult The native Datacloud match record
		 */
		protected MatchRecord(Datacloud.MatchRecord nativeResult) {
			this.nativeResult = nativeResult;
		}

		/**
		 * @description Returns additional information about the match.
		 * @return List of additional information objects
		 */
		global List<Duplicates.AdditionalInformationMap> getAdditionalInformation() {
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

		/**
		 * @description Returns the underlying native Datacloud match record.
		 * @return The wrapped Datacloud.MatchRecord instance
		 */
		global Datacloud.MatchRecord toDatacloudType() {
			return this.nativeResult;
		}

		/**
		 * @description Retrieves native additional information from the wrapped Datacloud result.
		 * @return List of native Datacloud additional information maps or empty list if null
		 */
		private List<Datacloud.AdditionalInformationMap> getNativeAdditionalInformation() {
			return this.nativeResult?.additionalinformation ?? new List<Datacloud.AdditionalInformationMap>{};
		}

		/**
		 * @description Retrieves native field diffs from the wrapped Datacloud result.
		 * @return List of native Datacloud field diffs or empty list if null
		 */
		private List<Datacloud.FieldDiff> getNativeFieldDiffs() {
			return this.nativeResult?.fieldDiffs ?? new List<Datacloud.FieldDiff>{};
		}

		/**
		 * @description Wraps native additional information objects.
		 * @return List of wrapped AdditionalInformationMap objects
		 */
		private List<Duplicates.AdditionalInformationMap> wrapAdditionalInformation() {
			List<Duplicates.AdditionalInformationMap> infos = new List<Duplicates.AdditionalInformationMap>{};
			for (Datacloud.AdditionalInformationMap info : this.getNativeAdditionalInformation()) {
				infos?.add(new Duplicates.AdditionalInformationMap(info));
			}
			return infos;
		}

		/**
		 * @description Wraps native field difference objects.
		 * @return List of wrapped FieldDiff objects
		 */
		private List<Duplicates.FieldDiff> wrapFieldDiffs() {
			List<Duplicates.FieldDiff> diffs = new List<Duplicates.FieldDiff>{};
			for (Datacloud.FieldDiff diff : this.getNativeFieldDiffs()) {
				diffs?.add(new Duplicates.FieldDiff(diff));
			}
			return diffs;
		}
	}

	/**
	 * @description Wrapper for match results from a specific duplicate rule.
	 */
	global virtual class MatchResult {
		private transient Datacloud.MatchResult nativeResult;
		/**
		 * @description The entity type for this match result.
		 */
		global String entityType {
			get {
				this.entityType = this.entityType ?? this.nativeResult?.entityType;
				return this.entityType;
			}
			protected set;
		}
		/**
		 * @description List of errors that occurred during matching.
		 */
		global List<Database.Error> errors {
			get {
				this.errors = this.errors ?? this.nativeResult?.errors;
				return this.errors;
			}
			protected set;
		}
		/**
		 * @description The name of the match engine used for this result.
		 */
		global String matchEngine {
			get {
				this.matchEngine = this.matchEngine ?? this.nativeResult?.matchEngine;
				return this.matchEngine;
			}
			protected set;
		}
		/**
		 * @description List of matching records found by this rule.
		 */
		global List<Duplicates.MatchRecord> matchRecords {
			get {
				this.matchRecords = this.matchRecords ?? this.wrapMatchRecords();
				return this.matchRecords;
			}
			protected set;
		}
		/**
		 * @description The name of the duplicate rule that generated this match result.
		 */
		global String rule {
			get {
				this.rule = this.rule ?? this.nativeResult?.rule;
				return this.rule;
			}
			protected set;
		}
		/**
		 * @description The number of matching records found.
		 */
		global Integer size {
			get {
				return this.nativeResult?.getSize() ?? this.matchRecords?.size() ?? 0;
			}
		}
		/**
		 * @description Indicates whether the match operation was successful.
		 */
		global Boolean success {
			get {
				return this.nativeResult?.success ?? this.errors?.isEmpty() != false;
			}
		}

		/**
		 * @description Constructor wrapping a native match result.
		 * @param nativeResult The native Datacloud match result
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
		global Boolean isSuccess() {
			return this.success;
		}

		/**
		 * @description Returns the underlying native Datacloud match result.
		 * @return The wrapped Datacloud.MatchResult instance
		 */
		global Datacloud.MatchResult toDatacloudType() {
			return this.nativeResult;
		}

		/**
		 * @description Retrieves native match records from the wrapped Datacloud result.
		 * @return List of native Datacloud match records or empty list if null
		 */
		private List<Datacloud.MatchRecord> getNativeMatchRecords() {
			return this.nativeResult?.matchRecords ?? new List<Datacloud.MatchRecord>{};
		}

		/**
		 * @description Wraps native match record objects.
		 * @return List of wrapped MatchRecord objects
		 */
		private List<Duplicates.MatchRecord> wrapMatchRecords() {
			List<Duplicates.MatchRecord> records = new List<Duplicates.MatchRecord>{};
			for (Datacloud.MatchRecord record : this.getNativeMatchRecords()) {
				records?.add(new Duplicates.MatchRecord(record));
			}
			return records;
		}
	}

	/**
	 * @description Handles execution of duplicate detection requests against the native Datacloud APIs.
	 */
	public inherited sharing virtual class Request {
		protected List<SObject> records { get; private set; }

		/**
		 * @description Constructor for Request with input data.
		 * @param records The list of SObject records to check for duplicates
		 */
		protected Request(List<SObject> records) {
			this.records = records;
		}

		/**
		 * @description Executes the duplicate detection request against native Datacloud APIs.
		 * @return List of FindDuplicatesResult wrapping native Datacloud results
		 */
		protected virtual List<Duplicates.FindDuplicatesResult> process() {
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
