/**
 * @description Checks the running user's custom permissions, with a mockable lookup for testing.
 * Custom permissions from other packages must include their namespace prefix; ex., `SBQQ__SomePermission`.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing virtual class Permissions {
	/**
	 * @description Constructor for Permissions instance with DatabaseLayer factory.
	 * @param factory The DatabaseLayer factory instance
	 */
	@SuppressWarnings('PMD.EmptyStatementBlock')
	public Permissions(DatabaseLayer factory) {
		// Note: Only accessible via DatabaseLayer.Permissions
	}

	/**
	 * @description Checks whether the running user has the specified custom permission.
	 * @param permissionName The case-insensitive API name of the custom permission
	 * @return True if the running user has the permission; false if not, or if the name is blank
	 */
	global Boolean hasPermission(String permissionName) {
		// FeatureManagement.checkPermission throws an uncatchable System.UnexpectedException on blank names
		return String.isNotBlank(permissionName) && this.checkPermission(permissionName);
	}

	/**
	 * @description Virtual hook for MockPermissions to override the permission lookup.
	 * @param permissionName The API name of the custom permission
	 * @return True if the running user has the permission
	 */
	protected virtual Boolean checkPermission(String permissionName) {
		return FeatureManagement.checkPermission(permissionName);
	}
}
