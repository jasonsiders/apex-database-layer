The `MockDuplicates.Simulator` interface defines the contract for custom duplicate detection simulators.

## Overview

This interface allows test developers to implement custom logic for simulating duplicate detection results, enabling complex test scenarios beyond what `MockDuplicates.StaticResults` provides.

## Methods

### `simulate`

Simulates duplicate detection for the given input.

```apex
global List<Duplicates.FindDuplicatesResult> simulate(Object input)
```

**Parameters:**
- `input` - The input parameter (either List<SObject> or Iterable<Id>)

**Returns:** List of simulated `FindDuplicatesResult` objects

**Throws:** Any exception to simulate error conditions

## Example Implementation

```apex
public class ConditionalSimulator implements MockDuplicates.Simulator {
    public List<Duplicates.FindDuplicatesResult> simulate(Object input) {
        List<Duplicates.FindDuplicatesResult> results = new List<Duplicates.FindDuplicatesResult>();

        if (input instanceof List<SObject>) {
            List<SObject> records = (List<SObject>) input;

            // Custom logic based on record content
            for (SObject record : records) {
                Duplicates.FindDuplicatesResult result = new MockDuplicates.FindDuplicatesResult();

                if (String.isNotEmpty((String) record.get('Name'))) {
                    result = result.asSuccessful();
                } else {
                    Duplicates.Error error = new MockDuplicates.Error()
                        .withMessage('Name is required')
                        .addField('Name');
                    result = result.asFailed().addError(error);
                }

                results.add(result);
            }
        }

        return results;
    }
}
```

## Using Custom Simulators

```apex
@IsTest
static void testWithCustomSimulator() {
    MockDuplicates.setGlobalMock(new ConditionalSimulator());

    List<Duplicates.FindDuplicatesResult> results = DatabaseLayer.Duplicates.findDuplicates(records);
    // Results are based on custom simulator logic
}
```

## Related Classes

- [MockDuplicates.StaticResults](./The-MockDuplicates.StaticResults-Class) - Built-in simulator implementation
- [MockDuplicates](./The-MockDuplicates-Class) - Mock implementation and setup
