@SuppressWarnings('PMD.ApexDoc,PMD.AvoidGlobalModifier')
global class DatabaseLayer {
	/**
	 * Handles interactions with the Salesforce Database, via DML and SOQL.
	 * Use the `Dml` and `Soql` static properties to get the correct instance of each.
	 * Automatically inject mock versions of these classes via the `useMocks()` method.
	 **/
	public static final DatabaseLayerUtils UTILS;
	private static final DatabaseLayer INSTANCE;

	private Dml currentDml;
	private SoqlProvider currentSoql;

	static {
		INSTANCE = new DatabaseLayer();
		UTILS = new DatabaseLayerUtils(INSTANCE);
	}

	private DatabaseLayer() {
		this.currentDml = new Dml(this);
		this.currentSoql = new SoqlProvider(this);
	}

	// **** STATIC **** //
	// These static properties are the primary way that callers interact with the Database Layer
	@SuppressWarnings('PMD.PropertyNamingConventions')
	global static Dml Dml {
		get {
			// Returns the current Dml instance
			return INSTANCE?.currentDml;
		}
	}
	@SuppressWarnings('PMD.PropertyNamingConventions')
	global static SoqlProvider Soql {
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

	// **** INNER **** //
	global class SoqlProvider {
		/**
		 * This class is responsible for provisioning a Soql instance of the correct type
		 **/
		public Soql.PreAndPostProcessor plugin { get; private set; }
		private Boolean useMocks { get; private set; }

		private SoqlProvider(DatabaseLayer factory) {
			this.useMocks = false;
			this.initPlugins();
		}

		global Soql newQuery(SObjectType objectType) {
			return (this.useMocks == true)
				? new MockSoql(INSTANCE)?.setFrom(objectType)?.toSoql()
				: new Soql(INSTANCE)?.setFrom(objectType)?.toSoql();
		}

		@TestVisible
		private void initPlugins() {
			// Initializes plugins based on the related custom metadata record
			// In production use cases, this will only happen once per transaction
			// In @IsTest uses cases, this happens every time the caller switches from Soql/MockSoql
			// Test callers can also call this method directly to recalculate the plugins after injecting mock metadata:
			SObjectField field = DatabaseLayerSetting__mdt.SoqlPreAndPostProcessor__c;
			this.plugin = (Soql.PreAndPostProcessor) DatabaseLayer.Utils?.Plugins?.initPlugin(field);
		}

		private SoqlProvider useMocks(Boolean useMocks) {
			this.useMocks = useMocks;
			return this;
		}
	}
}
