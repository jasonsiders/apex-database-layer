The `Permissions` class checks whether the running user has a custom permission.

It wraps the standard [`FeatureManagement.checkPermission`](https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_class_System_FeatureManagement.htm) method, so that tests can grant and revoke custom permissions without creating permission sets or permission set assignments. See [Mocking Custom Permissions](./Mocking-Custom-Permissions) for details.

## Constructing `Permissions` Objects

`Permissions` objects cannot be directly constructed via the `new` keyword. Instead, access the class and its methods via the `DatabaseLayer.Permissions` static property:

```apex
Boolean canApprove = DatabaseLayer.Permissions.hasPermission('Can_Approve_Discounts');
```

The `DatabaseLayer` class is responsible for instantiating objects of the correct type at runtime. In `@IsTest` context, developers can call `DatabaseLayer.useMocks()`, and an instance of the [`MockPermissions`](./The-MockPermissions-Class) class will be returned instead:

```apex
DatabaseLayer.useMocks();
Assert.isInstanceOfType(DatabaseLayer.Permissions, MockPermissions.class, 'Not a mock');
```

## Methods

### `hasPermission`

Checks whether the running user has the specified custom permission.

- `Boolean hasPermission(String permissionName)`

**Parameters:**

- `permissionName` (String): The API name of the custom permission. Matching is case-insensitive.

**Return Value:**

- Boolean: `true` if the running user has the permission. `false` if the user does not have the permission, if the permission does not exist, or if `permissionName` is blank.

```apex
if (DatabaseLayer.Permissions.hasPermission('Can_Approve_Discounts')) {
    // ...
}
```

## Considerations

- Only the running user's permissions can be checked, since `FeatureManagement.checkPermission` only supports the running user.
- Custom permissions from other packages must include the package's namespace prefix, ex., `SBQQ__HideGlobalHeader`. Without the prefix, the check returns `false`, even if the user has the permission.
- `FeatureManagement.checkPermission` throws an uncatchable `System.UnexpectedException` when given a blank name. `hasPermission` returns `false` instead.
