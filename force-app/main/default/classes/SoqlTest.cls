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
    // * OPERATORS
    @IsTest 
    static void shouldOutputExactMatchString() {
        Soql.Operator operator = Soql.EQUALS;
        String value = 'foo';

        Test.startTest();
        String result = operator?.processStringValue(value);
        Test.stopTest();

        Assert.areEqual('\'' + value + '\'', result, 'Wrong string value');
    }
   
    @IsTest 
    static void shouldOuptutStartsWithString() {
        Soql.Operator operator = Soql.STARTS_WITH;
        String value = 'foo';

        Test.startTest();
        String result = operator?.processStringValue(value);
        Test.stopTest();

        Assert.areEqual('\'' + value + '%\'', result, 'Wrong string value');
    }

    @IsTest 
    static void shouldOuptutEndsWithString() {
        Soql.Operator operator = Soql.ENDS_WITH;
        String value = 'foo';

        Test.startTest();
        String result = operator?.processStringValue(value);
        Test.stopTest();

        Assert.areEqual('\'%' + value + '\'', result, 'Wrong string value');
    }

    @IsTest 
    static void shouldOuptutContainsString() {
        Soql.Operator operator = Soql.CONTAINS;
        String value = 'foo';

        Test.startTest();
        String result = operator?.processStringValue(value);
        Test.stopTest();

        Assert.areEqual('\'%' + value + '%\'', result, 'Wrong string value');
    }

    // * AGGREGATION
    @IsTest 
    static void shouldCreateAggregateClause() {
        String value = new Soql.Aggregation(Soql.AggregateFunction.COUNT, Account.Id)?.toString();
        Assert.areEqual('COUNT(Id)', value, 'Wrong toString() value');
    }

    @IsTest 
    static void shouldCreateAggregateClauseWithAlias() {
        String value = new Soql.Aggregation(Soql.AggregateFunction.COUNT, Account.Id)?.withAlias('num')?.toString();
        Assert.areEqual('COUNT(Id) num', value, 'Wrong toString() value');
    }

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
    static void shouldCreateEmptyBinder() {
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