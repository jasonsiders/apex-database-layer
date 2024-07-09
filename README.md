# Apex Database Layer
(Some introductory text here...)

## Getting Started
- Available as an unlocked package, see the Releases tab in GH

## Usage

### Constructing Database Objects: The `DatabaseLayer` Class
The `DatabaseLayer` class is responsible for constructing new `Dml` and `Soql` objects:
```java
Dml myDml = DatabaseLayer.newDml();
Soql mySoql = DatabaseLayer.newSoql(Account.SObjectType);
```

By default, each of these methods will return base implementations of the `Dml` and `Soql` classes, which directly interact with the Salesforce database. In `@IsTest` context, you can use the `DatabaseLayer.useMocks()` method. Once this is done, the `newDml()` and `newSoql()` methods will return mock instances of their respective objects:
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

### Building Test Records: The `MockRecord` Class
- Using the `MockRecord` class to build test records without real DML or SOQL

### Performing CRUD Operations: The `Dml` Class
Give brief overviews before redirecting to the [`Dml`](force-app/main/default/classes/Dml/README.md) class's documentation.

#### Performing DML Operations
- Performing DML
  - DML Methods vs. the `Database` class's DML Methods
  - The `doDml()` method and the `Dml.Operation` enum
- Configuration Options

#### Mocking DML Operations
- Mocking successful operations
  - Simulates a successful DML operation by default. 
  - Using the `MockDml.History` objects to assert performed DML.
- Mocking failed operations
  - MockDml's `fail()` & `failIf()` methods, and the `MockDml.ConditionalFailure` interface.

### Performing Query Operations: The `Soql` Class
Give brief overviews before redirecting to the [`Soql`](force-app/main/default/classes/Soql/README.md) class's documentation.

#### Performing SOQL Operations
- Performing Queries/Query Methods
- Building Queries

#### Mocking SOQL Operations
- Simulating queries
  - The `MockSoql.Simulator` interface and `setMock()` method
  - (TODO) The `MockSoql.StaticSimulator` class?
- Constructing `AggregateResults`: The `MockSoql.AggregateResult` class
- Special Considerations for Mocking `QueryLocators`