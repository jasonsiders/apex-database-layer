/**
 * @description Main entry point for the Apex Database Layer library. Provides singleton access to DML and SOQL providers with integrated mocking capabilities.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global class DatabaseLayer {
	private static final DatabaseLayer INSTANCE = new DatabaseLayer();
	@SuppressWarnings('PMD.FieldNamingConventions')
	@TestVisible
	private static DatabaseLayer.Configuration Config = new DatabaseLayer.Configuration();

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
	 * @description Provides access to utility methods for database operations and testing.
	 * @return Singleton instance of the DatabaseLayerUtils class
	 */
	@SuppressWarnings('PMD.PropertyNamingConventions')
	public static final DatabaseLayerUtils Utils {
		get {
			DatabaseLayer.Utils = DatabaseLayer.Utils ?? new DatabaseLayerUtils(INSTANCE);
			return DatabaseLayer.Utils;
		}
		private set;
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
		// ! Deprecated: Will be removed in a future version
		// ! Replace usage with DatabaseLayer.Config.useMockDml = true
		INSTANCE.currentDml = new MockDml(INSTANCE);
		return (MockDml) INSTANCE.currentDml;
	}

	/**
	 * @description Switches the SOQL provider to use mock implementation for testing.
	 * @return The SOQL provider configured for mocking
	 */
	@TestVisible
	private static SoqlProvider useMockSoql() {
		// ! Deprecated: Will be removed in a future version
		// ! Replace usage with DatabaseLayer.Config.useMockSoql = true
		return INSTANCE.currentSoql?.useMocks(true);
	}

	/**
	 * @description Switches the DML provider back to real database operations.
	 * @return The real DML instance that was configured
	 */
	@TestVisible
	private static Dml useRealDml() {
		// ! Deprecated: Will be removed in a future version
		// ! Replace usage with DatabaseLayer.Config.useMockDml = false
		INSTANCE.currentDml = new Dml(INSTANCE);
		return INSTANCE.currentDml;
	}

	/**
	 * @description Switches the SOQL provider back to real database operations.
	 * @return The SOQL provider configured for real operations
	 */
	@TestVisible
	private static SoqlProvider useRealSoql() {
		// ! Deprecated: Will be removed in a future version
		// ! Replace usage with DatabaseLayer.Config.useMockSoql = false
		return INSTANCE.currentSoql?.useMocks(false);
	}

	/**
	 * @description Switches both DML and SOQL providers back to real database operations.
	 */
	@TestVisible
	private static void useRealData() {
		// ! Deprecated: Will be removed in a future version
		// ! Replace usage with DatabaseLayer.Config.useMockDml/Soql = false
		DatabaseLayer.useRealDml();
		DatabaseLayer.useRealSoql();
	}

	// **** INNER **** //
	global class Configuration {
		global Boolean useMockableCmdt {
			get;
			set {
				this.set(DatabaseLayer.Module.CMDT, value);
			}
		}
		global Boolean useMockDml {
			get;
			set {
				this.set(DatabaseLayer.Module.DML, value);
			}
		}
		global Boolean useMockSoql {
			get;
			set {
				this.set(DatabaseLayer.Module.SOQL, value);
			}
		}

		private Configuration() {
			// TODO: Think about the defaults for useMockableCmdt
			this.useMockableCmdt = Test.isRunningTest();
			this.useMockDml = false;
			this.useMockSoql = false;
		}

		private void set(DatabaseLayer.Module module, Boolean value) {
			if (module == DatabaseLayer.Module.CMDT) {
				INSTANCE.currentCmdt = (value == true) ? new Cmdt(INSTANCE) : new MockCmdt(INSTANCE);
			} else if (module == DatabaseLayer.Module.DML) {
				INSTANCE.currentDml = (value == true) ? new Dml(INSTANCE) : new MockDml(INSTANCE);
			} else if (module == DatabaseLayer.Module.SOQL) {
				INSTANCE.currentSoql?.useMocks(value);
			}
		}
	}

	private enum Module {
		CMDT,
		DML,
		SOQL
	}

	/**
	 * @description Factory class responsible for provisioning SOQL instances with proper configuration and plugin support.
	 */
	global virtual class SoqlProvider {
		/**
		 * @description The currently configured SOQL plugin for pre/post processing
		 */
		public Soql.PreAndPostProcessor plugin { get; private set; }
		protected Boolean useMocks { get; protected set; }

		/**
		 * @description Initializes a new SOQL provider instance with default configuration.
		 * Sets up plugins and configures for real database operations by default.
		 * @param factory The parent DatabaseLayer factory instance
		 */
		protected SoqlProvider(DatabaseLayer factory) {
			this.useMocks = false;
			this.initPlugins();
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

		/**
		 * @description Initializes SOQL plugins based on custom metadata configuration.
		 * Note: In production use cases, this will only happen once per transaction
		 * In @IsTest uses cases, this happens every time the caller switches from Soql/MockSoql
		 * Test callers can also call this method directly to recalculate the plugins after injecting mock metadata:
		 */
		@TestVisible
		private void initPlugins() {
			SObjectField field = DatabaseLayerSetting__mdt.SoqlPreAndPostProcessor__c;
			this.plugin = (Soql.PreAndPostProcessor) DatabaseLayer.Utils?.Plugins?.initPlugin(field);
		}

		protected virtual DatabaseLayer.SoqlProvider useMocks(Boolean useMocks) {
			this.useMocks = useMocks;
			return this;
		}
	}
}
