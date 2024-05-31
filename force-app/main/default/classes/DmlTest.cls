@IsTest 
private class DmlTest {
    @IsTest 
    static void shouldDoInsert() {
        Account account = DmlTest.initAccount();

        Test.startTest();
        Database.SaveResult result = DatabaseLayer.get()?.initDml()?.doInsert(account);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'DML failed: ' + result?.getErrors());
    }

    @IsTest 
    static void shouldDoInsertAsync() {
        Account account = DmlTest.initAccount();

        Test.startTest();
        Database.SaveResult result = DatabaseLayer.get()?.initDml()?.doInsertAsync(account);
        Test.stopTest();

        // Note: This should fail, since Account isn't an external object.
        // This doesn't seem to happen for updateAsync() or deleteAsync() - not sure why.
        // Without defining a custom external object, not possible to test the happy path for this
        Assert.isFalse(result?.isSuccess(), 'InsertAsync succeeded on non-external object');
        Database.Error error = result?.getErrors()[0] ?? null;
        System.StatusCode expected = System.StatusCode.CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY;
        Assert.areEqual(expected, error?.getStatusCode(), 'Wrong Error Code');
    }

    @IsTest 
    static void shouldDoInsertImmediate() {
        Account account = DmlTest.initAccount();

        Test.startTest();
        Database.SaveResult result = DatabaseLayer.get()?.initDml()?.doInsertImmediate(account);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'DML failed: ' + result?.getErrors());
    }

    @IsTest 
    static void shouldDoUpdate() {
        Account account = DmlTest.initAccount();
        insert account;

        Test.startTest();
        Database.SaveResult result = DatabaseLayer.get()?.initDml()?.doUpdate(account);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'DML failed: ' + result?.getErrors());
    }

    @IsTest 
    static void shouldDoUpdateAsync() {
        Account account = DmlTest.initAccount();
        insert account;

        Test.startTest();
        Database.SaveResult result = DatabaseLayer.get()?.initDml()?.doUpdateAsync(account);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'DML failed: ' + result?.getErrors());
    }

    @IsTest 
    static void shouldDoUpdateImmediate() {
        Account account = DmlTest.initAccount();
        insert account;

        Test.startTest();
        Database.SaveResult result = DatabaseLayer.get()?.initDml()?.doUpdateImmediate(account);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'DML failed: ' + result?.getErrors());
    }

    @IsTest 
    static void shouldDoUpsert() {
        Account account = DmlTest.initAccount();

        Test.startTest();
        Database.UpsertResult result = DatabaseLayer.get()?.initDml()?.doUpsert(account);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'DML failed: ' + result?.getErrors());
    }

    @IsTest 
    static void shouldDoUpsertWithExternalIdField() {
        Account acc = DmlTest.initAccount();
        SObjectField field = Account.Id;

        Test.startTest();
        Dml dml = DatabaseLayer.get()?.initDml()?.setExternalIdField(field);
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
        Database.DeleteResult result = DatabaseLayer.get()?.initDml()?.doDelete(account);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'DML failed: ' + result?.getErrors());
    }

    @IsTest 
    static void shouldDoDeleteAsync() {
        Account account = DmlTest.initAccount();
        insert account;

        Test.startTest();
        Database.DeleteResult result = DatabaseLayer.get()?.initDml()?.doDeleteAsync(account);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'DML failed: ' + result?.getErrors());
    }

    @IsTest 
    static void shouldDoDeleteImmediate() {
        Account account = DmlTest.initAccount();
        insert account;

        Test.startTest();
        Database.DeleteResult result = DatabaseLayer.get()?.initDml()?.doDeleteImmediate(account);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'DML failed: ' + result?.getErrors());
    }

    @IsTest 
    static void shouldDoHardDelete() {
        Account account = DmlTest.initAccount();
        insert account;

        Test.startTest();
        Database.DeleteResult result = DatabaseLayer.get()?.initDml()?.doHardDelete(account);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'DML failed: ' + result?.getErrors());
    }

    @IsTest 
    static void shouldDoUndelete() {
        Account account = DmlTest.initAccount();
        insert account;
        delete account;

        Test.startTest();
        Database.UndeleteResult result = DatabaseLayer.get()?.initDml()?.doUndelete(account);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'DML failed: ' + result?.getErrors());
    }

    @IsTest 
    static void shouldDoPublish() {
        BatchApexErrorEvent event = new BatchApexErrorEvent(); 

        Test.startTest();
        Database.SaveResult result = DatabaseLayer.get()?.initDml()?.doPublish(event); 
        Test.stopTest();

        // Note: Standard platform events that are available in all Salesforce orgs
        // (like BatchApexErrorEvent) can't be inserted by users; rather, generated by the system.
        // Without defining a custom platform event, not possible to test the happy path for this
        Assert.isFalse(result?.isSuccess(), 'Publish succeeded on standard platform event');
        Database.Error error = result?.getErrors()[0] ?? null;
        System.StatusCode expected = System.StatusCode.CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY;
        Assert.areEqual(expected, error?.getStatusCode(), 'Wrong Error Code');
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
        Database.LeadConvertResult result = DatabaseLayer.get()?.initDml()?.doConvert(leadToConvert);
        Test.stopTest();

        Assert.isTrue(result?.isSuccess(), 'Did not succeed: ' + result?.getErrors());
    }

    @IsTest 
    static void shouldDoDynamicDml() {
        // The doDml() method allows for callers to dynamically specify the type of operation taking place
        Account account1 = DmlTest.initAccount();
        Account account2 = DmlTest.initAccount();
        Account account3 = DmlTest.initAccount();
        BatchApexErrorEvent event = new BatchApexErrorEvent(); 
        Dml myDml = DatabaseLayer.get()?.initDml()?.setAllOrNone(false);

        Test.startTest();
        // * Insert Methods
        Database.SaveResult insertResult = (Database.SaveResult) myDml?.doDml(Dml.Operation.DO_INSERT, account1);
        Assert.isTrue(insertResult?.isSuccess(), 'Insert failed: ' + insertResult?.getErrors());
        Database.SaveResult insertAsyncResult = (Database.SaveResult) myDml?.doDml(Dml.Operation.DO_INSERT_ASYNC, account2);
        // Note: insertAsync() not allowed on non-external objects
        Assert.isFalse(insertAsyncResult?.isSuccess(), 'Async Insert succeeded for a non-external object');
        Database.SaveResult insertImmediateResult = (Database.SaveResult) myDml?.doDml(Dml.Operation.DO_INSERT_IMMEDIATE, account3);
        Assert.isTrue(insertImmediateResult?.isSuccess(), 'Immediate Insert failed: ' + insertImmediateResult?.getErrors());
        // * Update Methods
        Database.SaveResult updateResult = (Database.SaveResult) myDml?.doDml(Dml.Operation.DO_UPDATE, account1);
        Assert.isTrue(updateResult?.isSuccess(), 'Update failed: ' + updateResult?.getErrors());
        Database.SaveResult updateAsyncResult = (Database.SaveResult) myDml?.doDml(Dml.Operation.DO_UPDATE_ASYNC, account1);
        Assert.isTrue(updateAsyncResult?.isSuccess(), 'Async Update failed: ' + updateAsyncResult?.getErrors());
        Database.SaveResult updateImmediateResult = (Database.SaveResult) myDml?.doDml(Dml.Operation.DO_UPDATE_IMMEDIATE, account1);
        Assert.isTrue(updateImmediateResult?.isSuccess(), 'Immediate Update failed: ' + updateImmediateResult?.getErrors());
        // * Upsert Methods
        Database.UpsertResult upsertResult = (Database.UpsertResult) myDml?.doDml(Dml.Operation.DO_UPSERT, account1);
        Assert.isTrue(upsertResult?.isSuccess(), 'Upsert failed: ' + upsertResult?.getErrors());
        // Note: Before testing delete/undelete methods, ensure all records are inserted
        upsert new List<Account>{ account1, account2, account3 };
        // * Delete/Undelete Methods
        Database.DeleteResult deleteResult = (Database.DeleteResult) myDml?.doDml(Dml.Operation.DO_DELETE, account1);
        Assert.isTrue(deleteResult?.isSuccess(), 'Delete failed: ' + deleteResult?.getErrors());
        Database.DeleteResult deleteAsyncResult = (Database.DeleteResult) myDml?.doDml(Dml.Operation.DO_DELETE_ASYNC, account2); 
        Assert.isTrue(deleteAsyncResult?.isSuccess(), 'Async Delete failed: ' + deleteAsyncResult?.getErrors());
        Database.DeleteResult deleteImmediateResult = (Database.DeleteResult) myDml?.doDml(Dml.Operation.DO_DELETE_IMMEDIATE, account3); 
        Assert.isTrue(deleteImmediateResult?.isSuccess(), 'Immediate Delete failed: ' + deleteImmediateResult?.getErrors());
        Database.UndeleteResult undeleteResult = (Database.UndeleteResult) myDml?.doDml(Dml.Operation.DO_UNDELETE, account1);
        Assert.isTrue(undeleteResult?.isSuccess(), 'Undelete failed: ' + undeleteResult?.getErrors());
        Database.DeleteResult hardDeleteResult = (Database.DeleteResult) myDml?.doDml(Dml.Operation.DO_HARD_DELETE, account1);
        Assert.isTrue(hardDeleteResult?.isSuccess(), 'Hard Delete failed: ' + hardDeleteResult?.getErrors());
        // * Publish Methods
        // Note: EventBus.publish() not allowed on standard platform events
        Database.SaveResult publishResult = (Database.SaveResult) myDml?.doDml(Dml.Operation.DO_PUBLISH, event);
        Assert.isFalse(publishResult?.isSuccess(), 'Publish succeeded for a standard platform event');
        Test.stopTest();
    }

    @IsTest 
    static void shouldThrowExceptionIfInvalidOperation() {
        Account account = DmlTest.initAccount();
        
        Test.startTest();
        try {
            DatabaseLayer.get()?.initDml()?.doDml(null, account);
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
        DataSource.AsyncDeleteCallback callback = new TestDeleteCallback();

        Test.startTest();
        Dml dml = DatabaseLayer.get()?.initDml()?.setCallback(callback); 
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
        DataSource.AsyncSaveCallback callback = new TestSaveCallback();

        Test.startTest();
        Dml dml = DatabaseLayer.get()?.initDml()?.setCallback(callback); 
        Test.stopTest();

        Assert.isInstanceOfType(dml?.getSaveCallback(), TestSaveCallback.class, 'Did not set custom callback'); 
        // The Delete Callback shouldn't be affected by this
        Assert.isInstanceOfType(dml?.getDeleteCallback(), Dml.DefaultDeleteCallback.class, 'Delete Callback was overwritten');
    }

    @IsTest 
    static void shouldRunDefaultCallbacksWithoutError() {
        // Note: The DataSource.Async*Callback objects are not invoked when running the async DML methods in @IsTest context
        // Ensure the default implementations of these objects can be invoked w/out error
        Test.startTest();
        try {
            new Dml.DefaultDeleteCallback()?.processDelete(null);
            new Dml.DefaultSaveCallback()?.processSave(null);
        } catch (Exception error) {
            Assert.fail('An error was thrown: ' + error);
        }
        Test.stopTest();
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