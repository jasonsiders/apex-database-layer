public abstract class SObjectUtils {
    static Integer numMockIds = 0; 
    
    public static Schema.ChildRelationship getChildRelationshipFrom(SObjectField lookupField) {
        List<SObjectType> relatedToObjects = lookupField?.getDescribe()?.getReferenceTo();
        // * Note: the above Schema method returns a List<SObjectType>, not a single SObjectType.
        // In nearly all cases, this will contain a single SObjectType; notable exceptions include polymorphic fields (ie, Task.WhatId)
        // In these cases, it's better to provide the specific/intended Schema.ChildRelationship when constructing a Subquery
        SObjectType relatedToObject = relatedToObjects?.isEmpty() == false ? relatedToObjects[0] : null;
        List<Schema.ChildRelationship> relationships = relatedToObject?.getDescribe()?.getChildRelationships();
        relationships = relationships ?? new List<Schema.ChildRelationship>();
        for (Schema.ChildRelationship relationship : relationships) {
            // Unfortunately, no way of telling if a Schema.ChildRelationship matches w/out manually iterating & checking their fields
            SObjectField relationshipField = relationship?.getField();
            if (relationshipField == lookupField) {
                return relationship;
            }
        }
        // This should only ever return null if the field isn't a lookup
        return null;
    }

    // **** TEST ONLY **** //
    @TestVisible
    private static SObject mockLookup(SObject originalRecord, SObjectField lookupField, SObject parent) {
        // Populates a parent relationship, ex., Contact.Account with a parent SObject record.
        // Populate the lookup field (ex., SomeLookup__c)
        originalRecord?.put(lookupField, parent?.Id);
        // Populate the lookup relationship (ex., SomeLookup__r)
        String relationshipName = lookupField?.getDescribe()?.getRelationshipName();
        return SObjectUtils.mockReadOnlyFields(originalRecord, relationshipName, parent);
    }

    @TestVisible
    private static Id mockPlatformEventId(SObjectType objectType) {
        // Note: The Id of Platform Events is always a static/non-unique value across all events
        // It does not need to be incremented for uniqueness
        return objectType?.getDescribe()?.getKeyPrefix() + '0'?.repeat(15); 
    }

    @TestVisible
    private static SObject mockReadOnlyFields(SObject originalRecord, Map<String, Object> readOnlyValues) {
        // Sets the value of read-only fields on an existing SObject, returning a copy of that same object.
        // Note: Since JSON de/serialization is involved, cannot actually transform the existing object in memory.
        Map<String, Object> recordValues = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(originalRecord));
        recordValues?.putAll(readOnlyValues);
        return (SObject) JSON.deserialize(JSON.serialize(recordValues), SObject.class); 
    }

    @TestVisible
    private static SObject mockReadOnlyFields(SObject originalRecord, String fieldName, Object value) {
        return SObjectUtils.mockReadOnlyFields(originalRecord, new Map<String, Object>{ fieldName => value });
    }

    @TestVisible
    private static SObject mockReadOnlyFields(SObject originalRecord, SObjectField field, Object value) {
        return SObjectUtils.mockReadOnlyFields(originalRecord, field?.toString(), value); 
    }

    @TestVisible
    private static Id mockRecordId(SObjectType objectType) {
        String prefix = objectType?.getDescribe()?.getKeyPrefix();
        String suffix = String.valueOf(numMockIds++);
        String mid = 0?.toString()?.repeat(15 - suffix?.length());
        return prefix + mid + suffix;
    }

    @TestVisible
    private static SObject mockRelatedList(SObject originalRecord, String relationshipName, List<SObject> children) {
        // Populates a child relationship, ex., Account.Contacts with a list of SObjects
        RelatedList relatedList = new RelatedList(children);
        return SObjectUtils.mockReadOnlyFields(originalRecord, relationshipName, relatedList);
    }

    @TestVisible
    private static SObject mockRelatedList(SObject originalRecord, Schema.ChildRelationship relationship, List<SObject> children) {
        return SObjectUtils.mockRelatedList(originalRecord, relationship?.getRelationshipName(), children);
    }

    @TestVisible
    private static SObject mockRelatedList(SObject originalRecord, SObjectField lookupField, List<SObject> children) {
        Schema.ChildRelationship relationship = SObjectUtils.getChildRelationshipFrom(lookupField);
        return SObjectUtils.mockRelatedList(originalRecord, relationship, children);
    }

    // **** INNER **** //
    private class RelatedList {
		// Represents a child object relationship retrieved by SOQL.
		// This structure is required when mocking related lists on an SObject
		Boolean done;
		List<SObject> records;
		Integer totalSize;

		private RelatedList(List<SObject> records) {
			this.done = true;
			this.records = records ?? new List<SObject>();
			this.totalSize = records?.size() ?? 0; 
		}
	}
}