Using `DatabaseLayer.Permissions`, you can test code that checks custom permissions without creating permission sets or permission set assignments.

## Why Mock Custom Permissions?

Granting a custom permission to a user in a test normally requires several steps:

1. Query the `CustomPermission` record.
2. Insert a `PermissionSet`, and a `SetupEntityAccess` record linking it to the custom permission.
3. Insert a `PermissionSetAssignment` for the user.
4. Run the code under test inside `System.runAs`. `FeatureManagement.checkPermission` does not see permission set assignments made earlier in the same transaction until it runs as that user.

`MockPermissions` replaces all of this with a single line of code.

## Setting Up Mocks

First, ensure all custom permission checks in the code path to be tested use `DatabaseLayer.Permissions`. Standard `FeatureManagement` calls **_cannot_** be mocked:

```apex
// Don't do this:
Boolean canApprove = FeatureManagement.checkPermission('Can_Approve_Discounts');
// Do this instead:
Boolean canApprove = DatabaseLayer.Permissions.hasPermission('Can_Approve_Discounts');
```

Next, call `DatabaseLayer.useMocks()` in your test. Once this is called, `DatabaseLayer.Permissions` returns a [`MockPermissions`](./The-MockPermissions-Class) instance, and all custom permissions return `false` until granted.

Finally, use the static [`MockPermissions`](./The-MockPermissions-Class) methods to grant or revoke the permissions needed for your test:

```apex
@IsTest
static void shouldApproveDiscountWithPermission() {
    DatabaseLayer.useMocks();
    MockPermissions.grant('Can_Approve_Discounts');
    Opportunity opp = (Opportunity) new MockRecord(Opportunity.SObjectType)?.withId()?.toSObject();

    Test.startTest();
    DiscountService.approve(opp);
    Test.stopTest();

    Assert.isTrue(MockDml.UPDATED.wasProcessed(opp), 'Discount was not approved');
}

@IsTest
static void shouldNotApproveDiscountWithoutPermission() {
    DatabaseLayer.useMocks();
    // No grant: hasPermission returns false
    Opportunity opp = (Opportunity) new MockRecord(Opportunity.SObjectType)?.withId()?.toSObject();

    Test.startTest();
    DiscountService.approve(opp);
    Test.stopTest();

    Assert.isFalse(MockDml.UPDATED.wasProcessed(opp), 'Discount was approved');
}
```

## Granting Permissions to Specific Users

By default, `grant` and `revoke` apply to the running user. Pass a `User` or `List<User>` to apply them to other users, for code under test that runs inside `System.runAs`:

```apex
User salesRep = TestUserFactory.insertSalesRep();
MockPermissions.grant('Can_Approve_Discounts', salesRep);
System.runAs(salesRep) {
    Assert.isTrue(DatabaseLayer.Permissions.hasPermission('Can_Approve_Discounts'), 'Not granted');
}
// The running user was not granted the permission:
Assert.isFalse(DatabaseLayer.Permissions.hasPermission('Can_Approve_Discounts'), 'Granted to wrong user');
```

> **Note:** `System.runAs` only works with users that exist in the database. Users created with [`MockRecord`](./The-MockRecord-Class) can be passed to `grant`, but code can never run as them.

Use `grantToAll` and `revokeFromAll` to apply a permission to every user. The most recent call wins, so you can grant a permission to everyone except a specific user:

```apex
MockPermissions.grantToAll('Can_Approve_Discounts');
MockPermissions.revoke('Can_Approve_Discounts', salesRep);
```

## Namespaced Permissions

Custom permissions from other packages must include the package's namespace prefix, both in production code and in tests:

```apex
MockPermissions.grant('SBQQ__HideGlobalHeader');
Boolean hidden = DatabaseLayer.Permissions.hasPermission('SBQQ__HideGlobalHeader');
```
