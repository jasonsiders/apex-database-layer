/**
 * @description Internal utility class providing framework-specific functionality in a pseudo-namespace pattern.
 */
@SuppressWarnings('PMD.CognitiveComplexity')
public without sharing class DatabaseLayerUtils {
	// Note: These properties do not use traditional naming conventions to support a 'namespace-like' API
	@SuppressWarnings('PMD.PropertyNamingConventions')
	/**
	 * @description Cache utility for managing DatabaseLayer-specific caching operations.
	 */
	public final DatabaseLayerCache Cache { get; private set; }
	/**
	 * @description Utility for managing Schema.ChildRelationship objects.
	 */
	@SuppressWarnings('PMD.PropertyNamingConventions')
	public final DatabaseLayerChildRelationships ChildRelationships { get; private set; }
	/**
	 * @description Utility for managing plugin implementations.
	 * Note: Plugins are loaded dynamically based on custom metadata configuration.
	 */
	@SuppressWarnings('PMD.PropertyNamingConventions')
	public final DatabaseLayerUtils.Plugins Plugins { get; private set; }
	/**
	 * @description Utility for retrieving DatabaseLayerSetting__mdt configuration records.
	 */
	@SuppressWarnings('PMD.PropertyNamingConventions')
	public DatabaseLayerSetting__mdt Settings {
		get {
			this.Settings = this.Settings ?? this.getSettings();
			return this.Settings;
		}
		private set;
	}

	/**
	 * @description Constructor that initializes all utility sub-components
	 * @param factory The DatabaseLayer factory instance
	 */
	@SuppressWarnings('PMD.EmptyStatementBlock')
	public DatabaseLayerUtils(DatabaseLayer factory) {
		this.Cache = new DatabaseLayerCache(factory);
		this.ChildRelationships = new DatabaseLayerChildRelationships(factory);
		this.Plugins = new DatabaseLayerUtils.Plugins();
	}

	private DatabaseLayerSetting__mdt getSettings() {
		// Return the first mapped Database Layer Setting object
		// A validation rule ensures there will only be one record of this type in an org:
		Map<String, SObject> allSettingsMap = DatabaseLayer.Cmdt
			?.ofType(DatabaseLayerSetting__mdt.SObjectType)
			?.getAll();
		List<DatabaseLayerSetting__mdt> allSettings = (List<DatabaseLayerSetting__mdt>) allSettingsMap?.values();
		return allSettings?.isEmpty() == false ? allSettings?.get(0) : null;
	}

	// **** INNER **** //
	/**
	 * @description Utility for managing and initializing plugin implementations.
	 */
	@SuppressWarnings('PMD.AvoidDebugStatements')
	public class Plugins {
		/**
		 * @description The DML pre and post processor instance for this plugin configuration.
		 */
		@SuppressWarnings('PMD.PropertyNamingConventions')
		public Dml.PreAndPostProcessor Dml { get; private set; }
		/**
		 * @description The SOQL pre and post processor instance for this plugin configuration.
		 */
		@SuppressWarnings('PMD.PropertyNamingConventions')
		public Soql.PreAndPostProcessor Soql { get; private set; }

		/**
		 * @description Default constructor that initializes plugin instances.
		 */
		public Plugins() {
			this.init();
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
				return Type.forName(className)?.newInstance();
			} catch (Exception error) {
				String source = DatabaseLayerUtils.Plugin.class.getName();
				String msg = source + ': Invalid ' + field + ': "' + className + '". Details: ' + error;
				System.debug(System.LoggingLevel.WARN, msg);
				return null;
			}
		}

		/**
		 * @description Initialize the Dml/Soql plugins based on current DatabaseLayerSetting__mdt values
		 */
		/* prettier-ignore */
		@TestVisible
		private void init() {
			this.Dml = (Dml.PreAndPostProcessor) this.initPlugin(DatabaseLayerSetting__mdt.DmlPreAndPostProcessor__c);
			this.Soql = (Soql.PreAndPostProcessor) this.initPlugin(DatabaseLayerSetting__mdt.SoqlPreAndPostProcessor__c);
		}
	}
}
