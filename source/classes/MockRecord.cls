/**
 * @description Builder pattern class for constructing mock SObject records with comprehensive field, relationship, and Id generation support for testing.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier,PMD.CognitiveComplexity,PMD.ExcessivePublicCount')
global class MockRecord {
	private static final String ID_TOKEN = 'Id';
	private static Integer numMockIds = 0;

	private transient SObjectType objectType;
	private transient Map<String, Object> recordValues;

	@SuppressWarnings('PMD.PropertyNamingConventions')
	/**
	 * @description The Id property of this mock record, mirroring standard SObject functionality.
	 */
	global Id Id {
		get {
			// Mirrors standard SObject functionality; all SObject records have an Id property - even untyped!
			return (Id) this.get(ID_TOKEN);
		}
	}

	/**
	 * @description Constructor that creates a MockRecord from an existing SObject, preserving all field values.
	 * @param realRecord The existing SObject to copy values from
	 */
	global MockRecord(SObject realRecord) {
		this.objectType = realRecord?.getSObjectType();
		this.recordValues = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(realRecord, false));
	}

	/**
	 * @description Constructor that creates an empty MockRecord for the specified SObject type.
	 * @param objectType The SObjectType to create a mock record for
	 */
	global MockRecord(SObjectType objectType) {
		this(objectType?.newSObject());
	}

	// **** STATIC **** //
	/**
	 * @description Generates a unique mock record Id for the specified SObject type.
	 * @param objectType The SObjectType to generate an Id for
	 * @return A unique mock Id following Salesforce Id format
	 */
	global static Id initRecordId(SObjectType objectType) {
		String prefix = objectType?.getDescribe(Schema.SObjectDescribeOptions.DEFERRED)?.getKeyPrefix();
		String suffix = String.valueOf(MockRecord.numMockIds++);
		String mid = 0?.toString()?.repeat(15 - suffix?.length());
		return prefix + mid + suffix;
	}

	// **** MEMBER **** //
	/**
	 * @description Adds multiple records to a related list for SOQL simulation.
	 * @param relationship The child relationship to add records to
	 * @param records List of SObject records to add
	 * @return This MockRecord instance for method chaining
	 */
	global MockRecord addToRelatedList(Schema.ChildRelationship relationship, List<SObject> records) {
		return this.addUntypedChildRecords(relationship, records);
	}

	/**
	 * @description Adds multiple records to a related list using a lookup field.
	 * @param lookupField The lookup field that defines the relationship
	 * @param records List of SObject records to add
	 * @return This MockRecord instance for method chaining
	 */
	global MockRecord addToRelatedList(SObjectField lookupField, List<SObject> records) {
		Schema.ChildRelationship relationship = this.getChildRelationship(lookupField);
		return this.addToRelatedList(relationship, records);
	}

	/**
	 * @description Adds a single record to a related list for SOQL simulation.
	 * @param relationship The child relationship to add the record to
	 * @param record The SObject record to add
	 * @return This MockRecord instance for method chaining
	 */
	global MockRecord addToRelatedList(Schema.ChildRelationship relationship, SObject record) {
		return this.addToRelatedList(relationship, new List<SObject>{ record });
	}

	/**
	 * @description Adds a single record to a related list using a lookup field.
	 * @param lookupField The lookup field that defines the relationship
	 * @param record The SObject record to add
	 * @return This MockRecord instance for method chaining
	 */
	global MockRecord addToRelatedList(SObjectField lookupField, SObject record) {
		return this.addToRelatedList(lookupField, new List<SObject>{ record });
	}

	/**
	 * @description Adds multiple MockRecord instances to a related list.
	 * @param relationship The child relationship to add records to
	 * @param mocks List of MockRecord instances to add
	 * @return This MockRecord instance for method chaining
	 */
	global MockRecord addToRelatedList(Schema.ChildRelationship relationship, List<MockRecord> mocks) {
		return this.addUntypedChildRecords(relationship, mocks);
	}

	/**
	 * @description Adds multiple MockRecord instances to a related list using a lookup field.
	 * @param lookupField The lookup field that defines the relationship
	 * @param records List of MockRecord instances to add
	 * @return This MockRecord instance for method chaining
	 */
	global MockRecord addToRelatedList(SObjectField lookupField, List<MockRecord> records) {
		Schema.ChildRelationship relationship = this.getChildRelationship(lookupField);
		return this.addToRelatedList(relationship, records);
	}

	/**
	 * @description Adds a single MockRecord instance to a related list.
	 * @param relationship The child relationship to add the record to
	 * @param record The MockRecord instance to add
	 * @return This MockRecord instance for method chaining
	 */
	global MockRecord addToRelatedList(Schema.ChildRelationship relationship, MockRecord record) {
		return this.addToRelatedList(relationship, new List<MockRecord>{ record });
	}

	/**
	 * @description Adds a single MockRecord instance to a related list using a lookup field.
	 * @param lookupField The lookup field that defines the relationship
	 * @param record The MockRecord instance to add
	 * @return This MockRecord instance for method chaining
	 */
	global MockRecord addToRelatedList(SObjectField lookupField, MockRecord record) {
		return this.addToRelatedList(lookupField, new List<MockRecord>{ record });
	}

	/**
	 * @description Retrieves the value of the specified field.
	 * @param parameterName The field name to retrieve
	 * @return The current value of the field
	 */
	global Object get(String parameterName) {
		return this.recordValues?.get(parameterName);
	}

	/**
	 * @description Retrieves the value of the specified SObjectField.
	 * @param field The SObjectField to retrieve
	 * @return The current value of the field
	 */
	global Object get(SObjectField field) {
		return this.get(field?.toString());
	}

	/**
	 * @description Retrieves the parent record for the specified lookup field.
	 * @param lookupField The lookup field to retrieve the parent for
	 * @return The parent SObject record
	 */
	global SObject getLookup(SObjectField lookupField) {
		String relationshipName = lookupField?.getDescribe()?.getRelationshipName();
		return (SObject) this.get(relationshipName);
	}

	/**
	 * @description Retrieves the related list for the specified child relationship.
	 * @param relationship The child relationship to retrieve records for
	 * @return List of SObject records in the related list
	 */
	global List<SObject> getRelatedList(Schema.ChildRelationship relationship) {
		String relationshipName = relationship?.getRelationshipName();
		MockRecord.RelatedList relatedList = (MockRecord.RelatedList) this.get(relationshipName);
		return relatedList?.getRecords();
	}

	/**
	 * @description Retrieves the related list for the specified lookup field.
	 * @param lookupField The lookup field that defines the relationship
	 * @return List of SObject records in the related list
	 */
	global List<SObject> getRelatedList(SObjectField lookupField) {
		Schema.ChildRelationship relationship = this.getChildRelationship(lookupField);
		return this.getRelatedList(relationship);
	}

	/**
	 * @description Sets multiple field values at once.
	 * @param incomingValues Map of field names to values
	 * @return This MockRecord instance for method chaining
	 */
	global MockRecord setField(Map<String, Object> incomingValues) {
		this.recordValues?.putAll(incomingValues);
		return this;
	}

	/**
	 * @description Sets a single field value.
	 * @param fieldName The field name to set
	 * @param value The value to set
	 * @return This MockRecord instance for method chaining
	 */
	global MockRecord setField(String fieldName, Object value) {
		return this.setField(new Map<String, Object>{ fieldName => value });
	}

	/**
	 * @description Sets a field value using SObjectField reference.
	 * @param field The SObjectField to set
	 * @param value The value to set
	 * @return This MockRecord instance for method chaining
	 */
	global MockRecord setField(SObjectField field, Object value) {
		return this.setField(field?.toString(), value);
	}

	/**
	 * @description Sets a parent lookup relationship using an SObject.
	 * @param lookupField The lookup field that defines the relationship
	 * @param parent The parent SObject to associate
	 * @return This MockRecord instance for method chaining
	 */
	global MockRecord setLookup(SObjectField lookupField, SObject parent) {
		// Simulates a parent object retrieval in SOQL; ex., SELECT Id, Account.Name FROM Contact LIMIT 1
		return this.addUntypedParentRecord(lookupField, parent);
	}

	/**
	 * @description Sets a parent lookup relationship using a MockRecord.
	 * @param lookupField The lookup field that defines the relationship
	 * @param parent The parent MockRecord to associate
	 * @return This MockRecord instance for method chaining
	 */
	global MockRecord setLookup(SObjectField lookupField, MockRecord parent) {
		return this.addUntypedParentRecord(lookupField, parent);
	}

	/**
	 * @description Sets a related list using SObjects and a child relationship.
	 * @param relationship The child relationship to set records for
	 * @param relatedRecords List of SObjects for the related list
	 * @return This MockRecord instance for method chaining
	 */
	global MockRecord setRelatedList(Schema.ChildRelationship relationship, List<SObject> relatedRecords) {
		// Sets the related list used to simulate a child object retrieval in SOQL; ex., SELECT Id, (SELECT Id FROM Contacts) FROM Account LIMIT 1
		return this.setUntypedChildRecords(relationship, relatedRecords);
	}

	/**
	 * @description Sets a related list using SObjects and a lookup field.
	 * @param lookupField The lookup field that defines the relationship
	 * @param relatedRecords List of SObjects for the related list
	 * @return This MockRecord instance for method chaining
	 */
	global MockRecord setRelatedList(SObjectField lookupField, List<SObject> relatedRecords) {
		Schema.ChildRelationship relationship = this.getChildRelationship(lookupField);
		return this.setRelatedList(relationship, relatedRecords);
	}

	/**
	 * @description Sets a related list using MockRecords and a child relationship.
	 * @param relationship The child relationship to set records for
	 * @param relatedRecords List of MockRecords for the related list
	 * @return This MockRecord instance for method chaining
	 */
	global MockRecord setRelatedList(Schema.ChildRelationship relationship, List<MockRecord> relatedRecords) {
		return this.setUntypedChildRecords(relationship, relatedRecords);
	}

	/**
	 * @description Sets a related list using MockRecords and a lookup field.
	 * @param lookupField The lookup field that defines the relationship
	 * @param relatedRecords List of MockRecords for the related list
	 * @return This MockRecord instance for method chaining
	 */
	global MockRecord setRelatedList(SObjectField lookupField, List<MockRecord> relatedRecords) {
		Schema.ChildRelationship relationship = this.getChildRelationship(lookupField);
		return this.setRelatedList(relationship, relatedRecords);
	}

	/**
	 * @description Converts the MockRecord to an actual SObject instance.
	 * @return The built SObject with all configured field values
	 */
	global SObject toSObject() {
		return (SObject) JSON.deserialize(JSON.serialize(this.recordValues, false), SObject.class);
	}

	/**
	 * @description Generates and sets a unique Id for this record if one doesn't already exist.
	 * @return This MockRecord instance for method chaining
	 */
	global MockRecord withId() {
		Id recordId = this.Id ?? MockRecord.initRecordId(this.objectType);
		return this.setField(ID_TOKEN, recordId);
	}

	// **** OVERRIDES **** //
	/**
	 * @description Compares this MockRecord with another object for equality.
	 * Overrides the standard equals() method by delegating to the underlying SObject's equals implementation.
	 * Note: While this functionally overrides the equals() method, we don't technically override it
	 * @param obj The object to compare with
	 * @return True if the objects are equal, false otherwise
	 */
	global Boolean equals(Object obj) {
		return this.toSObject()?.equals(obj);
	}

	global override Integer hashCode() {
		// Use the underlying SObject's hashCode value:
		return this.toSObject()?.hashCode();
	}

	global override String toString() {
		// Use the underlying SObject for toString purposes:
		return this.toSObject()?.toString();
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
		this.setField(relationshipName, new MockRecord.RelatedList());
		return this.addUntypedChildRecords(relationship, mockOrRealRecords);
	}

	// **** INNER **** //
	private class RelatedList {
		// Represents a child object relationship retrieved by SOQL.
		// This structure is required when mocking related lists on an SObject
		private Boolean done;
		private transient List<MockRecord> mockRecords;
		private transient List<SObject> realRecords;
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
			// This may consist of both real records, and all mocks' SObject values
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
