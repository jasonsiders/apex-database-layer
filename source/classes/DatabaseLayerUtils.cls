/**
 * @description Internal utility class providing framework-specific functionality in a pseudo-namespace pattern.
 */
@SuppressWarnings('PMD.CognitiveComplexity')
public without sharing class DatabaseLayerUtils {
	// Note: These properties do not use traditional naming conventions to support a 'namespace-like' API
	/**
	 * @description Cache utility for managing DatabaseLayer-specific caching operations.
	 */
	@SuppressWarnings('PMD.PropertyNamingConventions')
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
	public DatabaseLayerPlugins Plugins { get; private set; }
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
		// Initialize plugins with null settings to avoid circular dependency during construction
		this.Plugins = new DatabaseLayerPlugins(factory);
	}

	private DatabaseLayerSetting__mdt getSettings() {
		// Return the first mapped Database Layer Setting object
		// A validation rule ensures there will only be one record of this type in an org:
		Map<String, SObject> allSettingsMap = DatabaseLayer.Cmdt
			?.ofType(DatabaseLayerSetting__mdt.SObjectType)
			?.getAll();
		List<DatabaseLayerSetting__mdt> allSettings = (List<DatabaseLayerSetting__mdt>) allSettingsMap?.values();
		DatabaseLayerSetting__mdt result = allSettings?.isEmpty() == false ? allSettings?.get(0) : null;
		// Update plugins with loaded settings after they are loaded
		this.Plugins?.updateSettings(result);
		return result;
	}
}
