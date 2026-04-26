/**
 * @description Flow action that provides richer query support than the standard "Get Records" element.
 * Unlike "Get Records", this action accepts raw SOQL strings with named bind variables, enabling
 * parent/child subqueries, complex ORDER BY clauses, and other constructs the standard element cannot express.
 * To stay within SOQL governor limits when Flow processes a record collection, identical query templates
 * are grouped and their bind values are merged into a single IN-list query where possible.
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

		/**
		 * @description Converts the list of bind variables into a map keyed by bind variable name.
		 * @return Map of bind variable name to Soql.Binder
		 */
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
		/**
		 * @description The internal SOQL query object used to execute the query.
		 */
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

		/**
		 * @description Executes the SOQL query and populates allResults and firstResult.
		 * @return This Output instance, for chaining
		 */
		private Output doQuery() {
			this.allResults = this.soql?.query();
			this.firstResult = (allResults?.isEmpty() == false) ? allResults?.get(0) : null;
			return this;
		}
	}

	/**
	 * @description Orchestrates bulkified execution of a batch of SOQL queries,
	 * grouping identical queries and applying IN-list optimization where possible.
	 */
	private class Container {
		/**
		 * @description The list of Output objects, one per input, in original order.
		 */
		private List<Output> outputs;

		/**
		 * @description Builds Outputs from the given inputs, one per input.
		 * @param inputs The list of Input objects to process
		 */
		private Container(List<Input> inputs) {
			this.outputs = new List<Output>{};
			for (Input input : inputs) {
				this.outputs.add(new Output(input));
			}
		}

		/**
		 * @description Builds a new WHERE criteria replacing the pivot condition with an IN-list bind.
		 * @param indexes Indexes of the outputs in this group
		 * @param pivotCondition The condition to replace with an IN-list
		 * @param bindVarName The bind variable name for the IN-list
		 * @return A new ConditionalLogic with the pivot condition replaced
		 */
		private Soql.ConditionalLogic buildInListCriteria(
			List<Integer> indexes,
			Soql.Condition pivotCondition,
			String bindVarName
		) {
			Soql.ConditionalLogic newCriteria = new Soql.ConditionalLogic();
			List<Soql.Criteria> criterion = this.outputs?.get(indexes?.get(0)).soql.whereCriteria.getCriterion();
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

		/**
		 * @description Collects the bind variable value for each indexed output.
		 * @param indexes Indexes of the outputs to collect from
		 * @param bindVarName The bind variable name to look up
		 * @return Ordered list of bind values, one per index
		 */
		private List<Object> collectBindValues(List<Integer> indexes, String bindVarName) {
			List<Object> values = new List<Object>();
			for (Integer index : indexes) {
				Output output = this.outputs?.get(index);
				Soql.Binder binder = (Soql.Binder) output.soql.binds?.get(bindVarName);
				values.add(binder.getValue());
			}
			return values;
		}

		/**
		 * @description Assigns query results back to each output, matching records by pivot field value.
		 * @param indexes Indexes of the outputs to populate
		 * @param origValues Original bind values in index order, used to look up result groups
		 * @param resultsByValue Map of pivot field value to matching records
		 */
		private void distributeResults(
			List<Integer> indexes,
			List<Object> origValues,
			Map<Object, List<SObject>> resultsByValue
		) {
			for (Integer i = 0; i < indexes.size(); i++) {
				Integer index = indexes?.get(i);
				Output output = this.outputs?.get(index);
				List<SObject> groupResults = resultsByValue?.get(origValues?.get(i)) ?? new List<SObject>();
				output.allResults = groupResults;
				output.firstResult = groupResults?.isEmpty() ? null : groupResults?.get(0);
			}
		}

		/**
		 * @description Executes the appropriate query strategy for a group of identical queries.
		 * Single inputs are queried directly; groups are bulkified via IN-list where possible.
		 * @param indexes Indexes of the outputs in this group
		 */
		private void executeGroup(List<Integer> indexes) {
			if (indexes.size() == 1) {
				this.outputs?.get(indexes?.get(0)).doQuery();
				return;
			}
			Soql.ConditionalLogic whereCriteria = this.outputs?.get(indexes?.get(0)).soql?.whereCriteria;
			Soql.Condition pivotCondition = (whereCriteria != null)
				? this.findPivotCondition(whereCriteria.getCriterion())
				: null;
			if (pivotCondition == null) {
				this.executePerInput(indexes);
				return;
			}
			String bindVarName = pivotCondition.value.toString().removeStart(':');
			List<Object> origValues = this.collectBindValues(indexes, bindVarName);
			if (this.valuesAreIdentical(origValues)) {
				this.executeOnceAndCopy(indexes);
			} else {
				this.executeWithInList(indexes, pivotCondition, origValues);
			}
		}

		/**
		 * @description Executes the query for the first output and copies results to all others in the group.
		 * Used when all inputs in a group have identical bind variable values.
		 * @param indexes Indexes of the outputs in this group
		 */
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

		/**
		 * @description Executes each output's query individually, without bulkification.
		 * Used as a fallback when IN-list optimization cannot be applied.
		 * @param indexes Indexes of the outputs to execute
		 */
		private void executePerInput(List<Integer> indexes) {
			for (Integer index : indexes) {
				Output output = this.outputs?.get(index);
				output.doQuery();
			}
		}

		/**
		 * @description Merges a group of queries into a single IN-list query, then distributes results back.
		 * @param indexes Indexes of the outputs in this group
		 * @param pivotCondition The condition to transform into an IN-list
		 * @param origValues Original bind values in index order
		 */
		private void executeWithInList(List<Integer> indexes, Soql.Condition pivotCondition, List<Object> origValues) {
			String bindVarName = pivotCondition.value.toString().removeStart(':');
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

		/**
		 * @description Delegates pivot condition search to PivotConditionFinder.
		 * @param criterion The WHERE criteria to search
		 * @return The single eligible pivot condition, or null if none or multiple found
		 */
		private Soql.Condition findPivotCondition(List<Soql.Criteria> criterion) {
			return new PivotConditionFinder().find(criterion);
		}

		/**
		 * @description Groups output indexes by their rendered query string.
		 * @return Map of query string to list of output indexes with that query
		 */
		private Map<String, List<Integer>> groupByQuery() {
			Map<String, List<Integer>> grouped = new Map<String, List<Integer>>();
			for (Integer i = 0; i < this.outputs.size(); i++) {
				String template = this.outputs?.get(i).query;
				if (grouped?.containsKey(template) == false) {
					grouped.put(template, new List<Integer>());
				}
				grouped.get(template).add(i);
			}
			return grouped;
		}

		/**
		 * @description Groups query results by the value of the pivot field.
		 * @param results The records returned by the bulkified query
		 * @param pivotProperty The field API name used as the grouping key
		 * @return Map of field value to matching records
		 */
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

		/**
		 * @description Runs the full bulkified execution: groups by query, then executes each group.
		 * @return The fully populated list of outputs, in original input order
		 */
		private List<Output> run() {
			Map<String, List<Integer>> groups = this.groupByQuery();
			for (List<Integer> indexes : groups.values()) {
				this.executeGroup(indexes);
			}
			return this.outputs;
		}

		/**
		 * @description Returns true if all values in the list are equal to each other.
		 * @param values The list of values to compare
		 * @return True if all values are identical, false otherwise
		 */
		private Boolean valuesAreIdentical(List<Object> values) {
			Object firstValue = values?.get(0);
			for (Object value : values) {
				Boolean isEqual = (value == null && firstValue == null) || (value != null && value.equals(firstValue));
				if (isEqual == false) {
					return false;
				}
			}
			return true;
		}
	}

	/**
	 * @description Scans a list of WHERE criteria to find the single condition eligible for IN-list bulkification.
	 * A condition is eligible if it uses equality (=), its value is a named bind variable (:name),
	 * and its field is not a relationship traversal (no dot). Returns null if any non-Condition criteria
	 * is present or if more than one eligible condition is found.
	 */
	private class PivotConditionFinder {
		/**
		 * @description The single eligible pivot condition found so far, or null if none yet.
		 */
		private Soql.Condition candidate;
		/**
		 * @description True when the search has been disqualified and cannot produce a valid result.
		 */
		private Boolean disqualified;

		/**
		 * @description Initializes the finder in a clean, unqualified state.
		 */
		private PivotConditionFinder() {
			this.disqualified = false;
		}

		/**
		 * @description Evaluates a single criteria entry, updating candidate or disqualifying the search.
		 * @param criteria The criteria to evaluate
		 */
		private void evaluate(Soql.Criteria criteria) {
			if ((criteria instanceof Soql.Condition) == false) {
				this.disqualified = true;
				return;
			}
			Soql.Condition condition = (Soql.Condition) criteria;
			if (this.isEligible(condition) == false) {
				return;
			}
			if (this.candidate != null) {
				this.disqualified = true;
				return;
			}
			this.candidate = condition;
		}

		/**
		 * @description Scans all criteria and returns the single eligible pivot condition, or null.
		 * @param criterion The list of WHERE criteria to evaluate
		 * @return The pivot condition if exactly one eligible condition exists, otherwise null
		 */
		private Soql.Condition find(List<Soql.Criteria> criterion) {
			for (Soql.Criteria criteria : criterion) {
				this.evaluate(criteria);
				if (this.disqualified) {
					return null;
				}
			}
			return this.candidate;
		}

		/**
		 * @description Returns true if the condition is eligible as a pivot: equality operator,
		 * bind variable value, and no relationship traversal in the field name.
		 * @param condition The condition to check
		 * @return True if eligible, false otherwise
		 */
		private Boolean isEligible(Soql.Condition condition) {
			String opStr = condition.operator?.toString();
			Object value = condition.value;
			if (opStr != '=' || (value instanceof String) == false) {
				return false;
			}
			String strValue = (String) value;
			return strValue?.startsWith(':') && condition.property.contains('.') == false;
		}
	}
}
