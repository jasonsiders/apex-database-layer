public class DatabaseLayer {
	// **** STATIC **** //
	static final DatabaseLayer SINGLETON_INSTANCE = new DatabaseLayer();

	public static DatabaseLayer get() {
		// Cannot manually construct a DatabaseLayer; this method retrieves the singleton
		return DatabaseLayer.SINGLETON_INSTANCE;
	}

	// **** MEMBER **** //
	private Dml dml;
	private Soql soql;

	private DatabaseLayer() {
		this.dml = new Dml(this);
		this.soql = new Soql(this);
	}

	public Dml initDml() {
		// Retrieve a new DML object of the correct type
		return this.dml?.clone();
	}

	public Soql initSoql(SObjectType fromObject) {
		// Retrieve a new SOQL object of the correct type
		return (Soql) this.soql?.clone()?.fromEntity(fromObject);
	}

	public Soql initSoql(String queryString) {
		// Retrieve a new SOQL object of the correct type, using a prebuilt query string
		return (Soql) this.soql?.clone()?.setQueryString(queryString);
	}

	// **** TEST ONLY **** //
	@TestVisible
	private DatabaseLayer useDatabase() {
		// All instances constructed from now on will use "real" DML/SOQL
		this.useDml(new Dml(this));
		this.useSoql(new Soql(this));
		return this;
	}

	@TestVisible
	private DatabaseLayer useMocks() {
		// All instances constructed from now on will use mock DML/SOQL
		this.useDml(new MockDml());
		this.useSoql(new MockSoql());
		return this;
	}

	@TestVisible
	private DatabaseLayer useDml(Dml instance) {
		this.dml = instance?.clone()?.reset();
		return this;
	}

	@TestVisible
	private DatabaseLayer useSoql(Soql instance) {
		this.soql = (Soql) instance?.clone()?.reset();
		return this;
	}
}
