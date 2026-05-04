/**
 * @description Flow action that provides richer query support than the standard "Get Records" element.
 * Unlike "Get Records", this action accepts raw SOQL strings with named bind variables, enabling
 * parent/child subqueries, complex ORDER BY clauses, and other constructs the standard element cannot express.
 * To stay within SOQL governor limits when Flow processes a record collection, identical query templates
 * are grouped and their bind values are merged into a single IN-list query where possible.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier,PMD.CognitiveComplexity')
global abstract inherited sharing class InvocableSoql {
	/**
	 * @description Invokes the SOQL query action with automatic bulkification for identical queries.
	 * @param inputs List of query inputs containing query strings and bind variables
	 * @return List of query outputs with results populated
	 */
	@InvocableMethod(
		category='Database Layer'
		label='Query Records'
		iconName='slds:standard:record_lookup'
		configurationEditor='c:soqlPropertyEditor'
	)
	global static List<Output> invoke(List<Input> inputs) {
		return new Container(inputs).run();
	}

	/**
	 * @description Method used by the custom property editor to validate query inputs
	 * @param queryToValidate The raw SOQL query to process
	 * @param binds Bind variables included in the invocable configuration
	 * @throws AuraHandledException if any Exception is thrown during query validation
	 */
	@AuraEnabled(cacheable=true)
	global static void validateQuery(String queryToValidate, List<BindVariable> binds) {
		new InvocableSoql.Validator().validate(queryToValidate, binds);
	}

	/**
	 * @description Input structure for SOQL queries with bind variables.
	 */
	global class Input {
		/**
		 * @description Bind variables configured by the custom property editor.
		 */
		@InvocableVariable(label='Bind Variables')
		global List<BindVariable> binds;
		/**
		 * @description The SOQL query string to execute.
		 */
		@InvocableVariable(label='Query' required=true)
		global String query;

		/**
		 * @description Returns a non-null list of configured bind variables.
		 * @return BindVariable objects to use in the query
		 */
		private List<BindVariable> getBinds() {
			return this.binds ?? new List<BindVariable>();
		}
	}

	/**
	 * @description Output structure for SOQL query results.
	 */
	global class Output {
		/**
		 * @description All records returned by the query.
		 */
		@InvocableVariable(label='All Results')
		global List<SObject> allResults;
		/**
		 * @description The first record from the query results, or null if no results.
		 */
		@InvocableVariable(label='First Result')
		global SObject firstResult;
		/**
		 * @description The rendered SOQL query string with bind variable placeholders.
		 */
		@InvocableVariable(label='Query')
		global String query;
		/**
		 * @description The internal SOQL query object used to execute the query.
		 */
		private transient Soql soql;

		/**
		 * @description Initializes a new Output with empty results.
		 */
		global Output() {
			this.allResults = new List<SObject>{};
		}

		/**
		 * @description Initializes Output from an Input, constructing the internal Soql object.
		 * @param input The Input containing query and bind variables
		 */
		private Output(Input input) {
			this();
			this.soql = this.buildSoql(input);
			this.query = this.soql?.toString();
		}

		/**
		 * @description Builds the Soql object from the given Input.
		 * @param input The Input containing the query string and bind variables
		 * @return The constructed and finalized Soql instance
		 */
		private Soql buildSoql(Input input) {
			String query = input?.query;
			Soql soql = DatabaseLayer.Soql.newQuery(query);
			for (BindVariable var : input?.getBinds()) {
				Soql.Binder bind = var?.toSoqlBinder();
				soql?.addBind(bind);
			}
			return soql;
		}

		/**
		 * @description Executes the SOQL query and stores the results.
		 * @return This Output instance, for chaining
		 */
		private Output doQuery() {
			List<SObject> results = this.soql?.query();
			this.setResults(results);
			return this;
		}

		/**
		 * @description Sets allResults and derives firstResult from it.
		 * @param results The query results to store
		 */
		private void setResults(List<SObject> results) {
			this.allResults = results;
			this.firstResult = results?.isEmpty() == false ? results?.get(0) : null;
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
				Output output = new Output(input);
				this.outputs.add(output);
			}
		}

		/**
		 * @description Runs the full bulkified execution: groups by query, then executes each group.
		 * @return The fully populated list of outputs, in original input order
		 */
		public List<Output> run() {
			Map<String, List<Integer>> groups = this.groupByQuery();
			for (List<Integer> indexes : groups.values()) {
				this.executeGroup(indexes);
			}
			return this.outputs;
		}

		/**
		 * @description Resolves the source criteria from the first output, then delegates to replacePivotWithInList.
		 * @param indexes Indexes of the outputs in this group
		 * @param pivotCondition The condition to replace with an IN-list
		 * @return A new ConditionalLogic with the pivot condition replaced
		 */
		private Soql.ConditionalLogic buildInListCriteria(List<Integer> indexes, Soql.Condition pivotCondition) {
			Output firstOutput = this.outputs.get(indexes.get(0));
			List<Soql.Criteria> criterion = firstOutput.soql?.whereCriteria?.getCriterion();
			return this.replacePivotWithInList(criterion, pivotCondition);
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
				Output output = this.outputs.get(index);
				values.add(output.soql?.binds?.get(bindVarName));
			}
			return values;
		}

		/**
		 * @description Copies query results from a source output to all subsequent outputs in the group.
		 * @param indexes Indexes of the outputs in this group
		 * @param source The output whose results to copy
		 */
		private void copyResultsTo(List<Integer> indexes, Output source) {
			for (Integer i = 1; i < indexes.size(); i++) {
				Integer index = indexes.get(i);
				Output output = this.outputs.get(index);
				output.setResults(source.allResults);
			}
		}

		/**
		 * @description Assigns query results back to each output, matching records by pivot field value.
		 * @param indexes Indexes of the outputs to populate
		 * @param bindValues Per-input bind values in index order, used to look up result groups
		 * @param resultsByValue Map of pivot field value to matching records
		 */
		private void distributeResults(
			List<Integer> indexes,
			List<Object> bindValues,
			Map<Object, List<SObject>> resultsByValue
		) {
			for (Integer i = 0; i < indexes.size(); i++) {
				Integer index = indexes.get(i);
				Object bindValue = bindValues.get(i);
				Output output = this.outputs.get(index);
				List<SObject> groupResults = resultsByValue.get(bindValue) ?? new List<SObject>();
				output.setResults(groupResults);
			}
		}

		/**
		 * @description Returns true if two nullable objects are equal.
		 * @param a First object to compare
		 * @param b Second object to compare
		 * @return True if both are null or both are non-null and equal
		 */
		private Boolean equalsFirst(Object a, Object b) {
			return (a == null && b == null) || (a != null && a.equals(b));
		}

		/**
		 * @description Resolves the pivot condition and routes to the appropriate bulk strategy.
		 * @param indexes Indexes of the outputs in this group
		 */
		private void executeBulk(List<Integer> indexes) {
			Soql.Condition pivotCondition = this.resolvePivotCondition(indexes);
			if (pivotCondition == null) {
				this.executePerInput(indexes);
			} else {
				this.executePivotGroup(indexes, pivotCondition);
			}
		}

		/**
		 * @description Routes a group to the appropriate execution strategy based on group size.
		 * @param indexes Indexes of the outputs in this group
		 */
		private void executeGroup(List<Integer> indexes) {
			if (indexes.size() == 1) {
				this.executeSingle(indexes);
			} else {
				this.executeBulk(indexes);
			}
		}

		/**
		 * @description Executes the query for the first output and copies results to the rest of the group.
		 * Used when all inputs in a group have identical bind variable values.
		 * @param indexes Indexes of the outputs in this group
		 */
		private void executeOnceAndCopy(List<Integer> indexes) {
			Output firstOutput = this.outputs.get(indexes.get(0));
			firstOutput.doQuery();
			this.copyResultsTo(indexes, firstOutput);
		}

		/**
		 * @description Executes each output's query individually, without bulkification.
		 * Used as a fallback when IN-list optimization cannot be applied.
		 * @param indexes Indexes of the outputs to execute
		 */
		private void executePerInput(List<Integer> indexes) {
			for (Integer index : indexes) {
				Output output = this.outputs.get(index);
				output.doQuery();
			}
		}

		/**
		 * @description Collects bind values for the pivot field and routes to the appropriate execution strategy.
		 * @param indexes Indexes of the outputs in this group
		 * @param pivotCondition The eligible pivot condition identified for this group
		 */
		private void executePivotGroup(List<Integer> indexes, Soql.Condition pivotCondition) {
			String bindName = pivotCondition.value.toString().removeStart(':');
			List<Object> bindValues = this.collectBindValues(indexes, bindName);
			PivotContext pivot = new PivotContext(pivotCondition, bindName, bindValues);
			Boolean identical = this.valuesAreIdentical(pivot.bindValues);
			if (identical) {
				this.executeOnceAndCopy(indexes);
			} else {
				this.executeWithInList(indexes, pivot);
			}
		}

		/**
		 * @description Executes the query for a single-output group directly.
		 * @param indexes Indexes of the outputs in this group
		 */
		private void executeSingle(List<Integer> indexes) {
			Output output = this.outputs.get(indexes.get(0));
			output.doQuery();
		}

		/**
		 * @description Merges a group of queries into a single IN-list query, then distributes results back.
		 * @param indexes Indexes of the outputs in this group
		 * @param pivot The pivot context for this group
		 */
		private void executeWithInList(List<Integer> indexes, PivotContext pivot) {
			Output executor = this.runMergedQuery(indexes, pivot);
			List<SObject> results = executor.allResults;
			String pivotField = pivot.condition.property;
			Map<Object, List<SObject>> resultsByValue = this.groupResultsByPivotField(results, pivotField);
			this.distributeResults(indexes, pivot.bindValues, resultsByValue);
		}

		/**
		 * @description Delegates pivot condition search to PivotConditionFinder.
		 * @param criterion The WHERE criteria to search
		 * @return The single eligible pivot condition, or null if none or multiple found
		 */
		private Soql.Condition findPivotCondition(List<Soql.Criteria> criterion) {
			PivotConditionFinder finder = new PivotConditionFinder();
			return finder.find(criterion);
		}

		/**
		 * @description Groups output indexes by their rendered query string.
		 * @return Map of query string to list of output indexes with that query
		 */
		private Map<String, List<Integer>> groupByQuery() {
			Map<String, List<Integer>> grouped = new Map<String, List<Integer>>();
			for (Integer i = 0; i < this.outputs.size(); i++) {
				Output output = this.outputs.get(i);
				String template = output.query;
				List<Integer> bucket = grouped.get(template);
				if (bucket == null) {
					bucket = new List<Integer>();
					grouped.put(template, bucket);
				}
				bucket.add(i);
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
				List<SObject> bucket = grouped.get(key);
				if (bucket == null) {
					bucket = new List<SObject>();
					grouped.put(key, bucket);
				}
				bucket.add(record);
			}
			return grouped;
		}

		/**
		 * @description Copies a criteria list, replacing the pivot condition with an IN-list equivalent.
		 * @param criterion The source criteria to copy
		 * @param pivotCondition The condition to replace
		 * @return A new ConditionalLogic with the pivot condition replaced
		 */
		private Soql.ConditionalLogic replacePivotWithInList(
			List<Soql.Criteria> criterion,
			Soql.Condition pivotCondition
		) {
			Soql.ConditionalLogic newCriteria = new Soql.ConditionalLogic();
			for (Soql.Criteria criteria : criterion) {
				Soql.Criteria conditionToAdd = (criteria == pivotCondition)
					? new Soql.Condition(pivotCondition.property, Soql.IN_COLLECTION, pivotCondition.value)
					: criteria;
				newCriteria.addCondition(conditionToAdd);
			}
			return newCriteria;
		}

		/**
		 * @description Resolves the pivot condition from the first output's WHERE criteria.
		 * @param indexes Indexes of the outputs in this group
		 * @return The single eligible pivot condition, or null if none found
		 */
		private Soql.Condition resolvePivotCondition(List<Integer> indexes) {
			Output firstOutput = this.outputs.get(indexes.get(0));
			Soql.ConditionalLogic whereCriteria = firstOutput.soql?.whereCriteria;
			List<Soql.Criteria> criterion = whereCriteria?.getCriterion();
			return (criterion != null) ? this.findPivotCondition(criterion) : null;
		}

		/**
		 * @description Configures and executes the IN-list query on the first output in the group.
		 * @param indexes Indexes of the outputs in this group
		 * @param pivot The pivot context for this group
		 * @return The executor output after running the merged query
		 */
		private Output runMergedQuery(List<Integer> indexes, PivotContext pivot) {
			Soql.ConditionalLogic newCriteria = this.buildInListCriteria(indexes, pivot.condition);
			Output executor = this.outputs.get(indexes.get(0));
			executor.soql?.setWhereCriteria(newCriteria);
			executor.soql?.addBind(pivot.bindName, pivot.bindValues);
			executor.doQuery();
			return executor;
		}

		/**
		 * @description Returns true if all values in the list are equal to each other.
		 * @param values The list of values to compare
		 * @return True if all values are identical, false otherwise
		 */
		private Boolean valuesAreIdentical(List<Object> values) {
			Object firstValue = values?.get(0);
			Boolean allEqual = true;
			for (Object value : values) {
				allEqual = allEqual && this.equalsFirst(value, firstValue);
			}
			return allEqual;
		}
	}

	/**
	 * @description Encapsulates the pivot condition and per-input bind values for IN-list execution.
	 */
	private class PivotContext {
		/**
		 * @description WHERE condition selected as the pivot for IN-list bulkification.
		 */
		private Soql.Condition condition;
		/**
		 * @description Name of the bind variable referenced by the pivot condition.
		 */
		private String bindName;
		/**
		 * @description Per-input bind values collected for the pivot bind variable.
		 */
		private List<Object> bindValues;

		/**
		 * @description Initializes context required to execute a bulkified IN-list query.
		 * @param condition WHERE condition selected as the pivot
		 * @param bindName Name of the bind variable referenced by the pivot condition
		 * @param bindValues Per-input bind values for the pivot bind variable
		 */
		private PivotContext(Soql.Condition condition, String bindName, List<Object> bindValues) {
			this.condition = condition;
			this.bindName = bindName;
			this.bindValues = bindValues;
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
			} else {
				Soql.Condition condition = (Soql.Condition) criteria;
				this.evaluateCondition(condition);
			}
		}

		/**
		 * @description Updates candidate or disqualifies the search based on condition eligibility.
		 * @param condition The condition to evaluate
		 */
		private void evaluateCondition(Soql.Condition condition) {
			Boolean eligible = this.isEligible(condition);
			if (eligible) {
				this.recordCandidate(condition);
			}
		}

		/**
		 * @description Scans all criteria and returns the single eligible pivot condition, or null.
		 * @param criterion The list of WHERE criteria to evaluate
		 * @return The pivot condition if exactly one eligible condition exists, otherwise null
		 */
		private Soql.Condition find(List<Soql.Criteria> criterion) {
			for (Soql.Criteria criteria : criterion) {
				if (!this.disqualified) {
					this.evaluate(criteria);
				}
			}
			return this.disqualified ? null : this.candidate;
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
			if (opStr == '=' && value instanceof String) {
				String strValue = (String) value;
				return strValue?.startsWith(':') == true && condition.property?.contains('.') == false;
			} else {
				return false;
			}
		}

		/**
		 * @description Records the condition as the candidate, or disqualifies if a candidate already exists.
		 * @param condition The eligible condition to record
		 */
		private void recordCandidate(Soql.Condition condition) {
			if (this.candidate != null) {
				this.disqualified = true;
			} else {
				this.candidate = condition;
			}
		}
	}

	/**
	 * @description Responsible for query validation logic from the custom property editor
	 */
	private class Validator {
		/**
		 * @description Constructs a query
		 * @throws AuraHandledException if any Exception is thrown during query validation in an Aura context
		 * @throws Exception if any Exception is thrown during any other execution context
		 */
		public void validate(String queryString, List<BindVariable> binds) {
			try {
				Soql soql = DatabaseLayer.Soql.newQuery(queryString);
				this.applyDummyBinds(soql, binds);
				soql?.queryFirst();
			} catch (Exception anyError) {
				throw this.getException(anyError);
			}
		}

		/**
		 * @description Applies null/empty bind variables to the given queries, for validation purposes
		 */
		private void applyDummyBinds(Soql query, List<BindVariable> binds) {
			for (BindVariable bind : binds ?? new List<BindVariable>()) {
				Object dummyValue = (bind?.isCollection == true) ? bind?.getType()?.newInstance() : null;
				query?.addBind(bind?.key, dummyValue);
			}
		}

		/**
		 * @description Wraps an Exception in an AuraHandledException if called from Aura
		 * @return The proper Exception object, depending on the execution context
		 */
		private Exception getException(Exception originalError) {
			String msg = originalError?.getMessage();
			Boolean shouldWrap = System.Request.getCurrent().getQuiddity() == System.Quiddity.AURA;
			return (shouldWrap) ? new AuraHandledException(msg) : originalError;
		}
	}
}
