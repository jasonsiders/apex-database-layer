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
    @IsTest 
    static void shouldOutputBooleanCondition() {
        Object value = true;
        Soql.Condition condition = new Soql.Condition(Account.Id, Soql.EQUALS, value);

        Test.startTest();
        String result = condition?.toString();
        Test.stopTest();

        String expected = 'Id = true';
        Assert.areEqual(expected, result, 'Unexpected condition output');
    }

    @IsTest 
    static void shouldOutputBooleanListCondition() {
        Object value = new List<Boolean>{ true, false };
        Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

        Test.startTest();
        String result = condition?.toString();
        Test.stopTest();

        String expected = 'Id IN (true, false)';
        Assert.areEqual(expected, result, 'Unexpected condition output');
    }

    @IsTest 
    static void shouldOutputBooleanSetCondition() {
        Object value = new Set<Boolean>{ true, false };
        Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

        Test.startTest();
        String result = condition?.toString();
        Test.stopTest();

        String expected = 'Id IN (true, false)';
        Assert.areEqual(expected, result, 'Unexpected condition output');
    }

    @IsTest 
    static void shouldOutputDateCondition() {
        Object value = Date.newInstance(2024, 03, 15);
        Soql.Condition condition = new Soql.Condition(Account.Id, Soql.EQUALS, value);

        Test.startTest();
        String result = condition?.toString();
        Test.stopTest();

        String expected = 'Id = 2024-03-15';
        Assert.areEqual(expected, result, 'Unexpected condition output');
    }

    @IsTest 
    static void shouldOutputDateListCondition() {
        Object value = new List<Date>{
            Date.newInstance(2024, 03, 15),
            Date.newInstance(2024, 04, 15)
        };
        Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

        Test.startTest();
        String result = condition?.toString();
        Test.stopTest();

        String expected = 'Id IN (2024-03-15, 2024-04-15)';
        Assert.areEqual(expected, result, 'Unexpected condition output');
    }

    @IsTest 
    static void shouldOutputDateSetCondition() {
        Object value = new Set<Date>{
            Date.newInstance(2024, 03, 15),
            Date.newInstance(2024, 04, 15)
        };
        Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

        Test.startTest();
        String result = condition?.toString();
        Test.stopTest();

        String expected = 'Id IN (2024-03-15, 2024-04-15)';
        Assert.areEqual(expected, result, 'Unexpected condition output');
    }

    @IsTest 
    static void shouldOutputDateTimeCondition() {
        DateTime now = DateTime.now();
        Object value = now;
        Soql.Condition condition = new Soql.Condition(Account.Id, Soql.EQUALS, value);

        Test.startTest();
        String result = condition?.toString();
        Test.stopTest();

        String dtFormat = 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'';
        String expected = 'Id = ' + now?.formatGmt(dtFormat);
        Assert.areEqual(expected, result, 'Unexpected condition output');
    }

    @IsTest 
    static void shouldOutputDateTimeListCondition() {
        DateTime dt1 = DateTime.now();
        DateTime dt2 = DateTime.now()?.addDays(30);
        Object value = new List<DateTime>{ dt1, dt2 };
        Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

        Test.startTest();
        String result = condition?.toString();
        Test.stopTest();

        String dtFormat = 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'';
        List<String> dtStrings = new List<String>{ dt1?.formatGmt(dtFormat), dt2?.formatGmt(dtFormat) };
        String expected = 'Id IN (' + String.join(dtStrings, ', ') + ')';
        Assert.areEqual(expected, result, 'Unexpected condition output');
    }

    @IsTest 
    static void shouldOutputDateTimeSetCondition() {
        DateTime dt1 = DateTime.now();
        DateTime dt2 = DateTime.now()?.addDays(30);
        Object value = new Set<DateTime>{ dt1, dt2 };
        Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

        Test.startTest();
        String result = condition?.toString();
        Test.stopTest();

        String dtFormat = 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'';
        List<String> dtStrings = new List<String>{ dt1?.formatGmt(dtFormat), dt2?.formatGmt(dtFormat) };
        String expected = 'Id IN (' + String.join(dtStrings, ', ') + ')';
        Assert.areEqual(expected, result, 'Unexpected condition output');
    }

    @IsTest 
    static void shouldOutputDecimalCondition() {
        Object value = 123.45;
        Soql.Condition condition = new Soql.Condition(Account.Id, Soql.EQUALS, value);

        Test.startTest();
        String result = condition?.toString();
        Test.stopTest();

        String expected = 'Id = 123.45';
        Assert.areEqual(expected, result, 'Unexpected condition output');
    }

    @IsTest 
    static void shouldOutputDecimalListCondition() {
        Object value = new List<Decimal>{ 123.45, 987.65 };
        Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

        Test.startTest();
        String result = condition?.toString();
        Test.stopTest();

        String expected = 'Id IN (123.45, 987.65)';
        Assert.areEqual(expected, result, 'Unexpected condition output');
    }

    @IsTest 
    static void shouldOutputDecimalSetCondition() {
        Object value = new Set<Decimal>{ 123.45, 987.65 };
        Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

        Test.startTest();
        String result = condition?.toString();
        Test.stopTest();

        String expected = 'Id IN (123.45, 987.65)';
        Assert.areEqual(expected, result, 'Unexpected condition output');
    }

    @IsTest 
    static void shouldOutputIdCondition() {
        Object value = UserInfo.getUserId();
        Soql.Condition condition = new Soql.Condition(Account.Id, Soql.EQUALS, value);

        Test.startTest();
        String result = condition?.toString();
        Test.stopTest();

        String expected = 'Id = \'' + UserInfo.getUserId() + '\'';
        Assert.areEqual(expected, result, 'Unexpected condition output');
    }

    @IsTest 
    static void shouldOutputIdListCondition() {
        Id mockAccountId = SObjectType.Account.getKeyPrefix() + '0'?.repeat(15);
        Object value = new List<Id>{ UserInfo.getUserId(), mockAccountId };
        Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

        Test.startTest();
        String result = condition?.toString();
        Test.stopTest();

        String expected = 'Id IN (\'' + UserInfo.getUserId() + '\', \'' + mockAccountId + '\')';
        Assert.areEqual(expected, result, 'Unexpected condition output');
    }

    @IsTest 
    static void shouldOutputIdSetCondition() {
        Id mockAccountId = SObjectType.Account.getKeyPrefix() + '0'?.repeat(15);
        Object value = new Set<Id>{ UserInfo.getUserId(), mockAccountId };
        Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

        Test.startTest();
        String result = condition?.toString();
        Test.stopTest();

        String expected = 'Id IN (\'' + UserInfo.getUserId() + '\', \'' + mockAccountId + '\')';
        Assert.areEqual(expected, result, 'Unexpected condition output');
    }

    @IsTest 
    static void shouldOutputIntegerCondition() {
        Object value = 123;
        Soql.Condition condition = new Soql.Condition(Account.Id, Soql.EQUALS, value);

        Test.startTest();
        String result = condition?.toString();
        Test.stopTest();

        String expected = 'Id = 123';
        Assert.areEqual(expected, result, 'Unexpected condition output');
    }

    @IsTest 
    static void shouldOutputIntegerListCondition() {
        Object value = new List<Integer>{ 123, 456 };
        Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

        Test.startTest();
        String result = condition?.toString();
        Test.stopTest();

        String expected = 'Id IN (123, 456)';
        Assert.areEqual(expected, result, 'Unexpected condition output');
    }

    @IsTest 
    static void shouldOutputIntegerSetCondition() {
        Object value = new Set<Integer>{ 123, 456 };
        Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

        Test.startTest();
        String result = condition?.toString();
        Test.stopTest();

        String expected = 'Id IN (123, 456)';
        Assert.areEqual(expected, result, 'Unexpected condition output');
    }

    @IsTest 
    static void shouldOutputStringCondition() {
        Object value = 'foo';
        Soql.Condition condition = new Soql.Condition(Account.Id, Soql.EQUALS, value);

        Test.startTest();
        String result = condition?.toString();
        Test.stopTest();

        String expected = 'Id = \'foo\'';
        Assert.areEqual(expected, result, 'Unexpected condition output');
    }

    @IsTest 
    static void shouldOutputStringListCondition() {
        Object value = new List<String>{ 'foo', 'bar' };
        Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

        Test.startTest();
        String result = condition?.toString();
        Test.stopTest();

        String expected = 'Id IN (\'foo\', \'bar\')';
        Assert.areEqual(expected, result, 'Unexpected condition output');
    }

    @IsTest 
    static void shouldOutputStringSetCondition() {
        Object value = new List<String>{ 'foo', 'bar' };
        Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

        Test.startTest();
        String result = condition?.toString();
        Test.stopTest();

        String expected = 'Id IN (\'foo\', \'bar\')';
        Assert.areEqual(expected, result, 'Unexpected condition output');
    }

    @IsTest 
    static void shouldOutputNullCondition() {
        Object value = null;
        Soql.Condition condition = new Soql.Condition(Account.Id, Soql.EQUALS, value);

        Test.startTest();
        String result = condition?.toString();
        Test.stopTest();

        String expected = 'Id = null';
        Assert.areEqual(expected, result, 'Unexpected condition output');
    }

    @IsTest 
    static void shouldOutputBindCondition() {
        Object value = new Soql.Binder('myList');
        Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

        Test.startTest();
        String result = condition?.toString();
        Test.stopTest();

        String expected = 'Id IN :myList';
        Assert.areEqual(expected, result, 'Unexpected condition output');
    }

    @IsTest 
    static void shouldOutputManualBind() {
        // Alternatively, callers can pass a string variable starting with ":" to indicate a bind
        Object value = ':myList';
        Soql.Condition condition = new Soql.Condition(Account.Id, Soql.IN_COLLECTION, value);

        Test.startTest();
        String result = condition?.toString();
        Test.stopTest();

        String expected = 'Id IN :myList';
        Assert.areEqual(expected, result, 'Unexpected condition output');
    }

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