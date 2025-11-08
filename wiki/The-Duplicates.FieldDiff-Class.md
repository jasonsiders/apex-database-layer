The `Duplicates.FieldDiff` class is a mockable wrapper for field differences between duplicate records.

## Overview

This class represents a single field that differs in value between the original record and a matched duplicate record.

## Methods

### `getFieldName`

Returns the name of the field that differs.

```apex
global String getFieldName()
```

**Returns:** API name of the field

### `getCompareValue`

Returns the value of the field on the matched record (compared to the original).

```apex
global Object getCompareValue()
```

**Returns:** The field value on the duplicate record; can be any data type

## Example Usage

```apex
for (Duplicates.FieldDiff diff : matchRecord.getFieldDiffs()) {
    String fieldName = diff.getFieldName();
    Object diffValue = diff.getCompareValue();

    System.debug('Field "' + fieldName + '" differs');
    System.debug('Duplicate value: ' + diffValue);
}
```

## Testing with Mocks

When testing, use `MockDuplicates.FieldDiff` to build test data:

```apex
Duplicates.FieldDiff fieldDiff = new MockDuplicates.FieldDiff()
    .withFieldName('Name')
    .withCompareValue('Different Name');
```

See [MockDuplicates.FieldDiff](./The-MockDuplicates.FieldDiff-Class) for mock implementation.
