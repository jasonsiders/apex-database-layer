@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class InvocableSoqlTest {
	private static final String QUERY_BY_NAME = 'SELECT Id, Name FROM Account WHERE Name = :name';
	private static final String QUERY_BY_NAME_AND_PHONE = 'SELECT Id, Name FROM Account WHERE Name = :name AND Phone = :phone';
	private static final String QUERY_NESTED_WHERE = 'SELECT Id, Name FROM Account WHERE (Name = :name OR Status__c = :status) AND IsActive = :active';
	private static final String QUERY_PARENT_FIELD = 'SELECT Id, Name FROM Account WHERE Parent.Name = :name';
	private static final String QUERY_WITH_LITERAL = 'SELECT Id, Name FROM Account WHERE Name = :name AND Phone = \'555-1234\'';
	private static final String QUERY_NO_WHERE = 'SELECT Id, Name FROM Account';
	private static final String QUERY_MULTIPLE_PIVOTS = 'SELECT Id, Name FROM Account WHERE Name = :name AND Phone = :phone';
	private static final String QUERY_WITH_COMPARISON = 'SELECT Id, Name FROM Account WHERE NumberOfEmployees > :count';

	static {
		DatabaseLayer.useMocks();
	}

	private static Map<String, Object> createStringVariable(String key, String value) {
		return InvocableSoqlTest.createBindVariable(key, value, 'String', false);
	}

	private static Map<String, Object> createBooleanVariable(String key, Boolean value) {
		return InvocableSoqlTest.createBindVariable(key, String.valueOf(value), 'Boolean', false);
	}

	private static Map<String, Object> createBindVariable(
		String key,
		String textValue,
		String typeName,
		Boolean isCollection
	) {
		return new Map<String, Object>{
			'key' => key,
			'textValue' => textValue,
			'typeName' => typeName,
			'isCollection' => isCollection
		};
	}

	private static InvocableSoql.Input createInput(String query, List<Map<String, Object>> binds) {
		InvocableSoql.Input input = new InvocableSoql.Input();
		input.query = query;
		input.bindsJson = JSON.serialize(binds ?? new List<Map<String, Object>>{});
		return input;
	}

	@IsTest
	private static void shouldReturnResultsForSingleInput() {
		Account mockAccount = new Account(Name = 'Acme');
		MockSoql.setGlobalMock().withResults(new List<SObject>{ mockAccount });

		InvocableSoql.Input input = InvocableSoqlTest.createInput(
			QUERY_BY_NAME,
			new List<Map<String, Object>>{ InvocableSoqlTest.createStringVariable('name', '"Acme"') }
		);

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ input });
		Test.stopTest();

		Assert.areEqual(1, outputs.size(), 'Should return 1 output');
		Assert.areEqual(1, outputs[0].allResults.size(), 'Should have 1 result');
		Assert.isNotNull(outputs[0].firstResult, 'firstResult should be populated');
		Assert.areEqual('Acme', outputs[0].firstResult.get('Name'), 'Result name should match');
	}

	@IsTest
	private static void shouldReturnEmptyOutputForEmptyInputs() {
		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{});
		Test.stopTest();

		Assert.areEqual(0, outputs.size(), 'Should return empty list for empty inputs');
	}

	@IsTest
	private static void shouldDescribeSObjectFieldsForPropertyEditor() {
		Test.startTest();
		List<InvocableSoql.FieldOption> fields = InvocableSoql.describeSObjectFields('Account');
		Test.stopTest();

		Map<String, InvocableSoql.FieldOption> fieldsByName = new Map<String, InvocableSoql.FieldOption>{};
		for (InvocableSoql.FieldOption field : fields) {
			fieldsByName.put(field.name, field);
		}

		Assert.isTrue(fieldsByName.containsKey('Name'), 'Account.Name should be available');
		Assert.areEqual('String', fieldsByName.get('Name').dataType, 'Account.Name should map to String');
		Assert.areEqual('Account Name', fieldsByName.get('Name').label, 'Account.Name label should be exposed');
	}

	@IsTest
	private static void shouldDescribeRelationshipFieldsForPropertyEditor() {
		Test.startTest();
		List<InvocableSoql.FieldOption> fields = InvocableSoql.describeSObjectFields('Opportunity');
		Test.stopTest();

		Map<String, InvocableSoql.FieldOption> fieldsByName = new Map<String, InvocableSoql.FieldOption>{};
		for (InvocableSoql.FieldOption field : fields) {
			fieldsByName.put(field.name, field);
		}

		Assert.isTrue(fieldsByName.containsKey('AccountId'), 'Opportunity.AccountId should be available');
		Assert.areEqual('String', fieldsByName.get('AccountId').dataType, 'Lookup IDs should map to String');
		Assert.areEqual(
			'Account',
			fieldsByName.get('AccountId').relationshipName,
			'Relationship name should be exposed'
		);
		Assert.areEqual(
			'Account',
			fieldsByName.get('AccountId').relationshipObjectType,
			'Relationship object type should be exposed'
		);
		Assert.isTrue(
			fieldsByName.get('AccountId').relationshipObjectTypes.contains('Account'),
			'All relationship object types should be exposed'
		);
	}

	@IsTest
	private static void shouldReturnNoFieldsForUnknownSObjectDescribe() {
		Test.startTest();
		List<InvocableSoql.FieldOption> fields = InvocableSoql.describeSObjectFields('NotARealObject__c');
		Test.stopTest();

		Assert.areEqual(0, fields.size(), 'Unknown object describes should return no field options');
	}

	@IsTest
	private static void shouldReturnEmptyResultsWhenQueryReturnsNothing() {
		MockSoql.setGlobalMock().withResults(new List<SObject>{});

		InvocableSoql.Input input = InvocableSoqlTest.createInput(
			QUERY_BY_NAME,
			new List<Map<String, Object>>{ InvocableSoqlTest.createStringVariable('name', '"NoMatch"') }
		);

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ input });
		Test.stopTest();

		Assert.areEqual(0, outputs[0].allResults.size(), 'allResults should be empty');
		Assert.isNull(outputs[0].firstResult, 'firstResult should be null when no results');
	}

	@IsTest
	private static void shouldPopulateFirstResultFromAllResults() {
		Account account1 = new Account(Name = 'Account1');
		Account account2 = new Account(Name = 'Account2');
		MockSoql.setGlobalMock().withResults(new List<SObject>{ account1, account2 });

		InvocableSoql.Input input = InvocableSoqlTest.createInput(QUERY_NO_WHERE, null);

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ input });
		Test.stopTest();

		Assert.areEqual(2, outputs[0].allResults.size(), 'Should have 2 results');
		Assert.areEqual(
			outputs[0].firstResult.get('Id'),
			outputs[0].allResults[0].get('Id'),
			'firstResult should be first element'
		);
	}

	@IsTest
	private static void shouldApplyBindVariables() {
		Account mockAccount = new Account(Name = 'TestAccount', Phone = '555-1234');
		MockSoql.setGlobalMock().withResults(new List<SObject>{ mockAccount });

		InvocableSoql.Input input = InvocableSoqlTest.createInput(
			QUERY_BY_NAME_AND_PHONE,
			new List<Map<String, Object>>{
				InvocableSoqlTest.createStringVariable('name', '"TestAccount"'),
				InvocableSoqlTest.createStringVariable('phone', '"555-1234"')
			}
		);

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ input });
		Test.stopTest();

		Assert.isTrue(outputs[0].query.contains(':name'), 'Query should contain :name');
		Assert.isTrue(outputs[0].query.contains(':phone'), 'Query should contain :phone');
	}

	@IsTest
	private static void shouldApplySerializedBindVariables() {
		Account mockAccount = new Account(Name = 'JsonAccount');
		MockSoql.setGlobalMock().withResults(new List<SObject>{ mockAccount });

		InvocableSoql.Input input = InvocableSoqlTest.createInput(
			QUERY_BY_NAME,
			new List<Map<String, Object>>{ InvocableSoqlTest.createStringVariable('name', '"JsonAccount"') }
		);

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ input });
		Test.stopTest();

		List<Object> outputBinds = (List<Object>) JSON.deserializeUntyped(outputs[0].bindsJson);
		Map<String, Object> outputBind = (Map<String, Object>) outputBinds[0];
		Assert.areEqual(1, outputBinds.size(), 'Output should include serialized bind variables');
		Assert.areEqual('name', outputBind.get('key'), 'Serialized bind key should be preserved');
		Assert.isTrue(outputs[0].query.contains(':name'), 'Query should contain :name');
	}

	@IsTest
	private static void shouldExecuteOnceForIdenticalBindValues() {
		Account acmeAccount = new Account(Name = 'Acme');
		MockSoql.setGlobalMock().withResults(new List<SObject>{ acmeAccount });

		List<Map<String, Object>> binds = new List<Map<String, Object>>{
			InvocableSoqlTest.createStringVariable('name', '"Acme"')
		};
		InvocableSoql.Input input1 = InvocableSoqlTest.createInput(QUERY_BY_NAME, binds);
		InvocableSoql.Input input2 = InvocableSoqlTest.createInput(QUERY_BY_NAME, binds);

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ input1, input2 });
		Test.stopTest();

		Assert.areEqual(2, outputs.size(), 'Should return 2 outputs');
		Assert.areEqual(1, outputs[0].allResults.size(), 'First output should have 1 result');
		Assert.areEqual(1, outputs[1].allResults.size(), 'Second output should have 1 result');
		Assert.areEqual(outputs[0].allResults, outputs[1].allResults, 'Outputs should share results');
	}

	@IsTest
	private static void shouldTransformToInListForSameTemplateWithDifferentBinds() {
		Account acmeAccount = new Account(Name = 'Acme');
		Account betaAccount = new Account(Name = 'Beta');
		MockSoql.setGlobalMock().withResults(new List<SObject>{ acmeAccount, betaAccount });

		InvocableSoql.Input input1 = InvocableSoqlTest.createInput(
			QUERY_BY_NAME,
			new List<Map<String, Object>>{ InvocableSoqlTest.createStringVariable('name', '"Acme"') }
		);
		InvocableSoql.Input input2 = InvocableSoqlTest.createInput(
			QUERY_BY_NAME,
			new List<Map<String, Object>>{ InvocableSoqlTest.createStringVariable('name', '"Beta"') }
		);

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ input1, input2 });
		Test.stopTest();

		Assert.areEqual(2, outputs.size(), 'Should return 2 outputs');
		Assert.areEqual(1, outputs[0].allResults.size(), 'First output should have 1 result');
		Assert.areEqual('Acme', outputs[0].allResults[0].get('Name'), 'First output should be Acme');
		Assert.areEqual(1, outputs[1].allResults.size(), 'Second output should have 1 result');
		Assert.areEqual('Beta', outputs[1].allResults[0].get('Name'), 'Second output should be Beta');
	}

	@IsTest
	private static void shouldReturnEmptyResultsForUnmatchedBindValue() {
		Account acmeAccount = new Account(Name = 'Acme');
		MockSoql.setGlobalMock().withResults(new List<SObject>{ acmeAccount });

		InvocableSoql.Input input1 = InvocableSoqlTest.createInput(
			QUERY_BY_NAME,
			new List<Map<String, Object>>{ InvocableSoqlTest.createStringVariable('name', '"Acme"') }
		);
		InvocableSoql.Input input2 = InvocableSoqlTest.createInput(
			QUERY_BY_NAME,
			new List<Map<String, Object>>{ InvocableSoqlTest.createStringVariable('name', '"NoMatch"') }
		);

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ input1, input2 });
		Test.stopTest();

		Assert.areEqual(1, outputs[0].allResults.size(), 'Matched input should have 1 result');
		Assert.areEqual(0, outputs[1].allResults.size(), 'Unmatched input should have 0 results');
		Assert.isNull(outputs[1].firstResult, 'firstResult should be null for unmatched');
	}

	@IsTest
	private static void shouldFallbackToPerInputForNestedWhereLogic() {
		Account account1 = new Account(Name = 'Acme');
		Account account2 = new Account(Name = 'Beta');
		MockSoql.setGlobalMock().withResults(new List<SObject>{ account1, account2 });

		InvocableSoql.Input input1 = InvocableSoqlTest.createInput(
			QUERY_NESTED_WHERE,
			new List<Map<String, Object>>{
				InvocableSoqlTest.createStringVariable('name', '"Acme"'),
				InvocableSoqlTest.createStringVariable('status', '"Active"'),
				InvocableSoqlTest.createBooleanVariable('active', true)
			}
		);
		InvocableSoql.Input input2 = InvocableSoqlTest.createInput(
			QUERY_NESTED_WHERE,
			new List<Map<String, Object>>{
				InvocableSoqlTest.createStringVariable('name', '"Beta"'),
				InvocableSoqlTest.createStringVariable('status', '"Active"'),
				InvocableSoqlTest.createBooleanVariable('active', true)
			}
		);

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ input1, input2 });
		Test.stopTest();

		Assert.areEqual(2, outputs.size(), 'Should return 2 outputs');
		Assert.isNotNull(outputs[0].allResults, 'First output allResults should not be null');
		Assert.isNotNull(outputs[1].allResults, 'Second output allResults should not be null');
	}

	@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
	@IsTest
	private static void shouldFallbackToPerInputForParentFieldCondition() {
		Account acmeAccount = new Account(Name = 'Acme');
		MockSoql.setGlobalMock().withResults(new List<SObject>{ acmeAccount });

		InvocableSoql.Input input1 = InvocableSoqlTest.createInput(
			QUERY_PARENT_FIELD,
			new List<Map<String, Object>>{ InvocableSoqlTest.createStringVariable('name', '"Acme"') }
		);
		InvocableSoql.Input input2 = InvocableSoqlTest.createInput(
			QUERY_PARENT_FIELD,
			new List<Map<String, Object>>{ InvocableSoqlTest.createStringVariable('name', '"Beta"') }
		);

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ input1, input2 });
		Test.stopTest();

		Assert.areEqual(2, outputs.size(), 'Should return 2 outputs');
	}

	@IsTest
	private static void shouldExecutePerInputForNoWhereClause() {
		Account account1 = new Account(Name = 'Account1');
		Account account2 = new Account(Name = 'Account2');
		MockSoql.setGlobalMock().withResults(new List<SObject>{ account1, account2 });

		InvocableSoql.Input input1 = InvocableSoqlTest.createInput(QUERY_NO_WHERE, null);
		InvocableSoql.Input input2 = InvocableSoqlTest.createInput(QUERY_NO_WHERE, null);

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ input1, input2 });
		Test.stopTest();

		Assert.areEqual(2, outputs.size(), 'Should return 2 outputs');
		Assert.areEqual(2, outputs[0].allResults.size(), 'First output should have 2 results');
		Assert.areEqual(2, outputs[1].allResults.size(), 'Second output should have 2 results');
	}

	@IsTest
	private static void shouldAddNonPivotConditionsToInListTransformation() {
		Account acmeAccount = new Account(Name = 'Acme', Phone = '555-1234');
		Account betaAccount = new Account(Name = 'Beta', Phone = '555-1234');
		MockSoql.setGlobalMock().withResults(new List<SObject>{ acmeAccount, betaAccount });

		InvocableSoql.Input input1 = InvocableSoqlTest.createInput(
			QUERY_WITH_LITERAL,
			new List<Map<String, Object>>{ InvocableSoqlTest.createStringVariable('name', '"Acme"') }
		);
		InvocableSoql.Input input2 = InvocableSoqlTest.createInput(
			QUERY_WITH_LITERAL,
			new List<Map<String, Object>>{ InvocableSoqlTest.createStringVariable('name', '"Beta"') }
		);

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ input1, input2 });
		Test.stopTest();

		Assert.areEqual(2, outputs.size(), 'Should return 2 outputs');
		Assert.isNotNull(outputs[0].allResults, 'First output allResults should not be null');
		Assert.isNotNull(outputs[1].allResults, 'Second output allResults should not be null');
	}

	@IsTest
	private static void shouldFallbackToPerInputForMultiplePivotConditions() {
		Account acmeAccount = new Account(Name = 'Acme', Phone = '555-1234');
		Account betaAccount = new Account(Name = 'Beta', Phone = '555-5678');
		MockSoql.setGlobalMock().withResults(new List<SObject>{ acmeAccount, betaAccount });

		InvocableSoql.Input input1 = InvocableSoqlTest.createInput(
			QUERY_MULTIPLE_PIVOTS,
			new List<Map<String, Object>>{
				InvocableSoqlTest.createStringVariable('name', '"Acme"'),
				InvocableSoqlTest.createStringVariable('phone', '"555-1234"')
			}
		);
		InvocableSoql.Input input2 = InvocableSoqlTest.createInput(
			QUERY_MULTIPLE_PIVOTS,
			new List<Map<String, Object>>{
				InvocableSoqlTest.createStringVariable('name', '"Beta"'),
				InvocableSoqlTest.createStringVariable('phone', '"555-5678"')
			}
		);

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ input1, input2 });
		Test.stopTest();

		Assert.areEqual(2, outputs.size(), 'Should return 2 outputs');
		Assert.isNotNull(outputs[0].allResults, 'First output should have results');
		Assert.isNotNull(outputs[1].allResults, 'Second output should have results');
	}

	@IsTest
	private static void shouldFallbackToPerInputForComparisonOperator() {
		Account account = new Account(Name = 'Test', NumberOfEmployees = 100);
		MockSoql.setGlobalMock().withResults(new List<SObject>{ account });

		InvocableSoql.Input input1 = InvocableSoqlTest.createInput(
			QUERY_WITH_COMPARISON,
			new List<Map<String, Object>>{ InvocableSoqlTest.createStringVariable('count', '50') }
		);
		InvocableSoql.Input input2 = InvocableSoqlTest.createInput(
			QUERY_WITH_COMPARISON,
			new List<Map<String, Object>>{ InvocableSoqlTest.createStringVariable('count', '150') }
		);

		Test.startTest();
		List<InvocableSoql.Output> outputs = InvocableSoql.invoke(new List<InvocableSoql.Input>{ input1, input2 });
		Test.stopTest();

		Assert.areEqual(2, outputs.size(), 'Should return 2 outputs');
		Assert.isNotNull(outputs[0].allResults, 'First output should have results');
		Assert.isNotNull(outputs[1].allResults, 'Second output should have results');
	}

	@IsTest
	private static void shouldFireOneQueryForSingleInput() {
		MockSoql.setGlobalMock().withResults(new List<SObject>{ new Account(Name = 'Acme') });
		InvocableSoql.Input input = InvocableSoqlTest.createInput(
			QUERY_BY_NAME,
			new List<Map<String, Object>>{ InvocableSoqlTest.createStringVariable('name', '"Acme"') }
		);
		Test.startTest();
		InvocableSoql.invoke(new List<InvocableSoql.Input>{ input });
		Test.stopTest();
		Assert.areEqual(1, MockSoql.MockDatabase?.getNumQueries(), 'Single input should fire exactly 1 query');
	}

	@IsTest
	private static void shouldFireOneQueryForIdenticalBindValues() {
		MockSoql.setGlobalMock().withResults(new List<SObject>{ new Account(Name = 'Acme') });
		List<Map<String, Object>> binds = new List<Map<String, Object>>{
			InvocableSoqlTest.createStringVariable('name', '"Acme"')
		};
		InvocableSoql.Input input1 = InvocableSoqlTest.createInput(QUERY_BY_NAME, binds);
		InvocableSoql.Input input2 = InvocableSoqlTest.createInput(QUERY_BY_NAME, binds);
		Test.startTest();
		InvocableSoql.invoke(new List<InvocableSoql.Input>{ input1, input2 });
		Test.stopTest();
		// executeOnceAndCopy: query fires once, results are copied to the second output
		Assert.areEqual(1, MockSoql.MockDatabase?.getNumQueries(), 'Identical bind values should fire only 1 query');
	}

	@IsTest
	private static void shouldFireOneQueryForDifferentBindValuesViaInList() {
		MockSoql.setGlobalMock()
			.withResults(new List<SObject>{ new Account(Name = 'Acme'), new Account(Name = 'Beta') });
		InvocableSoql.Input input1 = InvocableSoqlTest.createInput(
			QUERY_BY_NAME,
			new List<Map<String, Object>>{ InvocableSoqlTest.createStringVariable('name', '"Acme"') }
		);
		InvocableSoql.Input input2 = InvocableSoqlTest.createInput(
			QUERY_BY_NAME,
			new List<Map<String, Object>>{ InvocableSoqlTest.createStringVariable('name', '"Beta"') }
		);
		Test.startTest();
		InvocableSoql.invoke(new List<InvocableSoql.Input>{ input1, input2 });
		Test.stopTest();
		// executeWithInList: bind values are merged into one IN-list query
		Assert.areEqual(
			1,
			MockSoql.MockDatabase?.getNumQueries(),
			'Different bind values should merge into 1 IN-list query'
		);
	}

	@IsTest
	private static void shouldFireOneQueryPerInputForFallbackGroup() {
		MockSoql.setGlobalMock()
			.withResults(new List<SObject>{ new Account(Name = 'Acme'), new Account(Name = 'Beta') });
		InvocableSoql.Input input1 = InvocableSoqlTest.createInput(
			QUERY_NESTED_WHERE,
			new List<Map<String, Object>>{
				InvocableSoqlTest.createStringVariable('name', '"Acme"'),
				InvocableSoqlTest.createStringVariable('status', '"Active"'),
				InvocableSoqlTest.createBooleanVariable('active', true)
			}
		);
		InvocableSoql.Input input2 = InvocableSoqlTest.createInput(
			QUERY_NESTED_WHERE,
			new List<Map<String, Object>>{
				InvocableSoqlTest.createStringVariable('name', '"Beta"'),
				InvocableSoqlTest.createStringVariable('status', '"Active"'),
				InvocableSoqlTest.createBooleanVariable('active', true)
			}
		);
		Test.startTest();
		InvocableSoql.invoke(new List<InvocableSoql.Input>{ input1, input2 });
		Test.stopTest();
		// executePerInput: nested WHERE blocks IN-list optimization, each input fires its own query
		Assert.areEqual(
			2,
			MockSoql.MockDatabase?.getNumQueries(),
			'Nested WHERE fallback should fire 1 query per input'
		);
	}

	@IsTest
	private static void shouldValidateSimpleQuery() {
		DatabaseLayer.useRealData();
		String query = 'SELECT Id FROM Account ORDER BY CreatedDate DESC LIMIT 1';

		Test.startTest();
		try {
			InvocableSoql.validateQuery(query, null);
		} catch (Exception anyError) {
			Assert.fail('Should not have thrown an exception');
		}
		Test.stopTest();
	}

	@IsTest
	private static void shouldValidateQueryWithBinds() {
		DatabaseLayer.useRealData();
		String query = 'SELECT Id FROM Account WHERE Name = :name';
		List<String> binds = new List<String>{ 'name' };

		Test.startTest();
		try {
			InvocableSoql.validateQuery(query, binds);
		} catch (Exception anyError) {
			Assert.fail('Should not have thrown an exception');
		}
		Test.stopTest();
	}

	@SuppressWarnings('PMD.EmptyCatchBlock')
	@IsTest
	private static void shouldThrowExceptionIfInvalidQueryString() {
		DatabaseLayer.useRealData();
		String query = 'asdf';

		Test.startTest();
		try {
			InvocableSoql.validateQuery(query, null);
			Assert.fail('Should have thrown an exception');
		} catch (Exception anyError) {
			// As expected...
		}
		Test.stopTest();
	}

	@SuppressWarnings('PMD.EmptyCatchBlock')
	@IsTest
	private static void shouldThrowExceptionIfMissingBinds() {
		DatabaseLayer.useRealData();
		String query = 'SELECT Id FROM Account WHERE Name = :name';
		List<String> binds = new List<String>{ 'someOtherBind' };

		Test.startTest();
		try {
			InvocableSoql.validateQuery(query, binds);
			Assert.fail('Should have thrown an exception');
		} catch (Exception anyError) {
			// As expected...
		}
		Test.stopTest();
	}
}
