The `Cmdt.Repository` virtual class provides the base implementation for retrieving Custom Metadata Type (CMDT) records. This class serves as the foundation for both real database operations and can be extended for custom implementations.

The repository is returned by the `DatabaseLayer.Cmdt.ofType()` method and provides a unified interface for accessing CMDT records regardless of whether the system is configured for real database operations or mock testing scenarios.

```apex
// Get a repository for a specific CMDT type
Cmdt.Repository repository = DatabaseLayer.Cmdt.ofType(MySetting__mdt.SObjectType);

// Retrieve all records
List<MySetting__mdt> allSettings = (List<MySetting__mdt>) repository.getAll().values();

// Retrieve a specific record by developer name
MySetting__mdt specificSetting = (MySetting__mdt) repository.getInstance('Default');
```

## Implementation Details

The `Repository` class provides a simplified implementation that automatically selects only non-long-text fields to maintain the governor limit bypass behavior that Custom Metadata Type queries normally provide.

Key features of the implementation:

- **Automatic field filtering**: Excludes long text area fields from queries because including them causes CMDT queries to count against SOQL governor limits
- **Lazy loading**: Records are only queried when first accessed via `getAll()`
- **Namespace awareness**: Handles both namespaced and non-namespaced Custom Metadata Types
- **Extension support**: Can be subclassed via the `withRepository()` method for custom behavior

When `MockCmdt.mock()` is called for a specific Custom Metadata Type, subsequent calls to `DatabaseLayer.Cmdt.ofType()` for that same type will return a [`MockCmdt.Repository`](./The-MockCmdt.Repository-Class) instance instead.

## Custom Repository Example

You can create a custom repository implementation to handle specific requirements, such as including long-text fields:

```apex
public class CustomRepository extends Cmdt.Repository {
    public CustomRepository() {
        super(MySetting__mdt.SObjectType);
    }

    protected override List<SObject> queryAll() {
        // Custom implementation that includes long-text fields
        return Database.query('SELECT Id, DeveloperName, LongTextField__c FROM MySetting__mdt');
    }
}

// Register the custom repository
DatabaseLayer.Cmdt.ofType(MySetting__mdt.SObjectType)
    .withRepository(new CustomRepository());
```

---

## Methods

### `getAll`

Returns all records of the Custom Metadata Type managed by this repository.

- `Map<String, SObject> getAll()`

### `getInstance`

Returns a specific Custom Metadata Type record by its developer name. Returns `null` if no record with the specified developer name exists.

- `SObject getInstance(String key)`
