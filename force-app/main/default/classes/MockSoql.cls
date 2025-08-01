@SuppressWarnings('PMD.ApexDoc,PMD.AvoidGlobalModifier')
@IsTest
global class MockSoql extends Soql {
	/**
	 * This class mocks SOQL queries. By default, each query will return empty results.
	 * Users can use the `setGlobalMock()` static method(s), and `setMock()` member method(s)
	 * to inject a `MockSoql.Simulator` object which will simulate the query & return results
	 **/
	private static final String AGGREGATE_KEY_PREFIX = 'expr';
	private static MockSoql.Simulator globalMock;
	private transient MockSoql.Simulator currentMock;

	public MockSoql(DatabaseLayer factory) {
		super(factory);
	}

	// **** STATIC **** //
	global static MockSoql.Simulator setGlobalMock(MockSoql.Simulator simulator) {
		// This method assigns the given simulator object to be run for all queries by default,
		// unless a Soql object has a specific Simulator assigned to it
		// Similar to using Test.setMock w/the System.HttpCalloutMock interface
		MockSoql.globalMock = simulator;
		return simulator;
	}

	global static MockSoql.StaticResults setGlobalMock() {
		// This overload instantiates a new StaticResults object, and returns it as a concrete instance
		// to allow for a more fluent interface + method chaining w/global mocks
		return (MockSoql.StaticResults) MockSoql.setGlobalMock(new MockSoql.StaticResults());
	}

	// **** MEMBER **** //
	public override Soql.Request initRequest(Soql.Operation operation) {
		MockSoql.Simulator simulator = this.getSimulator();
		return new MockSoql.Request(this, operation, simulator);
	}

	global MockSoql.Simulator setMock(MockSoql.Simulator simulator) {
		// Call this method to inject the given Simulator object
		// to be run whenever the current query runs, instead of the global mock
		this.currentMock = simulator;
		return this.currentMock;
	}

	global MockSoql.StaticResults setMock() {
		// Call this method to inject an return a concrete instance of a new StaticResults object
		// to be run whenever the current query runs, instead of the global mock
		return (MockSoql.StaticResults) this.setMock(new MockSoql.StaticResults());
	}

	private MockSoql.Simulator getSimulator() {
		// If the current query has a specific simulator assigned to it, return that simulator
		// Else return the globally assigned simulator
		return this.currentMock ?? MockSoql.globalMock;
	}

	// **** INNER **** //
	global class AggregateResult extends Soql.AggregateResult {
		/**
		 * Mocks the AggregateResult SObject, which cannot be manually constructed w/out performing a SOQL query
		 * These objects are comprised of properties with a default name, unless an alias is provided.
		 * Example with an alias: { "profileName": "System Administrator", "numUsers": 10 }
		 * Example w/out aliases: { "expr0": "System Administrator", "expr1": 10 }
		 **/
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

	global class Cursor extends Soql.Cursor {
		/**
		 * Mocks the Database.Cursor object, using an underlying List<SObject> to drive its behavior
		 **/
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

	global class QueryLocator extends Soql.QueryLocator {
		/**
		 * Mocks the Database.QueryLocator object, used in batch jobs.
		 * Note: This mock implementation has one big shortcoming.
		 * Because the underlying Database.QueryLocator object cannot be mocked,
		 * getLocator() will always return null in mock scenarios.
		 * Most custom implementations will call getQuery() or iterator() directly,
		 * but standard mechanisms (ie., Database.Batchable classes) won't work with this.
		 * One workaround is to individually test the start(), execute(), and finish() methods,
		 * instead of testing via Database.executeBatch()
		 **/
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

	global class QueryLocatorIterator implements System.Iterator<SObject> {
		/**
		 * This custom iterator mocks & mirrors the Database.QueryLocatorIterator,
		 * which is really just an Iterator<SObject> under the hood
		 **/
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

	global interface Simulator {
		/**
		 * This interface can be used to define query mocking logic.
		 * Example implementations include:
		 * 	- Return a static List<SObject>
		 * 	- Return dynamic List<SObject>, based on MockDml history/results
		 * 	- Return a List<MockSoql.AggregateResult>
		 *  - Throw an exception
		 **/
		List<Object> simulateQuery(Soql queryToMock);
	}

	global class StaticResults implements MockSoql.Simulator {
		private Exception error;
		private List<Object> results;

		@SuppressWarnings('PMD.EmptyStatementBlock')
		private StaticResults() {
			// Callers have no need to ever reference the StaticResults object directly
			// instead, use the StaticResults objects returned by the 0-arg setGlobalMock/setMock methods
		}

		global MockSoql.StaticResults withError(Exception error) {
			// This method injects the given error to be thrown whenever the simulator is run
			this.error = error;
			return this;
		}

		global MockSoql.StaticResults withError() {
			// This method injects a generic System.QueryException to be thrown whenever the simulator is run
			return this.withError(new System.QueryException());
		}

		global MockSoql.StaticResults withResults(List<Object> results) {
			this.results = results;
			return this;
		}

		global List<Object> simulateQuery(Soql queryToMock) {
			if (this.error != null) {
				throw this.error;
			}
			return this.results;
		}
	}
}
