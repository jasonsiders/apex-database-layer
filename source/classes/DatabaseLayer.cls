/**
 * @description Main entry point for the Apex Database Layer library. Provides singleton access to DML and SOQL providers with integrated mocking capabilities.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global class DatabaseLayer {
	public static final DatabaseLayerUtils UTILS;
	private static final DatabaseLayer INSTANCE;

	static {
		INSTANCE = new DatabaseLayer();
		UTILS = new DatabaseLayerUtils(INSTANCE);
	}

	private Cmdt currentCmdt;
	private Dml currentDml;
	private SoqlProvider currentSoql;

	private DatabaseLayer() {
		this.currentCmdt = new Cmdt(this);
		this.currentDml = new Dml(this);
		this.currentSoql = new SoqlProvider(this);
	}

	// **** STATIC **** //
	/**
	 * @description Primary access point for CMDT operations. Returns the currently configured CMDT provider instance.
	 * @return The current CMDT provider (real or mock based on configuration)
	 */
	@SuppressWarnings('PMD.PropertyNamingConventions')
	global static Cmdt Cmdt {
		get {
			return INSTANCE?.currentCmdt;
		}
	}
	/**
	 * @description Primary access point for DML operations. Returns the currently configured DML provider instance.
	 * @return Current DML provider (real or mock based on configuration)
	 */
	@SuppressWarnings('PMD.PropertyNamingConventions')
	global static Dml Dml {
		get {
			return INSTANCE?.currentDml;
		}
	}
	/**
	 * @description Primary access point for SOQL operations. Returns the currently configured SOQL provider instance.
	 * @return Current SOQL provider (real or mock based on configuration)
	 */
	@SuppressWarnings('PMD.PropertyNamingConventions')
	global static SoqlProvider Soql {
		get {
			return INSTANCE?.currentSoql;
		}
	}

	/**
	 * @description Switches both DML and SOQL providers to use mock implementations for testing.
	 */
	@TestVisible
	private static void useMocks() {
		DatabaseLayer.useMockDml();
		DatabaseLayer.useMockSoql();
	}

	/**
	 * @description Switches the DML provider to use mock implementation for testing.
	 * @return The mock DML instance that was configured
	 */
	@TestVisible
	private static MockDml useMockDml() {
		INSTANCE.currentDml = new MockDml(INSTANCE);
		return (MockDml) INSTANCE.currentDml;
	}

	/**
	 * @description Switches the SOQL provider to use mock implementation for testing.
	 * @return The SOQL provider configured for mocking
	 */
	@TestVisible
	private static SoqlProvider useMockSoql() {
		return INSTANCE.currentSoql?.useMocks(true);
	}

	/**
	 * @description Switches the DML provider back to real database operations.
	 * @return The real DML instance that was configured
	 */
	@TestVisible
	private static Dml useRealDml() {
		INSTANCE.currentDml = new Dml(INSTANCE);
		return INSTANCE.currentDml;
	}

	/**
	 * @description Switches the SOQL provider back to real database operations.
	 * @return The SOQL provider configured for real operations
	 */
	@TestVisible
	private static SoqlProvider useRealSoql() {
		return INSTANCE.currentSoql?.useMocks(false);
	}

	/**
	 * @description Switches both DML and SOQL providers back to real database operations.
	 */
	@TestVisible
	private static void useRealData() {
		DatabaseLayer.useRealDml();
		DatabaseLayer.useRealSoql();
	}

	// **** INNER **** //
	/**
	 * @description Factory class responsible for provisioning SOQL instances with proper configuration and plugin support.
	 */
	global virtual class SoqlProvider {
		protected Boolean useMocks { get; protected set; }

		/**
		 * @description Initializes a new SOQL provider instance with default configuration.
		 * Sets up plugins and configures for real database operations by default.
		 * @param factory The parent DatabaseLayer factory instance
		 */
		protected SoqlProvider(DatabaseLayer factory) {
			this.useMocks = false;
		}

		/**
		 * @description Creates a new SOQL query builder for the specified SObject type.
		 * @param objectType The SObject type to query
		 * @return A configured SOQL builder instance (real or mock based on current configuration)
		 */
		global Soql newQuery(SObjectType objectType) {
			Soql query = (this.useMocks == true) ? new MockSoql(INSTANCE) : new Soql(INSTANCE);
			return query?.setFrom(objectType)?.toSoql();
		}

		private DatabaseLayer.SoqlProvider useMocks(Boolean value) {
			this.useMocks = value;
			return this;
		}
	}
}
