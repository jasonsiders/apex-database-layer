@IsTest 
private class ConditionTest {
    @IsTest 
    static void shouldOutputBooleanFilters() {
        Test.startTest();
        ConditionTest.checkOutput('SomeField = true', new Condition('SomeField', Condition.EQUALS, true));
        ConditionTest.checkOutput('SomeField != true', new Condition('SomeField', Condition.NOT_EQUALS, true));
        ConditionTest.checkOutput('SomeField > true', new Condition('SomeField', Condition.GREATER_THAN, true));
        ConditionTest.checkOutput('SomeField >= true', new Condition('SomeField', Condition.GREATER_OR_EQUAL, true));
        ConditionTest.checkOutput('SomeField < true', new Condition('SomeField', Condition.LESS_THAN, true));
        ConditionTest.checkOutput('SomeField <= true', new Condition('SomeField', Condition.LESS_OR_EQUAL, true));
        ConditionTest.checkOutput('SomeField LIKE \'true%\'', new Condition('SomeField', Condition.STARTS_WITH, true));
        ConditionTest.checkOutput('SomeField NOT LIKE \'true%\'', new Condition('SomeField', Condition.NOT_STARTS_WITH, true));
        ConditionTest.checkOutput('SomeField LIKE \'%true\'', new Condition('SomeField', Condition.ENDS_WITH, true));
        ConditionTest.checkOutput('SomeField NOT LIKE \'%true\'', new Condition('SomeField', Condition.NOT_ENDS_WITH, true));
        ConditionTest.checkOutput('SomeField LIKE \'%true%\'', new Condition('SomeField', Condition.CONTAINS, true));
        ConditionTest.checkOutput('SomeField NOT LIKE \'%true%\'', new Condition('SomeField', Condition.NOT_CONTAINS, true));
        Test.stopTest();
    }

    @IsTest 
    static void shouldOutputDateTimeFilters() {
        DateTime now = DateTime.now();
        String formatted = now?.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
    
        Test.startTest();
        ConditionTest.checkOutput('SomeField = ' + formatted, new Condition('SomeField', Condition.EQUALS, now));
        ConditionTest.checkOutput('SomeField != ' + formatted, new Condition('SomeField', Condition.NOT_EQUALS, now));
        ConditionTest.checkOutput('SomeField > ' + formatted, new Condition('SomeField', Condition.GREATER_THAN, now));
        ConditionTest.checkOutput('SomeField >= ' + formatted, new Condition('SomeField', Condition.GREATER_OR_EQUAL, now));
        ConditionTest.checkOutput('SomeField < ' + formatted, new Condition('SomeField', Condition.LESS_THAN, now));
        ConditionTest.checkOutput('SomeField <= ' + formatted, new Condition('SomeField', Condition.LESS_OR_EQUAL, now));
        ConditionTest.checkOutput('SomeField LIKE \'' + formatted + '%\'', new Condition('SomeField', Condition.STARTS_WITH, now));
        ConditionTest.checkOutput('SomeField NOT LIKE \'' + formatted + '%\'', new Condition('SomeField', Condition.NOT_STARTS_WITH, now));
        ConditionTest.checkOutput('SomeField LIKE \'%' + formatted + '\'', new Condition('SomeField', Condition.ENDS_WITH, now));
        ConditionTest.checkOutput('SomeField NOT LIKE \'%' + formatted + '\'', new Condition('SomeField', Condition.NOT_ENDS_WITH, now));
        ConditionTest.checkOutput('SomeField LIKE \'%' + formatted + '%\'', new Condition('SomeField', Condition.CONTAINS, now));
        ConditionTest.checkOutput('SomeField NOT LIKE \'%' + formatted + '%\'', new Condition('SomeField', Condition.NOT_CONTAINS, now));
        Test.stopTest();
    }

    @IsTest 
    static void shouldOutputDateFilters() {
        Date today = Date.today();
        String formatted = DateTime.newInstanceGmt(today?.year(), today?.month(), today?.year())?.formatGmt('yyyy-MM-dd');

        Test.startTest();
        ConditionTest.checkOutput('SomeField = ' + formatted, new Condition('SomeField', Condition.EQUALS, today));
        ConditionTest.checkOutput('SomeField != ' + formatted, new Condition('SomeField', Condition.NOT_EQUALS, today));
        ConditionTest.checkOutput('SomeField > ' + formatted, new Condition('SomeField', Condition.GREATER_THAN, today));
        ConditionTest.checkOutput('SomeField >= ' + formatted, new Condition('SomeField', Condition.GREATER_OR_EQUAL, today));
        ConditionTest.checkOutput('SomeField < ' + formatted, new Condition('SomeField', Condition.LESS_THAN, today));
        ConditionTest.checkOutput('SomeField <= ' + formatted, new Condition('SomeField', Condition.LESS_OR_EQUAL, today));
        ConditionTest.checkOutput('SomeField LIKE \'' + formatted + '%\'', new Condition('SomeField', Condition.STARTS_WITH, today));
        ConditionTest.checkOutput('SomeField NOT LIKE \'' + formatted + '%\'', new Condition('SomeField', Condition.NOT_STARTS_WITH, today));
        ConditionTest.checkOutput('SomeField LIKE \'%' + formatted + '\'', new Condition('SomeField', Condition.ENDS_WITH, today));
        ConditionTest.checkOutput('SomeField NOT LIKE \'%' + formatted + '\'', new Condition('SomeField', Condition.NOT_ENDS_WITH, today));
        ConditionTest.checkOutput('SomeField LIKE \'%' + formatted + '%\'', new Condition('SomeField', Condition.CONTAINS, today));
        ConditionTest.checkOutput('SomeField NOT LIKE \'%' + formatted + '%\'', new Condition('SomeField', Condition.NOT_CONTAINS, today));
        Test.stopTest();
    }

    @IsTest 
    static void shouldOutputDecimalFilters() {
        Decimal num = 1.23;

        Test.startTest();
        ConditionTest.checkOutput('SomeField = ' + num, new Condition('SomeField', Condition.EQUALS, num));
        ConditionTest.checkOutput('SomeField != ' + num, new Condition('SomeField', Condition.NOT_EQUALS, num));
        ConditionTest.checkOutput('SomeField > ' + num, new Condition('SomeField', Condition.GREATER_THAN, num));
        ConditionTest.checkOutput('SomeField >= ' + num, new Condition('SomeField', Condition.GREATER_OR_EQUAL, num));
        ConditionTest.checkOutput('SomeField < ' + num, new Condition('SomeField', Condition.LESS_THAN, num));
        ConditionTest.checkOutput('SomeField <= ' + num, new Condition('SomeField', Condition.LESS_OR_EQUAL, num));
        ConditionTest.checkOutput('SomeField LIKE \'' + num + '%\'', new Condition('SomeField', Condition.STARTS_WITH, num));
        ConditionTest.checkOutput('SomeField NOT LIKE \'' + num + '%\'', new Condition('SomeField', Condition.NOT_STARTS_WITH, num));
        ConditionTest.checkOutput('SomeField LIKE \'%' + num + '\'', new Condition('SomeField', Condition.ENDS_WITH, num));
        ConditionTest.checkOutput('SomeField NOT LIKE \'%' + num + '\'', new Condition('SomeField', Condition.NOT_ENDS_WITH, num));
        ConditionTest.checkOutput('SomeField LIKE \'%' + num + '%\'', new Condition('SomeField', Condition.CONTAINS, num));
        ConditionTest.checkOutput('SomeField NOT LIKE \'%' + num + '%\'', new Condition('SomeField', Condition.NOT_CONTAINS, num));
        Test.stopTest();
    }

    @IsTest 
    static void shouldOutputIdFilters() {
        Assert.fail('You still need to build this test');
    }

    @IsTest 
    static void shouldOutputIntegerFilters() {
        Assert.fail('You still need to build this test');
    }

    @IsTest 
    static void shouldOutputStringFilters() {
        Assert.fail('You still need to build this test');
    }

    @IsTest 
    static void shouldOutputTimeFilters() {
        Assert.fail('You still need to build this test');
    }

    // **** HELPER **** //
    static void checkOutput(String expected, Condition condition) {
        Assert.areEqual(expected, condition?.toString(), 'Unexpected ' + condition?.operator + ' value');
    }
}