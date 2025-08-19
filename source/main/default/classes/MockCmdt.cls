@SuppressWarnings('PMD.AvoidGlobalModifier')
@IsTest
global class MockCmdt {
    /**
	 * @description Creates and configures a MockCmdt.Repository for the specified Custom Metadata Type.
	 * This allows mocking CMDT records in tests without database operations.
	 * @param objectType The SObjectType of the Custom Metadata Type to mock
	 * @return A MockCmdt.Repository instance that can be configured with test data
	 */
	global static MockCmdt.Repository mock(SObjectType objectType) {
		String objectApiName = objectType?.toString();
		Cmdt.Repository existingRepo = Cmdt.repos?.get(objectApiName);
		MockCmdt.Repository results;
		if (existingRepo instanceof MockCmdt.Repository) {
			results = (MockCmdt.Repository) existingRepo;
		} else {
			results = new MockCmdt.Repository(objectType);
			Cmdt.repos?.put(objectApiName, results);
		}
		return results;
	}

	/**
	 * @description Remove an SObjectType from the list of repos. The `ofType` method will re-run the retrieval logic for that object
	 * @param objectType The SObjectType to reset
	 */
	global static void reset(SObjectType objectType) {
		String objectApiName = objectType?.toString();
		Cmdt.repos?.remove(objectApiName);
	}

	// **** INNER **** //
	/**
	 * @description Mock implementation of the Cmdt.Repository interface for testing purposes.
	 * Allows in-memory storage and manipulation of Custom Metadata Type records without database operations.
	 */
	global class Repository extends Cmdt.CacheBasedRepository {
		private Repository(SObjectType objectType) {
			super(objectType);
			// Note: Setting to a non-null value bypasses any/all queries in the parent class
			this.records = new Map<String, SObject>{};
		}

		/**
		 * @description Adds multiple records from a list to the mock repository.
		 * @param recordList List of SObject records to add
		 * @return This repository instance for method chaining
		 */
		global MockCmdt.Repository add(List<SObject> recordList) {
			Map<String, SObject> recordMap = Cmdt.mapByKey(recordList);
			this.records?.putAll(recordMap);
			return this;
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