public abstract class InvocableDmlDeleteRecords {
	@InvocableMethod(
		category='Database Layer'
		label='Delete Record(s)'
		iconName='slds:standard:record_delete'
		configurationEditor='c-dml-property
	)
	public static List<FlowDmlBaseOutput> invoke(List<FlowDmlDeleteInput> inputs) {
		return new List<FlowDmlBaseOutput>{};
	}
}
