The `Duplicates.Error` class is a mockable wrapper for error information from duplicate detection operations.

## Overview

This class provides information about errors that may occur during duplicate detection, including error messages, status codes, and affected fields.

## Methods

### `getMessage`

Returns the error message.

```apex
global String getMessage()
```

**Returns:** Human-readable error description

### `getStatusCode`

Returns the error status code.

```apex
global String getStatusCode()
```

**Returns:** Error status code as string (e.g., 'FIELD_ERROR', 'PERMISSION_DENIED')

### `getFields`

Returns the list of fields affected by this error.

```apex
global List<String> getFields()
```

**Returns:** List of field API names; empty if no specific fields are affected

## Example Usage

```apex
if (!result.getSuccess()) {
    for (Duplicates.Error error : result.getErrors()) {
        String message = error.getMessage();
        String statusCode = error.getStatusCode();
        List<String> affectedFields = error.getFields();

        System.debug('Error: ' + message);
        System.debug('Status: ' + statusCode);

        if (!affectedFields.isEmpty()) {
            System.debug('Affected fields: ' + String.join(affectedFields, ', '));
        }
    }
}
```

## Testing with Mocks

When testing error scenarios, use `MockDuplicates.Error` to build test data:

```apex
Duplicates.Error error = new MockDuplicates.Error()
    .withMessage('Permission denied')
    .withStatusCode('FIELD_ERROR')
    .addField('Name')
    .addField('Phone');

Duplicates.FindDuplicatesResult mockResult = new MockDuplicates.FindDuplicatesResult()
    .asFailed()
    .addError(error);
```

See [MockDuplicates.Error](./The-MockDuplicates.Error-Class) for mock implementation.
