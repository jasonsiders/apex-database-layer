/**
 * @description Mock implementation of SOQL operations for testing. Provides comprehensive query mocking with configurable result simulation and global/instance-level mock management.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
@IsTest
global class MockSoql extends Soql {
	/** @description Tracks all mock SOQL queries and row counts for assertion in tests */
	@SuppressWarnings('PMD.PropertyNamingConventions')
	global static MockSoql.Database MockDatabase { get; private set; }

	/** @description Prefix used for auto-generated alias keys in aggregate results */
	private static final String AGGREGATE_KEY_PREFIX = 'expr';
	/** @description Global simulator applied to all queries unless overridden at the instance level */
	private static MockSoql.Simulator globalMock;
	/** @description Instance-level simulator that takes precedence over the global simulator */
	private transient MockSoql.Simulator currentMock;

	/**
	 * @description Constructor for MockSoql instance.
	 * @param factory The DatabaseLayer factory instance
	 */
	public MockSoql(DatabaseLayer factory) {
		super(factory);
	}

	/**
	 * @description Constructor for MockSoql instance with raw SOQL query string.
	 * @param factory The DatabaseLayer factory instance
	 * @param queryString The raw SOQL query string to parse
	 */
	public MockSoql(DatabaseLayer factory, String queryString) {
		super(queryString);
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
	/**
	 * @description Initializes a mock SOQL request for the given operation.
	 * @param operation The operation type being performed
	 * @return A MockSoql.Request configured with the active simulator
	 */
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

	/**
	 * @description Returns the active simulator for this query, preferring the instance-level mock over the global mock.
	 * @return The active MockSoql.Simulator, or null if none is set
	 */
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
		/** @description Tracks how many parameters have been added without an explicit alias */
		private Integer numUnaliasedKeys = 0;

		/**
		 * @description Constructor for empty MockSoql.AggregateResult.
		 */
		global AggregateResult() {
			super(null);
		}

		/**
		 * @description Adds a parameter with a specific alias to the aggregate result.
		 * @param alias The alias for the parameter
		 * @param value The value of the parameter
		 * @return This AggregateResult instance for method chaining
		 */
		global AggregateResult addParameter(String alias, Object value) {
			this.params?.put(alias, value);
			this.incrementAliasedKeyCount(alias);
			return this;
		}

		/**
		 * @description Adds a parameter with an auto-generated alias to the aggregate result.
		 * @param value The value of the parameter
		 * @return This AggregateResult instance for method chaining
		 */
		global AggregateResult addParameter(Object value) {
			// If a key is not given, assign one using the default aggregate key prefix
			String key = AGGREGATE_KEY_PREFIX + this.numUnaliasedKeys;
			return this.addParameter(key, value);
		}

		/**
		 * @description Increments the unaliased key counter when the provided key matches the auto-generated prefix.
		 * @param key The alias key to evaluate
		 */
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
		/** @description The records returned by the mocked query, used to back all cursor operations */
		private List<SObject> records;

		/**
		 * @description Constructor for MockSoql.Cursor
		 * @param mockQuery The MockSoql instance to create a cursor for
		 */
		private Cursor(MockSoql mockQuery) {
			super(null);
			this.cursor = this.initMockCursor();
			this.records = mockQuery?.query();
		}

		/**
		 * @description Fetches a slice of records starting at the given position.
		 * @param position The zero-based index to start fetching from
		 * @param count The number of records to fetch
		 * @return The records in the requested range
		 */
		global override List<SObject> fetch(Integer position, Integer count) {
			// Mocks native functionality by retrieving SObjects between the specified params from the underlying list
			this.validateFetch(position, count);
			// Strangely, there isn't a native List.slice method in Apex:
			return (List<SObject>) this.slice(this.records, position, count);
		}

		/**
		 * @description Returns the total number of records available in this cursor.
		 * @return The number of records, or 0 if the record list is null
		 */
		global override Integer getNumRecords() {
			return this.records?.size() ?? 0;
		}

		/**
		 * @description Creates a fake Database.Cursor object with a valid-looking queryId so getCursor() returns non-null.
		 * @return A deserialized Database.Cursor with a fabricated queryId
		 */
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

		/**
		 * @description Returns a sub-list of objects starting at the given index for the specified number of elements.
		 * @param input The source list to slice
		 * @param first The zero-based index to start from
		 * @param numElements The number of elements to include
		 * @return A new list containing the requested slice
		 */
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

		/**
		 * @description Validates that the fetch arguments are non-null, non-negative, and within bounds.
		 * @param position The zero-based start index
		 * @param count The number of records to fetch
		 */
		private void validateFetch(Integer position, Integer count) {
			// Throws an exception if the provided arguments are invalid
			this.validateFetchArgsAreNotNull(position, count);
			this.validateFetchArgsArePositive(position, count);
			this.validateFetchArgsAreInBounds(position, count);
		}

		/**
		 * @description Throws a NullPointerException if either fetch argument is null.
		 * @param position The zero-based start index
		 * @param count The number of records to fetch
		 */
		private void validateFetchArgsAreNotNull(Integer position, Integer count) {
			// Neither parameter should be null:
			if (position == null || count == null) {
				System.Exception error = new System.NullPointerException();
				error?.setMessage('Attempt to de-reference a null object');
				throw error;
			}
		}

		/**
		 * @description Throws an InvalidParameterValueException if either fetch argument is negative.
		 * @param position The zero-based start index
		 * @param count The number of records to fetch
		 */
		private void validateFetchArgsArePositive(Integer position, Integer count) {
			// Neither parameter should be negative:
			if (position < 0) {
				throw new Soql.InvalidParameterValueException('Start position cannot be a negative value: ' + position);
			} else if (count < 0) {
				throw new Soql.InvalidParameterValueException('Fetch size cannot be a negative value: ' + count);
			}
		}

		/**
		 * @description Throws an InvalidParameterValueException if the fetch range exceeds the available records.
		 * @param position The zero-based start index
		 * @param count The number of records to fetch
		 */
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
	 * @description Tracks mock SOQL query requests and aggregate row counts for test-time assertion.
	 */
	global class Database {
		/** @description Running total of rows returned across all registered queries */
		private Integer numQueryRows;
		/** @description Ordered list of all query requests registered against this mock database */
		private List<Soql.Request> requests;

		/** @description Initializes the mock database with empty query tracking state */
		private Database() {
			this.reset();
		}

		/**
		 * @description Returns the total number of queries that have been executed.
		 * @return The number of registered query requests
		 */
		global Integer getNumQueries() {
			return this.requests?.size();
		}

		/**
		 * @description Returns all query requests that have been executed.
		 * @return The list of registered Soql.Request instances
		 */
		global List<Soql.Request> getQueries() {
			return this.requests;
		}

		/**
		 * @description Returns the total number of rows returned across all executed queries.
		 * @return The cumulative row count
		 */
		global Integer getQueryRows() {
			return this.numQueryRows;
		}

		/**
		 * @description Resets the mock database, clearing all query history and row counts.
		 */
		global void reset() {
			this.numQueryRows = 0;
			this.requests = new List<Soql.Request>{};
		}

		/**
		 * @description Records a completed query request and its result row count.
		 * @param request The query request that was executed
		 * @param results The results returned by the query
		 */
		private void register(Soql.Request request, List<Object> results) {
			Integer rows = results?.size() ?? 0;
			this.numQueryRows += rows;
			this.requests?.add(request);
		}
	}

	/**
	 * @description Mock implementation of Database.QueryLocator for testing batch processing operations.
	 * Note: Because the underlying Database.QueryLocator object itself cannot be mocked,
	 * getLocator() will always return null in mock scenarios.
	 * Most custom implementations will call getQuery() or iterator() directly,
	 * but standard mechanisms (ie., Database.Batchable classes) won't work with this.
	 * One workaround is to individually test the start(), execute(), and finish() methods,
	 * instead of testing via Database.executeBatch()
	 */
	global class QueryLocator extends Soql.QueryLocator {
		/** @description The SOQL query string associated with this locator */
		private String query;
		/** @description The records returned by the mocked query, used to back the iterator */
		private List<SObject> records;

		/**
		 * @description Constructor for MockSoql.QueryLocator
		 * @param mockQuery The MockSoql instance to create a query locator for
		 */
		private QueryLocator(MockSoql mockQuery) {
			super(null);
			this.query = mockQuery?.toString();
			this.records = mockQuery?.query();
		}

		/**
		 * @description Returns the SOQL query string associated with this locator.
		 * @return The SOQL query string
		 */
		global override String getQuery() {
			return this.query;
		}

		/**
		 * @description Returns an iterator over the mocked query results.
		 * @return A MockSoql.QueryLocatorIterator for the records
		 */
		global override System.Iterator<SObject> iterator() {
			return new MockSoql.QueryLocatorIterator(this.records);
		}
	}

	/**
	 * @description Mock iterator implementation for QueryLocator batch processing.
	 */
	global class QueryLocatorIterator implements System.Iterator<SObject> {
		/** @description The current position in the records list */
		private Integer index = 0;
		/** @description The records to iterate over */
		private List<SObject> records;

		/**
		 * @description Constructor for QueryLocatorIterator
		 * @param records The list of records to iterate over
		 */
		private QueryLocatorIterator(List<SObject> records) {
			this.records = records;
		}

		/**
		 * @description Checks if there are more records to iterate over.
		 * @return True if there are more records, false otherwise
		 */
		global Boolean hasNext() {
			return this.index < records?.size();
		}

		/**
		 * @description Returns the next record in the iteration.
		 * @return The next SObject record
		 * @throws System.NoSuchElementException If no more elements exist
		 */
		global SObject next() {
			if (this.hasNext() == true) {
				return this.records[index++];
			} else {
				String msg = 'Iterator has no more elements.';
				throw new System.NoSuchElementException(msg);
			}
		}
	}

	/**
	 * @description Mock SOQL request implementation that uses simulators to return predefined results.
	 */
	public class Request extends Soql.Request {
		/** @description The simulator used to generate mock results for this request */
		private transient MockSoql.Simulator simulator;

		/**
		 * @description Constructor for MockSoql.Request
		 * @param query The Soql query instance
		 * @param operation The operation type being performed
		 * @param simulator The simulator instance for mock behavior
		 */
		private Request(Soql query, Soql.Operation operation, MockSoql.Simulator simulator) {
			super(query, operation);
			this.isMockSoql = true;
			this.simulator = simulator;
		}

		/**
		 * @description Executes an aggregate query using the mock simulator
		 * @return List of aggregate results from the simulation
		 */
		public override List<Soql.AggregateResult> doAggregateQuery() {
			return (List<Soql.AggregateResult>) this.simulate() ?? new List<Soql.AggregateResult>();
		}

		/**
		 * @description Executes a count query using the mock simulator
		 * @return Count of records from the simulation
		 */
		public override Integer doCountQuery() {
			return ((List<SObject>) this.doQuery())?.size() ?? 0;
		}

		/**
		 * @description Creates a mock cursor for iterating through query results
		 * @return A MockSoql.Cursor instance
		 */
		public override Soql.Cursor doGetCursor() {
			return new MockSoql.Cursor((MockSoql) this.query);
		}

		/**
		 * @description Creates a mock query locator for batch processing
		 * @return A MockSoql.QueryLocator instance
		 */
		public override Soql.QueryLocator doGetQueryLocator() {
			return new MockSoql.QueryLocator((MockSoql) this.query);
		}

		/**
		 * @description Executes a query using the mock simulator
		 * @return Query results from the simulation
		 */
		public override Object doQuery() {
			return this.simulate() ?? new List<SObject>();
		}

		/**
		 * @description Runs the simulator logic to generate mock query results
		 * @return Simulated query results
		 */
		private Object simulate() {
			// Run the Simulator logic
			List<Object> results = this.simulator?.simulateQuery(this.query);
			MockSoql.MockDatabase?.register(this, results);
			return results;
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
		/** @description The exception to throw when the query is executed, if configured */
		private Exception error;
		/** @description The predefined results to return when the query is executed */
		private List<Object> results;

		/**
		 * @description Constructor for StaticResults class
		 */
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
