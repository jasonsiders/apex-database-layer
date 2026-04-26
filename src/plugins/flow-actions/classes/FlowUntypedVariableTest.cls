@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class FlowUntypedVariableTest {
	@IsTest
	private static void shouldDefaultIsCollectionToFalse() {
		Test.startTest();
		FlowUntypedVariable variable = new FlowUntypedVariable();
		Test.stopTest();

		Assert.isFalse(variable.isCollection, 'isCollection should default to false');
	}

	@IsTest
	private static void shouldGetValueAsString() {
		FlowUntypedVariable variable = new FlowUntypedVariable();
		variable.typeName = 'String';
		variable.textValue = '"hello"';

		Test.startTest();
		Object result = variable.getValue();
		Test.stopTest();

		Assert.areEqual('hello', result, 'Expected String value');
	}

	@IsTest
	private static void shouldGetValueAsBoolean() {
		FlowUntypedVariable variable = new FlowUntypedVariable();
		variable.typeName = 'Boolean';
		variable.textValue = 'true';

		Test.startTest();
		Object result = variable.getValue();
		Test.stopTest();

		Assert.areEqual(true, result, 'Expected Boolean value');
	}

	@IsTest
	private static void shouldGetValueAsCollection() {
		FlowUntypedVariable variable = new FlowUntypedVariable();
		variable.typeName = 'String';
		variable.isCollection = true;
		variable.textValue = '["a","b","c"]';

		Test.startTest();
		Object result = variable.getValue();
		Test.stopTest();

		List<String> values = (List<String>) result;
		Assert.areEqual(3, values?.size(), 'Expected 3 items in collection');
		Assert.areEqual('a', values[0], 'Wrong first item in collection');
	}

	@SuppressWarnings('PMD.EmptyCatchBlock')
	@IsTest
	private static void shouldThrowIllegalArgumentExceptionForInvalidJson() {
		FlowUntypedVariable variable = new FlowUntypedVariable();
		variable.typeName = 'Integer';
		variable.textValue = '"not-a-number"';

		Test.startTest();
		try {
			variable.getValue();
			Assert.fail('Did not throw a System.IllegalArgumentException');
		} catch (System.IllegalArgumentException error) {
			// As expected...
		}
		Test.stopTest();
	}

	@SuppressWarnings('PMD.EmptyCatchBlock')
	@IsTest
	private static void shouldThrowTypeExceptionForUnknownTypeName() {
		FlowUntypedVariable variable = new FlowUntypedVariable();
		variable.typeName = 'NoSuchType';
		variable.textValue = '"value"';

		Test.startTest();
		try {
			variable.getValue();
			Assert.fail('Did not throw a System.TypeException');
		} catch (System.TypeException error) {
			// As expected...
		}
		Test.stopTest();
	}
}
