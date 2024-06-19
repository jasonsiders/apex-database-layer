@IsTest
public class MockRecord {
    // **** STATIC **** //
    static final String ID_TOKEN = 'Id'; 
    static Integer numMockIds = 0;

    public static Id mockRecordId(SObjectType objectType) {
        String prefix = objectType?.getDescribe()?.getKeyPrefix();
		String suffix = String.valueOf(MockRecord.numMockIds++);
		String mid = 0?.toString()?.repeat(15 - suffix?.length());
		return prefix + mid + suffix;
    }

    // **** MEMBER **** //
    private SObjectType objectType;
    private Map<String, Object> recordValues;

    public MockRecord(SObject realRecord) {
        this.objectType = realRecord?.getSObjectType();
        this.recordValues = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(realRecord));
    }

    public MockRecord(SObjectType objectType) {
        this(objectType?.newSObject());
    }

    public MockRecord setField(Map<String, Object> incomingValues) {
        this.recordValues?.putAll(incomingValues);
        return this; 
    }

    public MockRecord setField(String fieldName, Object value) {
        return this.setField(new Map<String, Object>{ fieldName => value });
    }

    public MockRecord setField(SObjectField field, Object value) {
        return this.setField(field?.toString(), value);
    }

    public MockRecord setLookup(SObjectField lookupField, SObject parent) {
        // Set the lookup/Id pointer
        this.setField(lookupField, parent?.Id);
        // Set the lookup relationship
        String relationshipName = lookupField?.getDescribe()?.getRelationshipName();
        return this.setField(relationshipName, parent);
    }

    public MockRecord setRelatedList(String relationshipName, List<SObject> relatedRecords) {
        MockRecord.RelatedList relatedList = new MockRecord.RelatedList(relatedRecords);
        return this.setField(relationshipName, relatedList);
    }

    public MockRecord setRelatedList(Schema.ChildRelationship relationship, List<SObject> relatedRecords) {
        return this.setRelatedList(relationship?.getRelationshipName(), relatedRecords);
    }

    public MockRecord setRelatedList(SObjectField lookupField, List<SObject> relatedRecords) {
        Schema.ChildRelationship relationship = SObjectUtils.getChildRelationshipFrom(lookupField);
        return this.setRelatedList(relationship, relatedRecords);
    }

    public MockRecord withId() {
        Id recordId = (Id) this.recordValues?.get(ID_TOKEN) ?? MockRecord.mockRecordId(this.objectType);
        return this.setField(ID_TOKEN, recordId);
    }

    public SObject toSObject() {
        return (SObject) JSON.deserialize(JSON.serialize(this.recordValues), SObject.class);
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