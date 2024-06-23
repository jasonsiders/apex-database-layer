public abstract class ChildRelationshipService {
	/**
	 * This small service aims to make it easier to retrieve Schema.ChildRelationship objects from their linked SObjectField.
	 * Unlike SObjectTypes/SObjectFields, they do not have a declarable token, ex. Account.Contacts.
	 * Callers typically have to perform expensive & verbose describe operations to retrieve this object.
	 * By using this class, callers can retrieve a relationship object with a single line, ex:
	 * `Schema.ChildRelationship rel = ChildRelationshipService.getChildRelationshipFrom(Contact.AccountId);`
	 * As an added bonus, the relationship information for the lookup field's referenceTo object is cached,
	 * so that successive calls to the same object do not take the same processing time.
	 **/
	static final Map<SObjectType, ChildRelationshipService.CachedDescribe> DESCRIBES = new Map<SObjectType, ChildRelationshipService.CachedDescribe>();

	public static Schema.ChildRelationship getChildRelationshipFrom(SObjectField lookupField, SObjectType referenceTo) {
		// Returns the Schema.ChildRelationshp on the referenceTo SObjectType, that the provided lookupField points to.
		// Ex., getChildRelationshipFrom(Task.WhoId, Lead.SObjectType) -> Lead.Tasks
		return ChildRelationshipService.getDescribeFromCache(referenceTo)?.get(lookupField);
	}

	public static Schema.ChildRelationship getChildRelationshipFrom(SObjectField lookupField) {
		// Overload that uses the first SObjectType in the getReferenceTo() list to find the child relationship.
		// Use this overload when you know the field in question is not polymorphic; ex., Contact.AccountId.
		// * Note: the Schema.getReferenceTo() method returns a List<SObjectType>, not a single SObjectType.
		// Typically, a field is only be related to a single SObjectType; exceptions include polymorphic fields (ie, Task.WhatId).
		List<SObjectType> references = lookupField?.getDescribe()?.getReferenceTo();
		SObjectType referenceTo = references?.isEmpty() == false ? references[0] : null;
		return ChildRelationshipService.getChildRelationshipFrom(lookupField, referenceTo);
	}

	// **** PRIVATE **** //
	private static ChildRelationshipService.CachedDescribe getDescribeFromCache(SObjectType objectType) {
		// Retrieves a CachedDescribe object that represents cached Schema.ChildRelationships for the SObjectType
		ChildRelationshipService.CachedDescribe repo = DESCRIBES?.containsKey(objectType)
			? DESCRIBES?.get(objectType)
			: new ChildRelationshipService.CachedDescribe(objectType);
		DESCRIBES?.put(objectType, repo);
		return repo;
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
			return objectType?.getDescribe()?.getChildRelationships() ?? new List<Schema.ChildRelationship>();
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
