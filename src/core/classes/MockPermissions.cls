/**
 * @description Mock implementation of the Permissions class for testing custom permission logic.
 * Grants and revokes custom permissions in memory, without permission sets or permission set assignments.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
@IsTest
global class MockPermissions extends Permissions {
	/**
	 * @description Constructor for MockPermissions. Access this via DatabaseLayer.Permissions after enabling mocks.
	 * @param factory The DatabaseLayer factory instance
	 */
	public MockPermissions(DatabaseLayer factory) {
		super(factory);
	}
}
