/**
 * @description Handles all SOQL query operations with the Salesforce database. Provides a mockable, fluent query builder interface with comprehensive operator support and plugin capabilities.
 */
@SuppressWarnings(
	'PMD.AvoidGlobalModifier,PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.ExcessiveClassLength,PMD.ExcessivePublicCount'
)
global inherited sharing virtual class Soql extends Soql.Builder {
	// These operators are frequently used in WHERE clauses
	global static final Operator EQUALS = new Soql.Operator('=');
	global static final Operator NOT_EQUALS = new Soql.Operator('!=');
	global static final Operator IN_COLLECTION = new Soql.Operator('IN');
	global static final Operator NOT_IN_COLLECTION = new Soql.Operator('NOT IN');
	global static final Operator GREATER_THAN = new Soql.Operator('>');
	global static final Operator GREATER_OR_EQUAL = new Soql.Operator('>=');
	global static final Operator LESS_THAN = new Soql.Operator('<');
	global static final Operator LESS_OR_EQUAL = new Soql.Operator('<=');
	global static final Operator STARTS_WITH = new Soql.StartsWithOperator('LIKE');
	global static final Operator NOT_STARTS_WITH = new Soql.StartsWithOperator('NOT LIKE');
	global static final Operator ENDS_WITH = new Soql.EndsWithOperator('LIKE');
	global static final Operator NOT_ENDS_WITH = new Soql.EndsWithOperator('NOT LIKE');
	global static final Operator CONTAINS = new Soql.ContainsOperator('LIKE');
	global static final Operator NOT_CONTAINS = new Soql.ContainsOperator('NOT LIKE');
	// Other constants
	private static final Soql.LogicType DEFAULT_LOGIC_TYPE = Soql.LogicType.ALL_CONDITIONS;
	private static final String ID_REFERENCE = 'Id';

	// Member Properties:
	global String identifier { get; private set; }

	/**
	 * @description Constructor for Soql instance with DatabaseLayer factory.
	 * @param factory The DatabaseLayer factory instance
	 */
	public Soql(DatabaseLayer factory) {
		this();
	}

	/**
	 * @description Protected constructor for Soql instance initialization.
	 */
	protected Soql() {
		super();
	}

	/**
	 * @description Executes an aggregate query and returns mockable AggregateResult wrappers.
	 * @return List of Soql.AggregateResult objects wrapping Schema.AggregateResult
	 */
	global List<Soql.AggregateResult> aggregateQuery() {
		return (List<Soql.AggregateResult>) this.initRequest(Soql.Operation.AGGREGATE_QUERY)?.process();
	}

	/**
	 * @description Executes a COUNT() query and returns the number of matching records.
	 * @return Integer count of matching records
	 */
	global Integer countQuery() {
		return (Integer) this.initRequest(Soql.Operation.COUNT_QUERY)?.process();
	}

	/**
	 * @description Returns query results as a mockable Cursor wrapper.
	 * @return Soql.Cursor object wrapping Database.Cursor
	 */
	global Soql.Cursor getCursor() {
		return (Soql.Cursor) this.initRequest(Soql.Operation.GET_CURSOR)?.process();
	}

	/**
	 * @description Returns query results as a mockable QueryLocator wrapper for batch processing.
	 * @return Soql.QueryLocator object wrapping Database.QueryLocator
	 */
	global Soql.QueryLocator getQueryLocator() {
		return (Soql.QueryLocator) this.initRequest(Soql.Operation.GET_QUERY_LOCATOR)?.process();
	}

	/**
	 * @description Executes the SOQL query and returns matching records.
	 * @return List of SObject records matching the query criteria
	 */
	global List<SObject> query() {
		return (List<SObject>) this.initRequest(Soql.Operation.QUERY)?.process();
	}

	/**
	 * @description Executes the query and deserializes results to the specified type.
	 * @param returnType The type to deserialize query results into
	 * @return Query results deserialized as the specified type
	 */
	global Object query(Type returnType) {
		Object result = this.initRequest(Soql.Operation.QUERY)?.process();
		return JSON.deserialize(JSON.serialize(result), returnType);
	}

	/**
	 * @description Executes the query and returns only the first matching record.
	 * @return First SObject matching the query criteria, or null if no matches
	 */
	global SObject queryFirst() {
		Integer originalLimit = this.rowLimit;
		this.setRowLimit(1);
		List<SObject> results = this.query();
		this.setRowLimit(originalLimit);
		return results?.isEmpty() == false ? results?.get(0) : null;
	}

	/**
	 * @description Sets an identifier for this query that can be referenced in mocks.
	 * @param identifier Unique identifier for this query instance
	 * @return This Soql instance for method chaining
	 */
	global Soql setQueryIdentifier(String identifier) {
		this.identifier = identifier;
		return this;
	}

	/**
	 * @description Initializes a SOQL request object for the specified operation.
	 * @param operation The SOQL operation to perform
	 * @return A configured Soql.Request object
	 */
	protected virtual Soql.Request initRequest(Soql.Operation operation) {
		return new Soql.Request(this, operation);
	}

	// **** ENUMS *** //
	global enum Function {
		AVG,
		CALENDAR_MONTH,
		CALENDAR_QUARTER,
		CALENDAR_YEAR,
		COUNT,
		COUNT_DISTINCT,
		DAY_IN_MONTH,
		DAY_IN_WEEK,
		DAY_IN_YEAR,
		DAY_ONLY,
		FISCAL_MONTH,
		FISCAL_QUARTER,
		FISCAL_YEAR,
		FORMAT,
		HOUR_IN_DAY,
		MIN,
		MAX,
		SUM,
		WEEK_IN_MONTH,
		WEEK_IN_YEAR
	}

	global enum LogicType {
		ALL_CONDITIONS,
		ANY_CONDITIONS
	}

	global enum NullOrder {
		NULLS_FIRST,
		NULLS_LAST
	}

	global enum Operation {
		AGGREGATE_QUERY,
		COUNT_QUERY,
		GET_CURSOR,
		GET_QUERY_LOCATOR,
		QUERY
	}

	global enum Scope {
		// https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql_select_using_scope.htm
		DELEGATED,
		EVERYTHING,
		MINE,
		MINE_AND_MY_GROUPS,
		MY_TERRITORY,
		MY_TEAM_TERRITORY,
		TEAM
	}

	global enum SortDirection {
		ASCENDING,
		DESCENDING
	}

	global enum Usage {
		// https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql_select_for_view.htm
		// https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql_select_for_reference.htm
		// https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql_select_for_update.htm
		ALL_ROWS,
		FOR_VIEW,
		FOR_REFERENCE,
		FOR_UPDATE
	}

	// **** INTERFACE **** //
	global interface Criteria {
		// Mostly a marker interface, but also used to coerce toString()
		// Use this to denote classes that can be used in WHERE/HAVING clauses
		String toString();
	}

	global interface PreAndPostProcessor {
		void processPreSoql(Soql.Request request);
		void processPostSoql(Soql.Request request, Object results);
		void processSoqlError(Soql.Request request, Exception error);
	}

	global interface Selectable {
		// Mostly a marker interface, but also used to coerce toString()
		// Use this to denote classes that can be used in SELECT clauses
		String toString();
	}

	// **** INNER **** //
	/**
	 * @description Mockable wrapper for Schema.AggregateResult that enables testing of aggregate queries.
	 */
	global virtual class AggregateResult {
		protected Map<String, Object> params;

		/**
		 * @description Constructor that wraps a Schema.AggregateResult.
		 * @param result The Schema.AggregateResult to wrap
		 */
		protected AggregateResult(Schema.AggregateResult result) {
			this.params = result?.getPopulatedFieldsAsMap() ?? new Map<String, Object>();
		}

		/**
		 * @description Retrieves the value for the specified field or alias.
		 * @param key The field name or alias to retrieve
		 * @return The value associated with the key
		 */
		global Object get(String key) {
			return this.params?.get(key);
		}
	}

	/**
	 * @description Represents an aggregate function in a SOQL query (COUNT, SUM, AVG, etc.).
	 */
	global class Aggregation implements Soql.Selectable {
		private String alias;
		private String innerFieldName;
		private Function function;

		/**
		 * @description Constructor for aggregation with function and field name.
		 * @param function The aggregation function to apply
		 * @param innerFieldName The field name to aggregate
		 */
		global Aggregation(Soql.Function function, String innerFieldName) {
			this.alias = '';
			this.innerFieldName = innerFieldName;
			this.function = function;
		}

		/**
		 * @description Constructor for aggregation with function and SObjectField.
		 * @param function The aggregation function to apply
		 * @param field The SObjectField to aggregate
		 */
		global Aggregation(Soql.Function function, SObjectField field) {
			this(function, field?.toString());
		}

		/**
		 * @description Constructor for aggregation with function and parent field.
		 * @param function The aggregation function to apply
		 * @param field The parent field to aggregate
		 */
		global Aggregation(Soql.Function function, Soql.ParentField field) {
			this(function, field?.toString());
		}

		/**
		 * @description Constructor for aggregation with only function.
		 * @param function The aggregation function to apply
		 */
		global Aggregation(Soql.Function function) {
			this(function, '');
		}

		/**
		 * @description Returns the aggregation as a formatted SOQL string.
		 * @return The aggregation formatted for SOQL queries
		 */
		global override String toString() {
			String formatted = String.format(
				'{0}({1}) {2}',
				new List<String>{ this.function?.toString(), this.innerFieldName, this.alias }
			);
			return formatted?.trim();
		}

		/**
		 * @description Sets an alias for the aggregation result.
		 * @param alias The alias to use for this aggregation
		 * @return This Aggregation instance for method chaining
		 */
		global Soql.Aggregation withAlias(String alias) {
			this.alias = alias;
			return this;
		}
	}

	/**
	 * @description Represents a bind variable for parameterized SOQL queries.
	 */
	global class Binder {
		global String key { get; private set; }
		global Object value { get; private set; }

		global Binder(String key, Object value) {
			this.key = key;
			this.setValue(value);
		}

		global Binder(String key) {
			this(key, null);
		}

		global String getKey() {
			return this.key;
		}

		global Object getValue() {
			return this.value;
		}

		global Soql.Binder setValue(Object value) {
			this.value = value;
			return this;
		}

		global override String toString() {
			return ':' + this.getKey();
		}
	}

	/**
	 * @description Abstract base class providing fluent interface for building SOQL queries.
	 */
	global abstract class Builder {
		global transient System.AccessLevel accessLevel { get; protected set; }
		global Map<String, Object> binds { get; protected set; }
		global String entity { get; protected set; }
		global List<String> groupByClauses { get; protected set; }
		global Soql.ConditionalLogic havingCriteria { get; protected set; }
		global List<String> orderByClauses { get; protected set; }
		global Integer rowLimit { get; protected set; }
		global Integer rowOffset { get; protected set; }
		global Soql.Scope scope { get; protected set; }
		global Set<String> selectClauses { get; protected set; }
		global Soql.Usage usage { get; protected set; }
		global Soql.ConditionalLogic whereCriteria { get; protected set; }
		global String withClause { get; protected set; }
		// Read-only properties included for JSON output:
		private String accessLevelName {
			// System.AccessLevel isn't serializable,
			// and it does not have an enum name() property,
			// and toString() does not output its name either:
			get {
				return (this.accessLevel == System.AccessLevel.SYSTEM_MODE) ? 'SYSTEM_MODE' : 'USER_MODE';
			}
		}

		protected Builder() {
			this.reset();
		}

		global virtual override String toString() {
			// Outputs a SOQL Query string, following the syntax defined here:
			// https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql_select.htm#:~:text=SOQL%20query%20syntax%20consists%20of,typeOfField%20whenExpression%5B...%5D
			List<String> queryArgs = new List<String>{ this.getSelect(), this.getFrom(), this.getOptionalArgs() };
			return String.format('SELECT {0} FROM {1} {2}', queryArgs)?.trim();
		}

		global Soql.Builder addBind(Map<String, Object> bindMap) {
			this.binds?.putAll(bindMap);
			return this;
		}

		global Soql.Builder addBind(String key, Object value) {
			return this.addBind(new Map<String, Object>{ key => value });
		}

		global Soql.Builder addBind(Soql.Binder binder) {
			return this.addBind(binder?.getKey(), binder?.getValue());
		}

		global Soql.Builder setAccessLevel(System.AccessLevel accessLevel) {
			this.accessLevel = accessLevel;
			return this;
		}

		global Soql.Builder reset() {
			this.accessLevel = System.AccessLevel.USER_MODE;
			this.binds = new Map<String, Object>();
			this.groupByClauses = new List<String>();
			this.havingCriteria = new Soql.ConditionalLogic();
			this.orderByClauses = new List<String>();
			this.selectClauses = new Set<String>{ ID_REFERENCE };
			this.whereCriteria = new Soql.ConditionalLogic();
			return this;
		}

		global Soql.InnerQuery toInnerQuery() {
			return (Soql.InnerQuery) this;
		}

		global Soql toSoql() {
			return (Soql) this;
		}

		global Soql.Subquery toSubquery() {
			return (Soql.Subquery) this;
		}

		// * SELECT *
		@SuppressWarnings('PMD.EagerlyLoadedDescribeSObjectResult')
		global Soql.Builder selectAll() {
			// Note: Not sure why this PMD rule is flagging; the describe is explicitly deferred
			List<Schema.DescribeSObjectResult> describes = Schema.describeSObjects(
				new List<String>{ this.entity },
				Schema.SObjectDescribeOptions.DEFERRED
			);
			Schema.DescribeSObjectResult describe = describes?.isEmpty() == false ? describes?.get(0) : null;
			List<SObjectField> allFields = describe?.fields?.getMap()?.values() ?? new List<SObjectField>();
			for (SObjectField field : allFields) {
				this.addSelect(field);
			}
			return this;
		}

		// NOTE: With the advent of PR #49, we should consider making the string-based SELECT methods protected
		global Soql.Builder addSelect(String fieldName, String alias) {
			String clause = String.join(new List<String>{ fieldName, alias }, ' ')?.trim();
			this.selectClauses?.add(clause);
			return this;
		}

		global Soql.Builder addSelect(SObjectField field, String alias) {
			return this.addSelect(field?.toString(), alias);
		}

		global Soql.Builder addSelect(Soql.ParentField field, String alias) {
			return this.addSelect(field?.toString(), alias);
		}

		global Soql.Builder addSelect(String fieldName) {
			return this.addSelect(fieldName, '');
		}

		global Soql.Builder addSelect(List<SObjectField> fields) {
			for (SObjectField field : fields) {
				if (field != null) {
					this.addSelect(field?.toString());
				}
			}
			return this;
		}

		@SuppressWarnings('PMD.ExcessiveParameterList')
		global Soql.Builder addSelect(
			SObjectField field1,
			SObjectField field2,
			SObjectField field3,
			SObjectField field4,
			SObjectField field5
		) {
			// Currently supporting up to 5 SObjectFields per addSelect call:
			return this.addSelect(new List<SObjectField>{ field1, field2, field3, field4, field5 });
		}

		@SuppressWarnings('PMD.ExcessiveParameterList')
		global Soql.Builder addSelect(
			SObjectField field1,
			SObjectField field2,
			SObjectField field3,
			SObjectField field4
		) {
			return this.addSelect(field1, field2, field3, field4, null);
		}

		global Soql.Builder addSelect(SObjectField field1, SObjectField field2, SObjectField field3) {
			return this.addSelect(field1, field2, field3, null);
		}

		global Soql.Builder addSelect(SObjectField field1, SObjectField field2) {
			return this.addSelect(field1, field2, null);
		}

		global Soql.Builder addSelect(SObjectField field) {
			SObjectField nullField;
			return this.addSelect(field, nullField);
		}

		global Soql.Builder addSelect(List<Soql.Selectable> fields) {
			for (Soql.Selectable field : fields) {
				if (field != null) {
					this.handleSelectableLogic(field);
					this.addSelect(field?.toString());
				}
			}
			return this;
		}

		@SuppressWarnings('PMD.ExcessiveParameterList')
		global Soql.Builder addSelect(
			Soql.Selectable field1,
			Soql.Selectable field2,
			Soql.Selectable field3,
			Soql.Selectable field4,
			Soql.Selectable field5
		) {
			// Currently supporting up to 5 selectables per addSelect call:
			return this.addSelect(new List<Soql.Selectable>{ field1, field2, field3, field4, field5 });
		}

		@SuppressWarnings('PMD.ExcessiveParameterList')
		global Soql.Builder addSelect(
			Soql.Selectable field1,
			Soql.Selectable field2,
			Soql.Selectable field3,
			Soql.Selectable field4
		) {
			return this.addSelect(field1, field2, field3, field4, null);
		}

		global Soql.Builder addSelect(Soql.Selectable field1, Soql.Selectable field2, Soql.Selectable field3) {
			return this.addSelect(field1, field2, field3, null);
		}

		global Soql.Builder addSelect(Soql.Selectable field1, Soql.Selectable field2) {
			return this.addSelect(field1, field2, null);
		}

		global Soql.Builder addSelect(Soql.Selectable field) {
			return this.addSelect(field, null);
		}

		global Soql.Builder deselectAll() {
			// Remove all SELECT fields from the current query
			this.selectClauses?.clear();
			return this;
		}

		global Soql.Builder deselect(String fieldName) {
			// Remove a field from the current query
			this.selectClauses?.remove(fieldName);
			return this;
		}

		global Soql.Builder deselect(SObjectField field) {
			return this.deselect(field?.toString());
		}

		global Soql.Builder deselect(Soql.Selectable selectable) {
			return this.deselect(selectable?.toString());
		}

		// * FROM *
		global Soql.Builder setFrom(SObjectType objectType) {
			this.entity = objectType?.toString();
			return this;
		}

		// * USING SCOPE *
		global Soql.Builder setScope(Soql.Scope scope) {
			this.scope = scope;
			return this;
		}

		// * WHERE *
		global Soql.Builder addWhere(Soql.Criteria criteria) {
			this.whereCriteria?.addCondition(criteria);
			return this;
		}

		global Soql.Builder addWhere(String fieldName, Soql.Operator operator, Object value) {
			// Shorthand overload constructs a Condition object for the caller
			return this.addWhere(new Soql.Condition(fieldName, operator, value));
		}

		global Soql.Builder addWhere(SObjectField field, Soql.Operator operator, Object value) {
			return this.addWhere(field?.toString(), operator, value);
		}

		global Soql.Builder addWhere(Soql.ParentField field, Soql.Operator operator, Object value) {
			return this.addWhere(field?.toString(), operator, value);
		}

		global Soql.Builder addWhere(String fieldName, Soql.Operator operator, Soql.InnerQuery innerQuery) {
			// If the current `value` object is an InnerQuery, add its binds to the parent query:
			this.addBindsFromChildQuery(innerQuery);
			return this.addWhere(fieldName, operator, innerQuery?.toString());
		}

		global Soql.Builder addWhere(SObjectField field, Soql.Operator operator, Soql.InnerQuery innerQuery) {
			return this.addWhere(field?.toString(), operator, innerQuery);
		}

		global Soql.Builder addWhere(String fieldName, Soql.Operator operator, Soql.Binder binder) {
			// If the current `value` object is a Binder, bind the values so that callers don't need to do so manually
			return this.addWhere(fieldName, operator, binder?.toString())?.addBind(binder);
		}

		global Soql.Builder addWhere(SObjectField field, Soql.Operator operator, Soql.Binder binder) {
			return this.addWhere(field?.toString(), operator, binder);
		}

		global Soql.Builder addWhere(Soql.ParentField field, Soql.Operator operator, Soql.Binder binder) {
			return this.addWhere(field?.toString(), operator, binder);
		}

		global Soql.Builder setOuterWhereLogic(Soql.LogicType newLogicType) {
			this.whereCriteria?.setLogicType(newLogicType);
			return this;
		}

		// * WITH *
		global Soql.Builder withSecurityEnforced() {
			this.withClause = 'SECURITY_ENFORCED';
			// Note: Cannot use the WITH SECURITY_ENFORCED clause in queries using USER_MODE access level.
			this.setAccessLevel(System.AccessLevel.SYSTEM_MODE);
			return this;
		}

		// * GROUP BY *
		global Soql.Builder addGroupBy(String fieldName) {
			// Note: GROUP BY queries should never assume an implicit "Id" in the query
			this.deselect(ID_REFERENCE);
			this.groupByClauses?.add(fieldName);
			return this;
		}

		global Soql.Builder addGroupBy(SObjectField field) {
			return this.addGroupBy(field?.toString());
		}

		global Soql.Builder addGroupBy(Soql.ParentField field) {
			return this.addGroupBy(field?.toString());
		}

		// * HAVING *
		global Soql.Builder addHaving(Soql.Aggregation agg, Soql.Operator operator, Object value) {
			// Shorthand overload constructs the AggregateCondition for the caller
			Soql.Condition condition = new Soql.Condition(agg?.toString(), operator, value);
			this.havingCriteria?.addCondition(condition);
			return this;
		}

		global Soql.Builder setOuterHavingLogic(Soql.LogicType newLogicType) {
			this.havingCriteria?.setLogicType(newLogicType);
			return this;
		}

		// * ORDER BY *
		global Soql.Builder addOrderBy(Soql.SortOrder sortOrder) {
			this.orderByClauses?.add(sortOrder?.toString());
			return this;
		}

		global Soql.Builder addOrderBy(String fieldName, Soql.SortDirection direction) {
			Soql.SortOrder sortOrder = new Soql.SortOrder(fieldName, direction);
			return this.addOrderBy(sortOrder);
		}

		global Soql.Builder addOrderBy(SObjectField field, Soql.SortDirection direction) {
			return this.addOrderBy(field?.toString(), direction);
		}

		global Soql.Builder addOrderBy(Soql.ParentField field, Soql.SortDirection direction) {
			return this.addOrderBy(field?.toString(), direction);
		}

		// * LIMIT *
		global Soql.Builder setRowLimit(Integer rowLimit) {
			this.rowLimit = rowLimit;
			return this;
		}

		// * OFFSET *
		global Soql.Builder setRowOffset(Integer rowOffset) {
			this.rowOffset = rowOffset;
			return this;
		}

		// * USAGE *
		global Soql.Builder setUsage(Soql.Usage usage) {
			this.usage = usage;
			return this;
		}

		// **** PRIVATE **** //
		protected void addBindsFromChildQuery(Soql.Builder childQuery) {
			// Add all binds from a child query to the current query
			Map<String, Object> childBinds = childQuery?.binds ?? new Map<String, Object>();
			this.binds?.putAll(childBinds);
		}

		protected String constructClause(String prefix, Object value) {
			// Returns a specific SOQL clause (ex., "WHERE {value}"), provided that `value` is not null
			String output = value?.toString();
			return (String.isBlank(output) == false) ? (prefix + ' ' + output) : null;
		}

		protected virtual String getFrom() {
			return this.entity?.toString();
		}

		protected virtual String getGroupBy() {
			return (this.groupByClauses?.isEmpty() == false)
				? 'GROUP BY ' + String.join(this.groupByClauses, ', ')
				: null;
		}

		protected String getOptionalArgs() {
			List<String> args = new List<String>();
			for (
				String arg : new List<String>{
					this.constructClause('USING SCOPE', this.scope),
					this.constructClause('WHERE', this.whereCriteria),
					this.constructClause('WITH', this.withClause),
					this.getGroupBy(),
					this.constructClause('HAVING', this.havingCriteria),
					this.constructClause('ORDER BY', String.join(this.orderByClauses, ', ')),
					this.constructClause('LIMIT', this.rowLimit),
					this.constructClause('OFFSET', this.rowOffset),
					this.getUsage()
				}
			) {
				if (arg != null) {
					args?.add(arg);
				}
			}
			return String.join(args, ' ');
		}

		protected virtual String getSelect() {
			return String.join(new List<String>(this.selectClauses), ', ');
		}

		protected virtual String getUsage() {
			return this.usage?.toString()?.replace('_', ' ');
		}

		protected void handleSelectableLogic(Soql.Selectable selectable) {
			// Handles special "rules" for certain Selectable types:
			if (selectable instanceof Soql.Aggregation) {
				// Aggregate queries should never include the Id reference by itself
				this.deselect(ID_REFERENCE);
			} else if (selectable instanceof Soql.Subquery) {
				// Subqueries should have binds propogate up to parent
				Soql.Subquery subquery = (Soql.Subquery) selectable;
				this.addBindsFromChildQuery(subquery);
			}
		}
	}

	/**
	 * @description Represents a single condition in a WHERE or HAVING clause.
	 */
	global virtual class Condition implements Soql.Criteria {
		global final String property { get; protected set; }
		global final Soql.Operator operator { get; protected set; }
		global final Object value { get; protected set; }

		global Condition(String property, Soql.Operator operator, Object value) {
			this.property = property;
			this.operator = operator;
			this.value = value;
		}

		global Condition(SObjectField field, Soql.Operator operator, Object value) {
			this(field?.toString(), operator, value);
		}

		global Condition(Soql.ParentField field, Soql.Operator operator, Object value) {
			this(field?.toString(), operator, value);
		}

		global override String toString() {
			List<String> parts = new List<String>{
				this.property,
				this.operator?.toString(),
				this.formatValue(this.value)
			};
			return String.join(parts, ' ');
		}

		protected String formatValue(Object value) {
			if (value == null) {
				return 'null';
			} else if (value instanceof Date) {
				return this.processDate((Date) value);
			} else if (value instanceof DateTime) {
				return this.processDateTime((DateTime) value);
			} else if (value instanceof Iterable<Object>) {
				return this.processIterable((Iterable<Object>) value);
			} else if (value instanceof String) {
				return this.processString((String) value);
			} else {
				return String.valueOf(value);
			}
		}

		private String processDate(Date value) {
			String soqlFormat = 'yyyy-MM-dd';
			DateTime dateTimeValue = DateTime.newInstance(value.year(), value.month(), value.day());
			return dateTimeValue?.formatGmt(soqlFormat);
		}

		private String processDateTime(DateTime value) {
			String soqlFormat = 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'';
			return value?.formatGmt(soqlFormat);
		}

		protected String processIterable(Iterable<Object> values) {
			List<String> outputs = new List<String>();
			for (Object value : values) {
				String output = this.formatValue(value);
				outputs?.add(output);
			}
			return '(' + String.join(outputs, ', ') + ')';
		}

		private String processString(String value) {
			// Allow special modifiers (bind variables, inner queries, & relative date operators) to pass through unmodified
			for (String excludedModifier : new Set<String>{ 'LAST_N_DAYS', ':', '(' }) {
				if (value?.startsWithIgnoreCase(excludedModifier)) {
					return value;
				}
			}
			// Else, treat the value as a normal String:
			return this.operator?.processStringValue(value);
		}
	}

	/**
	 * @description Manages complex conditional logic with AND/OR operations for WHERE and HAVING clauses.
	 */
	global class ConditionalLogic implements Soql.Criteria {
		private List<Soql.Criteria> criterion = new List<Soql.Criteria>();
		private Soql.LogicType logicType = Soql.LogicType.ALL_CONDITIONS;

		global ConditionalLogic addCondition(List<Soql.Criteria> criterion) {
			this.criterion?.addAll(criterion);
			return this;
		}

		global ConditionalLogic addCondition(Soql.Criteria criteria) {
			return this.addCondition(new List<Soql.Criteria>{ criteria });
		}

		global ConditionalLogic addCondition(String fieldName, Soql.Operator operator, Object value) {
			Soql.Condition condition = new Soql.Condition(fieldName, operator, value);
			return this.addCondition(condition);
		}

		global ConditionalLogic addCondition(SObjectField field, Soql.Operator operator, Object value) {
			return this.addCondition(field?.toString(), operator, value);
		}

		global ConditionalLogic addCondition(Soql.ParentField field, Soql.Operator operator, Object value) {
			return this.addCondition(field?.toString(), operator, value);
		}

		global ConditionalLogic setLogicType(Soql.LogicType logicType) {
			this.logicType = logicType;
			return this;
		}

		global override String toString() {
			String delimiter = ' ' + this.getPredicate() + ' ';
			List<String> criteriaStrings = new List<String>();
			for (Soql.Criteria criteria : this.criterion) {
				// Wrap inner ConditionalLogic objects in parentheses
				String criteriaString = (criteria instanceof ConditionalLogic)
					? '(' + criteria?.toString() + ')'
					: criteria?.toString();
				criteriaStrings?.add(criteriaString);
			}
			return String.join(criteriaStrings, delimiter)?.trim();
		}

		private String getPredicate() {
			return (logicType == Soql.LogicType.ANY_CONDITIONS) ? 'OR' : 'AND';
		}
	}

	global virtual class ContainsOperator extends Soql.Operator {
		private ContainsOperator(String token) {
			super(token);
		}

		public override String processStringValue(String value) {
			return '\'%' + String.escapeSingleQuotes(value) + '%\'';
		}
	}

	/**
	 * @description Mockable wrapper for Database.Cursor that enables testing of cursor-based queries.
	 */
	global virtual class Cursor {
		protected Database.Cursor cursor;

		protected Cursor(Database.Cursor cursor) {
			this.cursor = cursor;
		}

		global virtual List<SObject> fetch(Integer position, Integer count) {
			try {
				return this.cursor?.fetch(position, count);
			} catch (System.InvalidParameterValueException error) {
				// This type of system exception cannot be manually constructed, except in VF/Aura contexts (??)
				// It is thrown whenever invalid parameters are supplied to the fetch() method
				// Wrap these exceptions so that both real and fake queries throw the same type of Exception for consistency
				String msg = error?.getMessage();
				throw new Soql.InvalidParameterValueException(msg);
			}
		}

		global Database.Cursor getCursor() {
			return this.cursor;
		}

		global virtual Integer getNumRecords() {
			return this.cursor?.getNumRecords();
		}
	}

	global class EndsWithOperator extends Soql.Operator {
		private EndsWithOperator(String token) {
			super(token);
		}

		public override String processStringValue(String value) {
			return '\'%' + String.escapeSingleQuotes(value) + '\'';
		}
	}

	/**
	 * @description Represents a subquery for use in WHERE clauses and other contexts requiring inner queries.
	 */
	global virtual class InnerQuery extends Soql.Builder implements Soql.Selectable {
		protected InnerQuery() {
			this.deselect(ID_REFERENCE);
		}

		global InnerQuery(SObjectType objectType) {
			this();
			this.setFrom(objectType);
		}

		global override String toString() {
			return '(' + super.toString() + ')';
		}
	}

	global class InvalidParameterValueException extends Exception {
		// This class wraps System.InvalidParameterValueExceptions thrown by invalid fetch calls in Database.Cursors
	}

	/**
	 * @description Base class for SOQL operators (=, !=, LIKE, IN, etc.) with string value processing.
	 */
	global virtual class Operator {
		private String token;

		/**
		 * @description Constructor for operator with specified token.
		 * @param token The SOQL operator token (=, !=, LIKE, etc.)
		 */
		protected Operator(String token) {
			this.token = token;
		}

		public virtual String processStringValue(String value) {
			return '\'' + String.escapeSingleQuotes(value) + '\'';
		}

		global override String toString() {
			return this.token;
		}
	}

	@SuppressWarnings('PMD.ExcessiveParameterList')
	global class ParentField implements Soql.Selectable {
		// Represents a reference to a SObjectField on a parent (or multi-grandparent) object, ex., "Account.Owner.Profile.Name"
		// SOQL supports querying fields objects up to 5 relationships away from the FROM object
		private String value;

		global ParentField(List<SObjectField> relationshipFieldChain) {
			relationshipFieldChain = relationshipFieldChain ?? new List<SObjectField>();
			this.value = this.computeValue(relationshipFieldChain);
		}

		global ParentField(
			SObjectField relationship1,
			SObjectField relationship2,
			SObjectField relationship3,
			SObjectField relationship4,
			SObjectField relationship5,
			SObjectField field
		) {
			this(
				new List<SObjectField>{
					relationship1,
					relationship2,
					relationship3,
					relationship4,
					relationship5,
					field
				}
			);
		}

		global ParentField(
			SObjectField relationship1,
			SObjectField relationship2,
			SObjectField relationship3,
			SObjectField relationship4,
			SObjectField field
		) {
			this(new List<SObjectField>{ relationship1, relationship2, relationship3, relationship4, field });
		}

		global ParentField(
			SObjectField relationship1,
			SObjectField relationship2,
			SObjectField relationship3,
			SObjectField field
		) {
			this(new List<SObjectField>{ relationship1, relationship2, relationship3, field });
		}

		global ParentField(SObjectField relationship1, SObjectField relationship2, SObjectField field) {
			this(new List<SObjectField>{ relationship1, relationship2, field });
		}

		global ParentField(SObjectField relationship1, SObjectField field) {
			this(new List<SObjectField>{ relationship1, field });
		}

		global override String toString() {
			return this.value;
		}

		private String computeValue(List<SObjectField> fields) {
			// Generate the String reference to the parent field:
			List<String> components = new List<String>();
			Integer size = fields?.size();
			Integer lastIteration = size - 1;
			for (Integer i = 0; i < size; i++) {
				SObjectField field = fields?.get(i);
				if (i < lastIteration) {
					String relationshipName = field?.getDescribe()?.getRelationshipName();
					components?.add(relationshipName);
				} else {
					// Final field in the chain - Get the API name of the field
					String fieldName = field?.toString();
					components?.add(fieldName);
				}
			}
			return String.join(components, '.');
		}
	}

	/**
	 * @description Mockable wrapper for Database.QueryLocator that enables testing of batch processing queries.
	 */
	global virtual class QueryLocator {
		private Database.QueryLocator locator;

		protected QueryLocator(Database.QueryLocator locator) {
			this.locator = locator;
		}

		global virtual Database.QueryLocator getLocator() {
			return this.locator;
		}

		global virtual String getQuery() {
			return this.locator?.getQuery();
		}

		global virtual System.Iterator<SObject> iterator() {
			return (System.Iterator<SObject>) this.locator?.iterator();
		}
	}

	/**
	 * @description Encapsulates a single SOQL operation with all its parameters and execution logic.
	 */
	global inherited sharing virtual class Request {
		global Boolean isMockSoql { get; protected set; }
		global Soql.Operation operation { get; private set; }
		global Soql query { get; private set; }
		protected transient System.AccessLevel accessLevel { get; private set; }
		protected transient Map<String, Object> binds { get; private set; }
		global String queryString {
			get {
				return this.query?.toString();
			}
		}

		protected Request(Soql query, Soql.Operation operation) {
			this.accessLevel = query?.accessLevel;
			this.binds = query?.binds;
			this.isMockSoql = false;
			this.operation = operation;
			this.query = query;
		}

		public Object process() {
			try {
				DatabaseLayer.Soql.Plugin?.processPreSoql(this);
				Object results = this.performQueryOperation();
				DatabaseLayer.Soql.Plugin?.processPostSoql(this, results);
				return results;
			} catch (Exception error) {
				DatabaseLayer.Soql.Plugin?.processSoqlError(this, error);
				String augmentedMsg = error?.getMessage() + '\nQuery: [' + this.queryString + ']';
				error?.setMessage(augmentedMsg);
				throw error;
			}
		}

		protected Object performQueryOperation() {
			if (this.operation == Soql.Operation.AGGREGATE_QUERY) {
				return this.doAggregateQuery();
			} else if (this.operation == Soql.Operation.COUNT_QUERY) {
				return this.doCountQuery();
			} else if (this.operation == Soql.Operation.GET_CURSOR) {
				return this.doGetCursor();
			} else if (this.operation == Soql.Operation.GET_QUERY_LOCATOR) {
				return this.doGetQueryLocator();
			} else {
				return this.doQuery();
			}
		}

		protected virtual List<Soql.AggregateResult> doAggregateQuery() {
			List<Schema.AggregateResult> results = (List<Schema.AggregateResult>) this.doQuery();
			List<Soql.AggregateResult> wrappers = new List<Soql.AggregateResult>();
			for (Schema.AggregateResult result : results) {
				Soql.AggregateResult wrapper = new Soql.AggregateResult(result);
				wrappers?.add(wrapper);
			}
			return wrappers;
		}

		protected virtual Integer doCountQuery() {
			// Note: A count query must not contain any fields, other than COUNT() aggregation
			// Avoid errors and simplify query construction by handling this in a temporary copy of the current query
			Soql.Aggregation count = new Soql.Aggregation(Soql.Function.COUNT);
			this.query?.deselectAll()?.addSelect(count)?.toSoql();
			return Database.countQueryWithBinds(this.queryString, this.binds, this.accessLevel);
		}

		protected virtual Soql.Cursor doGetCursor() {
			Database.Cursor cursor = Database.getCursorWithBinds(this.queryString, this.binds, this.accessLevel);
			return new Soql.Cursor(cursor);
		}

		protected virtual Soql.QueryLocator doGetQueryLocator() {
			Database.QueryLocator locator = Database.getQueryLocatorWithBinds(
				this.queryString,
				this.binds,
				this.accessLevel
			);
			return new Soql.QueryLocator(locator);
		}

		protected virtual Object doQuery() {
			return Database.queryWithBinds(this.queryString, this.binds, this.accessLevel);
		}
	}

	global class SortOrder {
		private List<String> fieldNames = new List<String>();
		private Soql.SortDirection direction = Soql.SortDirection.ASCENDING;
		private Soql.NullOrder nullOrder = Soql.NullOrder.NULLS_LAST;

		global SortOrder(List<String> fieldNames, Soql.SortDirection direction) {
			this.fieldNames = fieldNames;
			this.direction = direction;
		}

		global SortOrder(String fieldName, Soql.SortDirection direction) {
			this(new List<String>{ fieldName }, direction);
		}

		global SortOrder(List<SObjectField> fields, Soql.SortDirection direction) {
			for (SObjectField field : fields) {
				this.fieldNames?.add(field?.toString());
			}
			this.direction = direction;
		}

		global SortOrder(SObjectField field, Soql.SortDirection direction) {
			this(new List<SObjectField>{ field }, direction);
		}

		global SortOrder(List<Soql.ParentField> fields, Soql.SortDirection direction) {
			for (Soql.ParentField field : fields) {
				this.fieldNames?.add(field?.toString());
			}
			this.direction = direction;
		}

		global SortOrder(Soql.ParentField field, Soql.SortDirection direction) {
			this(new List<Soql.ParentField>{ field }, direction);
		}

		global SortOrder setNullOrder(Soql.NullOrder nullOrder) {
			this.nullOrder = nullOrder;
			return this;
		}

		global override String toString() {
			String orderByFields = String.join(fieldNames, ', ');
			return String.join(new List<String>{ orderByFields, this.getDirection(), this.getNullOrder() }, ' ');
		}

		private String getDirection() {
			return this.direction?.name()?.replace('ENDING', '');
		}

		private String getNullOrder() {
			return this.nullOrder?.name()?.replace('_', ' ');
		}
	}

	global class StartsWithOperator extends Soql.Operator {
		private StartsWithOperator(String token) {
			super(token);
		}

		public override String processStringValue(String value) {
			return '\'' + String.escapeSingleQuotes(value) + '%\'';
		}
	}

	global class Subquery extends Soql.InnerQuery {
		private String relationshipName;

		global Subquery(Schema.ChildRelationship relationship) {
			this.addSelect(ID_REFERENCE);
			this.relationshipName = relationship?.getRelationshipName();
		}

		global Subquery(SObjectField lookupFieldOnChildObject) {
			this(DatabaseLayer.Utils.ChildRelationships.getChildRelationshipFrom(lookupFieldOnChildObject));
		}

		global override String getFrom() {
			return this.relationshipName;
		}
	}
}
