public abstract class InvocableSoqlQueryRecords {
	@InvocableMethod(
		category='Database Layer'
		label='SOQL Query'
		iconName='slds:standard:record_lookup'
	)
	public static List<Output> invoke(List<Input> inputs) {
		return new List<Output>{};
	}

	public class Input {
		@InvocableVariable(label='Query' required=true)
		public String query;

		@InvocableVariable(label='Bind Variables')
		public List<FlowDynamicPrimitive> binds;

		public Input() {
			this.binds = new List<FlowDynamicPrimitive>{};
		}
	}

    public class Output {
        @InvocableVariable(label='All Results')
        public List<SObject> allResults;

        @InvocableVariable(label='First Result')
		public SObject firstResult;

		@InvocableVariable(label='Query')
		public String query;

		@InvocableVariable(label='Bind Variables')
		public List<FlowDynamicPrimitive> binds;

		public Output() {
			this.allResults = new List<SObject>{};
			this.binds = new List<FlowDynamicPrimitive>{};
		}

		private Output(Input input) {
			this();
			Soql soql = this.toSoql(input);
			this.binds = input?.binds ?? new List<FlowDynamicPrimitive>{};
			this.query = input?.query;
			this.doQuery(input);
		}

		private void doQuery(Input input) {
			Map<String, Soql.Binder> bindMap = this.getBindMap();
			Soql soql = DatabaseLayer.Soql.newQuery(input?.query)?.addBind(bindMap)?.toString();
			this.query = soql?.toString();
			this.allResults = soql?.query();
			this.firstResult = (allResults?.isEmpty() == false) ? allResults?.get(0) : null;
		}
    }
}