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

	private MockRecord.Attributes attributes;
	private Boolean isMock = true; // TODO!
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
		this.attributes = new MockRecord.Attributes(this.objectType);
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
		String relationshipName = relationship?.getRelationshipName();
		MockRecord.RelatedList relatedList = (MockRecord.RelatedList) this.get(relationshipName) ??
			new MockRecord.RelatedList(relationship);
		relatedList?.add(records);
		this.setField(relationshipName, relatedList);
		return this;
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

	public MockRecord addToRelatedList(Schema.ChildRelationship relationship, List<MockRecord> records) {
		String relationshipName = relationship?.getRelationshipName();
		MockRecord.RelatedList relatedList = (MockRecord.RelatedList) this.get(relationshipName) ??
			new MockRecord.RelatedList(relationship);
		relatedList?.add(records);
		return this;
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
		return this.recordValues?.get(parameterName);
	}

	public Object get(SObjectField field) {
		return this.get(field?.toString());
	}

	public SObject getLookup(SObjectField lookupField) {
		String relationshipName = lookupField?.getDescribe()?.getRelationshipName();
		return (SObject) this.get(relationshipName);
	}

	public List<SObject> getRelatedList(Schema.ChildRelationship relationship) {
		String relationshipName = relationship?.getRelationshipName();
		MockRecord.RelatedList relatedList = (MockRecord.RelatedList) this.get(relationshipName);
		return relatedList?.records;
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
		// Set the lookup/Id pointer
		this.setField(lookupField, parent?.Id);
		// Set the lookup relationship
		String relationshipName = lookupField?.getDescribe()?.getRelationshipName();
		return this.setField(relationshipName, parent);
	}

	public MockRecord setRelatedList(Schema.ChildRelationship relationship, List<SObject> relatedRecords) {
		// Simulates a child object retrieval in SOQL; ex., SELECT Id, (SELECT Id FROM Contacts) FROM Account LIMIT 1
		String relationshipName = relationship?.getRelationshipName();
		MockRecord.RelatedList relatedList = new MockRecord.RelatedList(relationship)?.add(relatedRecords);
		return this.setField(relationshipName, relatedList);
	}

	public MockRecord setRelatedList(SObjectField lookupField, List<SObject> relatedRecords) {
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
		Id recordId = (Id) this.recordValues?.get(ID_TOKEN) ?? MockRecord.initRecordId(this.objectType);
		return this.setField(ID_TOKEN, recordId);
	}

	// **** PRIVATE **** //
	private Schema.ChildRelationship getChildRelationship(SObjectField lookupField) {
		return DatabaseLayer.Utils.ChildRelationships.getChildRelationshipFrom(lookupField);
	}

	// **** INNER **** //
	private class Attributes {
		/**
		 * Salesforce uses this object to aid in deserializing SObjects
		 * Without this, attempting to serialize & deserialize to a generic List<SObject> results in an error
		 */
		private String type;

		private Attributes(SObjectType objectType) {
			this.type = objectType?.toString();
		}
	}

	private class RelatedList {
		// Represents a child object relationship retrieved by SOQL.
		// This structure is required when mocking related lists on an SObject
		private Boolean done;
		private transient List<Object> mockOrRealRecords;
		private transient SObjectType objectType;
		private List<SObject> records {
			get {
				return (List<SObject>) JSON.deserialize(JSON.serialize(this.mockOrRealRecords), List<SObject>.class);
			}
		}

		private Integer totalSize {
			get {
				return this.mockOrRealRecords?.size() ?? 0;
			}
		}

		private RelatedList(Schema.ChildRelationship relationship) {
			this.done = true;
			this.mockOrRealRecords = new List<Object>();
			this.objectType = relationship?.getChildSObject();
		}

		private RelatedList add(List<Object> incoming) {
			this.mockOrRealRecords?.addAll(incoming);
			System.debug('@jason: <add()> --------------');
			System.debug('@jason: incoming: ' + JSON.serialize(incoming));
			System.debug('@jason: mockOrRealRecords: ' + JSON.serialize(this.mockOrRealRecords));
			System.debug('@jason: this: ' + JSON.serialize(this));
			System.debug('@jason: </add()> --------------');
			return this;
		}
	}
}
