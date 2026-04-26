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
		return new Container(inputs).run();
	}

	/**
	 * @description Input structure for SOQL queries with bind variables.
	 */
	public class Input {
		/**
		 * @description List of bind variables for the query.
		 */
		@InvocableVariable(label='Bind Variables')
		public List<FlowUntypedVariable> binds;
		/**
		 * @description The SOQL query string to execute.
		 */
		@InvocableVariable(label='Query' required=true)
		public String query;

		/**
		 * @description Initializes a new Input with an empty binds list.
		 */
		public Input() {
			this.binds = new List<FlowUntypedVariable>{};
		}

		private Map<String, Soql.Binder> getBindsByName() {
			Map<String, Soql.Binder> results = new Map<String, Soql.Binder>{};
			for (FlowUntypedVariable bind : this.binds) {
				String key = bind?.key;
				Object value = bind?.getValue();
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
		 * @description The bind variables used in the query.
		 */
		@InvocableVariable(label='Bind Variables')
		public List<FlowUntypedVariable> binds;
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

	private class Container {
		private List<Output> outputs;

		private Container(List<Input> inputs) {
			this.outputs = new List<Output>{};
			for (Input input : inputs) {
				this.outputs.add(new Output(input));
			}
		}

		private Soql.ConditionalLogic buildInListCriteria(
			List<Integer> indexes,
			Soql.Condition pivotCondition,
			String bindVarName
		) {
			Soql.ConditionalLogic newCriteria = new Soql.ConditionalLogic();
			List<Soql.Criteria> criterion = this.outputs[indexes[0]].soql.whereCriteria.getCriterion();
			for (Soql.Criteria criteria : criterion) {
				if (criteria == pivotCondition) {
					newCriteria.addCondition(
						new Soql.Condition(pivotCondition.property, Soql.IN_COLLECTION, ':' + bindVarName)
					);
				} else {
					newCriteria.addCondition(criteria);
				}
			}
			return newCriteria;
		}

		private List<Object> collectBindValues(List<Integer> indexes, String bindVarName) {
			List<Object> values = new List<Object>();
			for (Integer index : indexes) {
				Output output = this.outputs?.get(index);
				Soql.Binder binder = (Soql.Binder) output.soql.binds?.get(bindVarName);
				values.add(binder.getValue());
			}
			return values;
		}

		private void distributeResults(
			List<Integer> indexes,
			List<Object> origValues,
			Map<Object, List<SObject>> resultsByValue
		) {
			for (Integer i = 0; i < indexes.size(); i++) {
				Integer index = indexes?.get(i);
				Output output = this.outputs?.get(index);
				List<SObject> groupResults = resultsByValue?.get(origValues[i]) ?? new List<SObject>();
				output.allResults = groupResults;
				output.firstResult = groupResults.isEmpty() ? null : groupResults[0];
			}
		}

		private void executeGroup(List<Integer> indexes) {
			if (indexes.size() == 1) {
				this.outputs[indexes[0]].doQuery();
				return;
			}
			Soql.ConditionalLogic whereCriteria = this.outputs[indexes[0]].soql?.whereCriteria;
			if (whereCriteria == null) {
				this.executePerInput(indexes);
				return;
			}
			List<Soql.Criteria> criterion = whereCriteria.getCriterion();
			Soql.Condition pivotCondition = this.findPivotCondition(criterion);
			if (pivotCondition == null) {
				this.executePerInput(indexes);
				return;
			}
			String bindVarName = pivotCondition.value.toString().removeStart(':');
			List<Object> origValues = this.collectBindValues(indexes, bindVarName);
			if (this.valuesAreIdentical(origValues)) {
				this.executeOnceAndCopy(indexes);
			} else {
				this.executeWithInList(indexes, pivotCondition, bindVarName, origValues);
			}
		}

		private void executeOnceAndCopy(List<Integer> indexes) {
			Integer firstIndex = indexes?.get(0);
			Output firstOutput = this.outputs?.get(firstIndex);
			firstOutput.doQuery();
			List<SObject> results = firstOutput.allResults;
			SObject firstResult = firstOutput.firstResult;
			for (Integer i = 1; i < indexes.size(); i++) {
				Integer index = indexes?.get(i);
				Output output = this.outputs?.get(index);
				output.allResults = results;
				output.firstResult = firstResult;
			}
		}

		private void executePerInput(List<Integer> indexes) {
			for (Integer index : indexes) {
				Output output = this.outputs?.get(index);
				output.doQuery();
			}
		}

		private void executeWithInList(
			List<Integer> indexes,
			Soql.Condition pivotCondition,
			String bindVarName,
			List<Object> origValues
		) {
			Soql.ConditionalLogic newCriteria = this.buildInListCriteria(indexes, pivotCondition, bindVarName);
			Output executor = this.outputs?.get(indexes?.get(0));
			executor.soql.setWhereCriteria(newCriteria);
			executor.soql.addBind(bindVarName, origValues);
			executor.doQuery();
			Map<Object, List<SObject>> resultsByValue = this.groupResultsByPivotField(
				executor.allResults,
				pivotCondition.property
			);
			this.distributeResults(indexes, origValues, resultsByValue);
		}

		private Soql.Condition findPivotCondition(List<Soql.Criteria> criterion) {
			Soql.Condition candidate = null;
			for (Soql.Criteria criteria : criterion) {
				if ((criteria instanceof Soql.Condition) == false) {
					return null;
				}
				Soql.Condition condition = (Soql.Condition) criteria;
				String opStr = condition.operator?.toString();
				Object value = condition.value;
				if (opStr != '=' || (value instanceof String) == false) {
					continue;
				}
				String strValue = (String) value;
				if (strValue?.startsWith(':') == false || condition.property.contains('.')) {
					continue;
				}
				if (candidate != null) {
					return null;
				}
				candidate = condition;
			}
			return candidate;
		}

		private Map<String, List<Integer>> groupByQuery() {
			Map<String, List<Integer>> grouped = new Map<String, List<Integer>>();
			for (Integer i = 0; i < this.outputs.size(); i++) {
				String template = this.outputs[i].query;
				if (grouped?.containsKey(template) == false) {
					grouped.put(template, new List<Integer>());
				}
				grouped.get(template).add(i);
			}
			return grouped;
		}

		private Map<Object, List<SObject>> groupResultsByPivotField(List<SObject> results, String pivotProperty) {
			Map<Object, List<SObject>> grouped = new Map<Object, List<SObject>>();
			for (SObject record : results) {
				Object key = record.get(pivotProperty);
				if (grouped?.containsKey(key) == false) {
					grouped.put(key, new List<SObject>());
				}
				grouped.get(key).add(record);
			}
			return grouped;
		}

		private List<Output> run() {
			Map<String, List<Integer>> groups = this.groupByQuery();
			for (List<Integer> indexes : groups.values()) {
				this.executeGroup(indexes);
			}
			return this.outputs;
		}

		private Boolean valuesAreIdentical(List<Object> values) {
			Object firstValue = values[0];
			for (Object value : values) {
				Boolean isEqual = (value == null && firstValue == null) || (value != null && value.equals(firstValue));
				if (isEqual == false) {
					return false;
				}
			}
			return true;
		}
	}
}
