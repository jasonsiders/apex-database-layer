public class DatabaseLayer {
	// **** STATIC **** //
	static final DatabaseLayer INSTANCE = new DatabaseLayer();

	public static Dml newDml() {
		return INSTANCE?.dml?.clone();
	}

	public static Soql newSoql(SObjectType objectType) {
		return (Soql) INSTANCE?.soql?.clone()?.fromEntity(objectType);
	}

	public static Soql newSoql(String queryString) {
		return (Soql) INSTANCE?.soql?.clone()?.setQueryString(queryString);
	}
	
	public static void useRealData() {
		INSTANCE.dml = new Dml(INSTANCE);
		INSTANCE.soql = new Soql(INSTANCE);
	}

	public static void useMocks() {
		INSTANCE.dml = new MockDml();
		INSTANCE.soql = new MockSoql();
	}

	// **** MEMBER **** //
	private Dml dml;
	private Soql soql;

	private DatabaseLayer() {
		this.dml = new Dml(this);
		this.soql = new Soql(this);
	}
}
