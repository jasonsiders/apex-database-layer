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
		DatabaseLayer.useMocks();
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
		DatabaseLayer.useMocks();
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
	static void shouldCallActualDatacloudApiWithRecords() {
		List<DuplicateRule> accountRules = [
			SELECT Id
			FROM DuplicateRule
			WHERE SobjectType = 'Account' AND IsActive = true
			LIMIT 1
		];
		Boolean hasActiveRules = !accountRules.isEmpty();

		Account acc = new Account(Name = 'Test Account', Phone = '555-1234');

		Test.startTest();
		List<Duplicates.FindDuplicatesResult> results = DatabaseLayer.Duplicates.findDuplicates(
			new List<SObject>{ acc }
		);
		Test.stopTest();

		Assert.isNotNull(results, 'Results should not be null');
		if (hasActiveRules) {
			Assert.areEqual(1, results.size(), 'Should return one result per input record');
			Assert.isNotNull(results[0].getDuplicateResults(), 'Duplicate results initialized');
		}
	}

	@IsTest
	static void shouldCallActualDatacloudApiById() {
		List<DuplicateRule> leadRules = [
			SELECT Id
			FROM DuplicateRule
			WHERE SobjectType = 'Lead' AND IsActive = true
			LIMIT 1
		];
		Boolean hasActiveRules = !leadRules.isEmpty();

		Lead testLead = new Lead(LastName = 'Test', Company = 'Test', Email = 'test@example.com');
		insert testLead;

		Test.startTest();
		List<Duplicates.FindDuplicatesResult> results = DatabaseLayer.Duplicates.findDuplicates(
			new List<Id>{ testLead.Id }
		);
		Test.stopTest();

		Assert.isNotNull(results, 'Results should not be null');
		if (hasActiveRules) {
			Assert.areEqual(1, results.size(), 'Should return one result per input ID');
		}
	}

	@IsTest
	static void shouldCallActualDatacloudApiWithContact() {
		List<DuplicateRule> contactRules = [
			SELECT Id
			FROM DuplicateRule
			WHERE SobjectType = 'Contact' AND IsActive = true
			LIMIT 1
		];
		Boolean hasActiveRules = !contactRules.isEmpty();

		Contact con = new Contact(LastName = 'Test', Email = 'test@example.com');

		Test.startTest();
		List<Duplicates.FindDuplicatesResult> results = DatabaseLayer.Duplicates.findDuplicates(
			new List<SObject>{ con }
		);
		Test.stopTest();

		Assert.isNotNull(results, 'Results should not be null');
		if (hasActiveRules) {
			Assert.areEqual(1, results.size(), 'Should return one result per input record');
		}
	}
}
