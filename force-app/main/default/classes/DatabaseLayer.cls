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

	public static void useMocks() {
		// Replace the current Dml/Soql instances with mocks of these types
		// Subsuquent calls to newDml()/newSoql() will now return mocks
		INSTANCE.dml = new MockDml();
		INSTANCE.soql = new MockSoql();
	}

	public static void useRealData() {
		// Replace the current Dml/Soql instances with the real/non-mock versions of these types
		// Subsuquent calls to newDml()/newSoql() will now return these versions.
		INSTANCE.dml = new MockDml();
		INSTANCE.dml = new Dml(INSTANCE);
		INSTANCE.soql = new Soql(INSTANCE);
	}
}
