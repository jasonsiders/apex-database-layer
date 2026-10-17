/**
 * @description Mock implementation of the Permissions class for testing custom permission logic.
 * Grants and revokes custom permissions in memory, without permission sets or permission set assignments.
 * The most recent call wins: `grant`/`revoke` set a user's state, and `grantToAll`/`revokeFromAll` reset every user's state.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
@IsTest
global class MockPermissions extends Permissions {
	// Keys are lowercased, since the platform matches custom permission names case-insensitively
	private static Map<String, Boolean> defaultStates = new Map<String, Boolean>{};
	private static Map<String, Map<Id, Boolean>> userStates = new Map<String, Map<Id, Boolean>>{};

	// **** STATIC **** //
	/**
	 * @description Grants a custom permission to the running user.
	 * @param permissionName The API name of the custom permission
	 */
	global static void grant(String permissionName) {
		User runningUser = MockPermissions.getRunningUser();
		MockPermissions.grant(permissionName, runningUser);
	}

	/**
	 * @description Grants a custom permission to the specified user.
	 * @param permissionName The API name of the custom permission
	 * @param user The user to grant the permission to
	 */
	global static void grant(String permissionName, User user) {
		MockPermissions.grant(permissionName, new List<User>{ user });
	}

	/**
	 * @description Grants a custom permission to the specified users.
	 * @param permissionName The API name of the custom permission
	 * @param users The users to grant the permission to
	 */
	global static void grant(String permissionName, List<User> users) {
		MockPermissions.setUserStates(permissionName, users, true);
	}

	/**
	 * @description Grants a custom permission to all users, overriding any previous user-specific grants or revokes.
	 * @param permissionName The API name of the custom permission
	 */
	global static void grantToAll(String permissionName) {
		MockPermissions.setDefaultState(permissionName, true);
	}

	/**
	 * @description Revokes a custom permission from the running user.
	 * @param permissionName The API name of the custom permission
	 */
	global static void revoke(String permissionName) {
		User runningUser = MockPermissions.getRunningUser();
		MockPermissions.revoke(permissionName, runningUser);
	}

	/**
	 * @description Revokes a custom permission from the specified user.
	 * @param permissionName The API name of the custom permission
	 * @param user The user to revoke the permission from
	 */
	global static void revoke(String permissionName, User user) {
		MockPermissions.revoke(permissionName, new List<User>{ user });
	}

	/**
	 * @description Revokes a custom permission from the specified users.
	 * @param permissionName The API name of the custom permission
	 * @param users The users to revoke the permission from
	 */
	global static void revoke(String permissionName, List<User> users) {
		MockPermissions.setUserStates(permissionName, users, false);
	}

	/**
	 * @description Revokes a custom permission from all users, overriding any previous user-specific grants or revokes.
	 * @param permissionName The API name of the custom permission
	 */
	global static void revokeFromAll(String permissionName) {
		MockPermissions.setDefaultState(permissionName, false);
	}

	/**
	 * @description Returns a User record representing the running user.
	 * @return A User with the running user's Id
	 */
	private static User getRunningUser() {
		return new User(Id = UserInfo.getUserId());
	}

	/**
	 * @description Sets a custom permission's state for all users, and clears any user-specific states.
	 * @param permissionName The API name of the custom permission
	 * @param isGranted Whether the permission is granted
	 */
	private static void setDefaultState(String permissionName, Boolean isGranted) {
		String key = permissionName?.toLowerCase();
		MockPermissions.defaultStates?.put(key, isGranted);
		MockPermissions.userStates?.remove(key);
	}

	/**
	 * @description Sets a custom permission's state for the specified users.
	 * @param permissionName The API name of the custom permission
	 * @param users The users whose state to set
	 * @param isGranted Whether the permission is granted
	 */
	private static void setUserStates(String permissionName, List<User> users, Boolean isGranted) {
		String key = permissionName?.toLowerCase();
		Map<Id, Boolean> states = MockPermissions.userStates?.get(key) ?? new Map<Id, Boolean>{};
		for (User user : users) {
			states?.put(user?.Id, isGranted);
		}
		MockPermissions.userStates?.put(key, states);
	}

	// **** MEMBER **** //
	/**
	 * @description Constructor for MockPermissions. Access this via DatabaseLayer.Permissions after enabling mocks.
	 * @param factory The DatabaseLayer factory instance
	 */
	public MockPermissions(DatabaseLayer factory) {
		super(factory);
	}

	/**
	 * @description Checks the running user's mocked state for a custom permission, falling back to the all-users state.
	 * @param permissionName The API name of the custom permission
	 * @return True if the permission was granted to the running user
	 */
	protected override Boolean checkPermission(String permissionName) {
		String key = permissionName?.toLowerCase();
		Id userId = UserInfo.getUserId();
		Boolean defaultState = MockPermissions.defaultStates?.get(key) ?? false;
		return MockPermissions.userStates?.get(key)?.get(userId) ?? defaultState;
	}
}
