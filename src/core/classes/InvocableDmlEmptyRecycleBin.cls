/**
 * @description Flow action that permanently deletes records from the Recycle Bin via `DatabaseLayer.Dml`
 */
public inherited sharing class InvocableDmlEmptyRecycleBin extends InvocableDml {
	/** @description Only the invocable method creates instances, so callers go through it, like Flow does **/
	@SuppressWarnings('PMD.EmptyStatementBlock')
	private InvocableDmlEmptyRecycleBin() {
		// Nothing to initialize
	}

	// **** PUBLIC **** //
	/**
	 * @description Permanently deletes every input's records in a single DML operation, so a bulk run can't exhaust
	 * the DML statement limit
	 * @param inputs One input per flow interview
	 * @return One output per input, in the same order
	 */
	@InvocableMethod(
		category='Database Layer'
		configurationEditor='c-dml-records-editor'
		description='Permanently delete one or more records that are already in the Recycle Bin.'
		iconName='slds:standard:recycle_bin'
		label='DML: Empty Recycle Bin'
	)
	public static List<InvocableDml.Output> invoke(List<InvocableDml.Input> inputs) {
		return new InvocableDmlEmptyRecycleBin()?.run(inputs);
	}

	// **** PROTECTED **** //
	/**
	 * @description Goes through DatabaseLayer.Dml, so plugins and MockDml apply to flows too
	 * @param records The deleted records to remove from the Recycle Bin
	 * @param settings The input whose settings apply to the operation
	 * @return The results, in record order
	 */
	protected override List<InvocableDmlResult> doDml(List<SObject> records, InvocableDml.Input settings) {
		List<Database.EmptyRecycleBinResult> results = DatabaseLayer.Dml?.emptyRecycleBin(records);
		return InvocableDmlResult.fromList(results);
	}
}
