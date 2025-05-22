@SuppressWarnings('PMD.ApexDoc, PMD.EmptyCatchBlock')
@IsTest
private class MockSoqlTest {
	// **** CONSTANTS **** //
	private static final Integer NUM_ACCS = 10;

	// **** TESTS **** //
	@IsTest
	static void shouldMockCountQuery() {
		// Build a query
		Soql.Aggregation count = new Soql.Aggregation(Soql.Function.COUNT);
		MockSoql soql = (MockSoql) DatabaseLayer.useMockSoql()?.newQuery(Account.SObjectType)?.addSelect(count);
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
		MockSoql soql = (MockSoql) DatabaseLayer.useMockSoql()?.newQuery(Account.SObjectType)?.addSelect(Account.Name);
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
		MockSoql soql = (MockSoql) DatabaseLayer.useMockSoql()?.newQuery(Account.SObjectType)?.addSelect(Account.Name);
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
		MockSoql soql = (MockSoql) DatabaseLayer.useMockSoql()?.newQuery(Account.SObjectType)?.addSelect(Account.Name);
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
		MockSoql soql = (MockSoql) DatabaseLayer.useMockSoql()?.newQuery(Account.SObjectType)?.addSelect(Account.Name);
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
		MockSoql soql = (MockSoql) DatabaseLayer.useMockSoql()?.newQuery(Account.SObjectType)?.addSelect(Account.Name);
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
		MockSoql soql = (MockSoql) DatabaseLayer.useMockSoql()
			?.newQuery(User.SObjectType)
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
			Soql.AggregateResult expectedResult = mockResults?.get(i);
			Soql.AggregateResult actualResult = results?.get(i);
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
		MockSoql soql = (MockSoql) DatabaseLayer.useMockSoql()
			?.newQuery(User.SObjectType)
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
		MockSoql soql = (MockSoql) DatabaseLayer.useMockSoql()
			?.newQuery(User.SObjectType)
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
			SampleWrapper expectedResult = mockResults?.get(i);
			SampleWrapper actualResult = results?.get(i);
			Assert.areEqual(expectedResult?.profileName, actualResult?.profileName, 'Wrong profileName');
			Assert.areEqual(expectedResult?.numRecords, actualResult?.numRecords, 'Wrong numRecords');
		}
	}

	@IsTest
	static void shouldHandleErrorsWithMockAndCast() {
		// Build an aggregate query
		Soql.Aggregation count = new Soql.Aggregation(Soql.Function.COUNT, User.Id);
		MockSoql soql = (MockSoql) DatabaseLayer.useMockSoql()
			?.newQuery(User.SObjectType)
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
	static void shouldUseCustomSimulatorMocks() {
		// Establish Dml & Soql objects to be used
		DatabaseLayer.useMocks();
		MockSoql soql = (MockSoql) DatabaseLayer.Soql.newQuery(Task.SObjectType)
			?.addSelect(Task.WhatId)
			?.addSelect(Task.WhoId);
		// Mock with a custom class that leverages MockDml.INSERTED to generate results
		soql?.setMock(new CustomTaskQueryLogic());
		// Mock insert an account + related contact
		Account mockAccount = (Account) new MockRecord(Account.SObjectType)?.toSObject();
		DatabaseLayer.Dml.doInsert(mockAccount);
		Contact mockContact = (Contact) new MockRecord(Contact.SObjectType)
			?.setField(Contact.AccountId, mockAccount?.Id)
			?.toSObject();
		DatabaseLayer.Dml.doInsert(mockContact);

		Test.startTest();
		List<Task> tasks = soql?.query();
		Test.stopTest();

		// Expecting 1 task x each inserted Contact
		Assert.areEqual(1, tasks?.size(), 'Wrong # of tasks');
		Task firstTask = tasks?.get(0);
		Assert.areEqual(mockAccount?.Id, firstTask?.WhatId, 'Wrong WhatId');
		Assert.areEqual(mockContact?.Id, firstTask?.WhoId, 'Wrong WhoId');
	}

	@IsTest
	static void shouldSetGlobalMock() {
		DatabaseLayer.useMocks();
		MockSoql theQuery = (MockSoql) DatabaseLayer.Soql.newQuery(Account.SObjectType);
		// Set a global mock - all SOQL objects will return these results by default now:
		Account mockAccount = (Account) new MockRecord(Account.SObjectType)?.withId()?.toSObject();
		MockSoql.Simulator simulator = new MockSoql.StaticResults(new List<Account>{ mockAccount });
		MockSoql.setGlobalMock(simulator);

		Test.startTest();
		List<Account> accounts = theQuery?.query();
		Test.stopTest();

		Assert.areEqual(1, accounts?.size(), 'Wrong # of Accounts returned');
		Assert.areEqual(mockAccount?.Id, accounts?.get(0)?.Id, 'Wrong Account returned');
	}

	@IsTest
	static void shouldIgnoreGlobalMockIfSpecificSimulatorAssignedToQuery() {
		DatabaseLayer.useMocks();
		MockSoql theQuery = (MockSoql) DatabaseLayer.Soql.newQuery(Account.SObjectType);
		// Set a global mock - all SOQL objects will return these results by default now:
		Account mockAccount1 = (Account) new MockRecord(Account.SObjectType)?.withId()?.toSObject();
		MockSoql.Simulator simulator = new MockSoql.StaticResults(new List<Account>{ mockAccount1 });
		MockSoql.setGlobalMock(simulator);
		// Assign a different, specific mock to the query:
		Account mockAccount2 = (Account) new MockRecord(Account.SObjectType)?.withId()?.toSObject();
		theQuery?.setMock(new MockSoql.StaticResults(new List<Account>{ mockAccount2 }));

		Test.startTest();
		List<Account> accounts = theQuery?.query();
		Test.stopTest();

		Assert.areEqual(1, accounts?.size(), 'Wrong # of Accounts returned');
		Assert.areEqual(mockAccount2?.Id, accounts?.get(0)?.Id, 'Wrong Account returned');
	}

	@IsTest
	static void shouldIntelligentlyReturnCorrectQueryResults() {
		DatabaseLayer.useMocks();
		MockSoql accountQuery = (MockSoql) DatabaseLayer.Soql.newQuery(Account.SObjectType);
		MockSoql caseQuery = (MockSoql) DatabaseLayer.Soql.newQuery(Case.SObjectType);
		MockSoql.Simulator simulator = new MockSoqlTest.DynamicSimulator();
		MockSoql.setGlobalMock(simulator);

		Test.startTest();
		List<Account> accounts = (List<Account>) accountQuery?.query();
		List<Case> cases = (List<Case>) caseQuery?.query();
		Test.stopTest();

		Assert.areEqual(1, accounts?.size(), 'Wrong # of Accounts returned');
		Assert.areEqual('Foo', accounts?.get(0)?.Name, 'Wrong Account details');
		Assert.areEqual(1, cases?.size(), 'Wrong # of Cases returned');
		Assert.areEqual('12345678', cases?.get(0)?.CaseNumber, 'Wrong Case details');
	}

	@IsTest
	static void shouldReturnEmptyListIfNoMocks() {
		// If a MockSoql is ran, and no Simulator is injected, the methods will automatically return an empty List
		MockSoql soql = (MockSoql) DatabaseLayer.useMockSoql()?.newQuery(Account.SObjectType);

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
	private class CustomTaskQueryLogic implements MockSoql.Simulator {
		public List<Object> simulateQuery(Soql queryToMock) {
			// For each inserted contact, return a Task
			List<Task> results = new List<Task>();
			List<Contact> contacts = (List<Contact>) MockDml.INSERTED.getRecords(Contact.SObjectType);
			for (Contact contact : contacts) {
				Task task = (Task) new MockRecord(Task.SObjectType)
					?.setField(Task.Subject, 'Introductory Call')
					?.setField(Task.WhatId, contact?.AccountId)
					?.setField(Task.WhoId, contact?.Id)
					?.withId()
					?.toSObject();
				results?.add(task);
			}
			return results;
		}
	}

	private class DynamicSimulator implements MockSoql.Simulator {
		// This example returns a different list of records, depending on the from entity
		// You can use this in conjunction with MockSoql.setGlobalMock to dynamically inject query results into multiple soql objects,
		// without needing to directly asssign each their own unique simulator object
		public List<Object> simulateQuery(Soql queryToMock) {
			String entity = queryToMock?.entity;
			if (entity == Account.SObjectType.toString()) {
				Account mockAccount = (Account) new MockRecord(Account.SObjectType)
					?.setField(Account.Name, 'Foo')
					?.withId()
					?.toSObject();
				return new List<Account>{ mockAccount };
			} else if (entity == Case.SObjectType.toString()) {
				Case mockCase = (Case) new MockRecord(Case.SObjectType)
					?.setField(Case.CaseNumber, '12345678')
					?.withId()
					?.toSObject();
				return new List<Case>{ mockCase };
			} else {
				return new List<SObject>();
			}
		}
	}

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
