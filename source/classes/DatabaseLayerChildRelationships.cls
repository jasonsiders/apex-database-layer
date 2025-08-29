/**
 * @description Utility for retrieving and caching Schema.ChildRelationship objects from SObjectFields.
 * Provides efficient access to relationship metadata with built-in caching for performance.
 */
public class DatabaseLayerChildRelationships {
	private static final Map<SObjectType, DatabaseLayerChildRelationships.Describe> DESCRIBES;

	static {
		DESCRIBES = new Map<SObjectType, DatabaseLayerChildRelationships.Describe>{};
	}

	/**
	 * @description Constructor for DatabaseLayerChildRelationships.
	 * @param factory The DatabaseLayer factory instance
	 */
	@SuppressWarnings('PMD.EmptyStatementBlock')
	public DatabaseLayerChildRelationships(DatabaseLayer factory) {
		// Access this class via the DatabaseLayer.Utils.ChildRelationships property
	}

	/**
	 * @description Retrieves the child relationship for a lookup field on a specific parent object type.
	 * @param lookupField The lookup field to find the relationship for
	 * @param referenceTo The parent SObject type
	 * @return The corresponding Schema.ChildRelationship
	 */
	public Schema.ChildRelationship getChildRelationshipFrom(SObjectField lookupField, SObjectType referenceTo) {
		return this.getDescribeFromMap(referenceTo)?.get(lookupField);
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

	private DatabaseLayerChildRelationships.Describe getDescribeFromMap(SObjectType objectType) {
		// Retrieves a Describe object, which represents a cached Schema.ChildRelationships for the SObjectType
		DatabaseLayerChildRelationships.Describe describe = DESCRIBES?.containsKey(objectType)
			? DESCRIBES?.get(objectType)
			: new DatabaseLayerChildRelationships.Describe(objectType);
		DESCRIBES?.put(objectType, describe);
		return describe;
	}

	private class Describe {
		// Object used to map & stash Schema.ChildRelationships by their lookup field
		private Map<SObjectField, Schema.ChildRelationship> relationshipMap;

		/**
		 * @description Constructor that initializes the cached relationships for the specified object type.
		 * @param objectType The SObject type to cache relationships for
		 */
		public Describe(SObjectType objectType) {
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
