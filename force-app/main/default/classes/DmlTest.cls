@IsTest 
private class DmlTest {
    @IsTest 
    static void shouldDoInsert() {
        Account account = DmlTest.initAccount();

        Test.startTest();
        Database.SaveResult result = new Dml()?.doInsert(account);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'DML failed: ' + result?.getErrors());
    }

    @IsTest 
    static void shouldDoInsertAsync() {
        Account account = DmlTest.initAccount();

        Test.startTest();
        Database.SaveResult result = new Dml()?.doInsertAsync(account);
        Test.stopTest();

        // Note: This should fail, since Account isn't an external object.
        // This doesn't seem to happen for updateAsync() or deleteAsync() - not sure why.
        Assert.isFalse(result?.isSuccess(), 'insertAsync() succeeded on non-external object');
        Database.Error error = result?.getErrors()[0] ?? null;
        System.StatusCode expected = System.StatusCode.CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY;
        Assert.areEqual(expected, error?.getStatusCode(), 'Wrong Error Code');
    }

    @IsTest 
    static void shouldDoInsertImmediate() {
        Account account = DmlTest.initAccount();

        Test.startTest();
        Database.SaveResult result = new Dml()?.doInsertImmediate(account);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'DML failed: ' + result?.getErrors());
    }

    @IsTest 
    static void shouldDoUpdate() {
        Account account = DmlTest.initAccount();
        insert account;

        Test.startTest();
        Database.SaveResult result = new Dml()?.doUpdate(account);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'DML failed: ' + result?.getErrors());
    }

    @IsTest 
    static void shouldDoUpdateAsync() {
        Account account = DmlTest.initAccount();
        insert account;

        Test.startTest();
        Database.SaveResult result = new Dml()?.doUpdateAsync(account);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'DML failed: ' + result?.getErrors());
    }

    @IsTest 
    static void shouldDoUpdateImmediate() {
        Account account = DmlTest.initAccount();
        insert account;

        Test.startTest();
        Database.SaveResult result = new Dml()?.doUpdateImmediate(account);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'DML failed: ' + result?.getErrors());
    }

    @IsTest 
    static void shouldDoUpsert() {
        Account account = DmlTest.initAccount();

        Test.startTest();
        Database.UpsertResult result = new Dml()?.doUpsert(account);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'DML failed: ' + result?.getErrors());
    }

    @IsTest 
    static void shouldDoUpsertWithExternalIdField() {
        Account acc = DmlTest.initAccount();
        SObjectField field = Account.Id;

        Test.startTest();
        Dml dml = new Dml()?.setExternalIdField(field);
        Database.UpsertResult result = dml?.doUpsert(acc);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'DML failed: ' + result?.getErrors());
        Assert.areEqual(field, dml?.getExternalIdField(), 'Did not upsert by ' + field);
    }

    @IsTest 
    static void shouldDoDelete() {
        Account account = DmlTest.initAccount();
        insert account;

        Test.startTest();
        Database.DeleteResult result = new Dml()?.doDelete(account);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'DML failed: ' + result?.getErrors());
    }

    @IsTest 
    static void shouldDoDeleteAsync() {
        Account account = DmlTest.initAccount();
        insert account;

        Test.startTest();
        Database.DeleteResult result = new Dml()?.doDeleteAsync(account);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'DML failed: ' + result?.getErrors());
    }

    @IsTest 
    static void shouldDoDeleteImmediate() {
        Account account = DmlTest.initAccount();
        insert account;

        Test.startTest();
        Database.DeleteResult result = new Dml()?.doDeleteImmediate(account);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'DML failed: ' + result?.getErrors());
    }

    @IsTest 
    static void shouldDoHardDelete() {
        Account account = DmlTest.initAccount();
        insert account;

        Test.startTest();
        Database.DeleteResult result = new Dml()?.doHardDelete(account);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'DML failed: ' + result?.getErrors());
    }

    @IsTest 
    static void shouldDoUndelete() {
        Account account = DmlTest.initAccount();
        insert account;
        delete account;

        Test.startTest();
        Database.UndeleteResult result = new Dml()?.doUndelete(account);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'DML failed: ' + result?.getErrors());
    }

    @IsTest 
    static void shouldDoConvert() {
        Lead lead = DmlTest.initLead();
        insert lead; 
        LeadStatus status = [SELECT ApiName FROM LeadStatus WHERE IsConverted = true LIMIT 1];
        Database.LeadConvert leadToConvert = new Database.LeadConvert();
        leadToConvert?.setLeadId(lead?.Id);
        leadToConvert?.setConvertedStatus(status?.ApiName);

        Test.startTest();
        Database.LeadConvertResult result = new Dml()?.doConvert(leadToConvert);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'Did not succeed: ' + result?.getErrors());
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
        
        Test.startTest();
        try {
            new Dml()?.doDml(null, account);
            Assert.fail('An Exception was not thrown');
        } catch (System.DmlException error) {
            Assert.isTrue(error?.getMessage()?.startsWith('Unsupported'), 'Wrong error message');
        }
        Test.stopTest();
    }

    @IsTest 
    static void shouldSetCustomDeleteCallback() {
        // When updating external objects via the *async() methods, 
        // you can specify a custom callback class that will run when the Dml finishes processing
        // By defualt, the Dml class runs a dummy/no-op class, but callers can specify their own logic
        Test.startTest();
        Dml dml = new Dml()?.setCallback(new TestDeleteCallback()); 
        Test.stopTest();

        Assert.isInstanceOfType(dml?.getDeleteCallback(), TestDeleteCallback.class, 'Did not set custom callback'); 
        // The Save Callback shouldn't be affected by this
        Assert.isInstanceOfType(dml?.getSaveCallback(), Dml.DefaultSaveCallback.class, 'Save Callback was overwritten');
    }

    @IsTest 
    static void shouldSetCustomSaveCallback() {
        // When updating external objects via the *async() methods, 
        // you can specify a custom callback class that will run when the Dml finishes processing
        // By defualt, the Dml class runs a dummy/no-op class, but callers can specify their own logic
        Test.startTest();
        Dml dml = new Dml()?.setCallback(new TestSaveCallback()); 
        Test.stopTest();

        Assert.isInstanceOfType(dml?.getSaveCallback(), TestSaveCallback.class, 'Did not set custom callback'); 
        // The Delete Callback shouldn't be affected by this
        Assert.isInstanceOfType(dml?.getDeleteCallback(), Dml.DefaultDeleteCallback.class, 'Delete Callback was overwritten');
    }

    // **** HELPER **** //
    static final Integer TEST_SIZE = 2;
    static List<Database.DeleteResult> deleteCallbacksMade = new List<Database.DeleteResult>();
    static List<Database.SaveResult> saveCallbacksMade = new List<Database.SaveResult>();

    static Account initAccount() {
        return new Account(Name = 'Robinson Industries');
    }

    static List<Account> initAccountList() {
        Account account = DmlTest.initAccount();
        return new List<Account>{ account };
    }

    static Lead initLead() {
        return new Lead(
            Company = 'Tharsis Inc.',
            FirstName = 'John',
            LastName = 'Doe'
        );
    }

    private class TestDeleteCallback extends DataSource.AsyncDeleteCallback {
        public override void processDelete(Database.DeleteResult result) {
            DmlTest.deleteCallbacksMade?.add(result);
        }
    }

    private class TestSaveCallback extends DataSource.AsyncSaveCallback {
        public override void processSave(Database.SaveResult result) {
            DmlTest.saveCallbacksMade?.add(result);
        }
    }
}