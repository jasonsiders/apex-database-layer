public class DatabaseLayer {
	/**
	 * Handles interactions with the Salesforce Database, via DML and SOQL.
	 * Use the `Dml` and `Soql` static properties to get the correct instance of each.
	 * Automatically inject mock versions of these classes via the `useMocks()` method.
	 **/
	// **** CONSTANTS **** //
	private static final DatabaseLayer INSTANCE = new DatabaseLayer();

	// **** MEMBER **** //
	private Dml currentDml;
	private SoqlProvider currentSoql;

	private DatabaseLayer() {
		this.currentDml = new Dml(this);
		this.currentSoql = new SoqlProvider(this);
	}

	// **** STATIC **** //
	// These public static properties are the primary way that callers interact with the Database Layer
	@SuppressWarnings('PMD.PropertyNamingConventions')
	public static Dml Dml {
		get {
			// Returns the current Dml instance
			return INSTANCE?.currentDml;
		}
	}
	@SuppressWarnings('PMD.PropertyNamingConventions')
	public static SoqlProvider Soql {
		get {
			// Returns a new copy of the current Soql instance on each reference
			return INSTANCE?.currentSoql;
		}
	}

	@TestVisible
	private static MockDml useMockDml() {
		// Replace the current Dml instances with mocks of these types
		// Subsuquent calls to DatabaseLayer.Dml will now return mocks
		INSTANCE.currentDml = new MockDml(INSTANCE);
		return (MockDml) INSTANCE.currentDml;
	}

	@TestVisible
	private static SoqlProvider useMockSoql() {
		// Replace the current Dml instances with mocks of these types
		// Subsuquent calls to DatabaseLayer.Soql will now return mocks
		return INSTANCE.currentSoql?.useMocks(true);
	}

	@TestVisible
	private static void useMocks() {
		// Use mock data for both DML and SOQL operations going forward.
		DatabaseLayer.useMockDml();
		DatabaseLayer.useMockSoql();
	}

	@TestVisible
	private static Dml useRealDml() {
		// Replace the current Dml instances with the real/non-mock versions of these types
		// Subsuquent calls to DatabaseLayer.Dml will now return these versions.
		INSTANCE.currentDml = new Dml(INSTANCE);
		return INSTANCE.currentDml;
	}

	@TestVisible
	private static SoqlProvider useRealSoql() {
		// Replace the current Dml instances with real/non-mock versions of these types
		// Subsuquent calls to DatabaseLayer.Soql will now return these versions.
		return INSTANCE.currentSoql?.useMocks(false);
	}

	@TestVisible
	private static void useRealData() {
		// Use real data for both DML and SOQL operations going forward.
		DatabaseLayer.useRealDml();
		DatabaseLayer.useRealSoql();
	}

	public class SoqlProvider {
		private Boolean useMocks;

		private SoqlProvider(DatabaseLayer factory) {
			this.useMocks = false;
		}

		public Soql newQuery(SObjectType objectType) {
			return (this.useMocks == true)
				? (Soql) new MockSoql(INSTANCE)?.fromSObject(objectType)
				: (Soql) new Soql(INSTANCE)?.fromSObject(objectType);
		}

		private SoqlProvider useMocks(Boolean useMocks) {
			this.useMocks = useMocks;
			return this;
		}
	}
}
