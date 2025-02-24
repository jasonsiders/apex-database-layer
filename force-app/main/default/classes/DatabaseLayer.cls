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
	private Soql currentSoql;

	private DatabaseLayer() {
		this.currentDml = new Dml(this);
		this.currentSoql = new Soql(this);
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
	public static Soql Soql {
		get {
			// Returns a new copy of the current Soql instance on each reference
			return (Soql) INSTANCE?.currentSoql?.clone();
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
	private static MockSoql useMockSoql() {
		// Replace the current Dml instances with mocks of these types
		// Subsuquent calls to DatabaseLayer.Soql will now return mocks
		INSTANCE.currentSoql = new MockSoql();
		return (MockSoql) INSTANCE.currentSoql;
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
	private static Soql useRealSoql() {
		// Replace the current Dml instances with real/non-mock versions of these types
		// Subsuquent calls to DatabaseLayer.Soql will now return these versions.
		INSTANCE.currentSoql = new Soql(INSTANCE);
		return INSTANCE.currentSoql;
	}

	@TestVisible
	private static void useRealData() {
		// Use real data for both DML and SOQL operations going forward.
		DatabaseLayer.useRealDml();
		DatabaseLayer.useRealSoql();
	}
}
