In a typical Apex codebase that does _not_ mock database operations, test classes consume a significant amount of resources simply by _setting up records_ into a state suitable for each test. In many cases, this setup is more resource-intensive than the code being tested!

This issue becomes especially relevant the deeper you go into the Salesforce data model. Take the `OpportunityContactRole` as an example. To create one, you need to:

1. Create an Account
2. Create a Contact related to that Account
3. Create an Opportunity related to that Account
4. Create an OpportunityContactRole related to both the Contact and Opportunity

That's _4 DML statements_ just to create a single test record! Depending on the production code you’re testing—or whether the data is created in a `@TestSetup` method—you may also need at least _1 SOQL_ query to retrieve it, plus potentially more DML to fine-tune the record per test method.

## The Problem: Mocking Pitfalls

The `OpportunityContactRole` is a great example of why mocking database operations is so valuable—and also why many Salesforce developers struggle to adopt the concept.

Without interacting with the database, it's _impossible_ to construct an object like `OpportunityContactRole`—at least, not one that’s useful in real tests.

```apex
OpportunityContactRole contactRole = new OpportunityContactRole();
// Can't set 'ContactId' without creating a Contact first...
// Can't set 'Id' without inserting the OpportunityContactRole...
// Can't set 'OpportunityId' without creating an Opportunity first...
// Oh, at least we can set the 'Role' picklist! ¯\_(ツ)_/¯
contactRole.Role = 'Primary Contact';
```

## The Solution: `MockRecord`

The [`MockRecord`](./The-MockRecord-Class) class is a _flexible SObject constructor_ that allows you to easily generate records for your tests without using DML or SOQL.

`MockRecord` can do many things that are otherwise impossible without directly interacting with the Salesforce database:

- Create a record with an `Id`
- Populate formula field values
- Set system fields like `CreatedDate`
- Populate parent (or grandparent, etc.) relationships such as `Account.Owner.Name`
- Populate child (or grandchild, etc.) relationships like `Account.Opportunities`

Continuing with our example, here’s how you’d create an `OpportunityContactRole` using `MockRecord`:

```apex
Contact con = (Contact) new MockRecord(Contact.SObjectType)?.withId()?.toSObject();
Opportunity opp = (Opportunity) new MockRecord(Opportunity.SObjectType)?.withId()?.toSObject();
OpportunityContactRole contactRole = (OpportunityContactRole) new MockRecord(OpportunityContactRole.SObjectType)
  ?.setField(OpportunityContactRole.ContactId, con?.Id)
  ?.setField(OpportunityContactRole.OpportunityId, opp?.Id)
  ?.setField(OpportunityContactRole.Role, 'Primary Contact')
  ?.withId()
  ?.toSObject();
```

Creating this `OpportunityContactRole` takes only _2–6 milliseconds_—a fraction of the time required using DML and SOQL!

The resulting SObject can be used anywhere in Apex tests that leverage mocks:

```apex
@IsTest
static void someTest() {
  DatabaseLayer.useMocks();
  // Assume this method generates the mock OpportunityContactRole from our previous example:
  OpportunityContactRole contactRole = MyTest.initMockContactRole();
  // Inject the contact role into a query result:
  List<OpportunityContactRole> contactRoles = new List<OpportunityContactRole>{ contactRole };
  MockSoql.setGlobalMock().withResults(contactRoles);

  Test.startTest();
  new SomeClass().process(contactRoles);
  Test.stopTest();

  // Assume that the above class updates the Opportunity’s Stage to "Closed Won":
  Assert.isTrue(DatabaseLayer.UPDATED.wasProcessed(contactRole?.OpportunityId), 'Opportunity was not updated');
  Opportunity opp = (Opportunity) DatabaseLayer.UPDATED.get(contactRole?.OpportunityId);
  Assert.areEqual('Closed Won', opp?.StageName, 'Opportunity is not Closed Won');
}
```

### Advanced Example: Relationships, Formula Fields, System Fields

Here’s a more advanced example that creates an Opportunity with:

- Parent (lookup) relationships (`Opportunity.Account`)
- Child (related list) relationships (`Opportunity.OpportunityContactRoles`)
- Formula fields (`SomeFormulaCheckbox__c`)
- Read-only System fields (`CreatedDate`)

```apex
User owner = (User) new MockRecord(User.SObjectType)?.withId()?.toSObject();
Account acc = (Account) new MockRecord(Account.SObjectType)
  ?.setLookup(Account.OwnerId, owner)
  ?.withId()
  ?.toSObject();
Contact con = (Contact) new MockRecord(Contact.SObjectType)?.withId()?.toSObject();
// We don’t need to immediately cast to SObject—useful if setting fields used by child records:
MockRecord mockOpp = new MockRecord(Opportunity.SObjectType)?.withId();
OpportunityContactRole contactRole = (OpportunityContactRole) new MockRecord(OpportunityContactRole.SObjectType)
  ?.setField(OpportunityContactRole.ContactId, con?.Id)
  ?.setField(OpportunityContactRole.OpportunityId, mockOpp?.get(Opportunity.Id))
  ?.setField(OpportunityContactRole.Role, 'Primary Contact')
  ?.withId()
  ?.toSObject();
List<OpportunityContactRole> contactRoles = new List<OpportunityContactRole>{ contactRole };
Opportunity opp = (Opportunity) mockOpp
  ?.setField(Opportunity.CreatedDate, DateTime.now().addDays(-7))
  ?.setField(Opportunity.SomeFormulaCheckbox__c, true)
  ?.setLookup(Opportunity.AccountId, acc)
  ?.setRelatedList(OpportunityContactRole.OpportunityId, contactRoles)
  ?.toSObject();
```

Here’s the resulting `Opportunity`, in JSON:

```json
{
	"attributes": {
		"type": "Opportunity",
		"url": "/services/data/v64.0/sobjects/Opportunity/006000000000000003"
	},
	"Account": {
		"attributes": {
			"type": "Account",
			"url": "/services/data/v64.0/sobjects/Account/001000000000000001"
		},
		"Owner": {
			"attributes": {
				"type": "User",
				"url": "/services/data/v64.0/sobjects/User/005000000000000000"
			},
			"Id": "005000000000000000"
		},
		"OwnerId": "005000000000000000",
		"Id": "001000000000000001"
	},
	"AccountId": "001000000000000001",
	"CreatedDate": "2025-06-26T14:32:49.653+0000",
	"OpportunityContactRoles": {
		"totalSize": 1,
		"done": true,
		"records": [
			{
				"attributes": {
					"type": "OpportunityContactRole",
					"url": "/services/data/v64.0/sobjects/OpportunityContactRole/00K000000000000004"
				},
				"Role": "Primary Contact",
				"OpportunityId": "006000000000000003",
				"Id": "00K000000000000004",
				"ContactId": "003000000000000002"
			}
		]
	},
	"Id": "006000000000000003",
	"SomeFormulaCheckbox__c": true
}
```
