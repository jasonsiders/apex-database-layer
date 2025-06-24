public class DatabaseLayerUtils {
	private static final DatabaseLayerUtils.ChildRelationshipUtility CHILD_RELATIONSHIPS;

	static {
		CHILD_RELATIONSHIPS = new DatabaseLayerUtils.ChildRelationshipUtility();
	}

	@SuppressWarnings('PMD.EmptyStatementBlock')
	public DatabaseLayerUtils(DatabaseLayer factory) {
		// The utility class can't be manually constructed outside of this package
		// Necessary in the absence of @NamespaceAccessible-like annotation for unlocked packages
	}

	public Schema.ChildRelationship getChildRelationshipFrom(SObjectField lookupField, SObjectType referenceTo) {
		// Returns the Schema.ChildRelationshp on the referenceTo SObjectType, that the provided lookupField points to.
		// Ex., getChildRelationshipFrom(Task.WhoId, Lead.SObjectType) -> Lead.Tasks
		return CHILD_RELATIONSHIPS?.getChildRelationshipFrom(lookupField, referenceTo);
	}

	public Schema.ChildRelationship getChildRelationshipFrom(SObjectField lookupField) {
		// Overload that uses the first SObjectType in the getReferenceTo() list to find the child relationship.
		// Use this overload when you know the field in question is not polymorphic; ex., Contact.AccountId.
		return CHILD_RELATIONSHIPS?.getChildRelationshipFrom(lookupField);
	}

	// **** INNER **** //
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

	private class ChildRelationshipUtility {
		/**
		 * This small utility aims to make it easier to retrieve Schema.ChildRelationship objects from their linked SObjectField.
		 * Unlike SObjectTypes/SObjectFields, they do not have a declarable token, ex. Account.Contacts.
		 * Callers typically have to perform expensive & verbose describe operations to retrieve this object.
		 * Using this utility, callers can retrieve a relationship object with a single line, ex:
		 * `Schema.ChildRelationship rel = DatabaseLayer.Utils.getChildRelationshipFrom(Contact.AccountId);`
		 * As an added bonus, the relationship information for the lookup field's referenceTo object is cached,
		 * so that successive calls to the same object do not take the same processing time.
		 **/
		private Map<SObjectType, DatabaseLayerUtils.CachedDescribe> describes;

		private ChildRelationshipUtility() {
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
}
