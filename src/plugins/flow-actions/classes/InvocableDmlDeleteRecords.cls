public abstract class InvocableDmlDeleteRecords {
	@InvocableMethod(
		category='Database Layer'
		label='Delete Record(s)'
		iconName='slds:standard:record_delete'
		configurationEditor='c-flow-dml-property-editor'
	)
	public static List<FlowDmlBaseOutput> invoke(List<FlowDmlDeleteInput> inputs) {
		return new List<FlowDmlBaseOutput>{};
	}
}
