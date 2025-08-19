/**
 * @description Internal utility class providing framework-specific functionality in a pseudo-namespace pattern.
 */
public without sharing class DatabaseLayerUtils {
	// Note: These properties do not use traditional naming conventions to support a 'namespace-like' API
	/**
	 * @description Utility for managing Schema.ChildRelationship objects.
	 */
	@SuppressWarnings('PMD.PropertyNamingConventions')
	public final DatabaseLayerUtils.ChildRelationships ChildRelationships { get; private set; }
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
		this.ChildRelationships = new DatabaseLayerUtils.ChildRelationships();
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
	 * @description Utility for retrieving and caching Schema.ChildRelationship objects from SObjectFields.
	 * Provides efficient access to relationship metadata with built-in caching for performance.
	 */
	public class ChildRelationships {
		private Map<SObjectType, DatabaseLayerUtils.CachedDescribe> describes;

		private ChildRelationships() {
			this.describes = new Map<SObjectType, DatabaseLayerUtils.CachedDescribe>();
		}

		/**
		 * @description Retrieves the child relationship for a lookup field on a specific parent object type.
		 * @param lookupField The lookup field to find the relationship for
		 * @param referenceTo The parent SObject type
		 * @return The corresponding Schema.ChildRelationship
		 */
		public Schema.ChildRelationship getChildRelationshipFrom(SObjectField lookupField, SObjectType referenceTo) {
			return this.getDescribeFromCache(referenceTo)?.get(lookupField);
		}

		/**
		 * @description Retrieves the child relationship for a non-polymorphic lookup field.
		 * @param lookupField The lookup field to find the relationship for
		 * @return The corresponding Schema.ChildRelationship
		 */
		public Schema.ChildRelationship getChildRelationshipFrom(SObjectField lookupField) {
			List<SObjectType> references = lookupField?.getDescribe()?.getReferenceTo();
			// Note: the Schema.getReferenceTo() method returns a List<SObjectType>, not a single SObjectType.
			// Typically, a field is only be related to a single SObjectType; excluding polymorphic fields (ie, Task.WhatId).
			SObjectType referenceTo = references?.isEmpty() == false ? references?.get(0) : null;
			return this.getChildRelationshipFrom(lookupField, referenceTo);
		}

		private DatabaseLayerUtils.CachedDescribe getDescribeFromCache(SObjectType objectType) {
			// Retrieves a CachedDescribe object, which represents a cached Schema.ChildRelationships for the SObjectType
			DatabaseLayerUtils.CachedDescribe describe = this.describes?.containsKey(objectType)
				? this.describes?.get(objectType)
				: new DatabaseLayerUtils.CachedDescribe(objectType);
			this.describes?.put(objectType, describe);
			return describe;
		}
	}

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

	private class CachedDescribe {
		// Object used to map & cache Schema.ChildRelationships by their lookup field.
		// Useful since the operation to retrieve Schema.ChildRelationships from an object can be expensive,
		// and Salesforce's built in Schema caching mechanism doesn't seem to handle this.
		// Note: In the future, consider upgrading this to use actual System.Cache.
		private Map<SObjectField, Schema.ChildRelationship> relationshipMap;

		/**
		 * @description Constructor that initializes the cached relationships for the specified object type.
		 * @param objectType The SObject type to cache relationships for
		 */
		public CachedDescribe(SObjectType objectType) {
			this.mapRelationships(objectType);
		}

		/**
		 * @description Retrieves the cached child relationship for the specified field.
		 * @param field The SObjectField to get the relationship for
		 * @return The corresponding Schema.ChildRelationship or null if not found
		 */
		public Schema.ChildRelationship get(SObjectField field) {
			return this.relationshipMap?.get(field);
		}

		private List<Schema.ChildRelationship> getRelationshipList(SObjectType objectType) {
			return objectType?.getDescribe(Schema.SObjectDescribeOptions.DEFERRED)?.getChildRelationships() ??
				new List<Schema.ChildRelationship>();
		}

		private void mapRelationships(SObjectType objectType) {
			this.relationshipMap = new Map<SObjectField, Schema.ChildRelationship>();
			for (Schema.ChildRelationship relationship : this.getRelationshipList(objectType)) {
				SObjectField field = relationship?.getField();
				this.relationshipMap?.put(field, relationship);
			}
		}
	}
}
