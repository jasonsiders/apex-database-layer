/**
 * @description The DML flow actions' records, with those that match merged into one, since a DML operation rejects a
 * record listed twice, ex: when two interviews update the same parent
 */
public inherited sharing class InvocableDmlRecordPool {
	/** @description The later inputs' copies of each pooled record, merged in once every input is pooled **/
	private Map<Integer, List<SObject>> copiesByPosition;
	/** @description Identifies a record; null matches on Id **/
	private SObjectField matchField;
	/** @description Keyed by the match field's value **/
	private Map<Object, Integer> positionsByKey;
	/** @description The records for the DML operation **/
	private List<SObject> records;

	// **** PUBLIC **** //
	/**
	 * @description Starts an empty pool
	 * @param matchField The field that identifies a record, or null to match on Id
	 */
	public InvocableDmlRecordPool(SObjectField matchField) {
		this.copiesByPosition = new Map<Integer, List<SObject>>{};
		this.matchField = matchField;
		this.positionsByKey = new Map<Object, Integer>{};
		this.records = new List<SObject>{};
	}

	/**
	 * @description Adds a record, or holds it as a copy of the pooled record it matches; a record without a key, ex:
	 * a new one, matches nothing
	 * @param record The record to add
	 * @return The record's position in the pool
	 */
	public Integer add(SObject record) {
		// shortcut: keys match case-sensitively, so external IDs that differ only in case still fail as duplicates;
		// lowercase text keys if flows hit it
		Object key = this.matchField == null ? record?.Id : record?.get(this.matchField);
		Integer position = this.positionsByKey?.get(key);
		if (position == null) {
			position = this.append(record, key);
		} else {
			this.addCopy(position, record);
		}
		return position;
	}

	/**
	 * @description Merges each pooled record's later copies into it, once every input is pooled
	 * @return The records for the DML operation
	 */
	public List<SObject> toRecords() {
		Map<Id, SObject> savedRecords = this.querySavedRecords();
		for (Integer position : this.copiesByPosition?.keySet()) {
			SObject pooled = this.records?.get(position);
			SObject saved = savedRecords?.get(pooled?.Id);
			for (SObject copy : this.copiesByPosition?.get(position)) {
				this.mergeInto(pooled, copy, saved);
			}
		}
		return this.records;
	}

	// **** PRIVATE **** //
	/**
	 * @description Notes the fields a copy disagrees on with the copies before it; copies that agree, or set
	 * different fields, merge without a query
	 * @param record A copy of a pooled record
	 * @param valuesByField The latest value of each field the copies so far hold
	 * @param conflicts Collects the fields the copies disagree on
	 */
	private void addConflicts(SObject record, Map<String, Object> valuesByField, Set<String> conflicts) {
		Map<String, Object> fields = record?.getPopulatedFieldsAsMap();
		for (String fieldName : fields?.keySet()) {
			Object value = fields?.get(fieldName);
			Object other = valuesByField?.get(fieldName);
			Boolean isHeld = valuesByField?.containsKey(fieldName) == true;
			if (
				isHeld &&
				InvocableDmlRecordPool.isFieldValue(value) &&
				InvocableDmlRecordPool.isChanged(value, other)
			) {
				conflicts?.add(fieldName);
			}
			valuesByField?.put(fieldName, value);
		}
	}

	/**
	 * @description Holds a later input's copy of a pooled record, to merge in once every input is pooled
	 * @param position The pooled record's position
	 * @param record The later input's copy
	 */
	private void addCopy(Integer position, SObject record) {
		if (this.copiesByPosition?.containsKey(position) == false) {
			this.copiesByPosition?.put(position, new List<SObject>{});
		}
		this.copiesByPosition?.get(position)?.add(record);
	}

	/**
	 * @description Adds a record that matches none in the pool
	 * @param record The record to add
	 * @param key The record's match field value, or null if it has none
	 * @return The record's position in the pool
	 */
	private Integer append(SObject record, Object key) {
		Integer position = this.records?.size();
		this.records?.add(record);
		if (key != null) {
			this.positionsByKey?.put(key, position);
		}
		return position;
	}

	/**
	 * @description Finds the fields that copies of a pooled record disagree on
	 * @param position The pooled record's position
	 * @return The fields' API names
	 */
	private Set<String> findConflicts(Integer position) {
		Set<String> conflicts = new Set<String>{};
		Map<String, Object> valuesByField = new Map<String, Object>{};
		SObject pooled = this.records?.get(position);
		this.addConflicts(pooled, valuesByField, conflicts);
		for (SObject copy : this.copiesByPosition?.get(position)) {
			this.addConflicts(copy, valuesByField, conflicts);
		}
		return conflicts;
	}

	/**
	 * @description Copies a later input's changes onto the pooled record it matches. A value that still matches the
	 * saved record is stale, ex: read before an earlier input changed the field, so it's skipped; when two inputs
	 * change one field, the later input wins
	 * @param pooled The pooled record
	 * @param record The later input's copy
	 * @param saved The record as saved, with the fields the copies disagree on, or null if none were queried
	 */
	private void mergeInto(SObject pooled, SObject record, SObject saved) {
		Map<String, Object> fields = record?.getPopulatedFieldsAsMap();
		Map<String, Object> savedFields = saved?.getPopulatedFieldsAsMap() ?? new Map<String, Object>{};
		for (String fieldName : fields?.keySet()) {
			Object value = fields?.get(fieldName);
			Object savedValue = savedFields?.get(fieldName);
			Boolean isStale =
				savedFields?.containsKey(fieldName) == true && !InvocableDmlRecordPool.isChanged(value, savedValue);
			if (!isStale) {
				this.setField(pooled, fieldName, value);
			}
		}
	}

	/**
	 * @description Finds the fields that each pooled record's copies disagree on, by object, since each object takes
	 * its own query
	 * @return The fields each saved record's copies disagree on, by Id, by object
	 */
	private Map<SObjectType, Map<Id, Set<String>>> findConflictsByType() {
		Map<SObjectType, Map<Id, Set<String>>> conflictsByType = new Map<SObjectType, Map<Id, Set<String>>>{};
		for (Integer position : this.copiesByPosition?.keySet()) {
			SObject pooled = this.records?.get(position);
			Set<String> conflicts = this.findConflicts(position);
			SObjectType objectType = pooled?.getSObjectType();
			Map<Id, Set<String>> conflictsById = conflictsByType?.get(objectType) ?? new Map<Id, Set<String>>{};
			// shortcut: a record upserted by external ID without an Id can't be read back, so the later input wins on
			// every field; query by the external ID if flows hit it
			if (pooled?.Id != null && conflicts?.isEmpty() == false) {
				conflictsById?.put(pooled?.Id, conflicts);
				conflictsByType?.put(objectType, conflictsById);
			}
		}
		return conflictsByType;
	}

	/**
	 * @description Reads the saved records whose copies disagree, to tell their changes from stale values; copies that
	 * agree, or set different fields, need no query
	 * @return The saved records, by Id
	 */
	private Map<Id, SObject> querySavedRecords() {
		Map<Id, SObject> savedRecords = new Map<Id, SObject>{};
		Map<SObjectType, Map<Id, Set<String>>> conflictsByType = this.findConflictsByType();
		for (SObjectType objectType : conflictsByType?.keySet()) {
			Map<Id, Set<String>> conflictsById = conflictsByType?.get(objectType);
			List<SObject> records = InvocableDmlRecordPool.queryFields(objectType, conflictsById);
			savedRecords?.putAll(records);
		}
		return savedRecords;
	}

	/**
	 * @description Sets one field on a pooled record. Apex can't put some values a queried record holds, ex: formulas,
	 * audit fields, and related records, so those keep the pooled record's value, as queried
	 * @param pooled The pooled record
	 * @param fieldName The field or relationship's API name
	 * @param value The field's value, or the related records
	 */
	private void setField(SObject pooled, String fieldName, Object value) {
		try {
			pooled?.put(fieldName, value);
		} catch (System.SObjectException ignored) {
			// DML wouldn't save the later input's value anyway
		}
	}

	/**
	 * @description Compares field values like DML would save them; `==` ignores case on text, so a change in case alone
	 * would look unchanged
	 * @param value A field value
	 * @param other Another value of the same field
	 * @return Whether the values differ
	 */
	private static Boolean isChanged(Object value, Object other) {
		Boolean isText = value instanceof String && other instanceof String;
		return isText ? !((String) value).equals((String) other) : value != other;
	}

	/**
	 * @description Related records, ex: a Get Records subquery's, aren't fields a query can select
	 * @param value A value from a record's populated fields
	 * @return Whether the value is a field's, not related records'
	 */
	private static Boolean isFieldValue(Object value) {
		return !(value instanceof SObject) && !(value instanceof List<SObject>);
	}

	/**
	 * @description Goes through DatabaseLayer.Soql, so plugins and MockSoql apply. Runs in system mode, since the values
	 * only decide which of the inputs' own values to save, and user mode would fail the action on a field the running
	 * user can't read
	 * @param objectType The object to read
	 * @param conflictsById The fields each record's copies disagree on, by Id
	 * @return The saved records, with those fields
	 */
	private static List<SObject> queryFields(SObjectType objectType, Map<Id, Set<String>> conflictsById) {
		Soql soql = DatabaseLayer.Soql?.newQuery(objectType);
		for (Set<String> conflicts : conflictsById?.values()) {
			for (String fieldName : conflicts) {
				soql?.addSelect(fieldName);
			}
		}
		Set<Id> recordIds = conflictsById?.keySet();
		soql?.addWhere('Id', Soql.IN_COLLECTION, recordIds)?.setAccessLevel(System.AccessLevel.SYSTEM_MODE);
		return soql?.query();
	}
}
