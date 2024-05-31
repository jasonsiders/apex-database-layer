public class DatabaseLayer {
    // **** STATIC **** // 
    static final DatabaseLayer SINGLETON_INSTANCE = new DatabaseLayer();

    public static DatabaseLayer get() {
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
    
    // **** TEST ONLY **** //
    @TestVisible
    private DatabaseLayer useDatabase() {
        // Revert all instances to use the 
        this.useDml(new Dml(this));
        this.useSoql(new Soql(this));
        return this;
    }
    
    @TestVisible
    private DatabaseLayer useMocks() {
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