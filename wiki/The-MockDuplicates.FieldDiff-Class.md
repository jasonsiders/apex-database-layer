Represents a field-level difference between records in test scenarios.

This class extends [Duplicates.FieldDiff](./The-Duplicates.FieldDiff-Class) and provides a fluent API for specifying how fields differ in duplicate matches.

## Methods

### `setDifference`

Sets the type of difference for this field. The `difference` parameter specifies the difference type: `IS_DIFFERENT`, `IS_NULL`, or `IS_SAME`. Returns this instance for method chaining.

- `MockDuplicates.FieldDiff setDifference(MockDuplicates.DiffType difference)`

```apex
diff.setDifference(MockDuplicates.DiffType.IS_DIFFERENT);
```

### `setName`

Sets the API name of the field. Returns this instance for method chaining.

- `MockDuplicates.FieldDiff setName(String name)`

```apex
diff.setName('Phone');
```

### `toTop`

Navigates back to the top-level `FindDuplicatesResult`.

- `MockDuplicates.FindDuplicatesResult toTop()`

```apex
MockDuplicates.FindDuplicatesResult result = diff.toTop();
```

### `up`

Navigates back to the parent `MatchRecord`.

- `MockDuplicates.MatchRecord up()`

```apex
MockDuplicates.MatchRecord matchRecord = diff.up();
```
