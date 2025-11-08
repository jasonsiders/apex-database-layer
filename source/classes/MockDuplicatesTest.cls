/**
 * @description Tests for MockDuplicates functionality.
 */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class MockDuplicatesTest {
	static {
		MockCmdt.mock(DatabaseLayerSetting__mdt.SObjectType);
		DatabaseLayer.useMockDuplicates();
	}

	@IsTest
	static void shouldMockFindDuplicatesByRecords() {
		Account acc = (Account) new MockRecord(Account.SObjectType).withId().toSObject();
		Duplicates.FindDuplicatesResult mockResult = new MockDuplicates.FindDuplicatesResult()
			.asSuccessful();
		MockDuplicates.setGlobalMock().withResult(mockResult);

		Test.startTest();
		List<Duplicates.FindDuplicatesResult> results = DatabaseLayer.Duplicates.findDuplicates(
			new List<SObject>{ acc }
		);
		Test.stopTest();

		Assert.areEqual(1, results.size(), 'Should have one result');
		Assert.isTrue(results[0].getSuccess(), 'Result should be successful');
		Assert.areEqual(0, Limits.getDmlStatements(), 'Should not perform actual DML');
	}

	@IsTest
	static void shouldMockFindDuplicatesByIds() {
		Account mockAcc = (Account) new MockRecord(Account.SObjectType).withId().toSObject();
		Id testId = mockAcc.Id;
		Duplicates.FindDuplicatesResult mockResult = new MockDuplicates.FindDuplicatesResult()
			.asSuccessful();
		MockDuplicates.setGlobalMock().withResult(mockResult);

		Test.startTest();
		List<Duplicates.FindDuplicatesResult> results = DatabaseLayer.Duplicates.findDuplicates(
			new List<Id>{ testId }
		);
		Test.stopTest();

		Assert.areEqual(1, results.size(), 'Should have one result');
		Assert.isTrue(results[0].getSuccess(), 'Result should be successful');
		Assert.areEqual(0, Limits.getDmlStatements(), 'Should not perform actual DML');
	}

	@IsTest
	static void shouldBuildComplexMockResult() {
		Account originalRecord = (Account) new MockRecord(Account.SObjectType)
			.withId()
			.toSObject();

		Account duplicateRecord = (Account) new MockRecord(Account.SObjectType)
			.withId()
			.toSObject();

		Duplicates.FieldDiff fieldDiff = new MockDuplicates.FieldDiff()
			.withFieldName('Name')
			.withCompareValue('Duplicate Account');

		Duplicates.MatchRecord matchRecord = new MockDuplicates.MatchRecord()
			.withRecord(duplicateRecord)
			.addFieldDiff(fieldDiff);

		Duplicates.MatchResult matchResult = new MockDuplicates.MatchResult()
			.withRule('Standard Account Rule')
			.withSize(1)
			.addMatchRecord(matchRecord);

		Duplicates.DuplicateResult duplicateResult = new MockDuplicates.DuplicateResult()
			.withRecord(originalRecord)
			.addMatchResult(matchResult);

		Duplicates.FindDuplicatesResult findDupResult = new MockDuplicates.FindDuplicatesResult()
			.asSuccessful()
			.addDuplicateResult(duplicateResult);

		MockDuplicates.setGlobalMock().withResult(findDupResult);

		Test.startTest();
		List<Duplicates.FindDuplicatesResult> results = DatabaseLayer.Duplicates.findDuplicates(
			new List<SObject>{ originalRecord }
		);
		Test.stopTest();

		Assert.areEqual(1, results.size(), 'Should have one result');
		Duplicates.FindDuplicatesResult result = results[0];
		Assert.isTrue(result.getSuccess(), 'Result should be successful');
		Assert.areEqual(1, result.getDuplicateResults().size(), 'Should have one duplicate result');

		Duplicates.DuplicateResult dupResult = result.getDuplicateResults()[0];
		Assert.isNotNull(dupResult.getRecord(), 'Should have record');
		Assert.areEqual(1, dupResult.getMatchResults().size(), 'Should have one match result');

		Duplicates.MatchResult matchRes = dupResult.getMatchResults()[0];
		Assert.areEqual('Standard Account Rule', matchRes.getRule(), 'Should have correct rule');
		Assert.areEqual(1, matchRes.getSize(), 'Should have correct size');
		Assert.areEqual(1, matchRes.getMatchRecords().size(), 'Should have one match record');

		Duplicates.MatchRecord matchRec = matchRes.getMatchRecords()[0];
		Assert.isNotNull(matchRec.getRecord(), 'Should have duplicate record');
		Assert.areEqual(1, matchRec.getFieldDiffs().size(), 'Should have one field diff');

		Duplicates.FieldDiff diff = matchRec.getFieldDiffs()[0];
		Assert.areEqual('Name', diff.getFieldName(), 'Should have correct field name');
		Assert.areEqual('Duplicate Account', diff.getCompareValue(), 'Should have correct field value');
	}

	@IsTest
	static void shouldThrowExceptionWhenConfigured() {
		Account acc = (Account) new MockRecord(Account.SObjectType).withId().toSObject();
		MockDuplicates.setGlobalMock().withError(new TypeException('Test error'));

		Test.startTest();
		try {
			DatabaseLayer.Duplicates.findDuplicates(new List<SObject>{ acc });
			Assert.fail('Should have thrown exception');
		} catch (TypeException e) {
			Assert.areEqual('Test error', e.getMessage(), 'Should throw configured error');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldHandleErrorResults() {
		Duplicates.Error error = new MockDuplicates.Error()
			.withMessage('Permission denied')
			.withStatusCode('FIELD_ERROR')
			.addField('Name');

		Duplicates.FindDuplicatesResult mockResult = new MockDuplicates.FindDuplicatesResult()
			.asFailed()
			.addError(error);

		MockDuplicates.setGlobalMock().withResult(mockResult);

		Test.startTest();
		List<Duplicates.FindDuplicatesResult> results = DatabaseLayer.Duplicates.findDuplicates(
			new List<SObject>()
		);
		Test.stopTest();

		Assert.areEqual(1, results.size(), 'Should have one result');
		Duplicates.FindDuplicatesResult result = results[0];
		Assert.isFalse(result.getSuccess(), 'Result should be failed');
		Assert.areEqual(1, result.getErrors().size(), 'Should have one error');

		Duplicates.Error resultError = result.getErrors()[0];
		Assert.areEqual('Permission denied', resultError.getMessage(), 'Should have correct error message');
		Assert.areEqual('FIELD_ERROR', resultError.getStatusCode(), 'Should have correct status code');
		Assert.areEqual(1, resultError.getFields().size(), 'Should have one field');
	}

	@IsTest
	static void shouldReturnEmptyResultsWhenNullSimulator() {
		Account acc = (Account) new MockRecord(Account.SObjectType).withId().toSObject();
		MockDuplicates duplicates = new MockDuplicates(null);

		Test.startTest();
		List<Duplicates.FindDuplicatesResult> results = duplicates.findDuplicates(
			new List<SObject>{ acc }
		);
		Test.stopTest();

		Assert.areEqual(0, results.size(), 'Should return empty list when no simulator configured');
	}

	@IsTest
	static void shouldSetMultipleResults() {
		List<Duplicates.FindDuplicatesResult> mockResults = new List<Duplicates.FindDuplicatesResult>();
		mockResults.add(new MockDuplicates.FindDuplicatesResult().asSuccessful());
		mockResults.add(new MockDuplicates.FindDuplicatesResult().asFailed());

		MockDuplicates.setGlobalMock().withResults(mockResults);

		Test.startTest();
		List<Duplicates.FindDuplicatesResult> results = DatabaseLayer.Duplicates.findDuplicates(
			new List<SObject>()
		);
		Test.stopTest();

		Assert.areEqual(2, results.size(), 'Should have two results');
		Assert.isTrue(results[0].getSuccess(), 'First result should be successful');
		Assert.isFalse(results[1].getSuccess(), 'Second result should be failed');
	}
}
