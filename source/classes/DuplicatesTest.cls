/**
 * @description Tests for Duplicates wrapper functionality.
 * Note: Full integration tests require Datacloud API access and duplicate rules configured in the org.
 */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class DuplicatesTest {
	private static final String TEST_COMPANY;
	private static final String TEST_EMAIL;
	private static final String TEST_FIRST_NAME;
	private static final String TEST_LAST_NAME;
	private static final String TEST_PHONE;

	static {
		TEST_COMPANY = 'Test Company';
		TEST_EMAIL = 'test@example.com.invalid';
		TEST_FIRST_NAME = 'John';
		TEST_LAST_NAME = 'Doe';
		TEST_PHONE = '+12345556789';
	}

	@TestSetup
	private static void setup() {
		// Create test records which would (normally) trip standard duplicate rules:
		Database.DmlOptions options = new Database.DmlOptions();
		options.DuplicateRuleHeader.allowSave = true;
		Account account = new Account(Name = TEST_COMPANY, Phone = TEST_PHONE);
		Database.insert(account, options);
		Contact contact = new Contact(
			AccountId = account?.Id,
			Email = TEST_EMAIL,
			FirstName = TEST_FIRST_NAME,
			LastName = TEST_LAST_NAME,
			Phone = TEST_PHONE
		);
		Database.insert(contact, options);
		Lead lead = new Lead(
			Company = TEST_COMPANY,
			Email = TEST_EMAIL,
			FirstName = TEST_FIRST_NAME,
			LastName = TEST_LAST_NAME,
			Phone = TEST_PHONE
		);
		Database.insert(lead, options);
	}

	@IsTest
	private static void shouldCallFindDuplicatesByRecords() {
		List<Account> accounts = [SELECT Id FROM Account LIMIT 1];

		Test.startTest();
		List<Duplicates.FindDuplicatesResult> results = DatabaseLayer.Duplicates.findDuplicates(accounts);
		Test.stopTest();

		Assert.areEqual(accounts?.size(), results?.size(), 'Wrong # of FindDuplicatesResults');
		for (Duplicates.FindDuplicatesResult result : results) {
			DuplicatesTest.assertOutputIsCorrect(result);
		}
	}

	@IsTest
	private static void shouldCallFindDuplicatesById() {
		Set<Id> accountIds = new Map<Id, Account>([SELECT Id FROM Account LIMIT 1])?.keySet();

		Test.startTest();
		List<Duplicates.FindDuplicatesResult> results = DatabaseLayer.Duplicates.findDuplicates(accountIds);
		Test.stopTest();

		Assert.areEqual(accountIds?.size(), results?.size(), 'Wrong # of FindDuplicatesResults');
		for (Duplicates.FindDuplicatesResult result : results) {
			DuplicatesTest.assertOutputIsCorrect(result);
		}
	}

	// **** HELPER **** //
	private static void assertOutputIsCorrect(Duplicates.FindDuplicatesResult findResult) {
		Datacloud.FindDuplicatesResult nativeFindResult = findResult?.nativeResult;
		Assert.isNotNull(nativeFindResult, 'Missing underlying Datacloud.FindDuplicateResult');
		Assert.areEqual(
			nativeFindResult?.getErrors()?.size(),
			findResult?.getErrors()?.size(),
			'Wrong # of getErrors() values'
		);
		Assert.areEqual(nativeFindResult?.isSuccess(), findResult?.isSuccess(), 'Wrong isSuccess() value');
		List<Duplicates.DuplicateResult> dupeResults = findResult?.getDuplicateResults();
		Assert.areEqual(
			nativeFindResult?.getDuplicateResults()?.size(),
			dupeResults?.size(),
			'Wrong # of DuplicateResults'
		);
		for (Duplicates.DuplicateResult dupeResult : dupeResults) {
			Datacloud.DuplicateResult nativeDupeResult = dupeResult?.nativeResult;
			Assert.isNotNull(nativeDupeResult, 'Missing underlying Datacloud.DuplicateResult');
			Assert.areEqual(
				nativeDupeResult?.getDuplicateRule(),
				dupeResult?.getDuplicateRule(),
				'Wrong getDuplicateRule() value'
			);
			Assert.areEqual(
				nativeDupeResult?.getDuplicateRuleEntityType(),
				dupeResult?.getDuplicateRuleEntityType(),
				'Wrong getDuplicateRuleEntityType() value'
			);
			Assert.areEqual(
				nativeDupeResult?.getErrorMessage(),
				dupeResult?.getErrorMessage(),
				'Wrong getErrorMessage() value'
			);
			Assert.areEqual(nativeDupeResult?.isAllowSave(), dupeResult?.isAllowSave(), 'Wrong isAllowSave() value');
			List<Duplicates.MatchResult> matchResults = dupeResult?.getMatchResults();
			Assert.areEqual(
				matchResults?.size(),
				nativeDupeResult?.getMatchResults()?.size(),
				'Wrong # of MatchResults'
			);
			for (Duplicates.MatchResult matchResult : matchResults) {
				Datacloud.MatchResult nativeMatchResult = matchResult?.nativeResult;
				Assert.isNotNull(nativeMatchResult, 'Missing underlying Datacloud.MatchResult');
				Assert.areEqual(
					nativeMatchResult?.getEntityType(),
					matchResult?.getEntityType(),
					'Wrong getEntityType() value'
				);
				Assert.areEqual(
					nativeMatchResult?.getErrors()?.size(),
					matchResult?.getErrors()?.size(),
					'Wrong # of getErrors() values'
				);
				Assert.areEqual(
					nativeMatchResult?.getMatchEngine(),
					matchResult?.getMatchEngine(),
					'Wrong getMatchEngine() value'
				);
				Assert.areEqual(nativeMatchResult?.getRule(), matchResult?.getRule(), 'Wrong getRule() value');
				Assert.areEqual(nativeMatchResult?.getSize(), matchResult?.getSize(), 'Wrong getSize() value');
				List<Duplicates.MatchRecord> matchRecords = matchResult?.getMatchRecords();
				Assert.areEqual(
					nativeMatchResult?.getMatchRecords()?.size(),
					matchRecords?.size(),
					'Wrong # of MatchRecords'
				);
				for (Duplicates.MatchRecord matchRecord : matchRecords) {
					Datacloud.MatchRecord nativeMatchRecord = matchRecord?.nativeResult;
					Assert.isNotNull(nativeMatchRecord, 'Missing underlying Datacloud.MatchRecord');
					Assert.areEqual(
						nativeMatchRecord?.getMatchConfidence(),
						matchRecord?.getMatchConfidence(),
						'Wrong getMatchConfidence() value'
					);
					Assert.areEqual(
						nativeMatchRecord?.getRecord()?.Id,
						matchRecord?.getRecord()?.Id,
						'Wrong getRecord() value'
					);
					List<Duplicates.AdditionalInformationMap> additionalInfos = matchRecord?.getAdditionalInformation();
					Assert.areEqual(
						nativeMatchRecord?.getAdditionalInformation()?.size(),
						additionalInfos?.size(),
						'Wrong # of AdditionalInformationMaps'
					);
					for (Duplicates.AdditionalInformationMap additionalInfo : additionalInfos) {
						Datacloud.AdditionalInformationMap nativeAdditionalInfo = additionalInfo?.nativeResult;
						Assert.isNotNull(nativeAdditionalInfo, 'Missing underlying Datacloud.AdditionalInformationMap');
						Assert.areEqual(
							nativeAdditionalInfo?.getName(),
							additionalInfo?.getName(),
							'Wrong getName() value'
						);
						Assert.areEqual(
							nativeAdditionalInfo?.getValue(),
							additionalInfo?.getValue(),
							'Wrong getValue() value'
						);
					}
					List<Duplicates.FieldDiff> fieldDiffs = matchRecord?.getFieldDiffs();
					Assert.areEqual(
						nativeMatchRecord?.getFieldDiffs()?.size(),
						fieldDiffs?.size(),
						'Wrong # of FieldDiffs'
					);
					for (Duplicates.FieldDiff fieldDiff : fieldDiffs) {
						Datacloud.FieldDiff nativeFieldDiff = fieldDiff?.nativeResult;
						Assert.isNotNull(nativeFieldDiff, 'Missing underlying Datacloud.FieldDiff');
						Assert.areEqual(
							nativeFieldDiff?.getDifference(),
							fieldDiff?.getDifference(),
							'Wrong getDifference() value'
						);
						Assert.areEqual(nativeFieldDiff?.getName(), fieldDiff?.getName(), 'Wrong getName() value');
					}
				}
			}
		}
	}
}
