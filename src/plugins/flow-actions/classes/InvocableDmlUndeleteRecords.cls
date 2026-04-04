public abstract class InvocableDmlUndeleteRecords {
	@InvocableMethod(
		category='Database Layer'
		label='Undelete Record(s)'
		iconName='slds:standard:return_order'
		configurationEditor='c-dml-property
	)
	public static List<FlowDmlBaseOutput> invoke(List<FlowDmlDeleteInput> inputs) {
		return new List<FlowDmlBaseOutput>{};
	}
}
