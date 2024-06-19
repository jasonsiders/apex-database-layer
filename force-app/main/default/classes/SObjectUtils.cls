public abstract class SObjectUtils {
	static Map<SObjectType, RelationshipRepo> relationships = new Map<SObjectType, RelationshipRepo>();

	public static Schema.ChildRelationship getChildRelationshipFrom(SObjectField lookupField, SObjectType referenceTo) {
		// Returns the Schema.ChildRelationshp on the referenceTo SObjectType, that the provided lookupField points to.
		// Ex., getChildRelationshipFrom(Task.WhoId, Lead.SObjectType) -> Lead.Tasks
		return SObjectUtils.getRelationshipsFrom(referenceTo)?.get(lookupField);
	}

	public static Schema.ChildRelationship getChildRelationshipFrom(SObjectField lookupField) {
		// Overload that uses the first SObjectType in the getReferenceTo() list to find the child relationship.
		// Use this overload when you know the field in question is not polymorphic; ex., Contact.AccountId.
		// * Note: the Schema.getReferenceTo() method returns a List<SObjectType>, not a single SObjectType.
		// Typically, a field is only be related to a single SObjectType; exceptions include polymorphic fields (ie, Task.WhatId).
		List<SObjectType> references = lookupField?.getDescribe()?.getReferenceTo();
		SObjectType referenceTo = references?.isEmpty() == false ? references[0] : null;
		return SObjectUtils.getChildRelationshipFrom(lookupField, referenceTo);
	}

	// **** PRIVATE **** //
	private static RelationshipRepo getRelationshipsFrom(SObjectType objectType) {
		// Retrieves a RelationshipRepo object that represents cached Schema.ChildRelationships for the SObjectType
		RelationshipRepo repo = SObjectUtils.relationships?.containsKey(objectType)
			? SObjectUtils.relationships?.get(objectType)
			: new RelationshipRepo(objectType);
		SObjectUtils.relationships?.put(objectType, repo);
		return repo;
	}

	// **** INNER **** //
	private class RelationshipRepo {
		// Object used to map & cache Schema.ChildRelationships by their lookup field.
		// This is necessary since the operation to retrieve Schema.ChildRelationships from an object can be expensive,
		// and Salesforce's built in Schema caching doesn't seem to handle this.
		// In the future, consider upgrading this to use actual System.Cache
		private Map<SObjectField, Schema.ChildRelationship> relationshipMap;

		public RelationshipRepo(SObjectType objectType) {
			this.relationshipMap = new Map<SObjectField, Schema.ChildRelationship>();
			this.mapRelationships(objectType);
		}

		public Schema.ChildRelationship get(SObjectField field) {
			return this.relationshipMap?.get(field);
		}

		private List<Schema.ChildRelationship> getRelationshipList(SObjectType objectType) {
			return objectType?.getDescribe()?.getChildRelationships() ?? new List<Schema.ChildRelationship>();
		}

		private void mapRelationships(SObjectType objectType) {
			for (Schema.ChildRelationship relationship : this.getRelationshipList(objectType)) {
				SObjectField field = relationship?.getField();
				this.relationshipMap?.put(field, relationship);
			}
		}
	}
}
