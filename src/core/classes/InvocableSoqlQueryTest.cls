@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class InvocableSoqlQueryTest {
	private static final List<Object> NO_VALUES = new List<Object>{};

	// **** TESTS **** //
	@IsTest
	private static void shouldSelectAllFieldsOfTheObjectAndItsParents() {
		List<String> fields = new List<String>{ '*', 'Account.Owner.*', 'Account.Name' };
		String definition = InvocableSoqlQueryTest.initDefinition('Contact', fields);

		Test.startTest();
		InvocableSoqlQuery query = InvocableSoqlQuery.parse(definition);
		Soql soql = query?.toSoql(InvocableSoqlQueryTest.NO_VALUES, System.AccessLevel.SYSTEM_MODE);
		String queryString = query?.toQueryString(InvocableSoqlQueryTest.NO_VALUES, System.AccessLevel.SYSTEM_MODE);
		Test.stopTest();

		Set<String> selected = soql?.selectClauses;
		Assert.isTrue(selected?.contains('LastName'), 'Did not select all of the contact\'s fields');
		Assert.isTrue(selected?.contains('Account.Owner.Name'), 'Did not select all of the account owner\'s fields');
		Assert.isTrue(selected?.contains('Account.Name'), 'Did not keep a named parent field');
		Assert.isTrue(queryString?.contains('Account.Owner.Email'), 'Query string lacks the expanded fields');
	}

	@IsTest
	private static void shouldRejectAllFieldsOfAnUnknownRelationship() {
		List<String> fields = new List<String>{ 'Nope.*' };
		String definition = InvocableSoqlQueryTest.initDefinition('Contact', fields);
		Exception caughtError;

		Test.startTest();
		try {
			InvocableSoqlQuery.parse(definition);
		} catch (Exception error) {
			caughtError = error;
		}
		Test.stopTest();

		Assert.isInstanceOfType(caughtError, IllegalArgumentException.class, 'Wrong error: ' + caughtError);
	}

	@IsTest
	private static void shouldLetPluginsAddConditionsToQueriesWithoutAny() {
		insert new List<Account>{ new Account(Name = 'Acme'), new Account(Name = 'Beta') };
		String definition = InvocableSoqlQueryTest.initDefinition('Account', new List<String>{ 'Name' });

		Test.startTest();
		InvocableSoqlQuery query = InvocableSoqlQuery.parse(definition);
		Soql builder = query?.toSoql(InvocableSoqlQueryTest.NO_VALUES, System.AccessLevel.SYSTEM_MODE);
		// A SOQL plugin can add conditions to any query before it runs:
		builder?.addWhere(Account.Name, Soql.EQUALS, 'Acme');
		List<Account> accounts = (List<Account>) builder?.query();
		Test.stopTest();

		Assert.areEqual(1, accounts?.size(), 'Wrong accounts: ' + accounts);
	}

	@IsTest
	private static void shouldGroupAnyConditionLogicApartFromAddedConditions() {
		insert new List<Account>{
			new Account(Name = 'Acme', Site = 'East'),
			new Account(Name = 'Beta', Site = 'West')
		};
		InvocableSoqlQuery definition = new InvocableSoqlQuery();
		definition.conditionLogic = 'OR';
		definition.conditions = new List<InvocableSoqlQuery.Condition>{
			InvocableSoqlQueryTest.initCondition('Name', 'Acme'),
			InvocableSoqlQueryTest.initCondition('Name', 'Beta')
		};
		definition.objectApiName = 'Account';
		String json = JSON.serialize(definition);
		InvocableSoql.Input input = new InvocableSoql.Input();

		Test.startTest();
		InvocableSoqlQuery query = InvocableSoqlQuery.parse(json);
		List<Object> values = query?.resolveValues(input);
		Soql builder = query?.toSoql(values, System.AccessLevel.SYSTEM_MODE);
		// A SOQL plugin's condition must apply to every record the logic finds, not just its last condition's:
		builder?.addWhere(Account.Site, Soql.EQUALS, 'East');
		List<Account> accounts = (List<Account>) builder?.query();
		Test.stopTest();

		Assert.areEqual(1, accounts?.size(), 'Wrong accounts: ' + accounts);
		Assert.areEqual('Acme', accounts?.get(0)?.Name, 'Wrong account');
	}

	// **** HELPERS **** //
	private static InvocableSoqlQuery.Condition initCondition(String field, String value) {
		InvocableSoqlQuery.Condition condition = new InvocableSoqlQuery.Condition();
		condition.field = field;
		condition.operator = 'EQUALS';
		condition.value = value;
		return condition;
	}

	private static String initDefinition(String objectApiName, List<String> fields) {
		InvocableSoqlQuery query = new InvocableSoqlQuery();
		query.conditions = new List<InvocableSoqlQuery.Condition>{};
		query.fields = fields;
		query.objectApiName = objectApiName;
		return JSON.serialize(query);
	}
}
