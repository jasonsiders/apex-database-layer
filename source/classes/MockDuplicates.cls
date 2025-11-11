@SuppressWarnings('PMD.AvoidGlobalModifier,PMD.CognitiveComplexity')
@IsTest
global class MockDuplicates extends Duplicates {
	// **** STATIC **** //
	private static Simulator simulator;

	static {
		MockDuplicates.setMock();
	}

	global static MockDuplicates.Simulator setMock(MockDuplicates.Simulator simulator) {
		MockDuplicates.simulator = simulator;
		return simulator;
	}

	global static MockDuplicates.BaseSimulator setMock() {
		MockDuplicates.BaseSimulator defaultSimulator = new MockDuplicates.BaseSimulator();
		return (MockDuplicates.BaseSimulator) MockDuplicates.setMock(defaultSimulator);
	}

	// **** MEMBER **** //
	public MockDuplicates(DatabaseLayer factory) {
		super(factory);
	}

	public override Duplicates.Request initRequest(List<SObject> records) {
		return new MockDuplicates.Request(records);
	}

	// **** INNER **** //
	global class AdditionalInformationMap extends Duplicates.AdditionalInformationMap {
		private transient MockDuplicates.MatchRecord parent;

		private AdditionalInformationMap(MockDuplicates.MatchRecord parent, String name, String value) {
			super(null);
			this.parent = parent;
			this.setName(name);
			this.setValue(value);
		}

		global MockDuplicates.AdditionalInformationMap setName(String name) {
			this.name = name;
			return this;
		}

		global MockDuplicates.AdditionalInformationMap setValue(String value) {
			this.value = value;
			return this;
		}

		global MockDuplicates.FindDuplicatesResult toTop() {
			return this.up()?.toTop();
		}

		global MockDuplicates.MatchRecord up() {
			return this.parent;
		}
	}

	// Represent the possible FieldDiff.difference values, as documented here:
	// https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_class_Datacloud_FieldDiff.htm#apex_Datacloud_FieldDiff_getDifference
	global enum DiffType {
		IS_DIFFERENT,
		IS_NULL,
		IS_SAME
	}

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

		global MockDuplicates.MatchResult addMatch(SObject record) {
			MockDuplicates.MatchResult match = new MockDuplicates.MatchResult(this, record);
			this.matchResults?.add(match);
			return match;
		}

		global MockDuplicates.MatchResult addMatch() {
			// Construct a match using the mock database
			SObject record = new MockRecord(this.objectType)?.withId()?.toSObject();
			return this.addMatch(record);
		}

		global MockDuplicates.DuplicateResult setErrorMessage(String errorMessage) {
			this.errorMessage = errorMessage;
			return this;
		}

		global MockDuplicates.DuplicateResult setRuleName(String ruleName) {
			this.duplicateRule = ruleName;
			return this;
		}

		global MockDuplicates.DuplicateResult setSaveBehavior(MockDuplicates.SaveBehavior behavior) {
			this.allowSave = (behavior == MockDuplicates.SaveBehavior.ALLOW);
			return this;
		}

		global MockDuplicates.FindDuplicatesResult toTop() {
			return this.up();
		}

		global MockDuplicates.FindDuplicatesResult up() {
			return this.parent;
		}
	}

	global class FieldDiff extends Duplicates.FieldDiff {
		private transient MockDuplicates.MatchRecord parent;

		private FieldDiff(MockDuplicates.MatchRecord parent, String name, MockDuplicates.DiffType difference) {
			super(null);
			this.parent = parent;
			this.setDifference(difference);
			this.setName(name);
		}

		global MockDuplicates.FieldDiff setDifference(MockDuplicates.DiffType difference) {
			this.difference = difference?.name()?.removeStart('IS_');
			return this;
		}

		global MockDuplicates.FieldDiff setName(String name) {
			this.name = name;
			return this;
		}

		global MockDuplicates.FindDuplicatesResult toTop() {
			return this.up()?.toTop();
		}

		global MockDuplicates.MatchRecord up() {
			return this.parent;
		}
	}

	global virtual class FindDuplicatesResult extends Duplicates.FindDuplicatesResult {
		private transient SObjectType objectType;

		// TODO: Should this be private?
		global FindDuplicatesResult(SObject record) {
			super(null);
			this.duplicateResults = new List<Duplicates.DuplicateResult>{};
			this.errors = new List<Database.Error>{};
			this.objectType = record?.getSObjectType();
		}

		global MockDuplicates.DuplicateResult addRule(SObjectType objectType) {
			MockDuplicates.DuplicateResult rule = new MockDuplicates.DuplicateResult(this, objectType);
			this.duplicateResults?.add(rule);
			return rule;
		}

		global MockDuplicates.DuplicateResult addRule() {
			return this.addRule(this.objectType);
		}

		global MockDuplicates.FindDuplicatesResult addError(Exception error) {
			Database.Error databaseError = new MockError(error)?.toDatabaseError();
			this.errors?.add(databaseError);
			return this;
		}

		global MockDuplicates.FindDuplicatesResult addError() {
			Exception error = new System.DmlException();
			return this.addError(error);
		}

		global MockDuplicates.FindDuplicatesResult throwException(Exception error) {
			throw error;
		}

		global MockDuplicates.FindDuplicatesResult throwException() {
			throw new System.HandledException();
		}
	}

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

		global MockDuplicates.AdditionalInformationMap addInfo(String name, String value) {
			MockDuplicates.AdditionalInformationMap info = new MockDuplicates.AdditionalInformationMap(
				this,
				name,
				value
			);
			this.additionalInformation?.add(info);
			return info;
		}

		global MockDuplicates.FieldDiff addFieldDiff(String fieldName, MockDuplicates.DiffType difference) {
			MockDuplicates.FieldDiff diff = new MockDuplicates.FieldDiff(this, fieldName, difference);
			this.fieldDiffs?.add(diff);
			return diff;
		}

		global MockDuplicates.MatchRecord clearAdditionalInfo() {
			this.additionalInformation?.clear();
			return this;
		}

		global MockDuplicates.MatchRecord clearFieldDiffs() {
			this.fieldDiffs?.clear();
			return this;
		}

		global MockDuplicates.MatchRecord setConfidence(Decimal confidence) {
			this.matchConfidence = confidence;
			return this;
		}

		global MockDuplicates.FindDuplicatesResult toTop() {
			return this.up()?.toTop();
		}

		global MockDuplicates.MatchResult up() {
			return this.parent;
		}
	}

	global class MatchResult extends Duplicates.MatchResult {
		private transient SObjectType objectType;
		private transient MockDuplicates.DuplicateResult parent;

		global MatchResult(MockDuplicates.DuplicateResult parent, SObject record) {
			super(null);
			this.objectType = record?.getSObjectType();
			this.entityType = this.objectType?.toString();
			this.errors = new List<Database.Error>{};
			this.matchRecords = new List<Duplicates.MatchRecord>{};
			this.parent = parent;
			this.setMatchEngine('MockMatchEngine');
			this.setRuleName('Mock_' + this.entityType + '_Match_Rule_v1_0');
		}

		global MockDuplicates.MatchRecord addRecord(SObject record) {
			MockDuplicates.MatchRecord matchRecord = new MockDuplicates.MatchRecord(this, record);
			this.matchRecords?.add(matchRecord);
			return matchRecord;
		}

		global MockDuplicates.MatchRecord addRecord() {
			SObject record = new MockRecord(this.objectType)?.withId()?.toSObject();
			return this.addRecord(record);
		}

		global MockDuplicates.MatchResult setMatchEngine(String matchEngine) {
			this.matchEngine = matchEngine;
			return this;
		}

		global MockDuplicates.MatchResult setRuleName(String ruleName) {
			this.rule = rule;
			return this;
		}

		global MockDuplicates.FindDuplicatesResult toTop() {
			return this.up()?.up();
		}

		global MockDuplicates.DuplicateResult up() {
			return this.parent;
		}
	}

	global class BaseSimulator implements MockDuplicates.Simulator {
		// * TODO: Figure out how we want callers to use this...

		@SuppressWarnings('PMD.EmptyStatementBlock')
		private BaseSimulator() {
			// Can only be constructed from within this file, or by calling MockDuplicates.setMock()
		}

		public MockDuplicates.FindDuplicatesResult simulate(SObject record) {
			return new MockDuplicates.FindDuplicatesResult(record);
		}
	}

	// Represents the DuplicateResult's allowSave Boolean, to be more explicit
	global enum SaveBehavior {
		ALLOW,
		BLOCK
	}

	global interface Simulator {
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
