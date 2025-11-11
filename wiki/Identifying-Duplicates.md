Performing duplicate detection using `apex-database-layer` is simple!

[DatabaseLayer.Duplicates](./The-Duplicates-Class) wraps the standard `Datacloud.FindDuplicates` class, providing a mockable interface for duplicate detection operations.

To leverage the framework, use the `DatabaseLayer.Duplicates` equivalent of Datacloud duplicate detection methods:

```apex
// Don't use the standard Datacloud method:
List<Datacloud.FindDuplicatesResult> results = Datacloud.FindDuplicates.findDuplicates(records);
// Use the DatabaseLayer.Duplicates equivalent:
List<Duplicates.FindDuplicatesResult> results = DatabaseLayer.Duplicates.findDuplicates(records);
```

---

## Why?

We recommend using `DatabaseLayer.Duplicates` instead of `Datacloud.FindDuplicates` methods across your entire codebase. This practice has the following benefits:

- Easily [mock duplicate detection operations](./Mocking-Duplicate-Rules) in tests, usually with just a few lines of code!
- Test duplicate rule logic without relying on actual duplicate rules in your org
- Simulate various duplicate detection scenarios including matches, errors, and field differences
