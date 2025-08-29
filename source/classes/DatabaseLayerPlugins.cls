/**
 * @description Utility for managing and initializing plugin implementations.
 */
@SuppressWarnings('PMD.AvoidDebugStatements')
public without sharing class DatabaseLayerPlugins {	
	/**
	 * @description The DML pre and post processor instance for this plugin configuration.
	 */
	@SuppressWarnings('PMD.PropertyNamingConventions')
	public Dml.PreAndPostProcessor Dml { 
		get {
			Dml = Dml ?? (Dml.PreAndPostProcessor) this.initPlugin(DatabaseLayerSetting__mdt.DmlPreAndPostProcessor__c);
			return Dml;
		}
		private set;
	}
	/**
	 * @description The SOQL pre and post processor instance for this plugin configuration.
	 */
	@SuppressWarnings('PMD.PropertyNamingConventions')
	public Soql.PreAndPostProcessor Soql { 
		get {
			Soql = Soql ?? (Soql.PreAndPostProcessor) this.initPlugin(DatabaseLayerSetting__mdt.SoqlPreAndPostProcessor__c);
			return Soql;
		}
		private set;
	}

	/**
	 * @description Default constructor that defers plugin initialization to avoid circular dependencies.
	 * @param factory The DatabaseLayer factory instance
	 */
	public DatabaseLayerPlugins(DatabaseLayer factory) {
		// Deferred initialization to avoid circular dependency with DatabaseLayer.Utils
	}

	/**
	 * @description Initializes a plugin instance based on custom metadata configuration.
	 * @param field The SObjectField on DatabaseLayerSetting__mdt containing the plugin class name
	 * @return The instantiated plugin object, or null if initialization fails
	 */
	public Object initPlugin(SObjectField field) {
		String className;
		try {
			className = (String) DatabaseLayer.Utils?.Settings?.get(field);
			return (className != null) ? Type.forName(className)?.newInstance() : null;
		} catch (Exception error) {
			String msg = DatabaseLayerPlugins.class + ': Invalid ' + field + ': "' + className + '\nDetails: ' + error;
			System.debug(System.LoggingLevel.WARN, msg);
			return null;
		}
	}

	/**
	 * @description Force-initialize the Dml/Soql plugins based on current DatabaseLayerSetting__mdt values
	 * Callers may use this method to force a recalculation of these plugins after setting CMDT field values
	 */
	/* prettier-ignore */
	@TestVisible
    private void init() {
        this.Dml = (Dml.PreAndPostProcessor) this.initPlugin(DatabaseLayerSetting__mdt.DmlPreAndPostProcessor__c);
        this.Soql = (Soql.PreAndPostProcessor) this.initPlugin(DatabaseLayerSetting__mdt.SoqlPreAndPostProcessor__c);
    }
}
