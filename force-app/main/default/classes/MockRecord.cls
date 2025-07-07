@IsTest
@SuppressWarnings('PMD.ApexDoc, PMD.CognitiveComplexity, PMD.ExcessivePublicCount')
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
	private static final String ID_TOKEN = 'Id';
	private static Integer numMockIds = 0;

	private transient SObjectType objectType;
	private transient Map<String, Object> recordValues;

	public Id Id {
		get {
			// Mirrors standard SObject functionality; all SObject records have an Id property - even untyped!
			return (Id) this.get(ID_TOKEN);
		}
	}

	public MockRecord(SObject realRecord) {
		// This constructor preserves the original values of the provided record.
		this.objectType = realRecord?.getSObjectType();
		this.recordValues = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(realRecord));
	}

	public MockRecord(SObjectType objectType) {
		// This constructor creates a brand new/empty SObject of the provided type.
		this(objectType?.newSObject());
	}

	// **** STATIC **** //
	public static Id initRecordId(SObjectType objectType) {
		// Generate a unique record Id for the given SObjectType, for mock database operations
		String prefix = objectType?.getDescribe(Schema.SObjectDescribeOptions.DEFERRED)?.getKeyPrefix();
		String suffix = String.valueOf(MockRecord.numMockIds++);
		String mid = 0?.toString()?.repeat(15 - suffix?.length());
		return prefix + mid + suffix;
	}

	// **** MEMBER **** //
	public MockRecord addToRelatedList(Schema.ChildRelationship relationship, List<SObject> records) {
		// Adds to the related list used to simulate a child object retrieval in SOQL; ex., SELECT Id, (SELECT Id FROM Contacts) FROM Account LIMIT 1
		return this.addUntypedChildRecords(relationship, records);
	}

	public MockRecord addToRelatedList(SObjectField lookupField, List<SObject> records) {
		Schema.ChildRelationship relationship = this.getChildRelationship(lookupField);
		return this.addToRelatedList(relationship, records);
	}

	public MockRecord addToRelatedList(Schema.ChildRelationship relationship, SObject record) {
		return this.addToRelatedList(relationship, new List<SObject>{ record });
	}

	public MockRecord addToRelatedList(SObjectField lookupField, SObject record) {
		return this.addToRelatedList(lookupField, new List<SObject>{ record });
	}

	public MockRecord addToRelatedList(Schema.ChildRelationship relationship, List<MockRecord> mocks) {
		return this.addUntypedChildRecords(relationship, mocks);
	}

	public MockRecord addToRelatedList(SObjectField lookupField, List<MockRecord> records) {
		Schema.ChildRelationship relationship = this.getChildRelationship(lookupField);
		return this.addToRelatedList(relationship, records);
	}

	public MockRecord addToRelatedList(Schema.ChildRelationship relationship, MockRecord record) {
		return this.addToRelatedList(relationship, new List<MockRecord>{ record });
	}

	public MockRecord addToRelatedList(SObjectField lookupField, MockRecord record) {
		return this.addToRelatedList(lookupField, new List<MockRecord>{ record });
	}

	public Object get(String parameterName) {
		// Retrieve the current record value for the given parameter:
		return this.recordValues?.get(parameterName);
	}

	public Object get(SObjectField field) {
		return this.get(field?.toString());
	}

	public SObject getLookup(SObjectField lookupField) {
		// Retrieves the lookup relationship matching the lookup field, ex., 'contact?.Owner'
		String relationshipName = lookupField?.getDescribe()?.getRelationshipName();
		return (SObject) this.get(relationshipName);
	}

	public List<SObject> getRelatedList(Schema.ChildRelationship relationship) {
		// Retrieves the underlying List<SObject> that makes up the corresponding related list, ex., 'account?.Contacts'
		String relationshipName = relationship?.getRelationshipName();
		MockRecord.RelatedList relatedList = (MockRecord.RelatedList) this.get(relationshipName);
		return relatedList?.getRecords();
	}

	public List<SObject> getRelatedList(SObjectField lookupField) {
		Schema.ChildRelationship relationship = this.getChildRelationship(lookupField);
		return this.getRelatedList(relationship);
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
		return this.addUntypedParentRecord(lookupField, parent);
	}

	public MockRecord setLookup(SObjectField lookupField, MockRecord parent) {
		return this.addUntypedParentRecord(lookupField, parent);
	}

	public MockRecord setRelatedList(Schema.ChildRelationship relationship, List<SObject> relatedRecords) {
		// Sets the related list used to simulate a child object retrieval in SOQL; ex., SELECT Id, (SELECT Id FROM Contacts) FROM Account LIMIT 1
		return this.setUntypedChildRecords(relationship, relatedRecords);
	}

	public MockRecord setRelatedList(SObjectField lookupField, List<SObject> relatedRecords) {
		Schema.ChildRelationship relationship = this.getChildRelationship(lookupField);
		return this.setRelatedList(relationship, relatedRecords);
	}

	public MockRecord setRelatedList(Schema.ChildRelationship relationship, List<MockRecord> relatedRecords) {
		return this.setUntypedChildRecords(relationship, relatedRecords);
	}

	public MockRecord setRelatedList(SObjectField lookupField, List<MockRecord> relatedRecords) {
		Schema.ChildRelationship relationship = this.getChildRelationship(lookupField);
		return this.setRelatedList(relationship, relatedRecords);
	}

	public SObject toSObject() {
		// Builds the specified record
		return (SObject) JSON.deserialize(JSON.serialize(this.recordValues), SObject.class);
	}

	public MockRecord withId() {
		// Provides a unique Id to simulate inserted records.
		// Note: If an Id is already present, its value will NOT be overwritten.
		Id recordId = this.Id ?? MockRecord.initRecordId(this.objectType);
		return this.setField(ID_TOKEN, recordId);
	}

	// **** PRIVATE **** //
	private MockRecord addUntypedChildRecords(Schema.ChildRelationship relationship, Object untypedListOfRecords) {
		// Simulates a child object retrieval in SOQL; ex., SELECT Id, (SELECT Id FROM Contacts) FROM Account LIMIT 1
		// This untyped method supports both mock & real records, used to consolidate logic from strongly-typed overrides
		String relationshipName = relationship?.getRelationshipName();
		MockRecord.RelatedList relatedList = (MockRecord.RelatedList) this.get(relationshipName) ??
			new MockRecord.RelatedList();
		relatedList?.add(untypedListOfRecords);
		this.setField(relationshipName, relatedList);
		return this;
	}

	private MockRecord addUntypedParentRecord(SObjectField lookupField, Object mockOrRealRecord) {
		// Simulates a parent object retrieval in SOQL
		// This untyped method supports both mock & real records, used to consolidate logic from strongly-typed overrides
		// Set the lookup/Id pointer
		Id parentId = (mockOrRealRecord instanceof MockRecord)
			? ((MockRecord) mockOrRealRecord)?.Id
			: ((SObject) mockOrRealRecord)?.Id;
		this.setField(lookupField, parentId);
		// Set the lookup relationship
		String relationshipName = lookupField?.getDescribe()?.getRelationshipName();
		return this.setField(relationshipName, mockOrRealRecord);
	}

	private Schema.ChildRelationship getChildRelationship(SObjectField lookupField) {
		return DatabaseLayer.Utils.ChildRelationships.getChildRelationshipFrom(lookupField);
	}

	private MockRecord setUntypedChildRecords(Schema.ChildRelationship relationship, Object mockOrRealRecords) {
		// Sets the related list used to simulate a child object retrieval in SOQL
		// This untyped method supports both mock & real records, used to consolidate logic from strongly-typed overrides
		String relationshipName = relationship?.getRelationshipName();
		// Overwrite previously set relationship name values before re-adding the related list:
		this.recordValues?.remove(relationshipName);
		return this.addUntypedChildRecords(relationship, mockOrRealRecords);
	}

	// **** INNER **** //
	private class RelatedList {
		// Represents a child object relationship retrieved by SOQL.
		// This structure is required when mocking related lists on an SObject
		// ** Members
		private Boolean done;
		private List<SObject> records {
			get {
				return this.getRecords();
			}
		}
		private Integer totalSize {
			get {
				return this.getSize();
			}
		}
		// ** Transient
		private transient List<MockRecord> mockRecords;
		private transient List<SObject> realRecords;

		private RelatedList() {
			this.done = true;
			this.mockRecords = new List<MockRecord>();
			this.realRecords = new List<SObject>();
		}

		private RelatedList add(Object incoming) {
			if (incoming instanceof List<MockRecord>) {
				List<MockRecord> mocks = (List<MockRecord>) incoming;
				this.mockRecords?.addAll(mocks);
			} else {
				List<SObject> real = (List<SObject>) incoming;
				this.realRecords?.addAll(real);
			}
			return this;
		}

		private List<SObject> getRecords() {
			// Gets a consolidated list of SObject records,
			// This may consist of both real records, and all mocks' toSObject values
			List<SObject> results = new List<SObject>();
			results?.addAll(this.realRecords);
			for (MockRecord mockRecord : this.mockRecords) {
				SObject record = mockRecord?.toSObject();
				results?.add(record);
			}
			return results;
		}

		private Integer getSize() {
			Integer numMocks = this.mockRecords?.size() ?? 0;
			Integer numRecords = this.realRecords?.size() ?? 0;
			return numMocks + numRecords;
		}
	}
}
