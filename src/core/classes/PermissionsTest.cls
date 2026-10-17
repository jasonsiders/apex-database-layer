@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class PermissionsTest {
	@IsTest
	private static void shouldReturnFalseForUnknownPermission() {
		Test.startTest();
		Boolean result = DatabaseLayer.Permissions?.hasPermission('Does_Not_Exist');
		Test.stopTest();

		Assert.isFalse(result, 'Running user should not have an unknown permission');
	}

	@IsTest
	private static void shouldReturnFalseForBlankPermissionName() {
		Test.startTest();
		// FeatureManagement.checkPermission throws an uncatchable exception for blank names
		Boolean blankResult = DatabaseLayer.Permissions?.hasPermission('');
		Boolean nullResult = DatabaseLayer.Permissions?.hasPermission(null);
		Test.stopTest();

		Assert.isFalse(blankResult, 'Blank permission name should return false');
		Assert.isFalse(nullResult, 'Null permission name should return false');
	}
}
