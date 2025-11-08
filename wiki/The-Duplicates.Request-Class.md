The `Duplicates.Request` class handles execution of duplicate detection requests against the native Datacloud APIs.

## Overview

This is an inner class of `Duplicates` that encapsulates the request-response cycle for duplicate detection operations. In most cases, developers interact with this class indirectly through the `findDuplicates` methods on the parent `Duplicates` class.

## Usage in Mock Context

When using mocks via `DatabaseLayer.useMocks()`, instances of `MockDuplicates.Request` are used instead to provide test-controlled duplicate detection results.

See [MockDuplicates.Request](./The-MockDuplicates.Request-Class) for mock implementation details.

## Integration with Duplicates

The `Request` class is instantiated internally by the `Duplicates.initRequest` method and should not be directly constructed in application code.

```apex
// In Duplicates.cls
protected virtual Duplicates.Request initRequest(Object input) {
    return new Duplicates.Request(input);
}
```

Subclasses like `MockDuplicates.Request` override this method to provide mock behavior.
