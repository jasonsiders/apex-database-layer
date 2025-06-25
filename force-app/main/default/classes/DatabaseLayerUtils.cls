public class DatabaseLayerUtils {
	public final DatabaseLayerUtils.ChildRelationships childRelationships { get; private set; }
	public final DatabaseLayerUtils.MetadataSelector metadataSelector { get; private set; }

	@SuppressWarnings('PMD.EmptyStatementBlock')
	public DatabaseLayerUtils(DatabaseLayer factory) {
		// The utility class can't be manually constructed outside of this package
		// Necessary in the absence of @NamespaceAccessible-like annotation for unlocked packages
		this.childRelationships = new DatabaseLayerUtils.ChildRelationships();
		this.metadataSelector = new DatabaseLayerUtils.MetadataSelector();
	}

	// **** INNER **** //
	public class ChildRelationships {
		/**
		 * This class makes it easier to retrieve Schema.ChildRelationship objects from their linked SObjectField.
		 * Unlike SObjectTypes/SObjectFields, ChildRelationships do not have a declarable token, ex. Account.Contacts.
		 * Callers typically have to perform expensive & verbose describe operations to retrieve this object.
		 * Using this utility, callers can retrieve a relationship object with a single line, ex:
		 * `Schema.ChildRelationship rel = DatabaseLayer.Utils.ChildRelationships.getChildRelationshipFrom(Contact.AccountId);`
		 * As an added bonus, the relationship information for the lookup field's referenceTo object is cached,
		 * so that successive calls to the same object do not take the same processing time.
		 **/
		private Map<SObjectType, DatabaseLayerUtils.CachedDescribe> describes;

		private ChildRelationships() {
			this.describes = new Map<SObjectType, DatabaseLayerUtils.CachedDescribe>();
		}

		public Schema.ChildRelationship getChildRelationshipFrom(SObjectField lookupField, SObjectType referenceTo) {
			// Returns the Schema.ChildRelationshp on the referenceTo SObjectType, that the provided lookupField points to.
			// Ex., getChildRelationshipFrom(Task.WhoId, Lead.SObjectType) -> Lead.Tasks
			return this.getDescribeFromCache(referenceTo)?.get(lookupField);
		}

		public Schema.ChildRelationship getChildRelationshipFrom(SObjectField lookupField) {
			// Overload that uses the first SObjectType in the getReferenceTo() list to find the child relationship.
			// Use this overload when you know the field in question is not polymorphic; ex., Contact.AccountId.
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

	public class MetadataSelector {
		/**
		 * This utility class is used to retrieve DatabaseLayerSetting__mdt settings from the org.
		 * It also provides a seam for mock settings to be injected.
		 * Note: The framework will *always* use the first defined record;
		 * There is a validation rule which helps enforce only 1x DatabaseLayerSetting__mdt per org
		 */
		@TestVisible
		private List<DatabaseLayerSetting__mdt> settings;

		public DatabaseLayerSetting__mdt get() {
			// Retrieve the first/default settings record; if none defined, returns null
			this.settings = this.settings ?? DatabaseLayerSetting__mdt.getAll()?.values();
			return this.settings?.isEmpty() == false ? this.settings?.get(0) : null;
		}
	}

	private class CachedDescribe {
		// Object used to map & cache Schema.ChildRelationships by their lookup field.
		// Useful since the operation to retrieve Schema.ChildRelationships from an object can be expensive,
		// and Salesforce's built in Schema caching mechanism doesn't seem to handle this.
		// Note: In the future, consider upgrading this to use actual System.Cache.
		private Map<SObjectField, Schema.ChildRelationship> relationshipMap;

		public CachedDescribe(SObjectType objectType) {
			this.mapRelationships(objectType);
		}

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
