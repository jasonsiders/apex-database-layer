@SuppressWarnings('PMD.AvoidGlobalModifier')
// @IsTest
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

	global static MockDuplicates.ResponseBuilder setMock() {
		MockDuplicates.ResponseBuilder defaultSimulator = new MockDuplicates.ResponseBuilder();
		return (MockDuplicates.ResponseBuilder) MockDuplicates.setMock(defaultSimulator);
	}

	// **** MEMBER **** //
	@SuppressWarnings('PMD.EmptyStatementBlock')
	public MockDuplicates(DatabaseLayer factory) {
        super(factory);
	}

	public override Duplicates.Request initRequest(List<SObject> records) {
		return new MockDuplicates.Request(records);
	}

	// **** INNER **** //
	global class DuplicateResult extends Duplicates.DuplicateResult {
		private transient MockDuplicates.FindDuplicatesResult parent;
		private transient SObjectType objectType; 

		global DuplicateResult(MockDuplicates.FindDuplicatesResult parent, SObjectType objectType) {
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
			MockDuplicates.MatchResult match = new MockDuplicates.MatchResult(record);
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

		global MockDuplicates.FindDuplicatesResult toParent() {
			return this.parent; 
		}
	}

	global class FindDuplicatesResult extends Duplicates.FindDuplicatesResult {
		private transient SObjectType objectType; 

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
	} 

	global class MatchResult extends Duplicates.MatchResult {
		global MatchResult(SObject record) {
			// TODO:
			super(null);
		}
	}

	global class ResponseBuilder implements MockDuplicates.Simulator {
		// Constructs the data structure for a single SObject passed to findDuplicates

		@SuppressWarnings('PMD.EmptyStatementBlock')
		private ResponseBuilder() {
			// Can only be constructed from within this file, or by calling MockDuplicates.setMock()
		}

		public Duplicates.FindDuplicatesResult simulate(SObject record) {
			return new MockDuplicates.FindDuplicatesResult(record);
		}
	}

	private class Request extends Duplicates.Request {
		private Request(List<SObject> records) {
			super(records);
		}

		public override List<Duplicates.FindDuplicatesResult> process() {
			List<Duplicates.FindDuplicatesResult> results = new List<Duplicates.FindDuplicatesResult>{};
			this.validateInput();
			for (SObject record : this.records) {
				Duplicates.FindDuplicatesResult result = MockDuplicates.simulator?.simulate(record);
				results?.add(result);
			}
			return results;
		}

		private void validateInput() {
			// Make sure the input list is within acceptable bounds:
			// Between 1 and 50 records
			// Must all of the same SObjectType
			// https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_class_Datacloud_FindDuplicatesResult.htm
		}
	}

	// Represents the DuplicateResult's allowSave Boolean, to be more explicit
	global enum SaveBehavior {
		ALLOW,
		BLOCK
	}

	global interface Simulator {
		Duplicates.FindDuplicatesResult simulate(SObject record);
	}
}