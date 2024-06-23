@IsTest
public class MockRecord {
	/**
	 * This class uses a builder pattern to construct SObject records for the purpose of mock database operations.
	 * It supports the following:
	 * - Setting "normal" fields (like Account.Name)
	 * - Setting read-only fields (like Account.CreatedDate)
	 * - Setting lookup relationships (like Account.Owner & Account.OwnerId)
	 * - Setting child relationships (like Account.Contacts)
	 * - Generating mock Ids, to simulate inserted records
	 * Once your MockRecord is ready to build, call `toSObject()` and cast the output to an SObject variable.
	 **/
	// **** STATIC **** //
	private static final String ID_TOKEN = 'Id';
	private static Integer numMockIds = 0;

	public static Id initRecordId(SObjectType objectType) {
		// Generate a unique record Id for the given SObjectType, for mock database operations
		String prefix = objectType?.getDescribe()?.getKeyPrefix();
		String suffix = String.valueOf(MockRecord.numMockIds++);
		String mid = 0?.toString()?.repeat(15 - suffix?.length());
		return prefix + mid + suffix;
	}

	// **** MEMBER **** //
	private SObjectType objectType;
	private Map<String, Object> recordValues;

	public MockRecord(SObject realRecord) {
		// This constructor preserves the original values of the provided record.
		this.objectType = realRecord?.getSObjectType();
		this.recordValues = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(realRecord));
	}

	public MockRecord(SObjectType objectType) {
		// This constructor creates a brand new/empty SObject of the provided type.
		this(objectType?.newSObject());
	}

	public MockRecord setField(Map<String, Object> incomingValues) {
		// Sets the provided field(s) to their specified values(s)
		// If a field value is already set, it will be overwritten.
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
		// Simulates a parent object retrieval in SOQL; ex., SELECT Id, Account.Name FROM Contact LIMIT 1
		// Set the lookup/Id pointer
		this.setField(lookupField, parent?.Id);
		// Set the lookup relationship
		String relationshipName = lookupField?.getDescribe()?.getRelationshipName();
		return this.setField(relationshipName, parent);
	}

	public MockRecord setRelatedList(String relationshipName, List<SObject> relatedRecords) {
		// Simulates a child object retrieval in SOQL; ex., SELECT Id, (SELECT Id FROM Contacts) FROM Account LIMIT 1
		MockRecord.RelatedList relatedList = new MockRecord.RelatedList(relatedRecords);
		return this.setField(relationshipName, relatedList);
	}

	public MockRecord setRelatedList(Schema.ChildRelationship relationship, List<SObject> relatedRecords) {
		return this.setRelatedList(relationship?.getRelationshipName(), relatedRecords);
	}

	public MockRecord setRelatedList(SObjectField lookupField, List<SObject> relatedRecords) {
		Schema.ChildRelationship relationship = ChildRelationshipService.getChildRelationshipFrom(lookupField);
		return this.setRelatedList(relationship, relatedRecords);
	}

	public MockRecord withId() {
		// Provides a unique Id to simulate inserted records.
		// Note: If an Id is already present, its value will NOT be overwritten.
		Id recordId = (Id) this.recordValues?.get(ID_TOKEN) ?? MockRecord.initRecordId(this.objectType);
		return this.setField(ID_TOKEN, recordId);
	}

	public SObject toSObject() {
		// Builds the specified record
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
