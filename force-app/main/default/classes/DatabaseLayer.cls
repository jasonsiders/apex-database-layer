public class DatabaseLayer {
	/**
	 * Handles interactions with the Salesforce Database, via DML and SOQL.
	 * Use the `newDml()` and `newSoql()` methods to construct instances of these types.
	 * Automatically inject mock versions of these classes via the `useMocks()` method.
	 **/
	// **** CONSTANTS **** //
	private static final DatabaseLayer INSTANCE = new DatabaseLayer();

	// **** MEMBER **** //
	private Dml dml;
	private Soql soql;

	private DatabaseLayer() {
		this.dml = new Dml(this);
		this.soql = new Soql(this);
	}

	// **** STATIC **** //
	public static Dml newDml() {
		// Returns a new instance of the current Dml type
		return INSTANCE?.dml?.clone();
	}

	public static Soql newSoql(SObjectType objectType) {
		// Returns a new instance of the current Soql type, that will return records of the provided SObjectType.
		return (Soql) INSTANCE?.soql?.clone()?.fromEntity(objectType);
	}

	public static void useMockDml() {
		// Replace the current Dml instances with mocks of these types
		// Subsuquent calls to newDml() will now return mocks
		INSTANCE.dml = new MockDml();
	}

	public static void useMockSoql() {
		// Replace the current Dml instances with mocks of these types
		// Subsuquent calls to newSoql() will now return mocks
		INSTANCE.soql = new MockSoql();
	}

	public static void useMocks() {
		// Use mock data for both DML and SOQL operations going forward.
		DatabaseLayer.useMockDml();
		DatabaseLayer.useMockSoql();
	}

	public static void useRealDml() {
		// Replace the current Dml instances with the real/non-mock versions of these types
		// Subsuquent calls to newDml() will now return these versions.
		INSTANCE.dml = new Dml(INSTANCE);
	}

	public static void useRealSoql() {
		// Replace the current Dml instances with real/non-mock versions of these types
		// Subsuquent calls to newSoql() will now return these versions.
		INSTANCE.soql = new Soql(INSTANCE);
	}

	public static void useRealData() {
		// Use real data for both DML and SOQL operations going forward.
		DatabaseLayer.useRealDml();
		DatabaseLayer.useRealSoql();
	}
}
