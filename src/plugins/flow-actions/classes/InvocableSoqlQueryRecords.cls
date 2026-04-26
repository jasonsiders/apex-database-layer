/**
 * @description Flow action for executing SOQL queries with bulkification support via IN-list transformation.
 */
public abstract class InvocableSoqlQueryRecords {
	/**
	 * @description Invokes the SOQL query action with automatic bulkification for identical queries.
	 * @param inputs List of query inputs containing query strings and bind variables
	 * @return List of query outputs with results populated
	 */
	@InvocableMethod(category='Database Layer' label='SOQL Query' iconName='slds:standard:record_lookup')
	public static List<Output> invoke(List<Input> inputs) {
		List<Output> outputs = new List<Output>{};
		for (Input input : inputs) {
			Output output = new Output(input);
			outputs?.add(output);
		}

		Map<String, List<Integer>> groupsByQuery = new Map<String, List<Integer>>();
		for (Integer i = 0; i < outputs.size(); i++) {
			String queryTemplate = outputs[i].query;
			if (!groupsByQuery.containsKey(queryTemplate)) {
				groupsByQuery.put(queryTemplate, new List<Integer>());
			}
			groupsByQuery.get(queryTemplate).add(i);
		}

		for (List<Integer> indexes : groupsByQuery.values()) {
			executeGroup(outputs, indexes);
		}

		return outputs;
	}

	/**
	 * @description Executes a group of outputs that share the same query template, attempting to bulkify via IN-list transformation.
	 * @param outputs The list of all outputs
	 * @param indexes The indexes of outputs in this group
	 */
	private static void executeGroup(List<Output> outputs, List<Integer> indexes) {
		if (indexes.size() == 1) {
			outputs[indexes[0]].doQuery();
			return;
		}

		Soql.ConditionalLogic whereCriteria = outputs[indexes[0]].soql?.whereCriteria;
		if (whereCriteria == null) {
			executePerInput(outputs, indexes);
			return;
		}

		List<Soql.Criteria> criterion = whereCriteria.getCriterion();
		Soql.Condition pivotCondition = findPivotCondition(criterion);

		if (pivotCondition == null) {
			executePerInput(outputs, indexes);
			return;
		}

		String bindVarName = pivotCondition.value.toString().removeStart(':');
		List<Object> origValues = collectBindValues(outputs, indexes, bindVarName);

		if (valuesAreIdentical(origValues)) {
			executeOnceAndCopy(outputs, indexes);
		} else {
			ExecutionContext ctx = new ExecutionContext(outputs, indexes, pivotCondition, bindVarName, origValues);
			executeWithInList(ctx);
		}
	}

	private static void executePerInput(List<Output> outputs, List<Integer> indexes) {
		for (Integer idx : indexes) {
			outputs[idx].doQuery();
		}
	}

	private static List<Object> collectBindValues(List<Output> outputs, List<Integer> indexes, String bindVarName) {
		List<Object> values = new List<Object>();
		for (Integer idx : indexes) {
			values.add(outputs[idx].soql.binds.get(bindVarName).getValue());
		}
		return values;
	}

	private static Boolean valuesAreIdentical(List<Object> values) {
		Object firstValue = values[0];
		for (Object val : values) {
			Boolean isEqual = (val == null && firstValue == null) || (val != null && val.equals(firstValue));
			if (!isEqual) {
				return false;
			}
		}
		return true;
	}

	/**
	 * @description Finds a single pivot condition suitable for IN-list bulkification.
	 * @param criterion The list of criteria to search
	 * @return The pivot condition if exactly one matches rules, null otherwise
	 */
	private static Soql.Condition findPivotCondition(List<Soql.Criteria> criterion) {
		List<Soql.Condition> candidates = new List<Soql.Condition>();
		for (Soql.Criteria c : criterion) {
			if (!(c instanceof Soql.Condition)) {
				return null;
			}

			Soql.Condition cond = (Soql.Condition) c;
			String opStr = cond.operator?.toString();
			Object val = cond.value;

			if (opStr == '=' && val instanceof String) {
				String strVal = (String) val;
				if (strVal.startsWith(':') && !cond.property.contains('.')) {
					candidates.add(cond);
				}
			}
		}

		if (candidates.size() == 1) {
			return candidates[0];
		}

		return null;
	}

	/**
	 * @description Executes first query once and copies results to all outputs in the group.
	 * @param outputs The list of all outputs
	 * @param indexes The indexes of outputs in this group
	 */
	private static void executeOnceAndCopy(List<Output> outputs, List<Integer> indexes) {
		outputs[indexes[0]].doQuery();
		List<SObject> results = outputs[indexes[0]].allResults;
		SObject firstResult = outputs[indexes[0]].firstResult;

		for (Integer i = 1; i < indexes.size(); i++) {
			outputs[indexes[i]].allResults = results;
			outputs[indexes[i]].firstResult = firstResult;
		}
	}

	/**
	 * @description Executes query with IN-list transformation and redistributes results by pivot field value.
	 * @param ctx Execution context containing outputs, indexes, and pivot condition details
	 */
	private static void executeWithInList(ExecutionContext ctx) {
		Soql.ConditionalLogic newCriteria = new Soql.ConditionalLogic();
		List<Soql.Criteria> criterion = ctx.outputs[ctx.indexes[0]].soql.whereCriteria.getCriterion();

		for (Soql.Criteria c : criterion) {
			if (c == ctx.pivotCondition) {
				newCriteria.addCondition(
					new Soql.Condition(ctx.pivotCondition.property, Soql.IN_COLLECTION, ':' + ctx.bindVarName)
				);
			} else {
				newCriteria.addCondition(c);
			}
		}

		Output executor = ctx.outputs[ctx.indexes[0]];
		executor.soql.setWhereCriteria(newCriteria);
		executor.soql.addBind(ctx.bindVarName, ctx.origValues);
		executor.doQuery();

		Map<Object, List<SObject>> resultsByValue = groupResultsByPivotField(
			executor.allResults,
			ctx.pivotCondition.property
		);

		for (Integer i = 0; i < ctx.indexes.size(); i++) {
			List<SObject> groupResults = resultsByValue.get(ctx.origValues[i]);
			if (groupResults == null) {
				groupResults = new List<SObject>();
			}
			ctx.outputs[ctx.indexes[i]].allResults = groupResults;
			ctx.outputs[ctx.indexes[i]].firstResult = groupResults.isEmpty() ? null : groupResults[0];
		}
	}

	private static Map<Object, List<SObject>> groupResultsByPivotField(List<SObject> results, String pivotProperty) {
		Map<Object, List<SObject>> grouped = new Map<Object, List<SObject>>();
		for (SObject record : results) {
			Object key = record.get(pivotProperty);
			if (!grouped.containsKey(key)) {
				grouped.put(key, new List<SObject>());
			}
			grouped.get(key).add(record);
		}
		return grouped;
	}

	@SuppressWarnings('PMD.ExcessiveParameterList')
	private class ExecutionContext {
		List<Output> outputs;
		List<Integer> indexes;
		Soql.Condition pivotCondition;
		String bindVarName;
		List<Object> origValues;

		private ExecutionContext(
			List<Output> outputs,
			List<Integer> indexes,
			Soql.Condition pivotCondition,
			String bindVarName,
			List<Object> origValues
		) {
			this.outputs = outputs;
			this.indexes = indexes;
			this.pivotCondition = pivotCondition;
			this.bindVarName = bindVarName;
			this.origValues = origValues;
		}
	}

	/**
	 * @description Input structure for SOQL queries with bind variables.
	 */
	public class Input {
		/**
		 * @description The SOQL query string to execute.
		 */
		@InvocableVariable(label='Query' required=true)
		public String query;
		/**
		 * @description List of bind variables for the query.
		 */
		@InvocableVariable(label='Bind Variables')
		public List<FlowUntypedVariable> binds;

		/**
		 * @description Initializes a new Input with an empty binds list.
		 */
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

	/**
	 * @description Output structure for SOQL query results.
	 */
	public class Output {
		/**
		 * @description All records returned by the query.
		 */
		@InvocableVariable(label='All Results')
		public List<SObject> allResults;
		/**
		 * @description The first record from the query results, or null if no results.
		 */
		@InvocableVariable(label='First Result')
		public SObject firstResult;
		/**
		 * @description The rendered SOQL query string with bind variable placeholders.
		 */
		@InvocableVariable(label='Query')
		public String query;
		/**
		 * @description The bind variables used in the query.
		 */
		@InvocableVariable(label='Bind Variables')
		public List<FlowUntypedVariable> binds;
		private transient Soql soql;

		/**
		 * @description Initializes a new Output with empty results and binds.
		 */
		public Output() {
			this.allResults = new List<SObject>{};
			this.binds = new List<FlowUntypedVariable>{};
		}

		/**
		 * @description Initializes Output from an Input, constructing the internal Soql object.
		 * @param input The Input containing query and bind variables
		 */
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
