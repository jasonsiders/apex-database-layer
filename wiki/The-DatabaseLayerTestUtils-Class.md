The `DatabaseLayerTestUtils` class is a test utility class providing common functionality and spy implementations for framework testing.

This class helps developers mock and test database layer functionality by providing spy implementations and utilities for initializing plugins during testing scenarios.

## Constructing `DatabaseLayerTestUtils` Objects

`DatabaseLayerTestUtils` objects cannot be directly constructed via the `new` keyword. Instead, access the class and its methods via static method calls:

```apex
DatabaseLayerTestUtils.initDmlAndSoqlPlugins('MyTestPlugin');
```

## Properties

### `DmlPluginSpy`

A static spy implementation for tracking DML plugin method invocations during testing.

### `SoqlPluginSpy`

A static spy implementation for tracking SOQL plugin method invocations during testing.

## Methods

### `initDmlAndSoqlPlugins`

Mocks DatabaseLayerParameter\_\_mdt records for DML and SOQL plugins and re-initializes plugins.

**Signature:**

```apex
global static void initDmlAndSoqlPlugins(String className)
```

**Parameters:**

- `className` (String): The fully-qualified Apex class name to use for both DML and SOQL pre/post processing

**Example:**

```apex
@IsTest
private class MyTest {
	@IsTest
	static void testWithPlugins() {
		// Initialize plugins for testing
		DatabaseLayerTestUtils.initDmlAndSoqlPlugins('MyTestPlugin');

		// Your test logic here
		// Both DML and SOQL operations will use MyTestPlugin for processing
	}
}
```

## Inner Classes

### `PreAndPostProcessorSpy`

Spy implementation for tracking plugin method invocations during testing.

**Properties:**

- `numPreCalls` (Integer): Number of times the pre-processing method was called
- `numPostCalls` (Integer): Number of times the post-processing method was called
- `numErrorCalls` (Integer): Number of times the error processing method was called

### `SamplePlugin`

Sample plugin implementation for testing both DML and SOQL processing hooks. Implements both `Dml.PreAndPostProcessor` and `Soql.PreAndPostProcessor` interfaces.

**Methods:**

- `processPreDml(Dml.Request request)`: Processes DML requests before execution for testing purposes
- `processPostDml(Dml.Request request, List<Object> databaseResults)`: Processes DML requests after execution for testing purposes
- `processDmlError(Dml.Request request, Exception error)`: Processes DML errors for testing purposes
- `processPreSoql(Soql.Request request)`: Processes SOQL requests before execution for testing purposes
- `processPostSoql(Soql.Request request, Object results)`: Processes SOQL requests after execution for testing purposes
- `processSoqlError(Soql.Request request, Exception error)`: Processes SOQL errors for testing purposes
