/**
 * @description Utility for managing and initializing plugin implementations.
 */
@SuppressWarnings('PMD.AvoidDebugStatements')
public without sharing class DatabaseLayerPlugins {
	private DatabaseLayerSetting__mdt settings;

	/**
	 * @description The DML pre and post processor instance for this plugin configuration.
	 */
	@SuppressWarnings('PMD.PropertyNamingConventions')
	public Dml.PreAndPostProcessor Dml {
		get {
			// prettier-ignore
			this.Dml = this.Dml ?? (Dml.PreAndPostProcessor) this.initPlugin(DatabaseLayerSetting__mdt.DmlPreAndPostProcessor__c);
			return this.Dml;
		}
		private set;
	}
	/**
	 * @description The SOQL pre and post processor instance for this plugin configuration.
	 */
	@SuppressWarnings('PMD.PropertyNamingConventions')
	public Soql.PreAndPostProcessor Soql {
		get {
			// prettier-ignore
			this.Soql = this.Soql ?? (Soql.PreAndPostProcessor) this.initPlugin(DatabaseLayerSetting__mdt.SoqlPreAndPostProcessor__c);
			return Soql;
		}
		private set;
	}

	/**
	 * @description Constructor that accepts settings to avoid circular dependencies.
	 * @param factory The DatabaseLayer factory, used to restrict constrction to internal callers only
	 */
	@SuppressWarnings('PMD.EmptyStatementBlock')
	public DatabaseLayerPlugins(DatabaseLayer factory) {
		// Can only be accessed via the DatabaseLayer.Utils.Plugins static property
	}

	/**
	 * @description Initializes a plugin instance based on custom metadata configuration.
	 * @param field The SObjectField on DatabaseLayerSetting__mdt containing the plugin class name
	 * @return The instantiated plugin object, or null if initialization fails
	 */
	public Object initPlugin(SObjectField field) {
		String className;
		try {
			className = (String) this.settings?.get(field);
			return (className != null) ? Type.forName(className)?.newInstance() : null;
		} catch (Exception error) {
			String msg = DatabaseLayerPlugins.class + ': Invalid ' + field + ': "' + className + '\nDetails: ' + error;
			System.debug(System.LoggingLevel.WARN, msg);
			return null;
		}
	}

	/**
	 * @description Updates the settings for this plugins instance and resets cached plugin instances
	 * @param settings The new DatabaseLayerSetting__mdt configuration
	 */
	public void updateSettings(DatabaseLayerSetting__mdt settings) {
		this.settings = settings;
		this.init();
	}

	/**
	 * @description Force-initialize the Dml/Soql plugins based on current DatabaseLayerSetting__mdt values
	 * Callers may use this method to force a recalculation of these plugins after setting CMDT field values
	 */
	/* prettier-ignore */
	@TestVisible
    private void init() {
        this.Dml = null;
        this.Soql = null;
    }
}
