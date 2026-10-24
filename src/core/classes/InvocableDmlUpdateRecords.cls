/**
 * @description Flow action that updates records via `DatabaseLayer.Dml`, exposing the access level, all-or-none
 * behavior, and every `Database.DmlOptions` setting
 */
public inherited sharing class InvocableDmlUpdateRecords extends InvocableDml {
	// **** PUBLIC **** //
	/**
	 * @description Updates every input's records in a single DML operation, using the first input's settings
	 * @param inputs One input per flow interview
	 * @return One output per input, in the same order
	 */
	@InvocableMethod(
		category='Database Layer'
		configurationEditor='c-dml-records-editor'
		description='Update one or more records, with control over the access level, partial success, and DML options.'
		iconName='slds:standard:record_update'
		label='Update Records'
	)
	public static List<InvocableDml.Output> invoke(List<InvocableDml.Input> inputs) {
		return new InvocableDmlUpdateRecords()?.run(inputs);
	}

	// **** PROTECTED **** //
	/**
	 * @description Goes through DatabaseLayer.Dml, so plugins and MockDml apply to flows too
	 * @param records The records to update
	 * @param settings The input whose settings apply to the operation
	 * @return The results, in record order
	 */
	protected override List<InvocableDmlResult> doDml(List<SObject> records, InvocableDml.Input settings) {
		Database.DmlOptions options = settings?.toDmlOptions();
		System.AccessLevel accessLevel = settings?.toAccessLevel();
		List<Database.SaveResult> results = DatabaseLayer.Dml?.doUpdate(records, options, accessLevel);
		return InvocableDmlResult.fromList(results);
	}
}
