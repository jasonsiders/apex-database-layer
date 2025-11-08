/**
 * @description Mock implementation of Duplicates for testing. Provides configurable result simulation and global/instance-level mock management.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
@IsTest
global class MockDuplicates extends Duplicates {
	private static MockDuplicates.Simulator globalSimulator;

	/**
	 * @description Constructor for MockDuplicates instance.
	 * @param factory The DatabaseLayer factory instance
	 */
	public MockDuplicates(DatabaseLayer factory) {
		super(factory);
	}

	// **** STATIC **** //
	/**
	 * @description Sets a global mock simulator to be used for all duplicate operations.
	 * @param simulator The simulator to use for mocking
	 * @return The configured simulator instance
	 */
	global static MockDuplicates.Simulator setGlobalMock(MockDuplicates.Simulator simulator) {
		MockDuplicates.globalSimulator = simulator;
		return simulator;
	}

	/**
	 * @description Creates and sets a new StaticResults global mock with fluent interface.
	 * @return A StaticResults instance for method chaining
	 */
	global static MockDuplicates.StaticResults setGlobalMock() {
		return (MockDuplicates.StaticResults) MockDuplicates.setGlobalMock(new MockDuplicates.StaticResults());
	}

	// **** MEMBER **** //

	/**
	 * @description Overrides request initialization to inject mock simulator.
	 * @param input The input (either List<SObject> or Iterable<Id>)
	 * @return A mock-configured Request instance
	 */
	protected override Duplicates.Request initRequest(Object input) {
		return new MockDuplicates.Request(input, MockDuplicates.globalSimulator);
	}

	// **** INNER CLASSES **** //

	/**
	 * @description Interface for simulating duplicate detection behavior.
	 */
	global interface Simulator {
		/**
		 * @description Simulates duplicate detection for the given input.
		 * @param input The input (either List<SObject> or Iterable<Id>)
		 * @return Simulated FindDuplicatesResult list
		 */
		List<Duplicates.FindDuplicatesResult> simulate(Object input);
	}

	/**
	 * @description Static results simulator for returning predefined duplicate detection results.
	 */
	global class StaticResults implements MockDuplicates.Simulator {
		private List<Duplicates.FindDuplicatesResult> results = new List<Duplicates.FindDuplicatesResult>();
		private Exception error;

		/**
		 * @description Adds a single result to the simulated results.
		 * @param result The result to add
		 * @return This StaticResults instance for method chaining
		 */
		global StaticResults withResult(Duplicates.FindDuplicatesResult result) {
			if (result != null) {
				this.results.add(result);
			}
			return this;
		}

		/**
		 * @description Sets the complete list of simulated results.
		 * @param results The results to set
		 * @return This StaticResults instance for method chaining
		 */
		global StaticResults withResults(List<Duplicates.FindDuplicatesResult> results) {
			this.results = results ?? new List<Duplicates.FindDuplicatesResult>();
			return this;
		}

		/**
		 * @description Sets an exception to be thrown when simulate is called.
		 * @param error The exception to throw
		 * @return This StaticResults instance for method chaining
		 */
		global StaticResults withError(Exception error) {
			this.error = error;
			return this;
		}

		/**
		 * @description Simulates duplicate detection by returning predefined results or throwing an error.
		 * @param input The input (not used in static results)
		 * @return The configured results list
		 */
		global List<Duplicates.FindDuplicatesResult> simulate(Object input) {
			if (this.error != null) {
				throw this.error;
			}
			return this.results;
		}
	}

	/**
	 * @description Mock Request that uses a simulator instead of calling real Datacloud APIs.
	 */
	public class Request extends Duplicates.Request {
		private MockDuplicates.Simulator simulator;

		/**
		 * @description Constructor for mock request with simulator.
		 * @param input The input (either List<SObject> or Iterable<Id>)
		 * @param simulator The simulator to use
		 */
		private Request(Object input, MockDuplicates.Simulator simulator) {
			super(input);
			this.simulator = simulator;
		}

		/**
		 * @description Executes the mock duplicate detection by delegating to the simulator.
		 * @return Simulated FindDuplicatesResult list
		 */
		protected override List<Duplicates.FindDuplicatesResult> execute() {
			return (this.simulator != null)
				? this.simulator.simulate(this.input)
				: new List<Duplicates.FindDuplicatesResult>();
		}
	}

	/**
	 * @description Mock wrapper for FindDuplicatesResult with builder support.
	 */
	global class FindDuplicatesResult extends Duplicates.FindDuplicatesResult {
		/**
		 * @description Constructor for empty mock FindDuplicatesResult.
		 */
		global FindDuplicatesResult() {
			super(null);
			this.success = false;
			this.errors = new List<Duplicates.Error>();
			this.duplicateResults = new List<Duplicates.DuplicateResult>();
		}

		/**
		 * @description Marks this result as successful.
		 * @return This FindDuplicatesResult instance for method chaining
		 */
		global MockDuplicates.FindDuplicatesResult asSuccessful() {
			this.success = true;
			return this;
		}

		/**
		 * @description Marks this result as failed.
		 * @return This FindDuplicatesResult instance for method chaining
		 */
		global MockDuplicates.FindDuplicatesResult asFailed() {
			this.success = false;
			return this;
		}

		/**
		 * @description Adds a single error.
		 * @param error The error to add
		 * @return This FindDuplicatesResult instance for method chaining
		 */
		global MockDuplicates.FindDuplicatesResult addError(Duplicates.Error error) {
			if (this.errors == null) {
				this.errors = new List<Duplicates.Error>();
			}
			if (error != null) {
				this.errors.add(error);
			}
			return this;
		}

		/**
		 * @description Adds a duplicate result.
		 * @param duplicateResult The duplicate result to add
		 * @return This FindDuplicatesResult instance for method chaining
		 */
		global MockDuplicates.FindDuplicatesResult addDuplicateResult(
			Duplicates.DuplicateResult duplicateResult
		) {
			if (this.duplicateResults == null) {
				this.duplicateResults = new List<Duplicates.DuplicateResult>();
			}
			if (duplicateResult != null) {
				this.duplicateResults.add(duplicateResult);
			}
			return this;
		}
	}

	/**
	 * @description Mock wrapper for DuplicateResult with builder support.
	 */
	global class DuplicateResult extends Duplicates.DuplicateResult {
		/**
		 * @description Constructor for empty mock DuplicateResult.
		 */
		global DuplicateResult() {
			super(null);
			this.record = null;
			this.matchResults = new List<Duplicates.MatchResult>();
		}

		/**
		 * @description Sets the record for this duplicate result.
		 * @param record The SObject record
		 * @return This DuplicateResult instance for method chaining
		 */
		global MockDuplicates.DuplicateResult withRecord(SObject record) {
			this.record = record;
			return this;
		}

		/**
		 * @description Adds a match result.
		 * @param matchResult The match result to add
		 * @return This DuplicateResult instance for method chaining
		 */
		global MockDuplicates.DuplicateResult addMatchResult(Duplicates.MatchResult matchResult) {
			if (this.matchResults == null) {
				this.matchResults = new List<Duplicates.MatchResult>();
			}
			if (matchResult != null) {
				this.matchResults.add(matchResult);
			}
			return this;
		}
	}

	/**
	 * @description Mock wrapper for MatchResult with builder support.
	 */
	global class MatchResult extends Duplicates.MatchResult {
		/**
		 * @description Constructor for empty mock MatchResult.
		 */
		global MatchResult() {
			super(null);
			this.rule = null;
			this.size = 0;
			this.matchRecords = new List<Duplicates.MatchRecord>();
		}

		/**
		 * @description Sets the rule name for this match result.
		 * @param rule The rule name
		 * @return This MatchResult instance for method chaining
		 */
		global MockDuplicates.MatchResult withRule(String rule) {
			this.rule = rule;
			return this;
		}

		/**
		 * @description Sets the match count for this result.
		 * @param size The number of matches
		 * @return This MatchResult instance for method chaining
		 */
		global MockDuplicates.MatchResult withSize(Integer size) {
			this.size = size;
			return this;
		}

		/**
		 * @description Adds a match record.
		 * @param matchRecord The match record to add
		 * @return This MatchResult instance for method chaining
		 */
		global MockDuplicates.MatchResult addMatchRecord(Duplicates.MatchRecord matchRecord) {
			if (this.matchRecords == null) {
				this.matchRecords = new List<Duplicates.MatchRecord>();
			}
			if (matchRecord != null) {
				this.matchRecords.add(matchRecord);
			}
			return this;
		}
	}

	/**
	 * @description Mock wrapper for MatchRecord with builder support.
	 */
	global class MatchRecord extends Duplicates.MatchRecord {
		/**
		 * @description Constructor for empty mock MatchRecord.
		 */
		global MatchRecord() {
			super(null);
			this.record = null;
			this.fieldDiffs = new List<Duplicates.FieldDiff>();
		}

		/**
		 * @description Sets the matching record.
		 * @param record The SObject record
		 * @return This MatchRecord instance for method chaining
		 */
		global MockDuplicates.MatchRecord withRecord(SObject record) {
			this.record = record;
			return this;
		}

		/**
		 * @description Adds a field diff.
		 * @param fieldDiff The field difference to add
		 * @return This MatchRecord instance for method chaining
		 */
		global MockDuplicates.MatchRecord addFieldDiff(Duplicates.FieldDiff fieldDiff) {
			if (this.fieldDiffs == null) {
				this.fieldDiffs = new List<Duplicates.FieldDiff>();
			}
			if (fieldDiff != null) {
				this.fieldDiffs.add(fieldDiff);
			}
			return this;
		}
	}

	/**
	 * @description Mock wrapper for FieldDiff with builder support.
	 */
	global class FieldDiff extends Duplicates.FieldDiff {
		/**
		 * @description Constructor for empty mock FieldDiff.
		 */
		global FieldDiff() {
			super(null);
			this.fieldName = null;
			this.compareValue = null;
		}

		/**
		 * @description Sets the field name.
		 * @param fieldName The name of the field that differs
		 * @return This FieldDiff instance for method chaining
		 */
		global MockDuplicates.FieldDiff withFieldName(String fieldName) {
			this.fieldName = fieldName;
			return this;
		}

		/**
		 * @description Sets the comparison value.
		 * @param compareValue The value to compare
		 * @return This FieldDiff instance for method chaining
		 */
		global MockDuplicates.FieldDiff withCompareValue(Object compareValue) {
			this.compareValue = compareValue;
			return this;
		}
	}

	/**
	 * @description Mock wrapper for Error with builder support.
	 */
	global class Error extends Duplicates.Error {
		/**
		 * @description Constructor for empty mock Error.
		 */
		global Error() {
			super(null);
			this.fields = new List<String>();
			this.message = null;
			this.statusCode = null;
		}

		/**
		 * @description Sets the error message.
		 * @param message The error message
		 * @return This Error instance for method chaining
		 */
		global MockDuplicates.Error withMessage(String message) {
			this.message = message;
			return this;
		}

		/**
		 * @description Sets the status code.
		 * @param statusCode The error status code
		 * @return This Error instance for method chaining
		 */
		global MockDuplicates.Error withStatusCode(String statusCode) {
			this.statusCode = statusCode;
			return this;
		}

		/**
		 * @description Adds a field affected by this error.
		 * @param field The field name
		 * @return This Error instance for method chaining
		 */
		global MockDuplicates.Error addField(String field) {
			if (this.fields == null) {
				this.fields = new List<String>();
			}
			if (field != null) {
				this.fields.add(field);
			}
			return this;
		}
	}
}