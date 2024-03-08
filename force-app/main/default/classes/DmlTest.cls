@IsTest 
private class DmlTest {
    @IsTest 
    static void shouldInsertSingleRecord() {
        Account account = DmlTest.initAccount();

        Test.startTest();
        Database.SaveResult result = new Dml()?.doInsert(account);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'DML failed');
    }

    @IsTest 
    static void shouldInsertSingleRecordWithOptions() {
        Account account = DmlTest.initAccount();
        Dml.Options options = new Dml.Options();

        Test.startTest();
        Database.SaveResult result = new Dml()?.doInsert(account, options);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'DML failed');
    }

    @IsTest 
    static void shouldInsertMultipleRecords() {
        List<Account> accounts = DmlTest.initAccountList();

        Test.startTest();
        List<Database.SaveResult> results = new Dml()?.doInsert(accounts);
        Test.stopTest();

        Assert.areEqual(accounts?.size(), results?.size(), 'Wrong # of DML results');
        for (Database.SaveResult result : results) {
            Assert.isTrue(result?.isSuccess(), 'DML failed');
        }
    }

    @IsTest 
    static void shouldUpdateSingleRecord() {
        Account account = DmlTest.initAccount();
        insert account;

        Test.startTest();
        Database.SaveResult result = new Dml()?.doUpdate(account);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'DML failed');
    }

    @IsTest 
    static void shouldUpdateSingleRecordWithOptions() {
        Account account = DmlTest.initAccount();
        insert account;
        Dml.Options options = new Dml.Options();

        Test.startTest();
        Database.SaveResult result = new Dml()?.doUpdate(account, options);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'DML failed');
    }
    
    @IsTest 
    static void shouldUpdateMultipleRecords() {
        List<Account> accounts = DmlTest.initAccountList();
        insert accounts;

        Test.startTest();
        List<Database.SaveResult> results = new Dml()?.doUpdate(accounts);
        Test.stopTest();

        Assert.areEqual(accounts?.size(), results?.size(), 'Wrong # of DML results');
        for (Database.SaveResult result : results) {
            Assert.isTrue(result?.isSuccess(), 'DML failed');
        }
    }

    @IsTest 
    static void shouldUpsertSingleRecord() {
        Account account = DmlTest.initAccount();

        Test.startTest();
        Database.UpsertResult result = new Dml()?.doUpsert(account);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'DML failed');
    }

    @IsTest 
    static void shouldUpsertSingleRecordWithOptions() {
        Account account = DmlTest.initAccount();
        Dml.Options options = new Dml.Options();

        Test.startTest();
        Database.UpsertResult result = new Dml()?.doUpsert(account, options);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'DML failed');
    }

    @IsTest 
    static void shouldUpsertMultipleRecords() {
        List<Account> accounts = DmlTest.initAccountList();

        Test.startTest();
        List<Database.UpsertResult> results = new Dml()?.doUpsert(accounts);
        Test.stopTest();

        Assert.areEqual(accounts?.size(), results?.size(), 'Wrong # of DML results');
        for (Database.UpsertResult result : results) {
            Assert.isTrue(result?.isSuccess(), 'DML failed');
        }
    }

    @IsTest 
    static void shouldUpsertRecordWithUpsertOptions() {
        Account acc = DmlTest.initAccount();
        Dml.UpsertOptions options = new Dml.UpsertOptions();

        Test.startTest();
        Database.UpsertResult result = new Dml()?.doUpsert(acc, options);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'DML failed');
    }

    @IsTest 
    static void shouldUpsertRecordWithExternalId() {
        Account acc = DmlTest.initAccount();
        Dml.UpsertOptions options = new Dml.UpsertOptions()?.setExternalIdField(Account.Id);

        Test.startTest();
        Database.UpsertResult result = new Dml()?.doUpsert(acc, options);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'DML failed');
    }

    @IsTest 
    static void shouldDeleteSingleRecord() {
        Account account = DmlTest.initAccount();
        insert account;

        Test.startTest();
        Database.DeleteResult result = new Dml()?.doDelete(account);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'DML failed');
    }

    @IsTest 
    static void shouldDeleteSingleRecordWithOptions() {
        Account account = DmlTest.initAccount();
        insert account;
        Dml.Options options = new Dml.Options();

        Test.startTest();
        Database.DeleteResult result = new Dml()?.doDelete(account, options);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'DML failed');
    }

    @IsTest 
    static void shouldDeleteMultipleRecords() {
        List<Account> accounts = DmlTest.initAccountList();
        insert accounts;

        Test.startTest();
        List<Database.DeleteResult> results = new Dml()?.doDelete(accounts);
        Test.stopTest();

        Assert.areEqual(accounts?.size(), results?.size(), 'Wrong # of DML results');
        for (Database.DeleteResult result : results) {
            Assert.isTrue(result?.isSuccess(), 'DML failed');
        }
    }

    @IsTest 
    static void shouldUndeleteSingleRecord() {
        Account account = DmlTest.initAccount();
        insert account;
        delete account;

        Test.startTest();
        Database.UndeleteResult result = new Dml()?.doUndelete(account);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'DML failed');
    }

    @IsTest 
    static void shouldUndeleteSingleRecordWithOptions() {
        Account account = DmlTest.initAccount();
        insert account;
        delete account;
        Dml.Options options = new Dml.Options();

        Test.startTest();
        Database.UndeleteResult result = new Dml()?.doUndelete(account, options);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'DML failed');
    }

    @IsTest 
    static void shouldUndeleteMultipleRecords() {
        List<Account> accounts = DmlTest.initAccountList();
        insert accounts;
        delete accounts;

        Test.startTest();
        List<Database.UndeleteResult> results = new Dml()?.doUndelete(accounts);
        Test.stopTest();

        Assert.areEqual(accounts?.size(), results?.size(), 'Wrong # of DML results');
        for (Database.UndeleteResult result : results) {
            Assert.isTrue(result?.isSuccess(), 'DML failed');
        }
    }

    @IsTest 
    static void shouldThrowExceptionIfMissingOperation() {
        Account account = DmlTest.initAccount();

        try {
            Test.startTest();
            new Dml()?.doDml(null, account);
            Test.stopTest();
            // Not expecting to make it this far...
            Assert.fail('An Exception was not thrown');
        } catch (System.DmlException error) {
            Assert.isTrue(error?.getMessage()?.startsWith('Unsupported'), 'Wrong error message');
        }
    }

    @IsTest 
    static void shouldGetAndSetAccessLevel() {
        System.AccessLevel level = System.AccessLevel.SYSTEM_MODE;

        Test.startTest();
        System.AccessLevel result = new Dml.Options()?.setAccessLevel(level)?.getAccessLevel();
        Test.stopTest();

        Assert.areEqual(level, result, 'Did not set Level');
    }

    @IsTest 
    static void shouldGetAndSetAllOrNone() {
        Boolean allOrNone = false;

        Test.startTest();
        Boolean result = new Dml.Options()?.setAllOrNone(allOrNone)?.getAllOrNone();
        Test.stopTest();

        Assert.areEqual(allOrNone, result, 'Did not set AllOrNone');
    }

    @IsTest 
    static void shouldGetAndSetDmlOptions() {
        Database.DmlOptions options = new Database.DmlOptions();
        options.AllowFieldTruncation = true;

        Test.startTest();
        Database.DmlOptions result = new Dml.Options().setDmlOptions(options)?.getDmlOptions();
        Test.stopTest();

        Assert.areEqual(options?.AllowFieldTruncation, result?.AllowFieldTruncation, 'Did not set DmlOptions');
    }

    @IsTest 
    static void shouldSetAssignmentRuleHeader() {
        Database.DmlOptions.AssignmentRuleHeader header = new Database.DmlOptions.AssignmentRuleHeader();
        header.useDefaultRule = false;

        Test.startTest();
        Dml.Options options = new Dml.Options()?.setAssignmentRuleHeader(header);
        Test.stopTest();

        Assert.areEqual(
            header?.UseDefaultRule, 
            options?.getDmlOptions()?.AssignmentRuleHeader?.UseDefaultRule, 
            'Did not set AssignmentRuleHeader'
        );
    }

    @IsTest 
    static void shouldSetEmailHeader() {
        Database.DmlOptions.EmailHeader header = new Database.DmlOptions.EmailHeader();
        header.TriggerAutoResponseEmail = true; 

        Test.startTest();
        Dml.Options options = new Dml.Options()?.setEmailHeader(header);
        Test.stopTest();

        Assert.areEqual(
            header?.TriggerAutoResponseEmail, 
            options?.getDmlOptions()?.EmailHeader?.TriggerAutoResponseEmail, 
            'Did not set EmailHeader'
        );
    }

    @IsTest 
    static void shouldSetFieldTruncation() {
        Boolean value = true; 

        Test.startTest();
        Dml.Options options = new Dml.Options()?.setFieldTruncation(value);
        Test.stopTest();

        Assert.areEqual(value, options?.getDmlOptions()?.AllowFieldTruncation, 'Wrong AllowFieldTruncation');
    }

    @IsTest 
    static void shouldSetLocaleOptions() {
        String value = 'en_GB';

        Test.startTest();
        Dml.Options options = new Dml.Options()?.setLocaleOptions(value);
        Test.stopTest();

        Assert.areEqual(value, options?.getDmlOptions()?.LocaleOptions, 'Wrong LocaleOptions');
    }

    // **** HELPER **** //
    static final Integer TEST_SIZE = 2;

    static Account initAccount() {
        return new Account(Name = 'Robinson Industries');
    }

    static List<Account> initAccountList() {
        Account account = DmlTest.initAccount();
        return new List<Account>{ account };
    }
}