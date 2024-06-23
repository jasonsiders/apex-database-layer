# Apex Database Mocks
(Some introductory text here...)

## Production Usage
(Some introductory text here...)

### Constructing Database Objects: The `DatabaseLayer` Class
- Constructing Dml: `DatabaseLayer.newDml()`
- Constructing Soql: `DatabaseLayer.newSoql(SObjectType)`

### Performing CRUD Operations: The `Dml` Class
- DML Methods vs. the `Database` class's DML Methods
- The `doDml()` method and the `Dml.Operation` enum
- Configuration Options
- Give brief overviews before redirecting to the [`Dml`](force-app/main/default/classes/Dml/README.md) class's documentation.

### Performing Query Operations: The `Soql` Class
- Performing Queries/Query Methods
- Building Queries
- Give brief overviews before redirecting to the [`Soql`](force-app/main/default/classes/Soql/README.md) class's documentation.

## Test Usage
(Some introductory text here...)

### Substituting Mocks in @IsTest Scenarios
- Using `DatabaseLayer.useMocks()` and `DatabaseLayer.useRealData()` methods

### Building Test Records
- Using the `MockRecord` class to build test records without real DML or SOQL

### Mocking DML Operations
- Mocking successful operations
  - Simulates a successful DML operation by default. 
  - Using the `MockDml.History` objects to assert performed DML.
- Mocking failed operations
  - MockDml's `fail()` & `failIf()` methods, and the `MockDml.ConditionalFailure` interface.

### Mocking SOQL Operations
- Simulating queries
  - The `MockSoql.Simulator` interface and `setMock()` method
  - (TODO) The `MockSoql.StaticSimulator` class?
- Constructing `AggregateResults`: The `MockSoql.AggregateResult` class
- Mocking `QueryLocators`
