/**
 * @description Tests for Duplicates wrapper functionality.
 * Note: Full integration tests require Datacloud API access and duplicate rules configured in the org.
 */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class DuplicatesTest {
	private static final String TEST_ACCOUNT_NAME;
	private static final String TEST_CITY;
	private static final String TEST_STREET;
	private static final String TEST_ZIP;
	private static List<Account> testAccounts {
		get {
			testAccounts = testAccounts ?? [SELECT Id FROM Account LIMIT 3];
			return testAccounts;
		}
		private set;
	}

	static {
		TEST_ACCOUNT_NAME = 'Doe Enterprises, LLC';
		TEST_CITY = 'Walla Walla';
		TEST_STREET = '1234 Main St.';
		TEST_ZIP = '98765';
	}

	@TestSetup
	private static void setup() {
		// Create test records which would (normally) trip standard duplicate rules:
		Account account = new Account(
			BillingCity = TEST_CITY,
			BillingPostalCode = TEST_ZIP,
			BillingStreet = TEST_STREET,
			Name = TEST_ACCOUNT_NAME,
			ShippingCity = TEST_CITY,
			ShippingPostalCode = TEST_ZIP,
			ShippingStreet = TEST_STREET
		);
		Account duplicate = account?.clone();
		// Bypass the duplicate rules on insert:
		Database.DmlOptions options = new Database.DmlOptions();
		options.DuplicateRuleHeader.allowSave = true;
		Database.insert(new List<Account>{ account, duplicate }, options);
	}

	@IsTest
	private static void shouldFindDuplicatesForMultipleRecords() {
		Test.startTest();
		List<Duplicates.FindDuplicatesResult> results = DatabaseLayer.Duplicates.findDuplicates(testAccounts);
		Test.stopTest();

		Assert.areEqual(testAccounts?.size(), results?.size(), 'Wrong # of FindDuplicatesResults');
		for (Duplicates.FindDuplicatesResult result : results) {
			DuplicatesTest.assertOutputIsCorrect(result);
		}
	}

	@IsTest
	private static void shouldFindDuplicatesForMultipleIds() {
		Set<Id> testAccountIds = new Map<Id, Account>(testAccounts)?.keySet();

		Test.startTest();
		List<Duplicates.FindDuplicatesResult> results = DatabaseLayer.Duplicates.findDuplicates(testAccountIds);
		Test.stopTest();

		Assert.areEqual(testAccountIds?.size(), results?.size(), 'Wrong # of FindDuplicatesResults');
		for (Duplicates.FindDuplicatesResult result : results) {
			DuplicatesTest.assertOutputIsCorrect(result);
		}
	}

	@IsTest
	private static void shouldFindDuplicatesForSingleRecord() {
		Account testAccount = testAccounts?.get(0);

		Test.startTest();
		Duplicates.FindDuplicatesResult result = DatabaseLayer.Duplicates.findDuplicates(testAccount);
		Test.stopTest();

		Assert.isNotNull(result, 'Did not return a FindDuplicatesResult');
		DuplicatesTest.assertOutputIsCorrect(result);
	}

	@IsTest
	private static void shouldFindDuplicatesForSingleId() {
		Id testAccountId = testAccounts?.get(0)?.Id;

		Test.startTest();
		Duplicates.FindDuplicatesResult result = DatabaseLayer.Duplicates.findDuplicates(testAccountId);
		Test.stopTest();

		Assert.isNotNull(result, 'Did not return a FindDuplicatesResult');
		DuplicatesTest.assertOutputIsCorrect(result);
	}

	// **** HELPER **** //
	@SuppressWarnings('PMD.NcssMethodCount')
	private static void assertOutputIsCorrect(Duplicates.FindDuplicatesResult findResult) {
		Datacloud.FindDuplicatesResult nativeFindResult = findResult?.toDatacloudType();
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
			Datacloud.DuplicateResult nativeDupeResult = dupeResult?.toDatacloudType();
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
				Datacloud.MatchResult nativeMatchResult = matchResult?.toDatacloudType();
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
				Assert.areEqual(nativeMatchResult?.isSuccess(), matchResult?.isSuccess(), 'Wrong isSuccess() value');
				List<Duplicates.MatchRecord> matchRecords = matchResult?.getMatchRecords();
				Assert.areEqual(
					nativeMatchResult?.getMatchRecords()?.size(),
					matchRecords?.size(),
					'Wrong # of MatchRecords'
				);
				for (Duplicates.MatchRecord matchRecord : matchRecords) {
					Datacloud.MatchRecord nativeMatchRecord = matchRecord?.toDatacloudType();
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
						Datacloud.AdditionalInformationMap nativeAdditionalInfo = additionalInfo?.toDatacloudType();
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
						Datacloud.FieldDiff nativeFieldDiff = fieldDiff?.toDatacloudType();
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
