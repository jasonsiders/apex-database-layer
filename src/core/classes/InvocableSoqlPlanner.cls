/**
 * @description Runs a batch of `SOQL: Get Record(s)` interviews
 */
public inherited sharing class InvocableSoqlPlanner {
	// **** PUBLIC **** //
	/**
	 * @description Runs each interview's query
	 * @param inputs One input per flow interview
	 * @return One output per input, in the same order
	 */
	public List<InvocableSoql.Output> run(List<InvocableSoql.Input> inputs) {
		List<InvocableSoql.Output> outputs = new List<InvocableSoql.Output>{};
		for (InvocableSoql.Input input : inputs) {
			InvocableSoqlQuery query = InvocableSoqlQuery.parse(input?.queryDefinition);
			List<Object> values = query?.resolveValues(input);
			List<SObject> records = query?.toSoql(values, input?.getAccessLevel())?.query();
			String queryString = query?.toQueryString(values);
			outputs?.add(new InvocableSoql.Output(records, queryString));
		}
		return outputs;
	}
}
