@SuppressWarnings('PMD.ApexDoc')
@IsTest
public class MockSoql extends Soql {
	/**
	 * This class mocks SOQL queries. By default, each query will return empty results.
	 * Users can use the `setGlobalMock()` static method, and `setMock()` member method(s)
	 * to inject a `MockSoql.Simulator` object which will simulate the query & return results
	 **/
	private static final String AGGREGATE_KEY_PREFIX = 'expr';
	private static MockSoql.Simulator globalMock;
	private MockSoql.Simulator currentMock;

	public MockSoql(DatabaseLayer factory) {
		super(factory);
	}

	// **** STATIC **** //
	public static MockSoql.Simulator setGlobalMock(MockSoql.Simulator simulator) {
		// This method assigns a simulator object, which will be run for all queries by default,
		// unless a Soql object has a specific Simulator assigned to it
		// Similar to using Test.setMock w/the System.HttpCalloutMock interface
		MockSoql.globalMock = simulator;
		return simulator;
	}

	// **** MEMBER **** //
	public Soql setError(Exception error) {
		// Call this method to inject the given Exception object
		// to be thrown whenever the current query runs, instead of the global mock
		MockSoql.Simulator simulator = new MockSoql.StaticResults(error);
		return this.setMock(simulator);
	}

	public Soql setError() {
		// Call this method to inject a generic System.QueryException
		// to be thrown whenever the current query runs, instead of the global mock
		return this.setError(new System.QueryException());
	}

	public Soql setMock(MockSoql.Simulator simulator) {
		// Call this method to inject an Simulator object
		// to be run whenever the current query runs, instead of the global mock
		this.currentMock = simulator;
		return this;
	}

	public Soql setMock(List<Object> results) {
		// Call this method to inject static List<Object>
		// to be returned whenever the current query runs, instead of the global mock
		MockSoql.Simulator simulator = new MockSoql.StaticResults(results);
		return this.setMock(simulator);
	}

	// **** OVERRIDES **** //
	public override List<Soql.AggregateResult> aggregateQuery() {
		return (List<Soql.AggregateResult>) this.simulate() ?? new List<Soql.AggregateResult>();
	}

	public override Integer countQuery() {
		return this.query()?.size();
	}

	public override Soql.QueryLocator getQueryLocator() {
		return new MockSoql.QueryLocator(this);
	}

	public override List<SObject> query() {
		return (List<SObject>) this.simulate() ?? new List<SObject>();
	}

	public override Object query(Type returnType) {
		return this.simulate() ?? returnType?.newInstance();
	}

	// **** PRIVATE **** //
	private MockSoql.Simulator getSimulator() {
		// If the current query has a specific simulator assigned to it, return that simulator
		// Else return the globally assigned simulator
		return this.currentMock ?? MockSoql.globalMock;
	}

	private Object simulate() {
		// Run the Simulator logic, and handle errors just like the super() class does
		try {
			return this.getSimulator()?.simulateQuery(this);
		} catch (Exception error) {
			this.handleQueryError(error);
			throw error;
		}
	}

	// **** INNER **** //
	public class AggregateResult extends Soql.AggregateResult {
		/**
		 * Mocks the AggregateResult SObject, which cannot be manually constructed w/out performing a SOQL query
		 * These objects are comprised of properties with a default name, unless an alias is provided.
		 * Example with an alias: { "profileName": "System Administrator", "numUsers": 10 }
		 * Example w/out aliases: { "expr0": "System Administrator", "expr1": 10 }
		 **/
		private Integer numUnaliasedKeys = 0;

		public AggregateResult() {
			super(null);
		}

		public AggregateResult addParameter(String alias, Object value) {
			this.params?.put(alias, value);
			this.incrementAliasedKeyCount(alias);
			return this;
		}

		public AggregateResult addParameter(Object value) {
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

	public class QueryLocator extends Soql.QueryLocator {
		/**
		 * Mocks the Database.QueryLocator object, used in batch jobs.
		 * Note: This mock implementation has one big shortcoming.
		 * Because the underlying Database.QueryLocator object cannot be mocked,
		 * getCursor() will always return null in mock scenarios.
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

		public override String getQuery() {
			return this.query;
		}

		public override System.Iterator<SObject> iterator() {
			return new MockSoql.QueryLocatorIterator(this.records);
		}
	}

	public class QueryLocatorIterator implements System.Iterator<SObject> {
		/**
		 * This custom iterator mocks & mirrors the Database.QueryLocatorIterator,
		 * which is really just an Iterator<SObject> under the hood
		 **/
		private Integer index = 0;
		private List<SObject> records;

		private QueryLocatorIterator(List<SObject> records) {
			this.records = records;
		}

		public Boolean hasNext() {
			return this.index < records?.size();
		}

		public SObject next() {
			if (this.hasNext() == true) {
				return this.records[index++];
			} else {
				String msg = 'Iterator has no more elements.';
				throw new System.NoSuchElementException(msg);
			}
		}
	}

	public interface Simulator {
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

	public class StaticResults implements MockSoql.Simulator {
		private Exception error;
		private List<Object> results;

		public StaticResults(Exception error) {
			this.error = error;
		}

		public StaticResults(List<Object> results) {
			this.results = results;
		}

		public List<Object> simulateQuery(Soql queryToMock) {
			if (this.error != null) {
				throw this.error;
			}
			return this.results;
		}
	}
}
