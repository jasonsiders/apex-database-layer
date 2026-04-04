public abstract class InvocableDmlPurgeRecords {
	@InvocableMethod(
		category='Database Layer'
		label='Purge Record(s) From Recycle Bin'
		iconName='slds:standard:recycle_bin'
		configurationEditor='c-dml-property-editor'
	)
	public static List<FlowDmlBaseOutput> invoke(List<FlowDmlDeleteInput> inputs) {
		return new List<FlowDmlBaseOutput>{};
	}
}
