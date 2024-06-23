# Apex Database Mocks
(Some introductory text here...)

## Getting Started
- Available as an unlocked package, see the Releases tab in GH

## Usage

### Constructing Database Objects: The `DatabaseLayer` Class
- Using `DatabaseLayer.newDml()` and `DatabaseLayer.newSoql()` in place of `new` keyword
- Using `DatabaseLayer.useMocks()` and `DatabaseLayer.useRealData()` in `@IsTest` context.

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