@IsTest
public class MockSoql extends Soql {
	static final String AGGREGATE_KEY_PREFIX = 'expr';

	// Note: The return type of various query methods may vary,
	// ex., List<SObject>, List<Soql.AggregateResult>, List<WrapperObject>
	List<Object> mockResults;
	Exception mockError;

	public MockSoql() {
		super();
	}

	@TestVisible
	private MockSoql(SObjectType objectType) {
		super();
		this.fromEntity(objectType);
	}

	public Soql injectError(Exception error) {
		// Inject the provided exception, to be thrown when the query runs
		this.mockError = error;
		return this;
	}

	public Soql injectError() {
		// Overload which always injects a System.QueryException
		System.QueryException queryError = new System.QueryException();
		return this.injectError(queryError);
	}

	public Soql injectResults(List<Object> mockResults) {
		// Inject a list of mock objects (SObjects, Soql.AggregateResult, custom return types)
		// to be returned when the query runs
		this.mockResults = mockResults;
		return this;
	}

	// **** OVERRIDES **** //
	public override List<Soql.AggregateResult> aggregateQuery() {
		try {
			this.throwIfHasInjectedException();
			return (List<Soql.AggregateResult>) this.mockResults ?? new List<Soql.AggregateResult>();
		} catch (Exception error) {
			this.handleQueryError(error);
			throw error;
		}
	}

	public override Integer countQuery() {
		return this.query()?.size();
	}

	public override Soql.QueryLocator getQueryLocator() {
		return new MockSoql.QueryLocator(this);
	}

	public override List<SObject> query() {
		try {
			this.throwIfHasInjectedException();
			return (List<SObject>) this.mockResults ?? new List<SObject>();
		} catch (Exception error) {
			this.handleQueryError(error);
			throw error;
		}
	}

	public override Object query(Type returnType) {
		try {
			this.throwIfHasInjectedException();
			return JSON.deserialize(JSON.serialize(this.mockResults), returnType);
		} catch (Exception error) {
			this.handleQueryError(error);
			throw error;
		}
	}

	private void throwIfHasInjectedException() {
		if (this.mockError != null) {
			throw this.mockError;
		}
	}

	// **** PRIVATE **** //
	public class AggregateResult extends Soql.AggregateResult {
		Integer numUnaliasedKeys = 0;

		public AggregateResult() {
			super(null);
		}

		public AggregateResult addParameter(String key, Object value) {
			this.params?.put(key, value);
			this.incrementAliasedKeyCount(key);
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
		// Note: This mock implementation has one big shortcoming.
		// Because the underlying Database.QueryLocator object cannot be mocked,
		// getCursor() will always return null in mock scenarios.
		// Most custom implementations will call getQuery() or iterator() directly,
		// but standard mechanisms (ie., Database.Batchable classes) won't work with this.
		// One workaround is to individually test the start(), execute(), and finish() methods,
		// instead of testing via Database.executeBatch()
		String query;
		List<SObject> records;

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
		// This custom iterator mirrors the Database.QueryLocatorIterator,
		// which is really just an Iterator<SObject> under the hood
		Integer index = 0;
		List<SObject> records;

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
}
