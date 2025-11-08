The `MockDuplicates.StaticResults` class provides predefined duplicate detection results for testing.

## Overview

This built-in simulator returns static results that you configure beforehand, making it ideal for most test scenarios. It implements the `MockDuplicates.Simulator` interface.

## Methods

### `withResult`

Adds a single result to the simulated results list.

```apex
global StaticResults withResult(Duplicates.FindDuplicatesResult result)
```

**Parameters:**
- `result` - A configured `FindDuplicatesResult` to add

**Returns:** This instance for method chaining

### `withResults`

Sets the complete list of simulated results.

```apex
global StaticResults withResults(List<Duplicates.FindDuplicatesResult> results)
```

**Parameters:**
- `results` - The complete list of results

**Returns:** This instance for method chaining

### `withError`

Sets an exception to be thrown when `simulate` is called.

```apex
global StaticResults withError(Exception error)
```

**Parameters:**
- `error` - The exception to throw

**Returns:** This instance for method chaining

### `simulate`

Executes the simulation by returning configured results or throwing an error.

```apex
global List<Duplicates.FindDuplicatesResult> simulate(Object input)
```

**Parameters:**
- `input` - The input (not used by StaticResults)

**Returns:** The configured results list

**Throws:** The configured error if set

## Usage Examples

### Single Result

```apex
Duplicates.FindDuplicatesResult mockResult = new MockDuplicates.FindDuplicatesResult()
    .asSuccessful();

MockDuplicates.setGlobalMock().withResult(mockResult);
```

### Multiple Results

```apex
List<Duplicates.FindDuplicatesResult> results = new List<Duplicates.FindDuplicatesResult>();
results.add(new MockDuplicates.FindDuplicatesResult().asSuccessful());
results.add(new MockDuplicates.FindDuplicatesResult().asFailed());

MockDuplicates.setGlobalMock().withResults(results);
```

### Error Condition

```apex
MockDuplicates.setGlobalMock()
    .withError(new System.NullPointerException('API unavailable'));

try {
    DatabaseLayer.Duplicates.findDuplicates(records);
    Assert.fail('Should throw exception');
} catch (System.NullPointerException ex) {
    // Expected
}
```

## Integration with MockDuplicates

`StaticResults` is automatically created when you call `MockDuplicates.setGlobalMock()` without arguments:

```apex
MockDuplicates.setGlobalMock() // Returns StaticResults
    .withResult(mockResult);
```

See [MockDuplicates](./The-MockDuplicates-Class) for more information.
