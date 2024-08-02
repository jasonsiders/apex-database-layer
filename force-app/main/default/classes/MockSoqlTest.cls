@IsTest
@SuppressWarnings('PMD.EmptyCatchBlock')
private class MockSoqlTest {
	// **** CONSTANTS **** //
	private static final Integer NUM_ACCS = 10;

	// **** TESTS **** //
	@IsTest
	static void shouldMockCountQuery() {
		// Build a query
		Soql.Aggregation count = new Soql.Aggregation(Soql.Function.COUNT);
		MockSoql soql = (MockSoql) new MockSoql(Account.SObjectType)?.addSelect(count);
		// Inject the query w/mock results
		List<Account> accounts = MockSoqlTest.initAccounts(NUM_ACCS);
		soql?.setMock(accounts);

		Test.startTest();
		Integer results = soql?.countQuery();
		Assert.areEqual(0, Limits.getQueries(), 'Actually executed SOQL');
		Test.stopTest();

		Assert.areEqual(NUM_ACCS, results, 'Wrong # of Accounts returned');
	}

	@IsTest
	static void shouldMockCountQueryErrors() {
		// Build a query
		MockSoql soql = (MockSoql) new MockSoql(Account.SObjectType)?.addSelect(Account.Name);
		// Inject the query w/a mock error
		soql?.setError();

		Test.startTest();
		try {
			soql?.countQuery();
			Assert.fail('The injected exception was not thrown');
		} catch (System.QueryException error) {
			Assert.areEqual(true, error?.getMessage()?.contains(soql?.toString()), 'Did not append query to error');
			Assert.areEqual(0, Limits.getQueries(), 'Actually executed SOQL');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldMockQueryLocator() {
		// Build a query
		MockSoql soql = (MockSoql) new MockSoql(Account.SObjectType)?.addSelect(Account.Name);
		// Inject the query w/mock results
		List<Account> accounts = MockSoqlTest.initAccounts(NUM_ACCS);
		soql?.setMock(accounts);

		Test.startTest();
		Soql.QueryLocator locator = soql?.getQueryLocator();
		Assert.areEqual(0, Limits.getQueries(), 'Actually executed SOQL');
		Test.stopTest();

		Assert.areEqual(soql?.toString(), locator?.getQuery(), 'Wrong query returned');
		System.Iterator<SObject> iterator = locator?.iterator();
		for (Integer i = 0; i < (NUM_ACCS + 1); i++) {
			if (i < NUM_ACCS) {
				Assert.areEqual(true, iterator?.hasNext(), i + '/' + NUM_ACCS + ': Iterator should hasNext()');
				Account account = (Account) iterator?.next();
				Assert.areNotEqual(null, account, i + '/' + NUM_ACCS + ': Iterator returned null record');
			} else {
				Assert.areEqual(false, iterator?.hasNext(), i + '/' + NUM_ACCS + ': Iterator should not hasNext()');
				try {
					iterator?.next();
					Assert.fail('Iterator did not throw a ' + System.NoSuchElementException.class);
				} catch (System.NoSuchElementException error) {
					// As expected
				}
			}
		}
	}

	@IsTest
	static void shouldMockQueryLocatorErrors() {
		// Build a query
		MockSoql soql = (MockSoql) new MockSoql(Account.SObjectType)?.addSelect(Account.Name);
		// Inject the query w/a mock error
		soql?.setError();

		Test.startTest();
		try {
			soql?.getQueryLocator();
			Assert.fail('The injected exception was not thrown');
		} catch (System.QueryException error) {
			Assert.areEqual(true, error?.getMessage()?.contains(soql?.toString()), 'Did not append query to error');
			Assert.areEqual(0, Limits.getQueries(), 'Actually executed SOQL');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldMockQuery() {
		// Build query
		MockSoql soql = (MockSoql) new MockSoql(Account.SObjectType)?.addSelect(Account.Name);
		// Inject the query w/mock results
		List<Account> accounts = MockSoqlTest.initAccounts(NUM_ACCS);
		soql?.setMock(accounts);

		Test.startTest();
		List<Account> results = soql?.query();
		Assert.areEqual(0, Limits.getQueries(), 'Actually executed SOQL');
		Test.stopTest();

		Assert.areEqual(accounts, results, 'Did not return the injected accounts');
	}

	@IsTest
	static void shouldMockQueryErrors() {
		// Build a query
		MockSoql soql = (MockSoql) new MockSoql(Account.SObjectType)?.addSelect(Account.Name);
		// Inject the query w/a mock error
		soql?.setError();

		Test.startTest();
		try {
			soql?.query();
			Assert.fail('The injected exception was not thrown');
		} catch (System.QueryException error) {
			Assert.areEqual(true, error?.getMessage()?.contains(soql?.toString()), 'Did not append query to error');
			Assert.areEqual(0, Limits.getQueries(), 'Actually executed SOQL');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldMockAggregateQuery() {
		// Build an aggregate query
		Soql.Aggregation count = new Soql.Aggregation(Soql.Function.COUNT, User.Id);
		MockSoql soql = (MockSoql) new MockSoql(User.SObjectType)
			?.addSelect('Profile.Name')
			?.addSelect(count)
			?.groupBy('Profile.Name');
		// Inject results into the query
		MockSoql.AggregateResult mockResult1 = new MockSoql.AggregateResult()
			?.addParameter('Foo Profile')
			?.addParameter(123);
		MockSoql.AggregateResult mockResult2 = new MockSoql.AggregateResult()
			?.addParameter('Bar Profile')
			?.addParameter(45);
		List<Soql.AggregateResult> mockResults = new List<Soql.AggregateResult>{ mockResult1, mockResult2 };
		soql?.setMock(mockResults);

		Test.startTest();
		List<Soql.AggregateResult> results = soql?.aggregateQuery();
		Assert.areEqual(0, Limits.getQueries(), 'Actually executed SOQL');
		Test.stopTest();

		Integer numResults = results?.size();
		Assert.areEqual(mockResults?.size(), numResults, 'Wrong # of AggregateResults');
		for (Integer i = 0; i < numResults; i++) {
			Soql.AggregateResult expectedResult = mockResults[i];
			Soql.AggregateResult actualResult = results[i];
			// Note: AggregateResults assigns unaliased fields with an expr_N_ key, where _N_ is the column index
			for (String key : new Set<String>{ 'expr0', 'expr1' }) {
				Assert.areEqual(expectedResult?.get(key), actualResult?.get(key), key + ': Wrong value');
			}
		}
	}

	@IsTest
	static void shouldMockAggregateQueryErrors() {
		// Build an aggregate query
		Soql.Aggregation count = new Soql.Aggregation(Soql.Function.COUNT, User.Id);
		MockSoql soql = (MockSoql) new MockSoql(User.SObjectType)
			?.addSelect('Profile.Name')
			?.addSelect(count)
			?.groupBy('Profile.Name');
		// Inject an error
		soql?.setError();

		Test.startTest();
		try {
			soql?.aggregateQuery();
			Assert.fail('The injected exception was not thrown');
		} catch (System.QueryException error) {
			Assert.areEqual(true, error?.getMessage()?.contains(soql?.toString()), 'Did not append query to error');
			Assert.areEqual(0, Limits.getQueries(), 'Actually executed SOQL');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldMockQueryAndCastToType() {
		// Build an aggregate query
		Soql.Aggregation count = new Soql.Aggregation(Soql.Function.COUNT, User.Id);
		MockSoql soql = (MockSoql) new MockSoql(User.SObjectType)
			?.addSelect('Profile.Name')
			?.addSelect(count)
			?.groupBy('Profile.Name');
		// Inject results
		SampleWrapper mockResult1 = new SampleWrapper()?.wrap('Foo Profile', 123);
		SampleWrapper mockResult2 = new SampleWrapper()?.wrap('Bar Profile', 45);
		List<SampleWrapper> mockResults = new List<SampleWrapper>{ mockResult1, mockResult2 };
		soql?.setMock(mockResults);

		Test.startTest();
		List<SampleWrapper> results = (List<SampleWrapper>) soql?.query(List<SampleWrapper>.class);
		Assert.areEqual(0, Limits.getQueries(), 'Actually executed SOQL');
		Test.stopTest();

		Integer numResults = results?.size();
		Assert.areEqual(mockResults?.size(), numResults, 'Wrong # of results returned');
		for (Integer i = 0; i < numResults; i++) {
			SampleWrapper expectedResult = mockResults[i];
			SampleWrapper actualResult = results[i];
			Assert.areEqual(expectedResult?.profileName, actualResult?.profileName, 'Wrong profileName');
			Assert.areEqual(expectedResult?.numRecords, actualResult?.numRecords, 'Wrong numRecords');
		}
	}

	@IsTest
	static void shouldHandleErrorsWithMockAndCast() {
		// Build an aggregate query
		Soql.Aggregation count = new Soql.Aggregation(Soql.Function.COUNT, User.Id);
		MockSoql soql = (MockSoql) new MockSoql(User.SObjectType)
			?.addSelect('Profile.Name')
			?.addSelect(count)
			?.groupBy('Profile.Name');
		// Inject an error
		soql?.setError(new System.TypeException());

		Test.startTest();
		try {
			soql?.query(List<SampleWrapper>.class);
			Assert.fail('The injected exception was not thrown');
		} catch (System.TypeException error) {
			Assert.areEqual(true, error?.getMessage()?.contains(soql?.toString()), 'Did not append query to error');
			Assert.areEqual(0, Limits.getQueries(), 'Actually executed SOQL');
		}
		Test.stopTest();
	}

	@IsTest
	static void shouldReturnEmptyListIfNoMocks() {
		// If a MockSoql is ran, and no Simulator is injected, the methods will automatically return an empty List
		MockSoql soql = (MockSoql) new MockSoql(Account.SObjectType);

		Test.startTest();
		List<Soql.AggregateResult> aggregateResults = soql?.aggregateQuery();
		Integer countResults = soql?.countQuery();
		Iterator<SObject> locatorIterator = soql?.getQueryLocator()?.iterator();
		List<SObject> queryResults = soql?.query();
		SObject queryFirstResult = soql?.queryFirst();
		List<SampleWrapper> queryCastResults = (List<SampleWrapper>) soql?.query(List<SampleWrapper>.class);
		Test.stopTest();

		Assert.areEqual(true, aggregateResults?.isEmpty(), 'aggregateQuery() returned results');
		Assert.areEqual(0, countResults, 'countQuery() returned results');
		Assert.areEqual(false, locatorIterator?.hasNext(), 'getQueryLocator() returned results');
		Assert.areEqual(true, queryResults?.isEmpty(), 'query() returned results');
		Assert.areEqual(null, queryFirstResult, 'queryFirst() returned result');
		Assert.areEqual(true, queryCastresults?.isEmpty(), 'query(Type) returned results');
	}

	// **** HELPER **** //
	static List<Account> initAccounts(Integer numAccounts) {
		List<Account> accounts = new List<Account>();
		for (Integer i = 0; i < numAccounts; i++) {
			String name = 'Test Account #' + (i + 1);
			Account account = new Account(Name = name);
			accounts?.add(account);
		}
		return accounts;
	}

	// **** INNER **** //
	private class SampleWrapper {
		public Integer numRecords;
		public String profileName;

		public SampleWrapper wrap(String profileName, Integer numRecords) {
			this.profileName = profileName;
			this.numRecords = numRecords;
			return this;
		}
	}
}
