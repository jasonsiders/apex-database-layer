@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class MockPermissionsTest {
	private static final String PERMISSION_NAME = 'Some_Permission';
	private static final User RUNNING_USER = new User(Id = UserInfo.getUserId());

	static {
		DatabaseLayer.useMocks();
	}

	@IsTest
	private static void shouldNotHavePermissionUnlessGranted() {
		Test.startTest();
		Boolean result = DatabaseLayer.Permissions?.hasPermission(PERMISSION_NAME);
		Test.stopTest();

		Assert.isFalse(result, 'Should not have an ungranted permission');
	}

	@IsTest
	private static void shouldGrantToRunningUser() {
		Test.startTest();
		MockPermissions.grant(PERMISSION_NAME);
		Test.stopTest();

		Boolean result = DatabaseLayer.Permissions?.hasPermission(PERMISSION_NAME);
		Assert.isTrue(result, 'Running user was not granted');
	}

	@IsTest
	private static void shouldGrantToSpecificUser() {
		String otherPermissionName = 'Other_Permission';
		User otherUser = (User) new MockRecord(User.SObjectType)?.withId()?.toSObject();

		Test.startTest();
		MockPermissions.grant(PERMISSION_NAME, RUNNING_USER);
		MockPermissions.grant(otherPermissionName, otherUser);
		Test.stopTest();

		Boolean result = DatabaseLayer.Permissions?.hasPermission(PERMISSION_NAME);
		Boolean otherResult = DatabaseLayer.Permissions?.hasPermission(otherPermissionName);
		Assert.isTrue(result, 'Running user was not granted');
		Assert.isFalse(otherResult, 'Running user has a permission granted to another user');
	}

	@IsTest
	private static void shouldGrantToListOfUsers() {
		User otherUser = (User) new MockRecord(User.SObjectType)?.withId()?.toSObject();

		Test.startTest();
		MockPermissions.grant(PERMISSION_NAME, new List<User>{ otherUser, RUNNING_USER });
		Test.stopTest();

		Boolean result = DatabaseLayer.Permissions?.hasPermission(PERMISSION_NAME);
		Assert.isTrue(result, 'Running user was not granted');
	}

	@IsTest
	private static void shouldGrantToUserRunningCode() {
		User testUser = MockPermissionsTest.insertUser();
		Boolean testUserResult;

		Test.startTest();
		MockPermissions.grant(PERMISSION_NAME, testUser);
		System.runAs(testUser) {
			testUserResult = DatabaseLayer.Permissions?.hasPermission(PERMISSION_NAME);
		}
		Test.stopTest();

		Boolean runningUserResult = DatabaseLayer.Permissions?.hasPermission(PERMISSION_NAME);
		Assert.isTrue(testUserResult, 'User running code was not granted');
		Assert.isFalse(runningUserResult, 'Granted to the wrong user');
	}

	@IsTest
	private static void shouldRevokeFromRunningUser() {
		MockPermissions.grant(PERMISSION_NAME);

		Test.startTest();
		MockPermissions.revoke(PERMISSION_NAME);
		Test.stopTest();

		Boolean result = DatabaseLayer.Permissions?.hasPermission(PERMISSION_NAME);
		Assert.isFalse(result, 'Was not revoked');
	}

	@IsTest
	private static void shouldGrantToAllUsers() {
		User testUser = MockPermissionsTest.insertUser();
		Boolean testUserResult;

		Test.startTest();
		MockPermissions.grantToAll(PERMISSION_NAME);
		System.runAs(testUser) {
			testUserResult = DatabaseLayer.Permissions?.hasPermission(PERMISSION_NAME);
		}
		Test.stopTest();

		Boolean runningUserResult = DatabaseLayer.Permissions?.hasPermission(PERMISSION_NAME);
		Assert.isTrue(runningUserResult, 'Running user was not granted');
		Assert.isTrue(testUserResult, 'Other user was not granted');
	}

	@IsTest
	private static void shouldRevokeFromAllUsers() {
		MockPermissions.grantToAll(PERMISSION_NAME);

		Test.startTest();
		MockPermissions.revokeFromAll(PERMISSION_NAME);
		Test.stopTest();

		Boolean result = DatabaseLayer.Permissions?.hasPermission(PERMISSION_NAME);
		Assert.isFalse(result, 'Was not revoked');
	}

	@IsTest
	private static void shouldRevokeFromUserAfterGrantToAll() {
		MockPermissions.grantToAll(PERMISSION_NAME);

		Test.startTest();
		MockPermissions.revoke(PERMISSION_NAME);
		Test.stopTest();

		Boolean result = DatabaseLayer.Permissions?.hasPermission(PERMISSION_NAME);
		Assert.isFalse(result, 'Most recent revoke should win');
	}

	@IsTest
	private static void shouldGrantToAllAfterUserRevoke() {
		MockPermissions.revoke(PERMISSION_NAME);

		Test.startTest();
		MockPermissions.grantToAll(PERMISSION_NAME);
		Test.stopTest();

		Boolean result = DatabaseLayer.Permissions?.hasPermission(PERMISSION_NAME);
		Assert.isTrue(result, 'Most recent grant should win');
	}

	@IsTest
	private static void shouldRevokeFromAllAfterUserGrant() {
		MockPermissions.grant(PERMISSION_NAME);

		Test.startTest();
		MockPermissions.revokeFromAll(PERMISSION_NAME);
		Test.stopTest();

		Boolean result = DatabaseLayer.Permissions?.hasPermission(PERMISSION_NAME);
		Assert.isFalse(result, 'Most recent revoke should win');
	}

	@IsTest
	private static void shouldNotStackRepeatedGrants() {
		MockPermissions.grant(PERMISSION_NAME);

		Test.startTest();
		MockPermissions.grant(PERMISSION_NAME);
		Boolean grantedResult = DatabaseLayer.Permissions?.hasPermission(PERMISSION_NAME);
		MockPermissions.revoke(PERMISSION_NAME);
		Test.stopTest();

		Boolean revokedResult = DatabaseLayer.Permissions?.hasPermission(PERMISSION_NAME);
		Assert.isTrue(grantedResult, 'Repeated grant was not a no-op');
		Assert.isFalse(revokedResult, 'One revoke should undo two grants');
	}

	@IsTest
	private static void shouldNotStackRepeatedRevokes() {
		MockPermissions.revoke(PERMISSION_NAME);

		Test.startTest();
		MockPermissions.revoke(PERMISSION_NAME);
		Boolean revokedResult = DatabaseLayer.Permissions?.hasPermission(PERMISSION_NAME);
		MockPermissions.grant(PERMISSION_NAME);
		Test.stopTest();

		Boolean grantedResult = DatabaseLayer.Permissions?.hasPermission(PERMISSION_NAME);
		Assert.isFalse(revokedResult, 'Repeated revoke was not a no-op');
		Assert.isTrue(grantedResult, 'One grant should undo two revokes');
	}

	@IsTest
	private static void shouldIgnoreCase() {
		Test.startTest();
		MockPermissions.grant('SBQQ__Some_Permission');
		Test.stopTest();

		Boolean result = DatabaseLayer.Permissions?.hasPermission('sbqq__some_permission');
		Assert.isTrue(result, 'Should ignore case');
	}

	@IsTest
	private static void shouldReturnFalseForBlankPermissionName() {
		Test.startTest();
		MockPermissions.grantToAll('');
		MockPermissions.grantToAll(null);
		Test.stopTest();

		Boolean blankResult = DatabaseLayer.Permissions?.hasPermission('');
		Boolean nullResult = DatabaseLayer.Permissions?.hasPermission(null);
		Assert.isFalse(blankResult, 'Blank permission name should return false');
		Assert.isFalse(nullResult, 'Null permission name should return false');
	}

	@IsTest
	private static void shouldNotAffectRealPermissions() {
		DatabaseLayer.useRealPermissions();

		Test.startTest();
		MockPermissions.grant(PERMISSION_NAME);
		Test.stopTest();

		Boolean result = DatabaseLayer.Permissions?.hasPermission(PERMISSION_NAME);
		Assert.isFalse(result, 'Used a mock grant');
	}

	// **** HELPER **** //
	private static User insertUser() {
		// System.runAs requires a user that exists in the database
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
