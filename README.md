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
- [ ] Give brief overviews before redirecting to the [`Dml`](force-app/main/default/classes/Dml/README.md) class's documentation.

#### The `Dml` Class
- Performing DML
  - DML Methods vs. the `Database` class's DML Methods
  - The `doDml()` method and the `Dml.Operation` enum
- Configuration Options

#### The `MockDml` Class
- Mocking successful operations
  - Simulates a successful DML operation by default. 
  - Using the `MockDml.History` objects to assert performed DML.
- Mocking failed operations
  - MockDml's `fail()` & `failIf()` methods, and the `MockDml.ConditionalFailure` interface.

### Performing SOQL Operations
- [ ] Give brief overviews before redirecting to the [`Soql`](force-app/main/default/classes/Soql/README.md) class's documentation.

#### The `Soql` Class
- Performing Queries/Query Methods
- Building Queries

#### The `MockSoql` Class
- [ ] Simulating queries
  - The `MockSoql.Simulator` interface and `setMock()` method
  - (TODO) The `MockSoql.StaticSimulator` class?
- [ ] Constructing `AggregateResults`: The `MockSoql.AggregateResult` class
- [ ] Special Considerations for Mocking `QueryLocators`

### Constructing Database Objects

#### The `DatabaseLayer` Class
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

### Building Test Records

#### The `MockRecord` Class
- Using the `MockRecord` class to build test records without real DML or SOQL