public abstract class SObjectUtils {
  static Integer numMockIds = 0;
  static Map<SObjectType, RelationshipRepo> relationships = new Map<SObjectType, RelationshipRepo>();

  public static Schema.ChildRelationship getChildRelationshipFrom(
    SObjectField lookupField,
    SObjectType referenceTo
  ) {
    // Returns the Schema.ChildRelationshp on the referenceTo SObjectType, that the provided lookupField points to.
    // Ex., getChildRelationshipFrom(Task.WhoId, Lead.SObjectType) -> Lead.Tasks
    return SObjectUtils.getRelationshipsFrom(referenceTo)?.get(lookupField);
  }

  public static Schema.ChildRelationship getChildRelationshipFrom(
    SObjectField lookupField
  ) {
    // Overload that uses the first SObjectType in the getReferenceTo() list to find the child relationship.
    // Use this overload when you know the field in question is not polymorphic; ex., Contact.AccountId.
    // * Note: the Schema.getReferenceTo() method returns a List<SObjectType>, not a single SObjectType.
    // Typically, a field is only be related to a single SObjectType; exceptions include polymorphic fields (ie, Task.WhatId).
    List<SObjectType> references = lookupField?.getDescribe()?.getReferenceTo();
    SObjectType referenceTo = references?.isEmpty() == false
      ? references[0]
      : null;
    return SObjectUtils.getChildRelationshipFrom(lookupField, referenceTo);
  }

  public static SObject setLookup(
    SObject originalRecord,
    SObjectField lookupField,
    SObject parent
  ) {
    // Populates a parent relationship, ex., Contact.Account with a parent SObject record.
    // Populate the lookup field (ex., SomeLookup__c)
    originalRecord?.put(lookupField, parent?.Id);
    // Populate the lookup relationship (ex., SomeLookup__r)
    String relationshipName = lookupField?.getDescribe()?.getRelationshipName();
    return SObjectUtils.setReadOnlyFields(
      originalRecord,
      relationshipName,
      parent
    );
  }

  public static SObject setLookup(
    SObject originalRecord,
    String fieldName,
    SObject parent
  ) {
    SObjectField lookupField = originalRecord
      ?.getSObjectType()
      ?.getDescribe()
      ?.fields
      ?.getMap()
      ?.get(fieldName);
    return SObjectUtils.setLookup(originalRecord, lookupField, parent);
  }

  public static SObject setReadOnlyFields(
    SObject originalRecord,
    Map<String, Object> readOnlyValues
  ) {
    // Sets the value of read-only fields on an existing SObject, returning a copy of that same object.
    // Note: Since JSON de/serialization is involved, cannot actually transform the existing object in memory.
    Map<String, Object> recordValues = (Map<String, Object>) JSON.deserializeUntyped(
      JSON.serialize(originalRecord)
    );
    recordValues?.putAll(readOnlyValues);
    return (SObject) JSON.deserialize(
      JSON.serialize(recordValues),
      SObject.class
    );
  }

  public static SObject setReadOnlyFields(
    SObject originalRecord,
    String fieldName,
    Object value
  ) {
    return SObjectUtils.setReadOnlyFields(
      originalRecord,
      new Map<String, Object>{ fieldName => value }
    );
  }

  public static SObject setReadOnlyFields(
    SObject originalRecord,
    SObjectField field,
    Object value
  ) {
    return SObjectUtils.setReadOnlyFields(
      originalRecord,
      field?.toString(),
      value
    );
  }

  public static SObject setRelatedList(
    SObject originalRecord,
    String relationshipName,
    List<SObject> children
  ) {
    // Populates a child relationship, ex., Account.Contacts with a list of SObjects
    RelatedList relatedList = new RelatedList(children);
    return SObjectUtils.setReadOnlyFields(
      originalRecord,
      relationshipName,
      relatedList
    );
  }

  public static SObject setRelatedList(
    SObject originalRecord,
    Schema.ChildRelationship relationship,
    List<SObject> children
  ) {
    return SObjectUtils.setRelatedList(
      originalRecord,
      relationship?.getRelationshipName(),
      children
    );
  }

  public static SObject setRelatedList(
    SObject originalRecord,
    SObjectField lookupField,
    List<SObject> children
  ) {
    Schema.ChildRelationship relationship = SObjectUtils.getChildRelationshipFrom(
      lookupField
    );
    return SObjectUtils.setRelatedList(originalRecord, relationship, children);
  }

  // **** TEST ONLY **** //
  @TestVisible
  private static Id mockPlatformEventId(SObjectType objectType) {
    // Note: The Id of Platform Events is always a static/non-unique value across all events
    // The Id value does not need to be incremented or be unique
    return objectType?.getDescribe()?.getKeyPrefix() + '0'?.repeat(15);
  }

  @TestVisible
  private static Id mockRecordId(SObjectType objectType) {
    String prefix = objectType?.getDescribe()?.getKeyPrefix();
    String suffix = String.valueOf(numMockIds++);
    String mid = 0?.toString()?.repeat(15 - suffix?.length());
    return prefix + mid + suffix;
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

    private List<Schema.ChildRelationship> getRelationshipList(
      SObjectType objectType
    ) {
      return objectType?.getDescribe()?.getChildRelationships() ??
        new List<Schema.ChildRelationship>();
    }

    private void mapRelationships(SObjectType objectType) {
      for (
        Schema.ChildRelationship relationship : this.getRelationshipList(
          objectType
        )
      ) {
        SObjectField field = relationship?.getField();
        this.relationshipMap?.put(field, relationship);
      }
    }
  }
}
