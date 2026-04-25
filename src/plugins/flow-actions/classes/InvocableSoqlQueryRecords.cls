public abstract class InvocableSoqlQueryRecords {
	@InvocableMethod(
		category='Database Layer'
		label='SOQL Query'
		iconName='slds:standard:record_lookup'
	)
	public static List<Output> invoke(List<Input> inputs) {
		List<Output> outputs = new List<Output>{};
		for (Input input : inputs) {
			Output output = new Output(input)?.doQuery();
			outputs?.add(output);
		}
		return outputs;
	}

	public class Input {
		@InvocableVariable(label='Query' required=true)
		public String query;
		@InvocableVariable(label='Bind Variables')
		public List<FlowUntypedVariable> binds;

		public Input() {
			this.binds = new List<FlowUntypedVariable>{};
		}

		private Map<String, Soql.Binder> getBindsByName() {
			Map<String, Soql.Binder> results = new Map<String, Soql.Binder>{};
			for (FlowUntypedVariable var : this.binds) {
				String key = var?.key;
				Object value = var?.getValue();
				Soql.Binder binder = new Soql.Binder(key, value);
				results?.put(key, binder);
			}
			return results;
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
		public List<FlowUntypedVariable> binds;
		private transient Soql soql;

		public Output() {
			this.allResults = new List<SObject>{};
			this.binds = new List<FlowUntypedVariable>{};
		}

		private Output(Input input) {
			this();
			this.binds = input?.binds; 
			Map<String, Soql.Binder> bindMap = input?.getBindsByName();
			this.soql = DatabaseLayer.Soql.newQuery(input?.query)?.addBind(bindMap)?.toSoql();
			this.query = this.soql?.toString();
		}

		private Output doQuery() {
			this.allResults = this.soql?.query();
			this.firstResult = (allResults?.isEmpty() == false) ? allResults?.get(0) : null;
			return this;
		}
    }
}