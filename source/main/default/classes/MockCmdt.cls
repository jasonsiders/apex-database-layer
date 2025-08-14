/**
 * @description Mock implementation of Custom Metadata Type (CMDT) operations for testing purposes.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
@IsTest
global class MockCmdt extends Cmdt {
	/**
	 * @description Constructs a new MockCmdt instance with the specified DatabaseLayer factory.
	 * @param factory The DatabaseLayer factory instance for configuration
	 */
	public MockCmdt(DatabaseLayer factory) {
		// Access this object via the `DatabaseLayer.Cmdt` property
		super(factory);
	}

	/**
	 * @description Creates a new mock repository for the specified Custom Metadata type.
	 * @param       objectType The Custom Metadata type to create a mock repository for
	 * @return      A mock repository instance for testing
	 */
	global MockCmdt.Repository mock(SObjectType objectType) {
		MockCmdt.Repository repository = new MockCmdt.Repository();
		this.repos?.put(objectType?.toString(), repository);
		return repository;
	}

	/**
	 * @description Mock repository implementation for managing test CMDT records in memory.
	 */
	global class Repository implements Cmdt.Repository {
		private Map<String, SObject> records;

		private Repository() {
			this.records = new Map<String, SObject>{};
		}

		/**
		 * @description Adds multiple records from a map to the mock repository.
		 * @param recordMap Map of record keys to SObject records
		 * @return This repository instance for method chaining
		 */
		global MockCmdt.Repository add(Map<String, SObject> recordMap) {
			this.records?.putAll(recordMap);
			return this;
		}

		/**
		 * @description Adds multiple records from a list to the mock repository.
		 * @param recordList List of SObject records to add
		 * @return This repository instance for method chaining
		 */
		global MockCmdt.Repository add(List<SObject> recordList) {
			Map<String, SObject> records = Cmdt.mapByKey(recordList);
			return this.add(records);
		}

		/**
		 * @description Adds a single record to the mock repository.
		 * @param record The SObject record to add
		 * @return This repository instance for method chaining
		 */
		global MockCmdt.Repository add(SObject record) {
			return this.add(new List<SObject>{ record });
		}

		/**
		 * @description Removes all records from the mock repository.
		 * @return This repository instance for method chaining
		 */
		global MockCmdt.Repository clear() {
			this.records?.clear();
			return this;
		}

		/**
		 * @description Retrieves all records from the mock repository.
		 * @return Map of all records indexed by their qualified API names
		 */
		global Map<String, SObject> getAll() {
			return this.records;
		}

		/**
		 * @description Retrieves a specific record by its qualified API name.
		 * @param qualifiedApiName The qualified API name of the record to retrieve
		 * @return The SObject record if found, null otherwise
		 */
		global SObject getInstance(String qualifiedApiName) {
			return this.getAll()?.get(qualifiedApiName);
		}

		/**
		 * @description Removes records with the specified keys from the mock repository.
		 * @param keys Set of record keys to remove
		 * @return This repository instance for method chaining
		 */
		global MockCmdt.Repository remove(Set<String> keys) {
			this.records?.keySet()?.removeAll(keys);
			return this;
		}

		/**
		 * @description Removes records specified in the map from the mock repository.
		 * @param recordMap Map containing records to remove
		 * @return This repository instance for method chaining
		 */
		global MockCmdt.Repository remove(Map<String, SObject> recordMap) {
			Set<String> keys = recordMap?.keySet();
			return this.remove(keys);
		}

		/**
		 * @description Removes records specified in the list from the mock repository.
		 * @param recordList List of records to remove
		 * @return This repository instance for method chaining
		 */
		global MockCmdt.Repository remove(List<SObject> recordList) {
			Map<String, SObject> recordMap = Cmdt.mapByKey(recordList);
			return this.remove(recordMap);
		}

		/**
		 * @description Removes a single record from the mock repository.
		 * @param record The SObject record to remove
		 * @return This repository instance for method chaining
		 */
		global MockCmdt.Repository remove(SObject record) {
			return this.remove(new List<SObject>{ record });
		}

		/**
		 * @description Removes a record with the specified key from the mock repository.
		 * @param key The record key to remove
		 * @return This repository instance for method chaining
		 */
		global MockCmdt.Repository remove(String key) {
			return this.remove(new Set<String>{ key });
		}
	}
}
