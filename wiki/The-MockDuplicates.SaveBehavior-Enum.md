Represents the `DuplicateResult`'s `allowSave` Boolean in an explicit way.

This enum provides a more readable way to specify whether records can be saved when duplicates are detected.

## Values

- `ALLOW` - Records can be saved despite duplicates being found (corresponds to `allowSave = true`)
- `BLOCK` - Records cannot be saved when duplicates are found (corresponds to `allowSave = false`)

## Example

```apex
dupResult.setSaveBehavior(MockDuplicates.SaveBehavior.BLOCK);
```
