/**
 * @description Mock implementation of SOQL operations for testing. Provides comprehensive query mocking with configurable result simulation and global/instance-level mock management.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
@IsTest
global class MockSoql extends Soql {
	private static final String AGGREGATE_KEY_PREFIX = 'expr';
	private static MockSoql.Simulator globalMock;
	private transient MockSoql.Simulator currentMock;

	/**
	 * @description Constructor for MockSoql instance.
	 * @param factory The DatabaseLayer factory instance
	 */
	public MockSoql(DatabaseLayer factory) {
		super(factory);
	}

	// **** STATIC **** //
	/**
	 * @description Sets a global mock simulator to be used for all SOQL queries unless overridden.
	 * @param simulator The simulator to use for mocking queries
	 * @return The configured simulator instance
	 */
	global static MockSoql.Simulator setGlobalMock(MockSoql.Simulator simulator) {
		MockSoql.globalMock = simulator;
		return simulator;
	}

	/**
	 * @description Creates and sets a new StaticResults global mock with fluent interface.
	 * @return A StaticResults instance for method chaining
	 */
	global static MockSoql.StaticResults setGlobalMock() {
		return (MockSoql.StaticResults) MockSoql.setGlobalMock(new MockSoql.StaticResults());
	}

	// **** MEMBER **** //
	public override Soql.Request initRequest(Soql.Operation operation) {
		MockSoql.Simulator simulator = this.getSimulator();
		return new MockSoql.Request(this, operation, simulator);
	}

	/**
	 * @description Sets a mock simulator for this specific query instance.
	 * @param simulator The simulator to use for this query
	 * @return The configured simulator instance
	 */
	global MockSoql.Simulator setMock(MockSoql.Simulator simulator) {
		this.currentMock = simulator;
		return this.currentMock;
	}

	/**
	 * @description Creates and sets a new StaticResults mock for this query instance.
	 * @return A StaticResults instance for method chaining
	 */
	global MockSoql.StaticResults setMock() {
		return (MockSoql.StaticResults) this.setMock(new MockSoql.StaticResults());
	}

	private MockSoql.Simulator getSimulator() {
		// If the current query has a specific simulator assigned to it, return that simulator
		// Else return the globally assigned simulator
		return this.currentMock ?? MockSoql.globalMock;
	}

	// **** INNER **** //
	/**
	 * @description Mock implementation of aggregate query results with support for aliases and auto-generated field names.
	 */
	global class AggregateResult extends Soql.AggregateResult {
		private Integer numUnaliasedKeys = 0;

		global AggregateResult() {
			super(null);
		}

		global AggregateResult addParameter(String alias, Object value) {
			this.params?.put(alias, value);
			this.incrementAliasedKeyCount(alias);
			return this;
		}

		global AggregateResult addParameter(Object value) {
			// If a key is not given, assign one using the default aggregate key prefix
			String key = AGGREGATE_KEY_PREFIX + this.numUnaliasedKeys;
			return this.addParameter(key, value);
		}

		private void incrementAliasedKeyCount(String key) {
			// If the key is unaliased, increment the counter. Else, do nothing
			if (key?.startsWith(AGGREGATE_KEY_PREFIX) == true) {
				this.numUnaliasedKeys++;
			}
		}
	}

	/**
	 * @description Mock implementation of Database.Cursor using List<SObject> for behavior simulation.
	 */
	global class Cursor extends Soql.Cursor {
		private List<SObject> records;

		private Cursor(MockSoql mockQuery) {
			super(null);
			this.cursor = this.initMockCursor();
			this.records = mockQuery?.query();
		}

		global override List<SObject> fetch(Integer position, Integer count) {
			// Mocks native functionality by retrieving SObjects between the specified params from the underlying list
			this.validateFetch(position, count);
			// Strangely, there isn't a native List.slice method in Apex:
			return (List<SObject>) this.slice(this.records, position, count);
		}

		global override Integer getNumRecords() {
			return this.records?.size() ?? 0;
		}

		private Database.Cursor initMockCursor() {
			// Mocks a fake Database.Cursor object, so that Soql.Cursor.getCursor() will return a non-null object
			// Note: Cursors have a 15-character queryId property that always starts with the same key prefix
			// Hijacking the existing mock record Id to generate this:
			String queryId = '0r8' + String.valueOf(MockRecord.initRecordId(User.SObjectType))?.right(12);
			return (Database.Cursor) JSON.deserialize(
				JSON.serialize(new Map<String, Object>{ 'queryId' => queryId }),
				Database.Cursor.class
			);
		}

		private List<Object> slice(List<Object> input, Integer first, Integer numElements) {
			// Retrieves a portion of the provided objects, starting at the "first" index, until the list size matches the numElements
			// Similar to slice() in JS, except the second parameter specifies the number of elements to return, not the ending index
			List<Object> results = input?.clone();
			// Remove any elements that precede the starting index:
			for (Integer i = 0; i < first; i++) {
				results?.remove(0);
			}
			// Remove any elements after the ending index:
			while (results?.size() > numElements) {
				results?.remove(numElements);
			}
			return results;
		}

		private void validateFetch(Integer position, Integer count) {
			// Throws an exception if the provided arguments are invalid
			this.validateFetchArgsAreNotNull(position, count);
			this.validateFetchArgsArePositive(position, count);
			this.validateFetchArgsAreInBounds(position, count);
		}

		private void validateFetchArgsAreNotNull(Integer position, Integer count) {
			// Neither parameter should be null:
			if (position == null || count == null) {
				System.Exception error = new System.NullPointerException();
				error?.setMessage('Attempt to de-reference a null object');
				throw error;
			}
		}

		private void validateFetchArgsArePositive(Integer position, Integer count) {
			// Neither parameter should be negative:
			if (position < 0) {
				throw new Soql.InvalidParameterValueException('Start position cannot be a negative value: ' + position);
			} else if (count < 0) {
				throw new Soql.InvalidParameterValueException('Fetch size cannot be a negative value: ' + count);
			}
		}

		private void validateFetchArgsAreInBounds(Integer position, Integer count) {
			// Should not attempt to fetch an index that doesn't exist:
			Integer maxIndexToFetch = (position + count);
			Integer upperBound = (this.records?.size() - 1);
			if (maxIndexToFetch > upperBound) {
				throw new Soql.InvalidParameterValueException('Fetch beyond bound detected: ' + maxIndexToFetch);
			}
		}
	}

	/**
	 * @description Mock implementation of Database.QueryLocator for batch processing simulation.
	 */
	global class QueryLocator extends Soql.QueryLocator {
		private String query;
		private List<SObject> records;

		private QueryLocator(MockSoql mockQuery) {
			super(null);
			this.query = mockQuery?.toString();
			this.records = mockQuery?.query();
		}

		global override String getQuery() {
			return this.query;
		}

		global override System.Iterator<SObject> iterator() {
			return new MockSoql.QueryLocatorIterator(this.records);
		}
	}

	/**
	 * @description Mock iterator implementation for QueryLocator batch processing.
	 */
	global class QueryLocatorIterator implements System.Iterator<SObject> {
		private Integer index = 0;
		private List<SObject> records;

		private QueryLocatorIterator(List<SObject> records) {
			this.records = records;
		}

		global Boolean hasNext() {
			return this.index < records?.size();
		}

		global SObject next() {
			if (this.hasNext() == true) {
				return this.records[index++];
			} else {
				String msg = 'Iterator has no more elements.';
				throw new System.NoSuchElementException(msg);
			}
		}
	}

	public class Request extends Soql.Request {
		private transient MockSoql.Simulator simulator;

		private Request(Soql query, Soql.Operation operation, MockSoql.Simulator simulator) {
			super(query, operation);
			this.isMockSoql = true;
			this.simulator = simulator;
		}

		public override List<Soql.AggregateResult> doAggregateQuery() {
			return (List<Soql.AggregateResult>) this.simulate() ?? new List<Soql.AggregateResult>();
		}

		public override Integer doCountQuery() {
			return ((List<SObject>) this.doQuery())?.size() ?? 0;
		}

		public override Soql.Cursor doGetCursor() {
			return new MockSoql.Cursor((MockSoql) this.query);
		}

		public override Soql.QueryLocator doGetQueryLocator() {
			return new MockSoql.QueryLocator((MockSoql) this.query);
		}

		public override Object doQuery() {
			return this.simulate() ?? new List<SObject>();
		}

		private Object simulate() {
			// Run the Simulator logic
			return this.simulator?.simulateQuery(this.query);
		}
	}

	/**
	 * @description Interface for defining custom query simulation logic.
	 */
	global interface Simulator {
		/**
		 * @description Simulates a SOQL query execution and returns mock results.
		 * @param queryToMock The SOQL query being mocked
		 * @return List of objects representing query results
		 */
		List<Object> simulateQuery(Soql queryToMock);
	}

	/**
	 * @description Static result simulator that returns predefined results or throws configured exceptions.
	 */
	global class StaticResults implements MockSoql.Simulator {
		private Exception error;
		private List<Object> results;

		@SuppressWarnings('PMD.EmptyStatementBlock')
		private StaticResults() {
			// Callers have no need to ever reference the StaticResults object directly
			// instead, use the StaticResults objects returned by the 0-arg setGlobalMock/setMock methods
		}

		/**
		 * @description Configures the simulator to throw the specified exception.
		 * @param error The exception to throw when the query is executed
		 * @return This StaticResults instance for method chaining
		 */
		global MockSoql.StaticResults withError(Exception error) {
			this.error = error;
			return this;
		}

		/**
		 * @description Configures the simulator to throw a generic QueryException.
		 * @return This StaticResults instance for method chaining
		 */
		global MockSoql.StaticResults withError() {
			return this.withError(new System.QueryException());
		}

		/**
		 * @description Configures the simulator to return the specified results.
		 * @param results The list of objects to return when the query is executed
		 * @return This StaticResults instance for method chaining
		 */
		global MockSoql.StaticResults withResults(List<Object> results) {
			this.results = results;
			return this;
		}

		/**
		 * @description Executes the configured simulation (return results or throw error).
		 * @param queryToMock The SOQL query being simulated
		 * @return The configured results or throws the configured exception
		 */
		global List<Object> simulateQuery(Soql queryToMock) {
			if (this.error != null) {
				throw this.error;
			}
			return this.results;
		}
	}
}
