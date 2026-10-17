The `MockPermissions` class mocks custom permission checks in Apex tests. It extends the [`Permissions`](./The-Permissions-Class) class.

When `DatabaseLayer.useMocks()` is called, `DatabaseLayer.Permissions` returns a `MockPermissions` instance. Its `hasPermission` method checks permissions granted with the static methods below, instead of the running user's real permissions. Permissions that were never granted return `false`.

```apex
@IsTest
static void shouldApproveDiscount() {
    DatabaseLayer.useMocks();
    MockPermissions.grant('Can_Approve_Discounts');

    Assert.isTrue(DatabaseLayer.Permissions.hasPermission('Can_Approve_Discounts'), 'Not granted');
}
```

The `MockPermissions` class is only available in test contexts (`@IsTest`).

## Behavior

- **The most recent call wins.** `grant` and `revoke` set the permission's state for each specified user. `grantToAll` and `revokeFromAll` set the state for all users, and clear any user-specific states for that permission.
- **Repeated calls have no extra effect.** Granting a permission twice, then revoking it once, leaves it revoked.
- **Matching is case-insensitive**, like `FeatureManagement.checkPermission`.
- **Blank permission names** always return `false`, even if granted.
- **Users are matched by Id.** Users passed to `grant` or `revoke` must have an Id; insert them first. A grant to a user without an Id never matches.

## Methods

### `grant`

Grants a custom permission to the specified user(s). If no users are specified, grants the permission to the running user.

- `static void grant(String permissionName)`
- `static void grant(String permissionName, User user)`
- `static void grant(String permissionName, List<User> users)`

### `grantToAll`

Grants a custom permission to all users, overriding any previous user-specific grants or revokes.

- `static void grantToAll(String permissionName)`

### `revoke`

Revokes a custom permission from the specified user(s). If no users are specified, revokes the permission from the running user.

- `static void revoke(String permissionName)`
- `static void revoke(String permissionName, User user)`
- `static void revoke(String permissionName, List<User> users)`

### `revokeFromAll`

Revokes a custom permission from all users, overriding any previous user-specific grants or revokes.

- `static void revokeFromAll(String permissionName)`
