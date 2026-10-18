/**
 * @description Flow action that undeletes records via `DatabaseLayer.Dml`, exposing the access level and all-or-none
 * behavior
 */
public inherited sharing class InvocableDmlUndeleteRecords extends InvocableDml {
	// **** PUBLIC **** //
	/**
	 * @description Undeletes every input's records in a single DML operation, using the first input's settings
	 * @param inputs One input per flow interview
	 * @return One output per input, in the same order
	 */
	@InvocableMethod(
		category='Database Layer'
		configurationEditor='c-dml-records-editor'
		description='Restore one or more records from the Recycle Bin, with control over the access level and partial success.'
		iconName='slds:standard:recycle_bin'
		label='Undelete Records'
	)
	public static List<InvocableDml.Output> invoke(List<InvocableDml.Input> inputs) {
		return new InvocableDmlUndeleteRecords()?.run(inputs);
	}

	// **** PROTECTED **** //
	/**
	 * @description Goes through DatabaseLayer.Dml, so plugins and MockDml apply to flows too
	 * @param records The records to undelete
	 * @param settings The input whose settings apply to the operation
	 * @return The results, in record order
	 */
	protected override List<InvocableDmlResult> doDml(List<SObject> records, InvocableDml.Input settings) {
		Boolean allOrNone = settings?.toAllOrNone();
		System.AccessLevel accessLevel = settings?.toAccessLevel();
		List<Database.UndeleteResult> results = DatabaseLayer.Dml?.doUndelete(records, allOrNone, accessLevel);
		return InvocableDmlResult.fromList(results);
	}
}
