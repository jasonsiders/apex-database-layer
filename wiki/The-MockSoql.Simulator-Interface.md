The `MockSoql.Simulator` interface defines custom logic for returning query results. Use this interface when you need more complex logic than what [`MockSoql.StaticResults`](./The-MockSoql.StaticResults-Class) can provide.

Example: This query returns a `List<Task>`, as long as the query is `FROM Task`:

```apex
private class CustomQueryLogic implements MockSoql.Simulator {
	public List<Object> simulateQuery(Soql queryToMock) {
		String fromSObjectName = queryToMock?.entity;
		if (fromSObjectName == Task.SObjectType.toString()) {
			return this.simulateTaskQuery();
		} else if (fromSObjectName == Account.SObjectType.toString()) {
			// You could imagine methods to simulate account queries here:
		} else {
			return new List<Object>();
		}
	}

	private List<Task> simulateTaskQuery() {
		// For each inserted contact, return a Task
		List<Task> results = new List<Task>();
		List<Contact> contacts = (List<Contact>) MockDml.INSERTED.getRecords(Contact.SObjectType);
		for (Contact contact : contacts) {
			Task task = (Task) new MockRecord(Task.SObjectType)
				?.setField(Task.Subject, 'Introductory Call')
				?.setField(Task.WhatId, contact?.AccountId)
				?.setField(Task.WhoId, contact?.Id)
				?.withId()
				?.toSObject();
			results?.add(task);
		}
		return results;
	}
}
```

---

### Methods

- `List<Object> simulateQuery(Soql queryToMock)`

Conditionally return results based on the details of the provided `Soql` argument.
