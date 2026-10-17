@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class MockPermissionsTest {
	private static final String PERMISSION_NAME = 'Some_Permission';
	private static final User RUNNING_USER = new User(Id = UserInfo.getUserId());

	@IsTest
	private static void shouldNotHavePermissionUnlessGranted() {
		DatabaseLayer.useMocks();

		Test.startTest();
		Boolean result = DatabaseLayer.Permissions?.hasPermission(PERMISSION_NAME);
		Test.stopTest();

		Assert.isFalse(result, 'Should not have an ungranted permission');
	}

	@IsTest
	private static void shouldGrantToRunningUser() {
		DatabaseLayer.useMocks();

		Test.startTest();
		MockPermissions.grant(PERMISSION_NAME);
		Test.stopTest();

		Assert.isTrue(DatabaseLayer.Permissions?.hasPermission(PERMISSION_NAME), 'Running user was not granted');
	}

	@IsTest
	private static void shouldGrantToSpecificUser() {
		DatabaseLayer.useMocks();
		String otherPermissionName = 'Other_Permission';
		User otherUser = (User) new MockRecord(User.SObjectType)?.withId()?.toSObject();

		Test.startTest();
		MockPermissions.grant(PERMISSION_NAME, RUNNING_USER);
		MockPermissions.grant(otherPermissionName, otherUser);
		Test.stopTest();

		Assert.isTrue(DatabaseLayer.Permissions?.hasPermission(PERMISSION_NAME), 'Running user was not granted');
		Assert.isFalse(
			DatabaseLayer.Permissions?.hasPermission(otherPermissionName),
			'Running user has a permission granted to another user'
		);
	}

	@IsTest
	private static void shouldGrantToListOfUsers() {
		DatabaseLayer.useMocks();
		User otherUser = (User) new MockRecord(User.SObjectType)?.withId()?.toSObject();

		Test.startTest();
		MockPermissions.grant(PERMISSION_NAME, new List<User>{ otherUser, RUNNING_USER });
		Test.stopTest();

		Assert.isTrue(DatabaseLayer.Permissions?.hasPermission(PERMISSION_NAME), 'Running user was not granted');
	}

	@IsTest
	private static void shouldGrantToUserRunningCode() {
		DatabaseLayer.useMocks();
		User testUser = MockPermissionsTest.insertUser();
		Boolean result;

		Test.startTest();
		MockPermissions.grant(PERMISSION_NAME, testUser);
		System.runAs(testUser) {
			result = DatabaseLayer.Permissions?.hasPermission(PERMISSION_NAME);
		}
		Test.stopTest();

		Assert.isTrue(result, 'User running code was not granted');
		Assert.isFalse(DatabaseLayer.Permissions?.hasPermission(PERMISSION_NAME), 'Granted to the wrong user');
	}

	@IsTest
	private static void shouldRevokeFromRunningUser() {
		DatabaseLayer.useMocks();
		MockPermissions.grant(PERMISSION_NAME);

		Test.startTest();
		MockPermissions.revoke(PERMISSION_NAME);
		Test.stopTest();

		Assert.isFalse(DatabaseLayer.Permissions?.hasPermission(PERMISSION_NAME), 'Was not revoked');
	}

	@IsTest
	private static void shouldRevokeFromSpecificUser() {
		DatabaseLayer.useMocks();
		MockPermissions.grant(PERMISSION_NAME);

		Test.startTest();
		MockPermissions.revoke(PERMISSION_NAME, RUNNING_USER);
		Test.stopTest();

		Assert.isFalse(DatabaseLayer.Permissions?.hasPermission(PERMISSION_NAME), 'Was not revoked');
	}

	@IsTest
	private static void shouldRevokeFromListOfUsers() {
		DatabaseLayer.useMocks();
		MockPermissions.grant(PERMISSION_NAME);

		Test.startTest();
		MockPermissions.revoke(PERMISSION_NAME, new List<User>{ RUNNING_USER });
		Test.stopTest();

		Assert.isFalse(DatabaseLayer.Permissions?.hasPermission(PERMISSION_NAME), 'Was not revoked');
	}

	@IsTest
	private static void shouldGrantToAllUsers() {
		DatabaseLayer.useMocks();
		User testUser = MockPermissionsTest.insertUser();
		Boolean testUserResult;

		Test.startTest();
		MockPermissions.grantToAll(PERMISSION_NAME);
		System.runAs(testUser) {
			testUserResult = DatabaseLayer.Permissions?.hasPermission(PERMISSION_NAME);
		}
		Test.stopTest();

		Assert.isTrue(DatabaseLayer.Permissions?.hasPermission(PERMISSION_NAME), 'Running user was not granted');
		Assert.isTrue(testUserResult, 'Other user was not granted');
	}

	@IsTest
	private static void shouldRevokeFromAllUsers() {
		DatabaseLayer.useMocks();
		MockPermissions.grantToAll(PERMISSION_NAME);

		Test.startTest();
		MockPermissions.revokeFromAll(PERMISSION_NAME);
		Test.stopTest();

		Assert.isFalse(DatabaseLayer.Permissions?.hasPermission(PERMISSION_NAME), 'Was not revoked');
	}

	@IsTest
	private static void shouldRevokeFromUserAfterGrantToAll() {
		DatabaseLayer.useMocks();
		MockPermissions.grantToAll(PERMISSION_NAME);

		Test.startTest();
		MockPermissions.revoke(PERMISSION_NAME);
		Test.stopTest();

		Assert.isFalse(DatabaseLayer.Permissions?.hasPermission(PERMISSION_NAME), 'Most recent revoke should win');
	}

	@IsTest
	private static void shouldGrantToAllAfterUserRevoke() {
		DatabaseLayer.useMocks();
		MockPermissions.revoke(PERMISSION_NAME);

		Test.startTest();
		MockPermissions.grantToAll(PERMISSION_NAME);
		Test.stopTest();

		Assert.isTrue(DatabaseLayer.Permissions?.hasPermission(PERMISSION_NAME), 'Most recent grant should win');
	}

	@IsTest
	private static void shouldRevokeFromAllAfterUserGrant() {
		DatabaseLayer.useMocks();
		MockPermissions.grant(PERMISSION_NAME);

		Test.startTest();
		MockPermissions.revokeFromAll(PERMISSION_NAME);
		Test.stopTest();

		Assert.isFalse(DatabaseLayer.Permissions?.hasPermission(PERMISSION_NAME), 'Most recent revoke should win');
	}

	@IsTest
	private static void shouldNotStackRepeatedGrants() {
		DatabaseLayer.useMocks();
		MockPermissions.grant(PERMISSION_NAME);

		Test.startTest();
		MockPermissions.grant(PERMISSION_NAME);
		Assert.isTrue(DatabaseLayer.Permissions?.hasPermission(PERMISSION_NAME), 'Repeated grant was not a no-op');
		MockPermissions.revoke(PERMISSION_NAME);
		Test.stopTest();

		Assert.isFalse(DatabaseLayer.Permissions?.hasPermission(PERMISSION_NAME), 'One revoke should undo two grants');
	}

	@IsTest
	private static void shouldNotStackRepeatedRevokes() {
		DatabaseLayer.useMocks();
		MockPermissions.revoke(PERMISSION_NAME);

		Test.startTest();
		MockPermissions.revoke(PERMISSION_NAME);
		Assert.isFalse(DatabaseLayer.Permissions?.hasPermission(PERMISSION_NAME), 'Repeated revoke was not a no-op');
		MockPermissions.grant(PERMISSION_NAME);
		Test.stopTest();

		Assert.isTrue(DatabaseLayer.Permissions?.hasPermission(PERMISSION_NAME), 'One grant should undo two revokes');
	}

	@IsTest
	private static void shouldIgnoreCase() {
		DatabaseLayer.useMocks();

		Test.startTest();
		MockPermissions.grant('SBQQ__Some_Permission');
		Test.stopTest();

		Assert.isTrue(DatabaseLayer.Permissions?.hasPermission('sbqq__some_permission'), 'Should ignore case');
	}

	@IsTest
	private static void shouldReturnFalseForBlankPermissionName() {
		DatabaseLayer.useMocks();

		Test.startTest();
		MockPermissions.grantToAll('');
		MockPermissions.grantToAll(null);
		Test.stopTest();

		Assert.isFalse(DatabaseLayer.Permissions?.hasPermission(''), 'Blank permission name should return false');
		Assert.isFalse(DatabaseLayer.Permissions?.hasPermission(null), 'Null permission name should return false');
	}

	@IsTest
	private static void shouldNotAffectRealPermissions() {
		// Mocks were never enabled; DatabaseLayer.Permissions should check the real permission
		Test.startTest();
		MockPermissions.grant(PERMISSION_NAME);
		Test.stopTest();

		Assert.isFalse(DatabaseLayer.Permissions?.hasPermission(PERMISSION_NAME), 'Used a mock grant');
	}

	// **** HELPER **** //
	private static User insertUser() {
		String username = 'mock-permissions-' + Crypto.getRandomInteger() + '@apex-database-layer.com';
		User testUser = new User(
			Alias = 'mockperm',
			Email = username,
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LastName = 'MockPermissionsTest',
			LocaleSidKey = 'en_US',
			ProfileId = UserInfo.getProfileId(),
			TimeZoneSidKey = 'America/Chicago',
			Username = username
		);
		insert testUser;
		return testUser;
	}
}
