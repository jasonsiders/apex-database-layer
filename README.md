# Apex Database Layer
- [ ] (Some introductory text here...)


## Getting Started
`apex-database-layer` is available as an unlocked package. You can find the latest or past versions in the [Releases](https://github.com/jasonsiders/apex-database-layer/releases) tab.

Use the following command to install the package in your environment:
```
sf package install -p {{package_version_id}}
```

## Usage

This package can be thought of in four categories, each with its own distinct set of responsibilities:
- `Dml` & `MockDml`: Performing DML operations
- `Soql` & `MockSoql`: Performing SOQL operations
- `DatabaseLayer`: Constructing `Dml` and `Soql` objects
- `MockRecord`: Mocking SObject records for test purposes

### Performing DML Operations
The `Dml` class is responsible for inserting, modifying, and deleting records in the salesforce database. It wraps the relevant methods in the standard [Database](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_methods_system_database.htm) class, like `Database.insert`. Use the `Dml` class in place of these methods.

```java
// Don't use these built-in platform methods
insert records;
Database.insert(records);
// Instead, use the Dml class's methods
Dml myDml = DatabaseLayer.newDml();
myDml?.doInsert(records);
```

In `@IsTest` context, you can run your custom logic without using actual DML by calling `DatabaseLayer.useMocks()`. This will automatically substitute real `Dml` objects with a `MockDml` object. 

By default this class will simulate successful DML operations. To simulate failures, use the `fail()` method:

```java
DatabaseLayer.useMocks();
MockDml dml = (MockDml) DatabaseLayer.newDml();
dml?.fail();
// All subsuquent dml operations should fail
dml?.doInsert(); 
```

If necessary, you can inject "smarter" failure logic via the `MockDml.ConditionalFailure` interface and the `failIf()` method:

```java
public class ExampleFailure implements MockDml.ConditionalFailure {
	public Exception checkFailure(Dml.Operation operation, SObject record) {
		// Return an Exception if the record/operation should fail
		// In this case, any updated Accounts will fail
		if (
			operation == Dml.Operation.DO_UPDATE && 
			record?.getSObjectType() == Account.SObjectType
		) {
			return new System.DmlException();
		} else {
			return null;
		}
	}
}

// Inject the conditional logic via the failIf() method
DatabaseLayer.useMocks();
MockDml dml = (MockDml) DatabaseLayer.newDml();
MockDml.ConditionalFailure logic = new ExampleFailure();
dml?.failIf(logic);
// This won't fail, because it's not an update!
dml?.doInsert();
```

`MockDml` does not actually modify records in the database, so you cannot use SOQL to retrieve changes and perform assertions against them. Instead, use history objects, like `MockDml.INSERTED` to retrieve modified SObject records in memory:

```java
DatabaseLayer.useMocks();
List<Lead> leads = MyTest.initLeads();

Test.startTest();
myFoo?.doBar(leads);
Test.stopTest();

List<Lead> updatedLeads = MockDml.UPDATED?.get(Lead.SObjectType);
Assert.areEqual(leads?.size(), updatedLeads?.size(), 'Wrong # of updated Leads');
```

View the [docs](docs/DML.md) to learn more about the `Dml` and `MockDml` classes.

---

### Performing SOQL Operations

#### The `Soql` Class
- Performing Queries/Query Methods
- Building Queries

#### The `MockSoql` Class
- [ ] Simulating queries
	- The `MockSoql.Simulator` interface and `setMock()` method
	- (TODO) The `MockSoql.StaticSimulator` class?
- [ ] Constructing `AggregateResults`: The `MockSoql.AggregateResult` class
- [ ] Special Considerations for Mocking `QueryLocators`

View the [docs](docs/SOQL.md) to learn more about the `Soql` and `MockSoql` classes.

---

### Constructing Database Objects

The `DatabaseLayer` class is responsible for constructing new `Dml` and `Soql` objects:

```java
Dml myDml = DatabaseLayer.newDml();
Soql mySoql = DatabaseLayer.newSoql(Account.SObjectType);
```

This approach allows for mocks to be automatically substituted at runtime during tests, if desired. By default, each of these methods will return base implementations of the `Dml` and `Soql` classes, which directly interact with the Salesforce database. In `@IsTest` context, you can use the `DatabaseLayer.useMocks()` method. Once this is done, the `newDml()` and `newSoql()` methods will return mock instances of their respective objects:

```java
@IsTest 
static void shouldUseMockDml() {
	// Assuming ExampleClass has a Dml property called "dmlInstance"
	DatabaseLayer.useMocks();
	ExampleClass example = new ExampleClass();
	Assert.isInstanceOfType(example.dmlInstance, MockDml.class, 'Not using mocks');
}
```

You can also revert the `DatabaseLayer` class to use real database operations by calling `DatabaseLayer.useRealData()`. This should only be used in cases where some (but not all) database operations should be mocked:

```java
@IsTest
static void shouldUseMixedOfMocksAndRealDml() {
	DatabaseLayer.useMocks();
	ExampleClass mockExample = new ExampleClass();
	Assert.isInstanceOfType(mockExample.dmlInstance, MockDml.class, 'Not using mocks');
	// Now switch to using real data, will apply to any new Dml classes going forward
	DatabaseLayer.useRealData();
	ExampleClass databaseExample = new ExampleClass();
	Assert.isNotInstanceOfType(databaseExample.dmlInstance, MockDml.class, 'Using mocks?');
}
```

---

### Building Test Records
While mocking database operations can provide many benefits, the process of mocking SObject records in the absence of real DML or SOQL can be tedious. 

The `MockRecord` class addresses many of the pains associated with this process, including:
- Set read-only fields (including system-level fields)
- Simulate record inserts
- Simulate parent and child relationship retrievals through SOQL

Use the class's fluent builder pattern to generate a record to your specifications, and then cast it back to a concrete SObject. Example:

```java
Account realAccount = [
	SELECT 
		Id, CreatedDate, Owner.Name, 
		(SELECT Id FROM Contacts) 
	FROM Account 
	LIMIT 1
];
// Let's make a test record that can be used to mock the above query!
User mockUser = (User) new MockRecord(User.SObjectType)
	?.setField(User.Name, 'John Doe')
	?.withId()
	?.toSObject();
Contact mockContact = (Contact) new MockRecord(Contact.SObjectType)
	?.withId()
	?.toSObject();
Account mockAccount = (Account) new MockRecord(Account.SObjectType)
	?.setField(Account.Name, 'John Doe Enterprises')
	?.setField(Account.CreatedDate, DateTime.now()?.addDays(-100))
	?.setLookup(Account.OwnerId, mockUser)
	?.setRelatedList(Contact.AccountId, new List<Contact>{ mockContact })
	?.withId()
	?.toSObject();
```