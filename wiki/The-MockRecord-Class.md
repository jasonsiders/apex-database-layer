Builder object creates an `SObject` for use in apex tests, without interacting with the Salesforce database.

This supports several functions that are otherwise impossible without manipulating and/or retrieving records from the database:

- Simulate record inserts - provisioning a record ID.
- Simulate parent and child relationships retrieved through SOQL
- Set read-only fields, including formula fields, and audit fields like `CreatedDate`

```apex
DatabaseLayer.useMocks();
// Generate some mock data:
Account mockAccount = (Account) new MockRecord(Account.SObjectType)
  ?.setField(Account.SomeFormulaCheckbox__c, true)
  ?.withId()
  ?.toSObject();
Contact mockContact = (Contact) new MockRecord(Contact.SObjectType)
  ?.setField(Contact.CreatedDate, DateTime.now())
  ?.setLookup(Contact.AccountId, mockAccount)
  ?.withId()
  ?.toSObject();
// Inject this contact in mock query results:
MockSoql.setGlobalMock().withResults(new List<Contact>{ mockContact });
// This query should now return our mocked contact:
List<Contact> contacts = (List<Contact>) DatabaseLayer.Soql.newQuery(Contact.SObjectType)
  ?.addSelect(new Soql.ParentField(Contact.AccountId, Account.SomeFormulaCheckbox__c))
  ?.addSelect(Contact.CreatedDate)
  ?.addOrderBy(Contact.CreatedDate, Soql.SortDirection.DESCENDING)
  ?.setRowLimit(1)
  ?.toSoql();
```

---

## Constructors

To create a new `MockRecord`, supply an existing `SObject` record as a starting point, or start from scratch with just the `SObjectType` to be created:

- `MockRecord(SObject existingRecord)`
- `MockRecord(SObjectType objectType)`

---

## Properties

<table>
  <thead>
    <tr>
      <th>Property</th>
      <th>Data Type</th>
      <th>Details</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Id</td>
      <td>Id</td>
      <td>Getter returns the current record Id, if set.</td>
    </tr>
  </tbody>
</table>

---

## Methods

### `addToRelatedList`

Adds records to a related list of child records on the record, by the lookup field on the child object, or its corresponding `Schema.ChildRelationship`. If the related list does not yet exist, one is created first.

- `MockRecord addToRelatedList(Schema.ChildRelationship childRelationship, List<SObject> childRecords)`
- `MockRecord addToRelatedList(SObjectField lookupFieldOnChildObject, List<SObject> childRecords)`
- `MockRecord addToRelatedList(Schema.ChildRelationship childRelationship, List<MockRecord> childRecords)`
- `MockRecord addToRelatedList(SObjectField lookupFieldOnChildObject, List<MockRecord> childRecords)`

### `get`

Returns the value of a field defined in the MockRecord.

- `Object get(String parameterName)`
- `Object get(SObjectField field)`

### `getLoookup`

Returns the value of a lookup relationship defined in the mock record:

- `SObject getLookup(SObjectField lookupField)`

### `getRelatedList`

Retrieves the value of a related list that matches a given child relationship.

- `List<SObject> getRelatedList(Schema.ChildRelationship relationship)`
- `List<SObject> getRelatedList(SObjectField lookupField)`

### `initRecordId`

Static method generates a unique record Id for use in database operations. Use this utility method outside of a `MockRecord` object context. If working with a `MockRecord`, use the [withId](./The-MockRecord-Class#withId) method instead.

- `static Id initRecordId(SObjectType objectType)`

### `setField`

Sets the value of a given field(s).

- `MockRecord setField(Map<String, Object> fieldValues)`
- `MockRecord setField(String fieldName, Object value)`
- `MockRecord setField(SObjectField field, Object value)`

### `setLookup`

Sets a lookup relationship on the record, by its corresponding lookup field.

This populates both the Id and the relationship itself. Ex., `Contact.AccountId` and `Contact.Account.Id`.

- `MockRecord setLookup(SObjectField lookupField, SObject parentRecord)`
- `MockRecord setLookup(SObjectField lookupField, MockRecord parentRecord)`

### `setRelatedList`

Sets a related list of child records on the record, by the lookup field on the child object, or its corresponding `Schema.ChildRelationship`.

- `MockRecord setRelatedList(Schema.ChildRelationship childRelationship, List<SObject> childRecords)`
- `MockRecord setRelatedList(SObjectField lookupFieldOnChildObject, List<SObject> childRecords)`
- `MockRecord setRelatedList(Schema.ChildRelationship childRelationship, List<MockRecord> childRecords)`
- `MockRecord setRelatedList(SObjectField lookupFieldOnChildObject, List<MockRecord> childRecords)`

### `toSObject`

Builds the current record instance to an actual `SObject` value.

To maximize performance, avoid calling this method until your record is fully built. Calling this method will cause any related parent/child `MockRecord` instances to be converted to an `SObject` as well.

- `SObject toSObject()`

### `withId`

Sets the `Id` field with a new, valid record Id that matches the `SObjectType`. If an Id is already set, its value will not be overwritten.

- `MockRecord withId()`
