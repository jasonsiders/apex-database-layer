@IsTest 
private class DmlTest {
    @IsTest 
    static void shouldDoInsert() {
        Account account = DmlTest.initAccount();

        Test.startTest();
        Database.SaveResult result = new Dml()?.doInsert(account);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'DML failed');
    }

    @IsTest 
    static void shouldDoUpdate() {
        Account account = DmlTest.initAccount();
        insert account;

        Test.startTest();
        Database.SaveResult result = new Dml()?.doUpdate(account);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'DML failed');
    }

    @IsTest 
    static void shouldDoUpsert() {
        Account account = DmlTest.initAccount();

        Test.startTest();
        Database.UpsertResult result = new Dml()?.doUpsert(account);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'DML failed');
    }

    @IsTest 
    static void shouldDoUpsertWithExternalIdField() {
        Account acc = DmlTest.initAccount();
        SObjectField field = Account.Id;
        

        Test.startTest();
        Dml dml = new Dml()?.setExternalIdField(field);
        Database.UpsertResult result = dml?.doUpsert(acc);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'DML failed');
        Assert.areEqual(field, dml?.getExternalIdField(), 'Did not upsert by ' + field);
    }

    @IsTest 
    static void shouldDoDelete() {
        Account account = DmlTest.initAccount();
        insert account;

        Test.startTest();
        Database.DeleteResult result = new Dml()?.doDelete(account);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'DML failed');
    }

    @IsTest 
    static void shouldDoUndelete() {
        Account account = DmlTest.initAccount();
        insert account;
        delete account;

        Test.startTest();
        Database.UndeleteResult result = new Dml()?.doUndelete(account);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'DML failed');
    }

    @IsTest 
    static void shouldDoDynamicDml() {
        // The doDml() method allows for callers to dynamically specify the type of operation taking place
        Account account = DmlTest.initAccount();
        Dml myDml = new Dml()?.setAllOrNone(false);

        Test.startTest();
        Database.SaveResult insertResult = (Database.SaveResult) myDml?.doDml(Dml.Operation.DO_INSERT, account);
        Assert.isTrue(insertResult?.isSuccess(), 'Insert failed: ' + insertResult?.getErrors());
        Database.SaveResult updateResult = (Database.SaveResult) myDml?.doDml(Dml.Operation.DO_UPDATE, account);
        Assert.isTrue(updateResult?.isSuccess(), 'Update failed: ' + updateResult?.getErrors());
        Database.UpsertResult upsertResult = (Database.UpsertResult) myDml?.doDml(Dml.Operation.DO_UPSERT, account);
        Assert.isTrue(upsertResult?.isSuccess(), 'Upsert failed: ' + upsertResult?.getErrors());
        Database.DeleteResult deleteResult = (Database.DeleteResult) myDml?.doDml(Dml.Operation.DO_DELETE, account);
        Assert.isTrue(deleteResult?.isSuccess(), 'Delete failed: ' + deleteResult?.getErrors());
        Database.UndeleteResult undeleteResult = (Database.UndeleteResult) myDml?.doDml(Dml.Operation.DO_UNDELETE, account);
        Assert.isTrue(undeleteResult?.isSuccess(), 'Undelete failed: ' + undeleteResult?.getErrors());
        Test.stopTest();
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