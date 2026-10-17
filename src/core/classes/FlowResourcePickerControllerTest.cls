@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class FlowResourcePickerControllerTest {
	@IsTest
	private static void shouldDescribeObject() {
		Test.startTest();
		FlowResourcePickerController.ObjectDescribe describe = FlowResourcePickerController.describeObject('Contact');
		Test.stopTest();

		Assert.areEqual('Contact', describe?.apiName, 'Wrong apiName');
		Assert.areEqual(Contact.SObjectType.getDescribe().getLabel(), describe?.label, 'Wrong label');
		Assert.areEqual(Contact.SObjectType.getDescribe().getLabelPlural(), describe?.labelPlural, 'Wrong labelPlural');
		Map<String, FlowResourcePickerController.FieldDescribe> fields = new Map<String, FlowResourcePickerController.FieldDescribe>();
		for (FlowResourcePickerController.FieldDescribe field : describe?.fields) {
			fields.put(field?.apiName, field);
		}
		Assert.areEqual(Contact.SObjectType.getDescribe().fields.getMap().size(), fields.size(), 'Wrong # of fields');
		FlowResourcePickerController.FieldDescribe lastName = fields.get('LastName');
		Assert.areEqual(Contact.LastName.getDescribe().getLabel(), lastName?.label, 'Wrong field label');
		Assert.areEqual('STRING', lastName?.dataType, 'Wrong field dataType');
		Assert.isNull(lastName?.relationshipName, 'Non-lookup has a relationshipName');
		Assert.isTrue(lastName?.referenceTo?.isEmpty(), 'Non-lookup has referenceTo');
		FlowResourcePickerController.FieldDescribe accountId = fields.get('AccountId');
		Assert.areEqual('REFERENCE', accountId?.dataType, 'Wrong lookup dataType');
		Assert.areEqual('Account', accountId?.relationshipName, 'Wrong relationshipName');
		Assert.areEqual(new List<String>{ 'Account' }, accountId?.referenceTo, 'Wrong referenceTo');
	}

	@IsTest
	private static void shouldRejectUnknownObject() {
		Test.startTest();
		Exception caughtError;
		try {
			FlowResourcePickerController.describeObject('Not_A_Real_Object__c');
		} catch (System.AuraHandledException error) {
			caughtError = error;
		}
		Test.stopTest();

		Assert.isNotNull(caughtError, 'Did not throw a System.AuraHandledException');
	}
}
