/**
 * @description Flow action that upserts records via `DatabaseLayer.Dml`, exposing the external ID field, access level, and
 * all-or-none behavior
 */
public inherited sharing class InvocableDmlUpsertRecords extends InvocableDml {
	// **** PUBLIC **** //
	/**
	 * @description Upserts every input's records in a single DML operation, using the first input's settings
	 * @param inputs One input per flow interview
	 * @return One output per input, in the same order
	 */
	@InvocableMethod(
		category='Database Layer'
		configurationEditor='c-dml-records-editor'
		description='Insert or update one or more records, matched by ID or an external ID field, with control over the access level and partial success.'
		iconName='slds:standard:record_update'
		label='Upsert Records'
	)
	public static List<InvocableDml.Output> invoke(List<InvocableDml.Input> inputs) {
		return new InvocableDmlUpsertRecords()?.run(inputs);
	}

	// **** PROTECTED **** //
	/**
	 * @description Goes through DatabaseLayer.Dml, so plugins and MockDml apply to flows too
	 * @param records The records to upsert
	 * @param settings The input whose settings apply to the operation
	 * @return The results, in record order
	 */
	protected override List<InvocableDmlResult> doDml(List<SObject> records, InvocableDml.Input settings) {
		SObjectField externalIdField = InvocableDmlUpsertRecords.getExternalIdField(records, settings?.externalIdField);
		Boolean allOrNone = settings?.toAllOrNone();
		System.AccessLevel accessLevel = settings?.toAccessLevel();
		List<Database.UpsertResult> results = DatabaseLayer.Dml
			?.doUpsert(records, externalIdField, allOrNone, accessLevel);
		return InvocableDmlResult.fromList(results);
	}

	// **** PRIVATE **** //
	/**
	 * @description Flow passes the field by name; an unknown name throws, since upserting on Ids instead could duplicate
	 * records
	 * @param records The records to upsert; the first one supplies the object
	 * @param fieldName The external ID field API name, or blank to match on Id
	 * @return The field, or null when the name is blank
	 */
	private static SObjectField getExternalIdField(List<SObject> records, String fieldName) {
		SObjectField field;
		if (String.isNotBlank(fieldName)) {
			SObjectType objectType = records?.get(0)?.getSObjectType();
			Map<String, SObjectField> fields = objectType
				?.getDescribe(SObjectDescribeOptions.DEFERRED)
				?.fields
				?.getMap();
			field = fields?.get(fieldName?.trim());
			if (field == null) {
				throw new IllegalArgumentException('Invalid external ID field for ' + objectType + ': ' + fieldName);
			}
		}
		return field;
	}
}
