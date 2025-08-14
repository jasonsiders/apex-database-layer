@SuppressWarnings('PMD.AvoidGlobalModifier')
@IsTest
global class MockCmdt extends Cmdt {
	global Boolean useMocksByDefault = false;

	public MockCmdt(DatabaseLayer factory) {
		// Access this object via the `DatabaseLayer.Cmdt` property
		super(factory);
	}

	global MockCmdt.Repository mock(SObjectType objectType) {
		String objectApiName = objectType?.toString();
		MockCmdt.Repository repository = new MockCmdt.Repository();
		this.repos?.put(objectApiName, repository);
		return repository;
	}

	protected override Cmdt.Repository initRepository(SObjectType objectType) {
		return (this.useMocksByDefault == true) ? this.mock(objectType) : super.initRepository(objectType);
	}

	global class Repository implements Cmdt.Repository {
		private Map<String, SObject> records;

		private Repository() {
			this.records = new Map<String, SObject>{};
		}

		global MockCmdt.Repository add(Map<String, SObject> recordMap) {
			this.records?.putAll(recordMap);
			return this;
		}

		global MockCmdt.Repository add(List<SObject> recordList) {
			Map<String, SObject> records = Cmdt.mapByKey(recordList);
			return this.add(records);
		}

		global MockCmdt.Repository add(SObject record) {
			return this.add(new List<SObject>{ record });
		}

		global MockCmdt.Repository clear() {
			this.records?.clear();
			return this;
		}

		global Map<String, SObject> getAll() {
			return this.records;
		}

		global SObject getInstance(String qualifiedApiName) {
			return this.getAll()?.get(qualifiedApiName);
		}

		global MockCmdt.Repository remove(Set<String> keys) {
			this.records?.keySet()?.removeAll(keys);
			return this;
		}

		global MockCmdt.Repository remove(Map<String, SObject> recordMap) {
			Set<String> keys = recordMap?.keySet();
			return this.remove(keys);
		}

		global MockCmdt.Repository remove(List<SObject> recordList) {
			Map<String, SObject> recordMap = Cmdt.mapByKey(recordList);
			return this.remove(recordMap);
		}

		global MockCmdt.Repository remove(SObject record) {
			return this.remove(new List<SObject>{ record });
		}

		global MockCmdt.Repository remove(String key) {
			return this.remove(new Set<String>{ key });
		}
	}
}
