/**
 * @description Flow action that deletes records via `DatabaseLayer.Dml`, exposing the access level and all-or-none
 * behavior
 */
public inherited sharing class InvocableDmlDeleteRecords extends InvocableDml {
	/** @description Only the invocable method creates instances, so callers go through it, like Flow does **/
	@SuppressWarnings('PMD.EmptyStatementBlock')
	private InvocableDmlDeleteRecords() {
		// Nothing to initialize
	}

	// **** PUBLIC **** //
	/**
	 * @description Deletes every input's records in a single DML operation, using the first input's settings, so a
	 * bulk run can't exhaust the DML statement limit
	 * @param inputs One input per flow interview
	 * @return One output per input, in the same order
	 */
	@InvocableMethod(
		category='Database Layer'
		configurationEditor='c-dml-records-editor'
		description='Delete one or more records, with control over the access level and partial success.'
		iconName='slds:standard:record_delete'
		label='DML: Delete Record(s)'
	)
	public static List<InvocableDml.Output> invoke(List<InvocableDml.Input> inputs) {
		return new InvocableDmlDeleteRecords()?.run(inputs);
	}

	// **** PROTECTED **** //
	/**
	 * @description Goes through DatabaseLayer.Dml, so plugins and MockDml apply to flows too
	 * @param records The records to delete
	 * @param settings The input whose settings apply to the operation
	 * @return The results, in record order
	 */
	protected override List<InvocableDmlResult> doDml(List<SObject> records, InvocableDml.Input settings) {
		Boolean allOrNone = settings?.getAllOrNone();
		System.AccessLevel accessLevel = settings?.getAccessLevel();
		List<Database.DeleteResult> results = DatabaseLayer.Dml?.doDelete(records, allOrNone, accessLevel);
		return InvocableDmlResult.fromList(results);
	}
}
