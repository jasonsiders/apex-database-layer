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
    static void shouldOutputDateTimeValue() {
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

    static void checkOutput(String expected, Condition condition) {
        Assert.areEqual(expected, condition?.toString(), 'Unexpected ' + condition?.operator + ' value');
    }
}