/**
 * @description Mock implementation of the Duplicates class for testing duplicate detection logic.
 * Provides a fluent API for simulating duplicate record detection results without hitting the database.
 * Allows tests to configure expected duplicate matches, errors, and field differences.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier,PMD.CognitiveComplexity')
@IsTest
global class MockDuplicates extends Duplicates {
	// **** STATIC **** //
	/**
	 * @description The current simulator instance controlling duplicate detection behavior.
	 * Access this property to verify which simulator is configured in tests.
	 */
	global static MockDuplicates.Simulator simulator { get; private set; }

	static {
		MockDuplicates.setMock();
	}

	/**
	 * @description Sets a custom simulator to control duplicate detection behavior in tests
	 * @param simulator The custom simulator implementation
	 * @return The configured simulator instance
	 */
	global static MockDuplicates.Simulator setMock(MockDuplicates.Simulator simulator) {
		MockDuplicates.simulator = simulator;
		return simulator;
	}

	/**
	 * @description Initializes the default BaseSimulator if no custom simulator is configured
	 * @return The BaseSimulator instance
	 */
	global static MockDuplicates.BaseSimulator setMock() {
		if (MockDuplicates.simulator instanceof MockDuplicates.BaseSimulator) {
			// Don't overwrite the base simulator if already configured!
			return (MockDuplicates.BaseSimulator) MockDuplicates.simulator;
		} else {
			MockDuplicates.Simulator baseSimulator = new MockDuplicates.BaseSimulator();
			return (MockDuplicates.BaseSimulator) MockDuplicates.setMock(baseSimulator);
		}
	}

	// **** MEMBER **** //
	/**
	 * @description Constructor for MockDuplicates. Access this via DatabaseLayer.Duplicates after enabling mocks.
	 * @param factory The DatabaseLayer factory instance
	 */
	public MockDuplicates(DatabaseLayer factory) {
		super(factory);
	}

	public override Duplicates.Request initRequest(List<SObject> records) {
		return new MockDuplicates.Request(records);
	}

	// **** INNER **** //
	/**
	 * @description Represents additional information associated with a duplicate match record.
	 * Provides a fluent API for building match metadata with navigation back to parent objects.
	 */
	global class AdditionalInformationMap extends Duplicates.AdditionalInformationMap {
		private transient MockDuplicates.MatchRecord parent;

		private AdditionalInformationMap(MockDuplicates.MatchRecord parent, String name, String value) {
			super(null);
			this.setName(name);
			this.setValue(value);
			this.parent = parent;
		}

		/**
		 * @description Sets the name of this additional information entry
		 * @param name The name to set
		 * @return This instance for method chaining
		 */
		global MockDuplicates.AdditionalInformationMap setName(String name) {
			this.name = name;
			return this;
		}

		/**
		 * @description Sets the value of this additional information entry
		 * @param value The value to set
		 * @return This instance for method chaining
		 */
		global MockDuplicates.AdditionalInformationMap setValue(String value) {
			this.value = value;
			return this;
		}

		/**
		 * @description Navigates back to the top-level FindDuplicatesResult
		 * @return The FindDuplicatesResult instance
		 */
		global MockDuplicates.FindDuplicatesResult toTop() {
			return this.up()?.toTop();
		}

		/**
		 * @description Navigates back to the parent MatchRecord
		 * @return The parent MatchRecord instance
		 */
		global MockDuplicates.MatchRecord up() {
			return this.parent;
		}
	}

	/**
	 * @description Represents the possible FieldDiff.difference values.
	 * @see https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_class_Datacloud_FieldDiff.htm#apex_Datacloud_FieldDiff_getDifference
	 */
	global enum DiffType {
		IS_DIFFERENT,
		IS_NULL,
		IS_SAME
	}

	/**
	 * @description Represents a duplicate rule result with match results and save behavior.
	 * Provides a fluent API for building duplicate detection results for a specific rule.
	 */
	global class DuplicateResult extends Duplicates.DuplicateResult {
		private transient MockDuplicates.FindDuplicatesResult parent;
		private transient SObjectType objectType;

		private DuplicateResult(MockDuplicates.FindDuplicatesResult parent, SObjectType objectType) {
			super(null);
			this.duplicateRuleEntityType = objectType?.toString();
			this.matchResults = new List<Duplicates.MatchResult>{};
			this.objectType = objectType;
			this.parent = parent;
			this.setErrorMessage('Duplicate Alert');
			this.setRuleName('Mock_' + objectType + '_Duplicate_Rule');
			this.setSaveBehavior(MockDuplicates.SaveBehavior.ALLOW);
		}

		/**
		 * @description Adds a match result for a specific record
		 * @param record The SObject record that matches
		 * @return The created MatchResult instance for method chaining
		 */
		global MockDuplicates.MatchResult addMatch() {
			MockDuplicates.MatchResult match = new MockDuplicates.MatchResult(this, this.objectType);
			this.matchResults?.add(match);
			return match;
		}

		/**
		 * @description Removes all match results from this duplicate rule result
		 * @return This instance for method chaining
		 */
		global MockDuplicates.DuplicateResult clearMatches() {
			this.matchResults?.clear();
			return this;
		}

		/**
		 * @description Sets the error message for this duplicate rule result
		 * @param errorMessage The error message to display
		 * @return This instance for method chaining
		 */
		global MockDuplicates.DuplicateResult setErrorMessage(String errorMessage) {
			this.errorMessage = errorMessage;
			return this;
		}

		/**
		 * @description Sets the duplicate rule name
		 * @param ruleName The name of the duplicate rule
		 * @return This instance for method chaining
		 */
		global MockDuplicates.DuplicateResult setRuleName(String ruleName) {
			this.duplicateRule = ruleName;
			return this;
		}

		/**
		 * @description Sets whether records can be saved despite duplicates
		 * @param behavior The save behavior (ALLOW or BLOCK)
		 * @return This instance for method chaining
		 */
		global MockDuplicates.DuplicateResult setSaveBehavior(MockDuplicates.SaveBehavior behavior) {
			this.allowSave = (behavior == MockDuplicates.SaveBehavior.ALLOW);
			return this;
		}

		/**
		 * @description Navigates back to the top-level FindDuplicatesResult
		 * @return The FindDuplicatesResult instance
		 */
		global MockDuplicates.FindDuplicatesResult toTop() {
			return this.up();
		}

		/**
		 * @description Navigates back to the parent FindDuplicatesResult
		 * @return The parent FindDuplicatesResult instance
		 */
		global MockDuplicates.FindDuplicatesResult up() {
			return this.parent;
		}
	}

	/**
	 * @description Represents a field-level difference between records.
	 * Provides a fluent API for specifying how fields differ in duplicate matches.
	 */
	global class FieldDiff extends Duplicates.FieldDiff {
		private transient MockDuplicates.MatchRecord parent;

		private FieldDiff(MockDuplicates.MatchRecord parent, String name, MockDuplicates.DiffType difference) {
			super(null);
			this.parent = parent;
			this.setDifference(difference);
			this.setName(name);
		}

		/**
		 * @description Sets the type of difference for this field
		 * @param difference The difference type (IS_DIFFERENT, IS_NULL, or IS_SAME)
		 * @return This instance for method chaining
		 */
		global MockDuplicates.FieldDiff setDifference(MockDuplicates.DiffType difference) {
			this.difference = difference?.name()?.removeStart('IS_');
			return this;
		}

		/**
		 * @description Sets the API name of the field
		 * @param name The field API name
		 * @return This instance for method chaining
		 */
		global MockDuplicates.FieldDiff setName(String name) {
			this.name = name;
			return this;
		}

		/**
		 * @description Navigates back to the top-level FindDuplicatesResult
		 * @return The FindDuplicatesResult instance
		 */
		global MockDuplicates.FindDuplicatesResult toTop() {
			return this.up()?.toTop();
		}

		/**
		 * @description Navigates back to the parent MatchRecord
		 * @return The parent MatchRecord instance
		 */
		global MockDuplicates.MatchRecord up() {
			return this.parent;
		}
	}

	/**
	 * @description Represents the top-level result of a duplicate detection operation.
	 * Contains duplicate rule results and any errors encountered.
	 */
	global virtual class FindDuplicatesResult extends Duplicates.FindDuplicatesResult {
		private transient SObjectType objectType;

		/**
		 * @description Constructor for FindDuplicatesResult
		 * @param objectType The SObjectType this result applies to
		 */
		global FindDuplicatesResult(SObjectType objectType) {
			super(null);
			this.duplicateResults = new List<Duplicates.DuplicateResult>{};
			this.errors = new List<Database.Error>{};
			this.objectType = objectType;
		}

		/**
		 * @description Adds a duplicate rule result for a specific object type
		 * @param objectType The SObjectType this rule applies to
		 * @return The created DuplicateResult instance for method chaining
		 */
		global MockDuplicates.DuplicateResult addRule(SObjectType objectType) {
			MockDuplicates.DuplicateResult rule = new MockDuplicates.DuplicateResult(this, objectType);
			this.duplicateResults?.add(rule);
			return rule;
		}

		/**
		 * @description Adds a duplicate rule result for the default object type
		 * @return The created DuplicateResult instance for method chaining
		 */
		global MockDuplicates.DuplicateResult addRule() {
			return this.addRule(this.objectType);
		}

		/**
		 * @description Adds an error to the result
		 * @param error The exception to convert to a Database.Error
		 * @return This instance for method chaining
		 */
		global MockDuplicates.FindDuplicatesResult addError(Exception error) {
			Database.Error databaseError = new MockError(error)?.toDatabaseError();
			this.errors?.add(databaseError);
			return this;
		}

		/**
		 * @description Adds a generic HandledException error to the result
		 * @return This instance for method chaining
		 */
		global MockDuplicates.FindDuplicatesResult addError() {
			Exception error = new System.HandledException();
			return this.addError(error);
		}

		/**
		 * @description Removes all errors from the result
		 * @return This instance for method chaining
		 */
		global MockDuplicates.FindDuplicatesResult clearErrors() {
			this.errors?.clear();
			return this;
		}

		/**
		 * @description Removes all duplicate rule results
		 * @return This instance for method chaining
		 */
		global MockDuplicates.FindDuplicatesResult clearDuplicateResults() {
			this.duplicateResults?.clear();
			return this;
		}
	}

	/**
	 * @description Represents a specific matched record in a duplicate detection result.
	 * Contains the record, confidence score, field differences, and additional information.
	 */
	global class MatchRecord extends Duplicates.MatchRecord {
		private transient MockDuplicates.MatchResult parent;

		private MatchRecord(MockDuplicates.MatchResult parent, SObject record) {
			super(null);
			this.additionalInformation = new List<MockDuplicates.AdditionalInformationMap>{};
			this.fieldDiffs = new List<MockDuplicates.FieldDiff>{};
			this.parent = parent;
			this.record = record;
			this.setConfidence(100.0);
		}

		/**
		 * @description Adds additional information metadata to this match record
		 * @param name The name of the additional information
		 * @param value The value of the additional information
		 * @return The created AdditionalInformationMap instance for method chaining
		 */
		global MockDuplicates.AdditionalInformationMap addAdditionalInfo(String name, String value) {
			MockDuplicates.AdditionalInformationMap info = new MockDuplicates.AdditionalInformationMap(
				this,
				name,
				value
			);
			this.additionalInformation?.add(info);
			return info;
		}

		/**
		 * @description Adds a field difference to this match record
		 * @param fieldName The API name of the field
		 * @param difference The type of difference (IS_DIFFERENT, IS_NULL, or IS_SAME)
		 * @return The created FieldDiff instance for method chaining
		 */
		global MockDuplicates.FieldDiff addFieldDiff(String fieldName, MockDuplicates.DiffType difference) {
			MockDuplicates.FieldDiff diff = new MockDuplicates.FieldDiff(this, fieldName, difference);
			this.fieldDiffs?.add(diff);
			return diff;
		}

		/**
		 * @description Removes all additional information from this match record
		 * @return This instance for method chaining
		 */
		global MockDuplicates.MatchRecord clearAdditionalInfo() {
			this.additionalInformation?.clear();
			return this;
		}

		/**
		 * @description Removes all field differences from this match record
		 * @return This instance for method chaining
		 */
		global MockDuplicates.MatchRecord clearFieldDiffs() {
			this.fieldDiffs?.clear();
			return this;
		}

		/**
		 * @description Sets the match confidence score (0-100)
		 * @param confidence The confidence score as a percentage
		 * @return This instance for method chaining
		 */
		global MockDuplicates.MatchRecord setConfidence(Decimal confidence) {
			this.matchConfidence = confidence;
			return this;
		}

		/**
		 * @description Navigates back to the top-level FindDuplicatesResult
		 * @return The FindDuplicatesResult instance
		 */
		global MockDuplicates.FindDuplicatesResult toTop() {
			return this.up()?.toTop();
		}

		/**
		 * @description Navigates back to the parent MatchResult
		 * @return The parent MatchResult instance
		 */
		global MockDuplicates.MatchResult up() {
			return this.parent;
		}
	}

	/**
	 * @description Represents the results from a specific matching rule.
	 * Contains matched records and any errors encountered during matching.
	 */
	global class MatchResult extends Duplicates.MatchResult {
		private transient SObjectType objectType;
		private transient MockDuplicates.DuplicateResult parent;

		/**
		 * @description Constructor for MatchResult
		 * @param parent The parent DuplicateResult instance
		 * @param record The SObject record being matched
		 */
		global MatchResult(MockDuplicates.DuplicateResult parent, SObjectType objectType) {
			super(null);
			this.entityType = objectType?.toString();
			this.errors = new List<Database.Error>{};
			this.matchRecords = new List<Duplicates.MatchRecord>{};
			this.objectType = objectType;
			this.parent = parent;
			this.setMatchEngine('MockMatchEngine');
			this.setRuleName('Mock_' + this.entityType + '_Match_Rule_v1_0');
		}

		/**
		 * @description Adds an error to this match result
		 * @param error The exception to convert to a Database.Error
		 * @return This instance for method chaining
		 */
		global MockDuplicates.MatchResult addError(Exception error) {
			Database.Error databaseError = new MockError(error)?.toDatabaseError();
			this.errors?.add(databaseError);
			return this;
		}

		/**
		 * @description Adds a generic HandledException error to this match result
		 * @return This instance for method chaining
		 */
		global MockDuplicates.MatchResult addError() {
			Exception error = new System.HandledException();
			return this.addError(error);
		}

		/**
		 * @description Adds a matched record to this match result
		 * @param record The SObject that was matched
		 * @return The created MatchRecord instance for method chaining
		 */
		global MockDuplicates.MatchRecord addRecord(SObject record) {
			MockDuplicates.MatchRecord matchRecord = new MockDuplicates.MatchRecord(this, record);
			this.matchRecords?.add(matchRecord);
			return matchRecord;
		}

		/**
		 * @description Adds a matched record using a generated mock SObject
		 * @return The created MatchRecord instance for method chaining
		 */
		global MockDuplicates.MatchRecord addRecord() {
			SObject record = new MockRecord(this.objectType)?.withId()?.toSObject();
			return this.addRecord(record);
		}

		/**
		 * @description Removes all errors from this match result
		 * @return This instance for method chaining
		 */
		global MockDuplicates.MatchResult clearErrors() {
			this.errors?.clear();
			return this;
		}

		/**
		 * @description Removes all matched records from this match result
		 * @return This instance for method chaining
		 */
		global MockDuplicates.MatchResult clearRecords() {
			this.matchRecords?.clear();
			return this;
		}

		/**
		 * @description Sets the matching engine name
		 * @param matchEngine The name of the matching engine
		 * @return This instance for method chaining
		 */
		global MockDuplicates.MatchResult setMatchEngine(String matchEngine) {
			this.matchEngine = matchEngine;
			return this;
		}

		/**
		 * @description Sets the matching rule name
		 * @param ruleName The name of the matching rule
		 * @return This instance for method chaining
		 */
		global MockDuplicates.MatchResult setRuleName(String ruleName) {
			this.rule = ruleName;
			return this;
		}

		/**
		 * @description Navigates back to the top-level FindDuplicatesResult
		 * @return The FindDuplicatesResult instance
		 */
		global MockDuplicates.FindDuplicatesResult toTop() {
			return this.up()?.up();
		}

		/**
		 * @description Navigates back to the parent DuplicateResult
		 * @return The parent DuplicateResult instance
		 */
		global MockDuplicates.DuplicateResult up() {
			return this.parent;
		}
	}

	/**
	 * @description Default simulator implementation that allows callers to inject simple simulation logic.
	 * Provides methods to configure expected FindDuplicatesResults for each SObjectType.
	 */
	global class BaseSimulator implements MockDuplicates.Simulator {
		// Allows callers to inject simple simulation logic for each SObjectType
		private transient Exception exceptionToThrow;
		private transient Map<String, MockDuplicates.FindDuplicatesResult> resultsByType;

		private BaseSimulator() {
			// Can only be constructed from within this file, or by calling MockDuplicates.setMock()
			this.resultsByType = new Map<String, MockDuplicates.FindDuplicatesResult>{};
		}

		/**
		 * @description Retrieves the configured FindDuplicatesResult for an object type
		 * @param objectApiName The API name of the SObject type
		 * @return The configured FindDuplicatesResult, or null if not configured
		 */
		global MockDuplicates.FindDuplicatesResult get(String objectApiName) {
			// Retrieve the FindDuplicateResult configured for the given SObjectType
			// An instance of this result object will be returned for each record of this type
			return this.resultsByType?.get(objectApiName);
		}

		/**
		 * @description Retrieves the configured FindDuplicatesResult for an object type
		 * @param objectType The SObjectType
		 * @return The configured FindDuplicatesResult, or null if not configured
		 */
		global MockDuplicates.FindDuplicatesResult get(SObjectType objectType) {
			String objectApiName = objectType?.toString();
			return this.get(objectApiName);
		}

		/**
		 * @description Configures the simulator to throw an exception
		 * @param error The exception to throw during simulation
		 * @return This instance for method chaining
		 */
		global MockDuplicates.BaseSimulator withException(Exception error) {
			this.exceptionToThrow = error;
			return this;
		}

		/**
		 * @description Configures the simulator to throw a generic HandledException
		 * @return This instance for method chaining
		 */
		global MockDuplicates.BaseSimulator withException() {
			Exception error = new System.HandledException();
			return this.withException(error);
		}

		/**
		 * @description Configures and returns a FindDuplicatesResult for an object type
		 * @param objectType The SObjectType to configure results for
		 * @return This instance for method chaining
		 */
		global MockDuplicates.FindDuplicatesResult withResults(SObjectType objectType) {
			// Define the FindDuplicateResults that will be returned for the current SObjectType
			String objectApiName = objectType?.toString();
			MockDuplicates.FindDuplicatesResult result = this.get(objectApiName) ??
				new MockDuplicates.FindDuplicatesResult(objectType);
			this.resultsByType?.put(objectApiName, result);
			return result;
		}

		/**
		 * @description Simulates duplicate detection for a record
		 * @param record The record to check for duplicates
		 * @return The configured FindDuplicatesResult, or throws an exception if configured
		 */
		public MockDuplicates.FindDuplicatesResult simulate(SObject record) {
			if (this.exceptionToThrow != null) {
				throw this.exceptionToThrow;
			} else {
				SObjectType objectType = record?.getSObjectType();
				return this.get(objectType) ?? new MockDuplicates.FindDuplicatesResult(objectType);
			}
		}
	}

	/**
	 * @description Represents the DuplicateResult's allowSave Boolean in an explicit way.
	 * ALLOW means records can be saved despite duplicates, BLOCK prevents saving.
	 */
	global enum SaveBehavior {
		ALLOW,
		BLOCK
	}

	/**
	 * @description Interface for custom simulator implementations.
	 * Implement this interface to provide custom duplicate detection logic in tests.
	 */
	global interface Simulator {
		/**
		 * @description Simulates duplicate detection for a given record
		 * @param record The SObject record to check for duplicates
		 * @return The FindDuplicatesResult containing simulated duplicate detection results
		 */
		MockDuplicates.FindDuplicatesResult simulate(SObject record);
	}

	private class Request extends Duplicates.Request {
		private transient Set<String> uniqueSObjectTypes;

		private Request(List<SObject> records) {
			super(records);
			this.uniqueSObjectTypes = new Set<String>{};
		}

		public override List<Duplicates.FindDuplicatesResult> process() {
			List<Duplicates.FindDuplicatesResult> results = new List<Duplicates.FindDuplicatesResult>{};
			this.validateInputSize(records);
			for (SObject record : this.records) {
				this.validateSObjectTypes(record);
				Duplicates.FindDuplicatesResult result = MockDuplicates.simulator?.simulate(record);
				results?.add(result);
			}
			return results;
		}

		private void validateInputSize(List<SObject> records) {
			// Mimic standard behavior, which limits the number of inputs between 1-50
			// https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_class_Datacloud_FindDuplicatesResult.htm
			Integer size = records?.size() ?? 0;
			if (size == 0) {
				String msg = 'The list of records to check is null or empty.';
				throw new System.HandledException(msg);
			} else if (size > 50) {
				String msg = 'The number of records to check is greater than the permitted batch size.';
				throw new System.HandledException(msg);
			}
		}

		private void validateSObjectTypes(SObject record) {
			// Mimic standard behavior which restricts mixed SObjectTypes in the same call
			// https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_class_Datacloud_FindDuplicatesResult.htm
			String objectApiName = record?.getSObjectType()?.toString();
			this.uniqueSObjectTypes?.add(objectApiName);
			Integer size = this.uniqueSObjectTypes?.size() ?? 0;
			if (size > 1) {
				String msg = 'The list of records to check contains more than one type of record.';
				throw new System.HandledException(msg);
			}
		}
	}
}
