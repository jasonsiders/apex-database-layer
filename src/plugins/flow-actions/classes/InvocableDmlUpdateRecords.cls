public abstract class InvocableDmlUpdateRecords {
	@InvocableMethod(
		category='Database Layer'
		label='Update Record(s)'
		iconName='slds:standard:record_update'
		configurationEditor='c-dml-property
	)
	public static List<FlowDmlBaseOutput> invoke(List<FlowDmlBaseInput> inputs) {
		return new List<FlowDmlBaseOutput>{};
	}
}
