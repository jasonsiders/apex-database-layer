/**
 * @description Tests for Duplicates wrapper functionality.
 * Note: Full integration tests require Datacloud API access and duplicate rules configured in the org.
 */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class DuplicatesTest {
	@IsTest
	static void shouldAccessDuplicatesViaDatabaseLayer() {
		Duplicates duplicates = DatabaseLayer.Duplicates;

		Assert.isNotNull(duplicates, 'Duplicates instance should not be null');
	}

	@IsTest
	static void shouldCallFindDuplicatesByRecords() {
		Account acc = (Account) new MockRecord(Account.SObjectType).withId().toSObject();

		Test.startTest();
		List<Duplicates.FindDuplicatesResult> results = DatabaseLayer.Duplicates.findDuplicates(
			new List<SObject>{ acc }
		);
		Test.stopTest();

		Assert.isNotNull(results, 'Results should not be null');
		Assert.areEqual(0, Limits.getDmlStatements(), 'Should not perform actual DML');
	}

	@IsTest
	static void shouldCallFindDuplicatesById() {
		Account mockAcc = (Account) new MockRecord(Account.SObjectType).withId().toSObject();
		Id testId = mockAcc.Id;

		Test.startTest();
		List<Duplicates.FindDuplicatesResult> results = DatabaseLayer.Duplicates.findDuplicates(
			new List<Id>{ testId }
		);
		Test.stopTest();

		Assert.isNotNull(results, 'Results should not be null');
		Assert.areEqual(0, Limits.getDmlStatements(), 'Should not perform actual DML');
	}

	@IsTest
	static void shouldReturnEmptyResultsWhenNoDatacloudApi() {
		Account acc = (Account) new MockRecord(Account.SObjectType).withId().toSObject();

		Test.startTest();
		List<Duplicates.FindDuplicatesResult> results = DatabaseLayer.Duplicates.findDuplicates(
			new List<SObject>{ acc }
		);
		Test.stopTest();

		Assert.isNotNull(results, 'Results should not be null');
		Assert.areEqual(0, results.size(), 'Should return empty results when Datacloud API unavailable');
	}
}
