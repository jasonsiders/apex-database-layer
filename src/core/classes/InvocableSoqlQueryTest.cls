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

	// **** HELPERS **** //
	private static String initDefinition(String objectApiName, List<String> fields) {
		InvocableSoqlQuery query = new InvocableSoqlQuery();
		query.conditions = new List<InvocableSoqlQuery.Condition>{};
		query.fields = fields;
		query.objectApiName = objectApiName;
		return JSON.serialize(query);
	}
}
