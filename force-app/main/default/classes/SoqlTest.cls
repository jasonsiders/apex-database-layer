@IsTest 
private class SoqlTest {
    // * MAIN METHODS
    // * BUILDER
    // * INNER QUERY
    // * SUBQUERY
    // * WITH CLAUSE
    // * AGGREGATE CONDITION
    // * CONDITIONAL LOGIC
    // * CONDITION
    // * OPERATOR
    // * OPERATOR SUBTYPES
    // * AGGREGATION
    // * BINDER
    @IsTest 
    static void shouldCreateBinderObject() {
        String key = 'ownerIds';
        List<Id> ownerIds = new List<Id>{ UserInfo.getUserId() };

        Test.startTest(); 
        Soql.Binder binder = new Soql.Binder(key, ownerIds);
        Test.stopTest();

        Assert.areEqual(key, binder?.getKey(), 'Wrong key');
        Assert.areEqual(':' + key, binder?.toString(), 'Wrong toString() value');
        Assert.areEqual(1, binder?.getValues()?.size(), 'Wrong # of values'); 
    }

    @IsTest 
    static void shouldCreateEmtpyBinder() {
        String key = 'ownerIds';

        Test.startTest();
        Soql.Binder binder = new Soql.Binder(key);
        Test.stopTest();

        Assert.areEqual(key, binder?.getKey(), 'Wrong key'); 
        Assert.areEqual(':' + key, binder?.toString(), 'Wrong toString() value'); 
        Assert.areEqual(0, binder?.getValues()?.size(), 'Wrong # of values');
    }

    // * ORDER BY CLAUSE
    @IsTest 
    static void shouldOrderByField() {
        String value = new Soql.OrderBy(Account.CreatedDate, Soql.SortOrder.ASCENDING)?.toString();
        Assert.areEqual('CreatedDate ASC NULLS LAST', value, 'Wrong value');
    }
    
    @IsTest 
    static void shouldSpecifyNullOrder() {
        String value = new Soql.OrderBy(Account.CreatedDate, Soql.SortOrder.DESCENDING)
            ?.setNullOrder(Soql.NullOrder.NULLS_FIRST)
            ?.toString();
        Assert.areEqual('CreatedDate DESC NULLS FIRST', value, 'Wrong value');
    }
}