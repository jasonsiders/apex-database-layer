@IsTest 
private class MockSoqlTest {
    @IsTest 
    static void shouldMockCountQuery() {
        List<Account> accounts = MockSoqlTest.initAccounts(NUM_ACCS);
        Soql.Aggregation count = new Soql.Aggregation(Soql.Function.COUNT);
        MockSoql soql = (MockSoql) new MockSoql(Account.SObjectType)?.addSelect(count);
        soql?.injectResults(accounts);

        Test.startTest();
        Integer results = soql?.countQuery();
        Test.stopTest();

        Assert.areEqual(NUM_ACCS, results, 'Wrong # of Accounts returned');
    }

    @IsTest 
    static void shouldMockCountQueryErrors() {
        List<Account> accounts = MockSoqlTest.initAccounts(NUM_ACCS);
        MockSoql soql = (MockSoql) new MockSoql(Account.SObjectType)?.addSelect(Account.Name);
        soql?.injectError();

        Test.startTest();
        try {
            soql?.countQuery();
            Assert.fail('The injected exception was not thrown');
        } catch (System.QueryException error) {
            // As expected
        }
        Test.stopTest();
    }

    @IsTest 
    static void shouldMockQueryLocator() {
        List<Account> accounts = MockSoqlTest.initAccounts(NUM_ACCS);
        MockSoql soql = (MockSoql) new MockSoql(Account.SObjectType)?.addSelect(Account.Name);
        soql?.injectResults(accounts);
        
        Test.startTest();
        Soql.QueryLocator locator = soql?.getQueryLocator();
        Test.stopTest();

        Assert.areEqual(soql?.toString(), locator?.getQuery(), 'Wrong query returned');
        System.Iterator<SObject> iterator = locator?.iterator();
        for (Integer i = 0; i < NUM_ACCS; i++) {
            if (i == NUM_ACCS) {
                Assert.isFalse(iterator?.hasNext(), i + '/' + NUM_ACCS + ': Iterator should not hasNext()');
            } else {
                Assert.isTrue(iterator?.hasNext(), i + '/' + NUM_ACCS + ': Iterator should hasNext()');
                Account account = (Account) iterator?.next();
                Assert.isNotNull(account, i + '/' + NUM_ACCS + ': Iterator returned null record');
            }
        }
    }

    @IsTest 
    static void shouldMockQueryLocatorErrors() {
        List<Account> accounts = MockSoqlTest.initAccounts(NUM_ACCS);
        MockSoql soql = (MockSoql) new MockSoql(Account.SObjectType)?.addSelect(Account.Name);
        soql?.injectError();

        Test.startTest();
        try {
            soql?.getQueryLocator();
            Assert.fail('The injected exception was not thrown');
        } catch (System.QueryException error) {
            // As expected
        }
        Test.stopTest();
    }

    @IsTest 
    static void shouldMockQuery() {
        List<Account> accounts = MockSoqlTest.initAccounts(NUM_ACCS);
        MockSoql soql = (MockSoql) new MockSoql(Account.SObjectType)?.addSelect(Account.Name);
        soql?.injectResults(accounts);

        Test.startTest();
        List<Account> results = soql?.query();
        Test.stopTest();

        Assert.areEqual(accounts, results, 'Did not return the injected accounts');
    }

    @IsTest 
    static void shouldMockQueryErrors() {
        List<Account> accounts = MockSoqlTest.initAccounts(NUM_ACCS);
        MockSoql soql = (MockSoql) new MockSoql(Account.SObjectType)?.addSelect(Account.Name);
        soql?.injectError();

        Test.startTest();
        try {
            soql?.query();
            Assert.fail('The injected exception was not thrown');
        } catch (System.QueryException error) {
            // As expected
        }
        Test.stopTest();
    }

    @IsTest 
    static void shouldMockAggregateQuery() {
        Assert.fail('You still need to build this test'); 
    }

    @IsTest 
    static void shouldMockAggregateQueryAndCastToType() {
        Assert.fail('You still need to build this test'); 
    }

    // **** HELPER **** // 
    static final Integer NUM_ACCS = 10; 

    static List<Account> initAccounts(Integer numAccounts) {
        List<Account> accounts = new List<Account>(); 
        for (Integer i = 0; i < numAccounts; i++) {
            String name = 'Test Account #' + (i + 1);
            Account account = new Account(Name = name);
            accounts?.add(account);
        }
        return accounts;
    }
}