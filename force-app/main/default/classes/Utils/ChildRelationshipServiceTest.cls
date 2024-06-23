@IsTest
private class ChildRelationshipServiceTest {
	@IsTest
	static void shouldGetChildRelationshipFromLookupField() {
		SObjectField field = Contact.AccountId;

		Test.startTest();
		Schema.ChildRelationship relationship = ChildRelationshipService.getChildRelationshipFrom(field);
		Test.stopTest();

		Assert.areEqual(field, relationship?.getField(), 'Relationship does not point to ' + field);
	}

	@IsTest
	static void shouldGetChildRelationshipFromPolymorphicLookupField() {
		SObjectField field = Task.WhoId; // Polymorphic! Can be a reference to Contact.Tasks OR Lead.Tasks
		SObjectType referenceTo = Lead.SObjectType; // ...in this case, we want Lead.Tasks

		Test.startTest();
		Schema.ChildRelationship relationship = ChildRelationshipService.getChildRelationshipFrom(field, referenceTo);
		Test.stopTest();

		Assert.areEqual(field, relationship?.getField(), 'Relationship does not point to ' + field);
	}

	@IsTest
	static void shouldReturnChildRelationshipsUnderHighStress() {
		// The operation to retrieve Schema.ChildRelationships from an object can be expensive,
		// so the class internally caches these results via an inner class.
		// Successive calls to retrieve the same SObjectType's relationships
		// should have similar performance implications as calling it once.
		SObjectField field = Contact.AccountId;
		ChildRelationshipService.getChildRelationshipFrom(field);
		Integer firstTime = Limits.getCpuTime();

		for (Integer i = 0; i < 10; i++) {
			Integer start = Limits.getCpuTime();
			ChildRelationshipService.getChildRelationshipFrom(field);
			Integer thisTime = Limits.getCpuTime() - start;
			Assert.areEqual(
				true,
				thisTime < firstTime,
				'Took longer than initial call: ' + new List<Integer>{ firstTime, thisTime }
			);
		}
	}

	@IsTest
	static void shouldReturnNullChildRelationshipIfNotLookupField() {
		SObjectField field = Contact.CreatedDate;

		Test.startTest();
		Schema.ChildRelationship relationship = ChildRelationshipService.getChildRelationshipFrom(field);
		Test.stopTest();

		Assert.areEqual(null, relationship, 'Non-lookup field returned a relationship anyways');
	}
}
