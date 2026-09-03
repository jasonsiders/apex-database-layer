/**
 * @description Handles all SOQL query operations with the Salesforce database. Provides a mockable, fluent query builder interface with comprehensive operator support and plugin capabilities.
 */
@SuppressWarnings(
	'PMD.AvoidGlobalModifier,PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.ExcessiveClassLength,PMD.ExcessivePublicCount,PMD.NcssCount'
)
global inherited sharing virtual class Soql extends Soql.Builder {
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
	// Matches the SOQL date literal grammar: the fixed keywords, plus the parameterized <LITERAL>:<n> forms.
	// See https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql_select_dateformats.htm
	private static final Pattern DATE_LITERAL_PATTERN = Pattern.compile(
		'(?i)^(YESTERDAY|TODAY|TOMORROW|(LAST|THIS|NEXT)_(WEEK|MONTH|QUARTER|YEAR|FISCAL_QUARTER|FISCAL_YEAR)|' +
			'(LAST|NEXT)_90_DAYS|(LAST_N|NEXT_N)_(DAYS|WEEKS|MONTHS|QUARTERS|YEARS|FISCAL_QUARTERS|FISCAL_YEARS):\\d+|' +
			'N_(DAYS|WEEKS|MONTHS|QUARTERS|YEARS|FISCAL_QUARTERS|FISCAL_YEARS)_AGO:\\d+)$'
	);

	// Member Properties:
	/**
	 * @description Unique identifier for this query instance that can be referenced in mocks.
	 */
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
	 * @description String-based constructor: parse raw SOQL into builder state
	 * @param queryString The raw SOQL query string to parse
	 */
	public Soql(String queryString) {
		super();
		new SoqlParser().parse(this, queryString);
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
	 * @description Executes the SOQL query and returns matching records, mapped by their Id.
	 * Note: Returns `Map<Id, SObject>` rather than a specific SObject subtype because Apex does not
	 * support covariant casting of generic Map types — a `Map<Id, SObject>` cannot be cast to
	 * `Map<Id, User>` at runtime, even if all values are User records. If a typed map is needed,
	 * use `query()` and construct the map directly:
	 * `new Map<Id, User>((List<User>) soql.query())`
	 * @return Map of SObject records matching the query criteria, grouped by their Id
	 */
	global Map<Id, SObject> queryAndMap() {
		List<SObject> records = this.query();
		return new Map<Id, SObject>(records);
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
	/**
	 * @description SOQL aggregate and date functions available for use in SELECT clauses.
	 */
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

	/**
	 * @description Logical operators for combining criteria in WHERE clauses.
	 */
	global enum LogicType {
		ALL_CONDITIONS,
		ANY_CONDITIONS
	}

	/**
	 * @description Null ordering options for ORDER BY clauses.
	 */
	global enum NullOrder {
		NULLS_FIRST,
		NULLS_LAST
	}

	/**
	 * @description Types of SOQL operations that can be performed.
	 */
	global enum Operation {
		AGGREGATE_QUERY,
		COUNT_QUERY,
		GET_CURSOR,
		GET_QUERY_LOCATOR,
		QUERY
	}

	/**
	 * @description Row locking scopes for FOR UPDATE clauses.
	 */
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

	/**
	 * @description Sort directions for ORDER BY clauses.
	 */
	global enum SortDirection {
		ASCENDING,
		DESCENDING
	}

	/**
	 * @description Usage types for FOR VIEW and FOR UPDATE clauses.
	 */
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
	/**
	 * @description Marker interface for criteria that can be used in WHERE/HAVING clauses.
	 */
	global interface Criteria {
		/**
		 * @description Returns the string representation of this criteria.
		 * @return String representation for use in SOQL clauses
		 */
		String toString();
	}

	/**
	 * @description Interface for plugins that can process SOQL operations before/after execution.
	 */
	global interface PreAndPostProcessor {
		/**
		 * @description Processes SOQL requests before execution.
		 * @param request The SOQL request being processed
		 */
		void processPreSoql(Soql.Request request);
		/**
		 * @description Processes SOQL requests after execution.
		 * @param request The SOQL request that was processed
		 * @param results The results from the SOQL operation
		 */
		void processPostSoql(Soql.Request request, Object results);
		/**
		 * @description Processes SOQL errors.
		 * @param request The SOQL request that failed
		 * @param error The exception that occurred
		 */
		void processSoqlError(Soql.Request request, Exception error);
	}

	/**
	 * @description Marker interface for objects that can be used in SELECT clauses.
	 */
	global interface Selectable {
		/**
		 * @description Returns the string representation of this selectable.
		 * @return String representation for use in SELECT clauses
		 */
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
		/**
		 * @description The bind variable key.
		 */
		global String key { get; private set; }
		/**
		 * @description The bind variable value.
		 */
		global Object value { get; private set; }

		/**
		 * @description Constructor for bind variable with key and value.
		 * @param key The bind variable key
		 * @param value The bind variable value
		 */
		global Binder(String key, Object value) {
			this.key = key;
			this.setValue(value);
		}

		/**
		 * @description Constructor for bind variable with key only.
		 * @param key The bind variable key
		 */
		global Binder(String key) {
			this(key, null);
		}

		/**
		 * @description Retrieves the bind variable key.
		 * @return The bind variable key
		 */
		global String getKey() {
			return this.key;
		}

		/**
		 * @description Retrieves the bind variable value.
		 * @return The bind variable value
		 */
		global Object getValue() {
			return this.value;
		}

		/**
		 * @description Sets the bind variable value.
		 * @param value The value to bind
		 * @return This Binder instance for method chaining
		 */
		global Soql.Binder setValue(Object value) {
			this.value = value;
			return this;
		}

		/**
		 * @description Returns the bind variable as a SOQL parameter string.
		 * @return The bind variable formatted as ':key'
		 */
		global override String toString() {
			return ':' + this.getKey();
		}
	}

	/**
	 * @description Abstract base class providing fluent interface for building SOQL queries.
	 */
	global abstract class Builder {
		// Backing state for selectClauses:
		private transient Set<String> resolvedSelectClauses;
		private transient Boolean selectAllPending = false;
		/**
		 * @description The configured access level for the query execution.
		 */
		global transient System.AccessLevel accessLevel { get; protected set; }
		/**
		 * @description Map containing bind variable name-value pairs for parameterized SOQL queries.
		 * Keys are variable names (without ':' prefix), values are the bound objects.
		 */
		global Map<String, Object> binds { get; protected set; }
		/**
		 * @description The SObjectType name for the FROM clause.
		 */
		global String entity { get; protected set; }
		/**
		 * @description List of GROUP BY field names.
		 */
		global List<String> groupByClauses { get; protected set; }
		/**
		 * @description HAVING clause criteria for aggregate queries.
		 */
		global Soql.ConditionalLogic havingCriteria { get; protected set; }
		/**
		 * @description List of ORDER BY clauses.
		 */
		global List<String> orderByClauses { get; protected set; }
		/**
		 * @description Maximum number of rows to return (LIMIT clause).
		 */
		global Integer rowLimit { get; protected set; }
		/**
		 * @description Number of rows to skip (OFFSET clause).
		 */
		global Integer rowOffset { get; protected set; }
		/**
		 * @description Query scope (USING SCOPE clause).
		 */
		global Soql.Scope scope { get; protected set; }
		/**
		 * @description Set of SELECT clause field names. Reading this resolves any pending
		 * {@link selectAll} call, so callers always observe the fully expanded clause list.
		 */
		global Set<String> selectClauses {
			get {
				this.resolveSelectAll();
				return this.resolvedSelectClauses;
			}
			protected set {
				this.resolvedSelectClauses = value;
			}
		}
		/**
		 * @description Query usage type (FOR UPDATE, FOR VIEW, etc.).
		 */
		global Soql.Usage usage { get; protected set; }
		/**
		 * @description WHERE clause criteria for filtering records.
		 */
		global Soql.ConditionalLogic whereCriteria { get; protected set; }
		/**
		 * @description WITH clause for query hints (e.g., SECURITY_ENFORCED).
		 */
		global String withClause { get; protected set; }
		// Read-only properties included for JSON output:
		/**
		 * @description Serializable representation of the access level.
		 */
		private String accessLevelName {
			// Note: System.AccessLevel is a weird enum - it isn't serializable,
			// it does not have an enum name() property, and toString() does not output its name either:
			get {
				return (this.accessLevel == System.AccessLevel.SYSTEM_MODE) ? 'SYSTEM_MODE' : 'USER_MODE';
			}
		}

		/**
		 * @description Constructor that initializes the builder with default values.
		 */
		protected Builder() {
			this.reset();
		}

		/**
		 * @description Converts the builder to a SOQL query string.
		 * @return The complete SOQL query string
		 */
		global virtual override String toString() {
			// Outputs a SOQL Query string, following the syntax defined here:
			// https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql_select.htm#:~:text=SOQL%20query%20syntax%20consists%20of,typeOfField%20whenExpression%5B...%5D
			List<String> queryArgs = new List<String>{ this.getSelect(), this.getFrom(), this.getOptionalArgs() };
			return String.format('SELECT {0} FROM {1} {2}', queryArgs)?.trim();
		}

		/**
		 * @description Adds multiple bind variables from a map.
		 * @param bindMap Map of bind variable keys to values
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder addBind(Map<String, Object> bindMap) {
			this.binds?.putAll(bindMap);
			return this;
		}

		/**
		 * @description Adds a single bind variable.
		 * @param key The bind variable key
		 * @param value The bind variable value
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder addBind(String key, Object value) {
			return this.addBind(new Map<String, Object>{ key => value });
		}

		/**
		 * @description Adds a bind variable using a Binder object.
		 * @param binder The Binder object containing key and value
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder addBind(Soql.Binder binder) {
			return this.addBind(binder?.getKey(), binder?.getValue());
		}

		/**
		 * @description Sets the access level for the query (USER_MODE or SYSTEM_MODE).
		 * @param accessLevel The access level to use
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder setAccessLevel(System.AccessLevel accessLevel) {
			this.accessLevel = accessLevel;
			return this;
		}

		/**
		 * @description Resets the builder to its default state.
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder reset() {
			this.accessLevel = System.AccessLevel.USER_MODE;
			this.binds = new Map<String, Object>();
			this.groupByClauses = new List<String>();
			this.havingCriteria = new Soql.ConditionalLogic();
			this.orderByClauses = new List<String>();
			this.selectAllPending = false;
			this.selectClauses = new Set<String>{ ID_REFERENCE };
			this.whereCriteria = new Soql.ConditionalLogic();
			return this;
		}

		/**
		 * @description Casts this builder to an InnerQuery for use in subqueries.
		 * @return This builder as an InnerQuery
		 */
		global Soql.InnerQuery toInnerQuery() {
			return (Soql.InnerQuery) this;
		}

		/**
		 * @description Casts this builder to a Soql instance for query execution.
		 * @return This builder as a Soql instance
		 */
		global Soql toSoql() {
			return (Soql) this;
		}

		/**
		 * @description Casts this builder to a Subquery for use in SELECT clauses.
		 * @return This builder as a Subquery
		 */
		global Soql.Subquery toSubquery() {
			return (Soql.Subquery) this;
		}

		// * SELECT *
		/**
		 * @description Adds all fields of the object to the SELECT clause.
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder selectAll() {
			this.selectAllPending = true;
			return this;
		}

		/**
		 * @description Expands a pending {@link selectAll} request, if one is outstanding.
		 */
		private void resolveSelectAll() {
			if (this.selectAllPending == true) {
				// Clear the flag first; addSelect() reads selectClauses, which would recurse back into here
				this.selectAllPending = false;
				this.expandSelectAll();
			}
		}

		/**
		 * @description Adds each of the entity's fields to the SELECT clause. In user mode, fields the
		 * running user cannot read are omitted, since user mode SOQL rejects the entire query rather
		 * than dropping inaccessible fields from the results.
		 */
		private void expandSelectAll() {
			Boolean isSystemMode = this.accessLevel == System.AccessLevel.SYSTEM_MODE;
			for (SObjectField field : this.getAllFields()) {
				if (isSystemMode || field?.getDescribe()?.isAccessible() == true) {
					this.addSelect(field);
				}
			}
		}

		/**
		 * @description Returns every field defined on the query's entity.
		 * @return All fields on the entity, or an empty list if the entity cannot be described
		 */
		@SuppressWarnings('PMD.EagerlyLoadedDescribeSObjectResult')
		private List<SObjectField> getAllFields() {
			// Note: Not sure why this PMD rule is flagging; the describe is explicitly deferred
			List<Schema.DescribeSObjectResult> describes = Schema.describeSObjects(
				new List<String>{ this.entity },
				Schema.SObjectDescribeOptions.DEFERRED
			);
			Schema.DescribeSObjectResult describe = describes?.isEmpty() == false ? describes?.get(0) : null;
			return describe?.fields?.getMap()?.values() ?? new List<SObjectField>();
		}

		/**
		 * @description Adds a field to the SELECT clause with an alias.
		 * @param fieldName The field name to select
		 * @param alias The alias for the field
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder addSelect(String fieldName, String alias) {
			String clause = String.join(new List<String>{ fieldName, alias }, ' ')?.trim();
			this.selectClauses?.add(clause);
			return this;
		}

		/**
		 * @description Adds an SObjectField to the SELECT clause with an alias.
		 * @param field The SObjectField to select
		 * @param alias The alias for the field
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder addSelect(SObjectField field, String alias) {
			return this.addSelect(field?.toString(), alias);
		}

		/**
		 * @description Adds a parent field to the SELECT clause with an alias.
		 * @param field The parent field to select
		 * @param alias The alias for the field
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder addSelect(Soql.ParentField field, String alias) {
			return this.addSelect(field?.toString(), alias);
		}

		/**
		 * @description Adds a field to the SELECT clause.
		 * @param fieldName The field name to select
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder addSelect(String fieldName) {
			return this.addSelect(fieldName, '');
		}

		/**
		 * @description Adds multiple SObjectFields to the SELECT clause.
		 * @param fields List of SObjectFields to select
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder addSelect(List<SObjectField> fields) {
			for (SObjectField field : fields) {
				if (field != null) {
					this.addSelect(field?.toString());
				}
			}
			return this;
		}

		/**
		 * @description Adds 5 SObjectFields to the SELECT clause.
		 * @param field1 First SObjectField to select
		 * @param field2 Second SObjectField to select
		 * @param field3 Third SObjectField to select
		 * @param field4 Fourth SObjectField to select
		 * @param field5 Fifth SObjectField to select
		 * @return This Builder instance for method chaining
		 */
		@SuppressWarnings('PMD.ExcessiveParameterList')
		global Soql.Builder addSelect(
			SObjectField field1,
			SObjectField field2,
			SObjectField field3,
			SObjectField field4,
			SObjectField field5
		) {
			// Currently supporting 5 SObjectFields per addSelect call:
			return this.addSelect(new List<SObjectField>{ field1, field2, field3, field4, field5 });
		}

		/**
		 * @description Adds 4 SObjectFields to the SELECT clause.
		 * @param field1 First SObjectField to select
		 * @param field2 Second SObjectField to select
		 * @param field3 Third SObjectField to select
		 * @param field4 Fourth SObjectField to select
		 * @return This Builder instance for method chaining
		 */
		@SuppressWarnings('PMD.ExcessiveParameterList')
		global Soql.Builder addSelect(
			SObjectField field1,
			SObjectField field2,
			SObjectField field3,
			SObjectField field4
		) {
			return this.addSelect(field1, field2, field3, field4, null);
		}

		/**
		 * @description Adds 3 SObjectFields to the SELECT clause.
		 * @param field1 First SObjectField to select
		 * @param field2 Second SObjectField to select
		 * @param field3 Third SObjectField to select
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder addSelect(SObjectField field1, SObjectField field2, SObjectField field3) {
			return this.addSelect(field1, field2, field3, null);
		}

		/**
		 * @description Adds 2 SObjectFields to the SELECT clause.
		 * @param field1 First SObjectField to select
		 * @param field2 Second SObjectField to select
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder addSelect(SObjectField field1, SObjectField field2) {
			return this.addSelect(field1, field2, null);
		}

		/**
		 * @description Adds a single SObjectField to the SELECT clause.
		 * @param field The SObjectField to select
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder addSelect(SObjectField field) {
			SObjectField nullField;
			return this.addSelect(field, nullField);
		}

		/**
		 * @description Adds multiple Selectable objects to the SELECT clause.
		 * @param fields List of Selectable objects to select
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder addSelect(List<Soql.Selectable> fields) {
			for (Soql.Selectable field : fields) {
				if (field != null) {
					this.handleSelectableLogic(field);
					this.addSelect(field?.toString());
				}
			}
			return this;
		}

		/**
		 * @description Adds 5 Selectable objects to the SELECT clause.
		 * @param field1 First Selectable object to select
		 * @param field2 Second Selectable object to select
		 * @param field3 Third Selectable object to select
		 * @param field4 Fourth Selectable object to select
		 * @param field5 Fifth Selectable object to select
		 * @return This Builder instance for method chaining
		 */
		@SuppressWarnings('PMD.ExcessiveParameterList')
		global Soql.Builder addSelect(
			Soql.Selectable field1,
			Soql.Selectable field2,
			Soql.Selectable field3,
			Soql.Selectable field4,
			Soql.Selectable field5
		) {
			// Currently supporting 5 selectables per addSelect call:
			return this.addSelect(new List<Soql.Selectable>{ field1, field2, field3, field4, field5 });
		}

		/**
		 * @description Adds 4 Selectable objects to the SELECT clause.
		 * @param field1 First Selectable object to select
		 * @param field2 Second Selectable object to select
		 * @param field3 Third Selectable object to select
		 * @param field4 Fourth Selectable object to select
		 * @return This Builder instance for method chaining
		 */
		@SuppressWarnings('PMD.ExcessiveParameterList')
		global Soql.Builder addSelect(
			Soql.Selectable field1,
			Soql.Selectable field2,
			Soql.Selectable field3,
			Soql.Selectable field4
		) {
			return this.addSelect(field1, field2, field3, field4, null);
		}

		/**
		 * @description Adds 3 Selectable objects to the SELECT clause.
		 * @param field1 First Selectable object to select
		 * @param field2 Second Selectable object to select
		 * @param field3 Third Selectable object to select
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder addSelect(Soql.Selectable field1, Soql.Selectable field2, Soql.Selectable field3) {
			return this.addSelect(field1, field2, field3, null);
		}

		/**
		 * @description Adds 2 Selectable objects to the SELECT clause.
		 * @param field1 First Selectable object to select
		 * @param field2 Second Selectable object to select
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder addSelect(Soql.Selectable field1, Soql.Selectable field2) {
			return this.addSelect(field1, field2, null);
		}

		/**
		 * @description Adds a single Selectable object to the SELECT clause.
		 * @param field The Selectable object to select
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder addSelect(Soql.Selectable field) {
			return this.addSelect(field, null);
		}

		/**
		 * @description Removes all fields from the SELECT clause.
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder deselectAll() {
			// Remove all SELECT fields from the current query
			this.selectAllPending = false;
			this.resolvedSelectClauses?.clear();
			return this;
		}

		/**
		 * @description Removes a specific field from the SELECT clause.
		 * @param fieldName The field name to remove
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder deselect(String fieldName) {
			// Remove a field from the current query
			this.selectClauses?.remove(fieldName);
			return this;
		}

		/**
		 * @description Removes a specific SObjectField from the SELECT clause.
		 * @param field The SObjectField to remove
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder deselect(SObjectField field) {
			return this.deselect(field?.toString());
		}

		/**
		 * @description Removes a specific Selectable object from the SELECT clause.
		 * @param selectable The Selectable object to remove
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder deselect(Soql.Selectable selectable) {
			return this.deselect(selectable?.toString());
		}

		// * FROM *
		/**
		 * @description Sets the FROM clause object type.
		 * @param objectType The SObjectType to query from
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder setFrom(SObjectType objectType) {
			this.entity = objectType?.toString();
			return this;
		}

		/**
		 * @description Sets the FROM clause to the specified entity name string.
		 * @param entityName The entity name to query from
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder setFrom(String entityName) {
			this.entity = entityName;
			return this;
		}

		/**
		 * @description Replaces the entire WHERE criteria tree.
		 * @param criteria The ConditionalLogic criteria to use
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder setWhereCriteria(Soql.ConditionalLogic criteria) {
			this.whereCriteria = criteria;
			return this;
		}

		/**
		 * @description Replaces the entire HAVING criteria tree.
		 * @param criteria The ConditionalLogic criteria to use
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder setHavingCriteria(Soql.ConditionalLogic criteria) {
			this.havingCriteria = criteria;
			return this;
		}

		/**
		 * @description Add a pre-formatted ORDER BY token verbatim (preserves round-trip fidelity)
		 * @param rawClause The raw ORDER BY clause to add
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder addRawOrderBy(String rawClause) {
			this.orderByClauses?.add(rawClause);
			return this;
		}

		/**
		 * @description Set WITH clause to any value (generalizes withSecurityEnforced)
		 * @param value The WITH clause value
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder setWithClause(String value) {
			this.withClause = value;
			return this;
		}

		// * USING SCOPE *
		/**
		 * @description Sets the USING SCOPE clause.
		 * @param scope The scope to use (MINE, EVERYTHING, etc.)
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder setScope(Soql.Scope scope) {
			this.scope = scope;
			return this;
		}

		// * WHERE *
		/**
		 * @description Adds a criteria object to the WHERE clause.
		 * @param criteria The criteria to add
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder addWhere(Soql.Criteria criteria) {
			this.whereCriteria?.addCondition(criteria);
			return this;
		}

		/**
		 * @description Adds a WHERE condition using field name, operator, and value.
		 * @param fieldName The field name to filter on
		 * @param operator The comparison operator
		 * @param value The value to compare against
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder addWhere(String fieldName, Soql.Operator operator, Object value) {
			// Shorthand overload constructs a Condition object for the caller
			return this.addWhere(new Soql.Condition(fieldName, operator, value));
		}

		/**
		 * @description Adds a WHERE condition using SObjectField, operator, and value.
		 * @param field The SObjectField to filter on
		 * @param operator The comparison operator
		 * @param value The value to compare against
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder addWhere(SObjectField field, Soql.Operator operator, Object value) {
			return this.addWhere(field?.toString(), operator, value);
		}

		/**
		 * @description Adds a WHERE condition using parent field, operator, and value.
		 * @param field The parent field to filter on
		 * @param operator The comparison operator
		 * @param value The value to compare against
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder addWhere(Soql.ParentField field, Soql.Operator operator, Object value) {
			return this.addWhere(field?.toString(), operator, value);
		}

		/**
		 * @description Adds a WHERE condition using field name, operator, and inner query.
		 * @param fieldName The field name to filter on
		 * @param operator The comparison operator
		 * @param innerQuery The inner query to compare against
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder addWhere(String fieldName, Soql.Operator operator, Soql.InnerQuery innerQuery) {
			// If the current `value` object is an InnerQuery, add its binds to the parent query:
			this.addBindsFromChildQuery(innerQuery);
			return this.addWhere(fieldName, operator, innerQuery?.toString());
		}

		/**
		 * @description Adds a WHERE condition using SObjectField, operator, and inner query.
		 * @param field The SObjectField to filter on
		 * @param operator The comparison operator
		 * @param innerQuery The inner query to compare against
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder addWhere(SObjectField field, Soql.Operator operator, Soql.InnerQuery innerQuery) {
			return this.addWhere(field?.toString(), operator, innerQuery);
		}

		/**
		 * @description Adds a WHERE condition using field name, operator, and bind variable.
		 * @param fieldName The field name to filter on
		 * @param operator The comparison operator
		 * @param binder The bind variable to compare against
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder addWhere(String fieldName, Soql.Operator operator, Soql.Binder binder) {
			// If the current `value` object is a Binder, bind the values so that callers don't need to do so manually
			return this.addWhere(fieldName, operator, binder?.toString())?.addBind(binder);
		}

		/**
		 * @description Adds a WHERE condition using SObjectField, operator, and bind variable.
		 * @param field The SObjectField to filter on
		 * @param operator The comparison operator
		 * @param binder The bind variable to compare against
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder addWhere(SObjectField field, Soql.Operator operator, Soql.Binder binder) {
			return this.addWhere(field?.toString(), operator, binder);
		}

		/**
		 * @description Adds a WHERE condition using parent field, operator, and bind variable.
		 * @param field The parent field to filter on
		 * @param operator The comparison operator
		 * @param binder The bind variable to compare against
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder addWhere(Soql.ParentField field, Soql.Operator operator, Soql.Binder binder) {
			return this.addWhere(field?.toString(), operator, binder);
		}

		/**
		 * @description Sets the logic type for combining WHERE conditions (AND/OR).
		 * @param newLogicType The logic type to use for WHERE conditions
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder setOuterWhereLogic(Soql.LogicType newLogicType) {
			this.whereCriteria?.setLogicType(newLogicType);
			return this;
		}

		// * WITH *
		/**
		 * @description Adds SECURITY_ENFORCED clause to the query and sets access level to SYSTEM_MODE.
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder withSecurityEnforced() {
			this.withClause = 'SECURITY_ENFORCED';
			// Note: Cannot use the WITH SECURITY_ENFORCED clause in queries using USER_MODE access level.
			this.setAccessLevel(System.AccessLevel.SYSTEM_MODE);
			return this;
		}

		// * GROUP BY *
		/**
		 * @description Adds a field to the GROUP BY clause.
		 * @param fieldName The field name to group by
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder addGroupBy(String fieldName) {
			// Note: GROUP BY queries should never assume an implicit "Id" in the query
			this.deselect(ID_REFERENCE);
			this.groupByClauses?.add(fieldName);
			return this;
		}

		/**
		 * @description Adds an SObjectField to the GROUP BY clause.
		 * @param field The SObjectField to group by
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder addGroupBy(SObjectField field) {
			return this.addGroupBy(field?.toString());
		}

		/**
		 * @description Adds a parent field to the GROUP BY clause.
		 * @param field The parent field to group by
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder addGroupBy(Soql.ParentField field) {
			return this.addGroupBy(field?.toString());
		}

		// * HAVING *
		/**
		 * @description Adds a HAVING condition using aggregation, operator, and value.
		 * @param agg The aggregation function to filter on
		 * @param operator The comparison operator
		 * @param value The value to compare against
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder addHaving(Soql.Aggregation agg, Soql.Operator operator, Object value) {
			// Shorthand overload constructs the AggregateCondition for the caller
			Soql.Condition condition = new Soql.Condition(agg?.toString(), operator, value);
			this.havingCriteria?.addCondition(condition);
			return this;
		}

		/**
		 * @description Sets the logic type for combining HAVING conditions (AND/OR).
		 * @param newLogicType The logic type to use for HAVING conditions
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder setOuterHavingLogic(Soql.LogicType newLogicType) {
			this.havingCriteria?.setLogicType(newLogicType);
			return this;
		}

		// * ORDER BY *
		/**
		 * @description Adds a sort order to the ORDER BY clause.
		 * @param sortOrder The sort order specification
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder addOrderBy(Soql.SortOrder sortOrder) {
			this.orderByClauses?.add(sortOrder?.toString());
			return this;
		}

		/**
		 * @description Adds an ORDER BY clause with field name and sort direction.
		 * @param fieldName The field name to sort by
		 * @param direction The sort direction (ASCENDING or DESCENDING)
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder addOrderBy(String fieldName, Soql.SortDirection direction) {
			Soql.SortOrder sortOrder = new Soql.SortOrder(fieldName, direction);
			return this.addOrderBy(sortOrder);
		}

		/**
		 * @description Adds an ORDER BY clause with SObjectField and sort direction.
		 * @param field The SObjectField to sort by
		 * @param direction The sort direction (ASCENDING or DESCENDING)
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder addOrderBy(SObjectField field, Soql.SortDirection direction) {
			return this.addOrderBy(field?.toString(), direction);
		}

		/**
		 * @description Adds an ORDER BY clause with parent field and sort direction.
		 * @param field The parent field to sort by
		 * @param direction The sort direction (ASCENDING or DESCENDING)
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder addOrderBy(Soql.ParentField field, Soql.SortDirection direction) {
			return this.addOrderBy(field?.toString(), direction);
		}

		// * LIMIT *
		/**
		 * @description Sets the LIMIT clause for maximum number of rows to return.
		 * @param rowLimit The maximum number of rows to return
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder setRowLimit(Integer rowLimit) {
			this.rowLimit = rowLimit;
			return this;
		}

		// * OFFSET *
		/**
		 * @description Sets the OFFSET clause for number of rows to skip.
		 * @param rowOffset The number of rows to skip
		 * @return This Builder instance for method chaining
		 */
		global Soql.Builder setRowOffset(Integer rowOffset) {
			this.rowOffset = rowOffset;
			return this;
		}

		// * USAGE *
		/**
		 * @description Sets the usage type for the query (FOR UPDATE, FOR VIEW, etc.).
		 * @param usage The usage type to apply
		 * @return This Builder instance for method chaining
		 */
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

		/**
		 * @description Builds the optional clauses of the SOQL query (WHERE, ORDER BY, etc.).
		 * @return String containing all optional query clauses
		 */
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

		/**
		 * @description Builds the SELECT clause of the SOQL query.
		 * @return String containing the SELECT clause fields
		 */
		protected virtual String getSelect() {
			return String.join(new List<String>(this.selectClauses), ', ');
		}

		/**
		 * @description Builds the usage clause (FOR UPDATE, FOR VIEW, etc.).
		 * @return String containing the usage clause
		 */
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
		/**
		 * @description The field name or property being compared in this condition.
		 */
		global final String property { get; protected set; }
		/**
		 * @description The comparison operator used in this condition.
		 */
		global final Soql.Operator operator { get; protected set; }
		/**
		 * @description The value being compared against in this condition.
		 */
		global final Object value { get; protected set; }

		/**
		 * @description Constructor for condition with property name, operator, and value.
		 * @param property The field name or property to compare
		 * @param operator The comparison operator
		 * @param value The value to compare against
		 */
		global Condition(String property, Soql.Operator operator, Object value) {
			this.property = property;
			this.operator = operator;
			this.value = value;
		}

		/**
		 * @description Constructor for condition with SObjectField, operator, and value.
		 * @param field The SObjectField to compare
		 * @param operator The comparison operator
		 * @param value The value to compare against
		 */
		global Condition(SObjectField field, Soql.Operator operator, Object value) {
			this(field?.toString(), operator, value);
		}

		/**
		 * @description Constructor for condition with parent field, operator, and value.
		 * @param field The parent field to compare
		 * @param operator The comparison operator
		 * @param value The value to compare against
		 */
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
			// Allow special modifiers (bind variables, inner queries, & relative date literals) to pass through unmodified
			if (value?.startsWith(':') == true || value?.startsWith('(') == true || this.isDateLiteral(value)) {
				return value;
			}
			if (value != null && value.length() >= 19 && value.contains('T') && this.isValidDateTimePrefix(value)) {
				return value;
			}
			return this.operator?.processStringValue(value);
		}

		private Boolean isDateLiteral(String value) {
			return value != null && DATE_LITERAL_PATTERN.matcher(value)?.matches() == true;
		}

		private Boolean isValidDateTimePrefix(String value) {
			if (value == null || value.length() < 10) {
				return false;
			}
			String prefix = value.substring(0, 10);
			if (prefix.substring(4, 5) != '-' || prefix.substring(7, 8) != '-') {
				return false;
			}
			try {
				Integer year = Integer.valueOf(prefix.substring(0, 4));
				Integer month = Integer.valueOf(prefix.substring(5, 7));
				Integer day = Integer.valueOf(prefix.substring(8, 10));
				return month >= 1 && month <= 12 && day >= 1 && day <= 31 && year >= 1000 && year <= 9999;
			} catch (Exception e) {
				return false;
			}
		}
	}

	/**
	 * @description Manages complex conditional logic with AND/OR operations for WHERE and HAVING clauses.
	 */
	global class ConditionalLogic implements Soql.Criteria {
		/**
		 * @description List of criteria conditions for this conditional logic.
		 */
		private List<Soql.Criteria> criterion = new List<Soql.Criteria>();
		/**
		 * @description The logic type for combining conditions (AND/OR).
		 */
		private Soql.LogicType logicType = Soql.LogicType.ALL_CONDITIONS;

		/**
		 * @description Adds multiple criteria conditions to this conditional logic.
		 * @param criterion List of criteria to add
		 * @return This ConditionalLogic instance for method chaining
		 */
		global ConditionalLogic addCondition(List<Soql.Criteria> criterion) {
			this.criterion?.addAll(criterion);
			return this;
		}

		/**
		 * @description Adds a single criteria condition to this conditional logic.
		 * @param criteria The criteria to add
		 * @return This ConditionalLogic instance for method chaining
		 */
		global ConditionalLogic addCondition(Soql.Criteria criteria) {
			return this.addCondition(new List<Soql.Criteria>{ criteria });
		}

		/**
		 * @description Adds a condition using field name, operator, and value.
		 * @param fieldName The field name to filter on
		 * @param operator The comparison operator
		 * @param value The value to compare against
		 * @return This ConditionalLogic instance for method chaining
		 */
		global ConditionalLogic addCondition(String fieldName, Soql.Operator operator, Object value) {
			Soql.Condition condition = new Soql.Condition(fieldName, operator, value);
			return this.addCondition(condition);
		}

		/**
		 * @description Adds a condition using SObjectField, operator, and value.
		 * @param field The SObjectField to filter on
		 * @param operator The comparison operator
		 * @param value The value to compare against
		 * @return This ConditionalLogic instance for method chaining
		 */
		global ConditionalLogic addCondition(SObjectField field, Soql.Operator operator, Object value) {
			return this.addCondition(field?.toString(), operator, value);
		}

		/**
		 * @description Adds a condition using parent field, operator, and value.
		 * @param field The parent field to filter on
		 * @param operator The comparison operator
		 * @param value The value to compare against
		 * @return This ConditionalLogic instance for method chaining
		 */
		global ConditionalLogic addCondition(Soql.ParentField field, Soql.Operator operator, Object value) {
			return this.addCondition(field?.toString(), operator, value);
		}

		/**
		 * @description Sets the logic type for combining conditions (AND/OR).
		 * @param logicType The logic type to use
		 * @return This ConditionalLogic instance for method chaining
		 */
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

		/**
		 * @description Gets the predicate string (AND/OR) based on the logic type.
		 * @return The predicate string for combining conditions
		 */
		private String getPredicate() {
			return (logicType == Soql.LogicType.ANY_CONDITIONS) ? 'OR' : 'AND';
		}
	}

	/**
	 * @description Operator for LIKE queries with wildcard patterns for contains operations.
	 */
	global virtual class ContainsOperator extends Soql.Operator {
		/**
		 * @description Constructor for ContainsOperator
		 * @param token The operator token
		 */
		private ContainsOperator(String token) {
			super(token);
		}

		/**
		 * @description Processes string values for CONTAINS operator by adding wildcard characters
		 * @param value The string value to process
		 * @return The processed string value with wildcards
		 */
		public override String processStringValue(String value) {
			return '\'%' + String.escapeSingleQuotes(value) + '%\'';
		}
	}

	/**
	 * @description Mockable wrapper for Database.Cursor that enables testing of cursor-based queries.
	 */
	global virtual class Cursor {
		protected Database.Cursor cursor;
		protected Integer numRecords {
			get {
				return this.cursor?.getNumRecords();
			}
		}

		protected Cursor(Database.Cursor cursor) {
			this.cursor = cursor;
		}

		/**
		 * @description Fetches records from the cursor starting at the specified position.
		 * @param position The starting position to fetch from
		 * @param count The number of records to fetch
		 * @return List of SObject records fetched from the cursor
		 */
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

		/**
		 * @description Gets the underlying Database.Cursor instance.
		 * @return The wrapped Database.Cursor instance
		 */
		global Database.Cursor getCursor() {
			return this.cursor;
		}

		/**
		 * @description Gets the total number of records available in the cursor.
		 * @return The total number of records in the cursor
		 */
		global virtual Integer getNumRecords() {
			return this.numRecords;
		}
	}

	/**
	 * @description Operator for LIKE queries with wildcard patterns for ends-with operations.
	 */
	global class EndsWithOperator extends Soql.Operator {
		/**
		 * @description Constructor for EndsWithOperator
		 * @param token The operator token
		 */
		private EndsWithOperator(String token) {
			super(token);
		}

		/**
		 * @description Processes string values for ENDS_WITH operator by adding prefix wildcard
		 * @param value The string value to process
		 * @return The processed string value with prefix wildcard
		 */
		public override String processStringValue(String value) {
			return '\'%' + String.escapeSingleQuotes(value) + '\'';
		}
	}

	/**
	 * @description Represents a subquery for use in WHERE clauses and other contexts requiring inner queries.
	 */
	global virtual class InnerQuery extends Soql.Builder implements Soql.Selectable {
		/**
		 * @description Default constructor that removes the default Id field from SELECT.
		 */
		protected InnerQuery() {
			this.deselect(ID_REFERENCE);
		}

		/**
		 * @description Constructor that sets the FROM clause to the specified object type.
		 * @param objectType The SObjectType to query from
		 */
		global InnerQuery(SObjectType objectType) {
			this();
			this.setFrom(objectType);
		}

		/**
		 * @description Constructor that sets the FROM clause to the specified entity name string.
		 * @param entityName The entity name to query from
		 */
		global InnerQuery(String entityName) {
			this();
			this.setFrom(entityName);
		}

		global override String toString() {
			return '(' + super.toString() + ')';
		}
	}

	/**
	 * @description Exception thrown when invalid parameters are provided to cursor operations.
	 */
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

		/**
		 * @description Processes a string value for use in SOQL queries by adding quotes and escaping.
		 * @param value The string value to process
		 * @return The processed string value with proper escaping and quotes
		 */
		public virtual String processStringValue(String value) {
			return '\'' + String.escapeSingleQuotes(value) + '\'';
		}

		global override String toString() {
			return this.token;
		}
	}

	/**
	 * @description Represents a reference to a field on a parent object for use in SOQL queries.
	 * SOQL supports querying fields objects up to 5 relationships away from the FROM object
	 */
	@SuppressWarnings('PMD.ExcessiveParameterList')
	global class ParentField implements Soql.Selectable {
		private String fieldReference;
		private String relationshipReference;

		/**
		 * @description Constructor that creates a parent field reference from a chain of relationship fields.
		 * @param relationshipFieldChain List of SObjectFields representing the relationship chain
		 */
		global ParentField(List<SObjectField> relationshipFieldChain) {
			relationshipFieldChain = relationshipFieldChain ?? new List<SObjectField>();
			this.computeReferences(relationshipFieldChain);
		}

		/**
		 * @description Constructor for 5 relationship levels deep.
		 * @param relationship1 First relationship field
		 * @param relationship2 Second relationship field
		 * @param relationship3 Third relationship field
		 * @param relationship4 Fourth relationship field
		 * @param relationship5 Fifth relationship field
		 * @param field The target field
		 */
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

		/**
		 * @description Constructor for 4 relationship levels deep.
		 * @param relationship1 First relationship field
		 * @param relationship2 Second relationship field
		 * @param relationship3 Third relationship field
		 * @param relationship4 Fourth relationship field
		 * @param field The target field
		 */
		global ParentField(
			SObjectField relationship1,
			SObjectField relationship2,
			SObjectField relationship3,
			SObjectField relationship4,
			SObjectField field
		) {
			this(new List<SObjectField>{ relationship1, relationship2, relationship3, relationship4, field });
		}

		/**
		 * @description Constructor for 3 relationship levels deep.
		 * @param relationship1 First relationship field
		 * @param relationship2 Second relationship field
		 * @param relationship3 Third relationship field
		 * @param field The target field
		 */
		global ParentField(
			SObjectField relationship1,
			SObjectField relationship2,
			SObjectField relationship3,
			SObjectField field
		) {
			this(new List<SObjectField>{ relationship1, relationship2, relationship3, field });
		}

		/**
		 * @description Constructor for 2 relationship levels deep.
		 * @param relationship1 First relationship field
		 * @param relationship2 Second relationship field
		 * @param field The target field
		 */
		global ParentField(SObjectField relationship1, SObjectField relationship2, SObjectField field) {
			this(new List<SObjectField>{ relationship1, relationship2, field });
		}

		/**
		 * @description Constructor for 1 relationship level deep.
		 * @param relationship1 The relationship field
		 * @param field The target field
		 */
		global ParentField(SObjectField relationship1, SObjectField field) {
			this(new List<SObjectField>{ relationship1, field });
		}

		/**
		 * @description Outputs the SOQL relationship of the compound field
		 * @return The dot-notation relationship reference string
		 */
		global String getRelationshipName() {
			return this.relationshipReference;
		}

		global override String toString() {
			return this.fieldReference;
		}

		/**
		 * @description Computes dot-notation string representations from the field chain.
		 * @param fields List of fields in the relationship chain
		 */
		private void computeReferences(List<SObjectField> fields) {
			// Generate the references to the parent field based on the ordered chain:
			List<String> components = new List<String>();
			String targetFieldRelationshipName;
			Integer size = fields?.size();
			Integer lastIndex = size - 1;
			for (Integer i = 0; i < size; i++) {
				SObjectField field = fields?.get(i);
				String relationshipName = field?.getDescribe()?.getRelationshipName();
				if (i < lastIndex) {
					components?.add(relationshipName);
				} else {
					// Final field in the chain:
					String targetFieldApiName = field?.toString();
					components?.add(targetFieldApiName);
					targetFieldRelationshipName = relationshipName;
				}
			}
			// Compute the compound field's API name
			this.fieldReference = String.join(components, '.');
			// Compute the compound field's relationship name
			components?.remove(lastIndex);
			components?.add(targetFieldRelationshipName);
			this.relationshipReference = String.join(components, '.');
		}
	}

	/**
	 * @description Mockable wrapper for Database.QueryLocator that enables testing of batch processing queries.
	 */
	global virtual class QueryLocator {
		protected transient Database.QueryLocator locator;

		protected QueryLocator(Database.QueryLocator locator) {
			this.locator = locator;
		}

		/**
		 * @description Gets the underlying Database.QueryLocator instance.
		 * @return The wrapped Database.QueryLocator instance
		 */
		global virtual Database.QueryLocator getLocator() {
			return this.locator;
		}

		/**
		 * @description Gets the SOQL query string from the query locator.
		 * @return The SOQL query string
		 */
		global virtual String getQuery() {
			return this.locator?.getQuery();
		}

		/**
		 * @description Gets an iterator for processing records in the query locator.
		 * @return Iterator for processing SObject records
		 */
		global virtual System.Iterator<SObject> iterator() {
			return (System.Iterator<SObject>) this.locator?.iterator();
		}
	}

	/**
	 * @description Encapsulates a single SOQL operation with all its parameters and execution logic.
	 */
	global inherited sharing virtual class Request {
		/**
		 * @description Indicates whether this request is using mock SOQL behavior.
		 */
		global Boolean isMockSoql { get; protected set; }
		/**
		 * @description The type of SOQL operation being performed.
		 */
		global Soql.Operation operation { get; private set; }
		/**
		 * @description The Soql query instance being executed.
		 */
		global Soql query { get; private set; }
		/**
		 * @description The SOQL query string representation.
		 */
		global String queryString {
			get {
				return this.query?.toString();
			}
		}
		protected transient System.AccessLevel accessLevel { get; private set; }
		protected transient Map<String, Object> binds { get; private set; }

		protected Request(Soql query, Soql.Operation operation) {
			this.accessLevel = query?.accessLevel;
			this.binds = query?.binds;
			this.isMockSoql = false;
			this.operation = operation;
			this.query = query;
		}

		/**
		 * @description Processes the SOQL request with pre/post processing and error handling.
		 * @return The result of the SOQL operation
		 */
		public Object process() {
			try {
				DatabaseLayer.Utils.Plugins.Soql?.processPreSoql(this);
				Object results = this.performQueryOperation();
				DatabaseLayer.Utils.Plugins.Soql?.processPostSoql(this, results);
				return results;
			} catch (Exception error) {
				DatabaseLayer.Utils.Plugins.Soql?.processSoqlError(this, error);
				String augmentedMsg = error?.getMessage() + '\nQuery: [' + this.queryString + ']';
				error?.setMessage(augmentedMsg);
				throw error;
			}
		}

		/**
		 * @description Performs the appropriate query operation based on the operation type.
		 * @return The result of the query operation
		 */
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

		/**
		 * @description Executes an aggregate query and wraps results in AggregateResult objects.
		 * @return List of wrapped aggregate results
		 */
		protected virtual List<Soql.AggregateResult> doAggregateQuery() {
			List<Schema.AggregateResult> results = (List<Schema.AggregateResult>) this.doQuery();
			List<Soql.AggregateResult> wrappers = new List<Soql.AggregateResult>();
			for (Schema.AggregateResult result : results) {
				Soql.AggregateResult wrapper = new Soql.AggregateResult(result);
				wrappers?.add(wrapper);
			}
			return wrappers;
		}

		/**
		 * @description Executes a COUNT query and returns the number of matching records.
		 * @return Integer count of matching records
		 */
		protected virtual Integer doCountQuery() {
			// Note: A count query must not contain any fields, other than COUNT() aggregation
			// Avoid errors and simplify query construction by handling this in a temporary copy of the current query
			Soql.Aggregation count = new Soql.Aggregation(Soql.Function.COUNT);
			this.query?.deselectAll()?.addSelect(count)?.toSoql();
			return Database.countQueryWithBinds(this.queryString, this.binds, this.accessLevel);
		}

		/**
		 * @description Executes the query and returns a cursor for result processing.
		 * @return Soql.Cursor wrapper for the query results
		 */
		protected virtual Soql.Cursor doGetCursor() {
			Database.Cursor cursor = Database.getCursorWithBinds(this.queryString, this.binds, this.accessLevel);
			return new Soql.Cursor(cursor);
		}

		/**
		 * @description Executes the query and returns a query locator for batch processing.
		 * @return Soql.QueryLocator wrapper for batch processing
		 */
		protected virtual Soql.QueryLocator doGetQueryLocator() {
			Database.QueryLocator locator = Database.getQueryLocatorWithBinds(
				this.queryString,
				this.binds,
				this.accessLevel
			);
			return new Soql.QueryLocator(locator);
		}

		/**
		 * @description Executes the basic SOQL query and returns matching records.
		 * @return List of SObject records matching the query criteria
		 */
		protected virtual Object doQuery() {
			return Database.queryWithBinds(this.queryString, this.binds, this.accessLevel);
		}
	}

	/**
	 * @description Represents an ORDER BY clause specification with field names, sort direction, and null ordering.
	 */
	global class SortOrder {
		private List<String> fieldNames = new List<String>();
		private Soql.SortDirection direction = Soql.SortDirection.ASCENDING;
		private Soql.NullOrder nullOrder = Soql.NullOrder.NULLS_LAST;

		/**
		 * @description Constructor for sort order with multiple field names.
		 * @param fieldNames List of field names to sort by
		 * @param direction The sort direction (ASCENDING or DESCENDING)
		 */
		global SortOrder(List<String> fieldNames, Soql.SortDirection direction) {
			this.fieldNames = fieldNames;
			this.direction = direction;
		}

		/**
		 * @description Constructor for sort order with a single field name.
		 * @param fieldName The field name to sort by
		 * @param direction The sort direction (ASCENDING or DESCENDING)
		 */
		global SortOrder(String fieldName, Soql.SortDirection direction) {
			this(new List<String>{ fieldName }, direction);
		}

		/**
		 * @description Constructor for sort order with multiple SObjectFields.
		 * @param fields List of SObjectFields to sort by
		 * @param direction The sort direction (ASCENDING or DESCENDING)
		 */
		global SortOrder(List<SObjectField> fields, Soql.SortDirection direction) {
			for (SObjectField field : fields) {
				this.fieldNames?.add(field?.toString());
			}
			this.direction = direction;
		}

		/**
		 * @description Constructor for sort order with a single SObjectField.
		 * @param field The SObjectField to sort by
		 * @param direction The sort direction (ASCENDING or DESCENDING)
		 */
		global SortOrder(SObjectField field, Soql.SortDirection direction) {
			this(new List<SObjectField>{ field }, direction);
		}

		/**
		 * @description Constructor for sort order with multiple parent fields.
		 * @param fields List of parent fields to sort by
		 * @param direction The sort direction (ASCENDING or DESCENDING)
		 */
		global SortOrder(List<Soql.ParentField> fields, Soql.SortDirection direction) {
			for (Soql.ParentField field : fields) {
				this.fieldNames?.add(field?.toString());
			}
			this.direction = direction;
		}

		/**
		 * @description Constructor for sort order with a single parent field.
		 * @param field The parent field to sort by
		 * @param direction The sort direction (ASCENDING or DESCENDING)
		 */
		global SortOrder(Soql.ParentField field, Soql.SortDirection direction) {
			this(new List<Soql.ParentField>{ field }, direction);
		}

		/**
		 * @description Sets the null ordering for the sort order.
		 * @param nullOrder The null ordering (NULLS_FIRST or NULLS_LAST)
		 * @return This SortOrder instance for method chaining
		 */
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

	/**
	 * @description Operator for LIKE queries with wildcard patterns for starts-with operations.
	 */
	global class StartsWithOperator extends Soql.Operator {
		/**
		 * @description Constructor for StartsWithOperator
		 * @param token The operator token
		 */
		private StartsWithOperator(String token) {
			super(token);
		}

		/**
		 * @description Processes string values for STARTS_WITH operator by adding suffix wildcard
		 * @param value The string value to process
		 * @return The processed string value with suffix wildcard
		 */
		public override String processStringValue(String value) {
			return '\'' + String.escapeSingleQuotes(value) + '%\'';
		}
	}

	/**
	 * @description Represents a subquery for use in SELECT clauses, using child relationship names.
	 */
	global class Subquery extends Soql.InnerQuery {
		private String relationshipName;

		/**
		 * @description Constructor that creates a subquery from a child relationship.
		 * @param relationship The child relationship to query
		 */
		global Subquery(Schema.ChildRelationship relationship) {
			this.addSelect(ID_REFERENCE);
			this.relationshipName = relationship?.getRelationshipName();
		}

		/**
		 * @description Constructor that creates a subquery from a lookup field on the child object.
		 * @param lookupFieldOnChildObject The lookup field on the child object
		 */
		global Subquery(SObjectField lookupFieldOnChildObject) {
			this(DatabaseLayer.Utils.ChildRelationships.getChildRelationshipFrom(lookupFieldOnChildObject));
		}

		/**
		 * @description Gets the FROM clause using the child relationship name.
		 * @return The child relationship name for the FROM clause
		 */
		global override String getFrom() {
			return this.relationshipName;
		}
	}

	/**
	 * @description Represents a TYPEOF clause for polymorphic field queries in SOQL.
	 */
	global class TypeOf implements Soql.Selectable {
		private List<String> elseFields;
		private String relationshipName;
		private List<String> whenClauses;

		/**
		 * @description Constructor for TypeOf with relationship name.
		 * @param relationshipName The polymorphic field name to query
		 */
		global TypeOf(String relationshipName) {
			this.relationshipName = relationshipName;
			this.whenClauses = new List<String>{};
		}

		/**
		 * @description Constructor for TypeOf with SObjectField.
		 * @param field The polymorphic SObjectField to query
		 */
		global TypeOf(SObjectField field) {
			this(field?.getDescribe()?.getRelationshipName());
		}

		/**
		 * @description Constructor for TypeOf with parent field.
		 * @param field The polymorphic parent field to query
		 */
		global TypeOf(Soql.ParentField field) {
			this(field?.getRelationshipName());
		}

		/**
		 * @description Adds a WHEN clause and returns a builder for specifying fields.
		 * @param objectType The SObjectType to match in the WHEN clause
		 * @return A WhenClause builder for specifying the fields to select
		 */
		global Soql.WhenClause when(SObjectType objectType) {
			return new Soql.WhenClause(this, objectType);
		}

		/**
		 * @description Adds an ELSE clause with multiple field names.
		 * @param fieldNames List of field names to select in the ELSE clause
		 * @return This TypeOf instance for method chaining
		 */
		global Soql.TypeOf elseSelect(List<String> fieldNames) {
			this.elseFields = fieldNames;
			return this;
		}

		/**
		 * @description Adds an ELSE clause with up to 5 field names.
		 * @param field1 First field name
		 * @param field2 Second field name
		 * @param field3 Third field name
		 * @param field4 Fourth field name
		 * @param field5 Fifth field name
		 * @return This TypeOf instance for method chaining
		 */
		@SuppressWarnings('PMD.ExcessiveParameterList')
		global Soql.TypeOf elseSelect(String field1, String field2, String field3, String field4, String field5) {
			List<String> fields = new List<String>();
			for (String field : new List<String>{ field1, field2, field3, field4, field5 }) {
				if (String.isNotBlank(field)) {
					fields.add(field);
				}
			}
			return this.elseSelect(fields);
		}

		/**
		 * @description Adds an ELSE clause with 4 field names.
		 * @param field1 First field name
		 * @param field2 Second field name
		 * @param field3 Third field name
		 * @param field4 Fourth field name
		 * @return This TypeOf instance for method chaining
		 */
		@SuppressWarnings('PMD.ExcessiveParameterList')
		global Soql.TypeOf elseSelect(String field1, String field2, String field3, String field4) {
			return this.elseSelect(field1, field2, field3, field4, null);
		}

		/**
		 * @description Adds an ELSE clause with 3 field names.
		 * @param field1 First field name
		 * @param field2 Second field name
		 * @param field3 Third field name
		 * @return This TypeOf instance for method chaining
		 */
		global Soql.TypeOf elseSelect(String field1, String field2, String field3) {
			return this.elseSelect(field1, field2, field3, null);
		}

		/**
		 * @description Adds an ELSE clause with 2 field names.
		 * @param field1 First field name
		 * @param field2 Second field name
		 * @return This TypeOf instance for method chaining
		 */
		global Soql.TypeOf elseSelect(String field1, String field2) {
			return this.elseSelect(field1, field2, null);
		}

		/**
		 * @description Adds an ELSE clause with a single field name.
		 * @param fieldName The field name to select in the ELSE clause
		 * @return This TypeOf instance for method chaining
		 */
		global Soql.TypeOf elseSelect(String fieldName) {
			return this.elseSelect(fieldName, null);
		}

		global override String toString() {
			// Construct a valid TYPEOF...WHEN...THEN...ELSE...END clause
			List<String> parts = new List<String>();
			parts.add('TYPEOF ' + this.relationshipName);
			for (String whenClause : this.whenClauses) {
				parts.add(whenClause);
			}
			if (this.elseFields != null && !this.elseFields.isEmpty()) {
				String fields = String.join(this.elseFields, ', ');
				parts.add('ELSE ' + fields);
			}
			parts.add('END');
			return String.join(parts, ' ');
		}

		/**
		 * @description Internal method to add a when clause.
		 * @param objectType The SObjectType for this WHEN clause
		 * @param fieldNames List of field names to select
		 */
		private void addWhenClause(SObjectType objectType, List<String> fieldNames) {
			String fields = String.join(fieldNames, ', ');
			this.whenClauses.add('WHEN ' + objectType + ' THEN ' + fields);
		}
	}

	/**
	 * @description Builder for WHEN clauses in TYPEOF queries.
	 */
	global class WhenClause {
		private Soql.TypeOf parent;
		private SObjectType objectType;

		/**
		 * @description Constructor for WhenClause builder.
		 * @param parent The parent TypeOf instance
		 * @param objectType The SObjectType for this WHEN clause
		 */
		private WhenClause(Soql.TypeOf parent, SObjectType objectType) {
			this.parent = parent;
			this.objectType = objectType;
		}

		/**
		 * @description Specifies fields to select for this WHEN clause using a list of SObjectFields.
		 * @param fields List of SObjectFields to select
		 * @return The parent TypeOf instance for continued chaining
		 */
		global Soql.TypeOf thenSelect(List<SObjectField> fields) {
			List<String> fieldNames = new List<String>();
			for (SObjectField field : fields) {
				if (field != null) {
					fieldNames.add(field?.toString());
				}
			}
			this.parent?.addWhenClause(this.objectType, fieldNames);
			return this.parent;
		}

		/**
		 * @description Specifies up to 5 SObjectFields to select for this WHEN clause.
		 * @param field1 First SObjectField
		 * @param field2 Second SObjectField
		 * @param field3 Third SObjectField
		 * @param field4 Fourth SObjectField
		 * @param field5 Fifth SObjectField
		 * @return The parent TypeOf instance for continued chaining
		 */
		@SuppressWarnings('PMD.ExcessiveParameterList')
		global Soql.TypeOf thenSelect(
			SObjectField field1,
			SObjectField field2,
			SObjectField field3,
			SObjectField field4,
			SObjectField field5
		) {
			return this.thenSelect(new List<SObjectField>{ field1, field2, field3, field4, field5 });
		}

		/**
		 * @description Specifies 4 SObjectFields to select for this WHEN clause.
		 * @param field1 First SObjectField
		 * @param field2 Second SObjectField
		 * @param field3 Third SObjectField
		 * @param field4 Fourth SObjectField
		 * @return The parent TypeOf instance for continued chaining
		 */
		@SuppressWarnings('PMD.ExcessiveParameterList')
		global Soql.TypeOf thenSelect(
			SObjectField field1,
			SObjectField field2,
			SObjectField field3,
			SObjectField field4
		) {
			return this.thenSelect(field1, field2, field3, field4, null);
		}

		/**
		 * @description Specifies 3 SObjectFields to select for this WHEN clause.
		 * @param field1 First SObjectField
		 * @param field2 Second SObjectField
		 * @param field3 Third SObjectField
		 * @return The parent TypeOf instance for continued chaining
		 */
		global Soql.TypeOf thenSelect(SObjectField field1, SObjectField field2, SObjectField field3) {
			return this.thenSelect(field1, field2, field3, null);
		}

		/**
		 * @description Specifies 2 SObjectFields to select for this WHEN clause.
		 * @param field1 First SObjectField
		 * @param field2 Second SObjectField
		 * @return The parent TypeOf instance for continued chaining
		 */
		global Soql.TypeOf thenSelect(SObjectField field1, SObjectField field2) {
			return this.thenSelect(field1, field2, null);
		}

		/**
		 * @description Specifies 1 SObjectField to select for this WHEN clause.
		 * @param field The SObjectField to select
		 * @return The parent TypeOf instance for continued chaining
		 */
		global Soql.TypeOf thenSelect(SObjectField field) {
			return this.thenSelect(field, null);
		}

		/**
		 * @description Specifies fields to select for this WHEN clause using a list of Soql.Selectables.
		 * @param fields List of Soql.Selectables to select
		 * @return The parent TypeOf instance for continued chaining
		 */
		global Soql.TypeOf thenSelect(List<Soql.Selectable> fields) {
			List<String> fieldNames = new List<String>();
			for (Soql.Selectable field : fields) {
				if (field != null) {
					fieldNames.add(field?.toString());
				}
			}
			this.parent?.addWhenClause(this.objectType, fieldNames);
			return this.parent;
		}

		/**
		 * @description Specifies up to 5 Soql.Selectables to select for this WHEN clause.
		 * @param field1 First Soql.Selectable
		 * @param field2 Second Soql.Selectable
		 * @param field3 Third Soql.Selectable
		 * @param field4 Fourth Soql.Selectable
		 * @param field5 Fifth Soql.Selectable
		 * @return The parent TypeOf instance for continued chaining
		 */
		@SuppressWarnings('PMD.ExcessiveParameterList')
		global Soql.TypeOf thenSelect(
			Soql.Selectable field1,
			Soql.Selectable field2,
			Soql.Selectable field3,
			Soql.Selectable field4,
			Soql.Selectable field5
		) {
			return this.thenSelect(new List<Soql.Selectable>{ field1, field2, field3, field4, field5 });
		}

		/**
		 * @description Specifies 4 Soql.Selectables to select for this WHEN clause.
		 * @param field1 First Soql.Selectable
		 * @param field2 Second Soql.Selectable
		 * @param field3 Third Soql.Selectable
		 * @param field4 Fourth Soql.Selectable
		 * @return The parent TypeOf instance for continued chaining
		 */
		@SuppressWarnings('PMD.ExcessiveParameterList')
		global Soql.TypeOf thenSelect(
			Soql.Selectable field1,
			Soql.Selectable field2,
			Soql.Selectable field3,
			Soql.Selectable field4
		) {
			return this.thenSelect(field1, field2, field3, field4, null);
		}

		/**
		 * @description Specifies 3 Soql.Selectables to select for this WHEN clause.
		 * @param field1 First Soql.Selectable
		 * @param field2 Second Soql.Selectable
		 * @param field3 Third Soql.Selectable
		 * @return The parent TypeOf instance for continued chaining
		 */
		global Soql.TypeOf thenSelect(Soql.Selectable field1, Soql.Selectable field2, Soql.Selectable field3) {
			return this.thenSelect(field1, field2, field3, null);
		}

		/**
		 * @description Specifies 2 Soql.Selectables to select for this WHEN clause.
		 * @param field1 First Soql.Selectable
		 * @param field2 Second Soql.Selectable
		 * @return The parent TypeOf instance for continued chaining
		 */
		global Soql.TypeOf thenSelect(Soql.Selectable field1, Soql.Selectable field2) {
			return this.thenSelect(field1, field2, null);
		}

		/**
		 * @description Specifies 1 Soql.Selectable to select for this WHEN clause.
		 * @param field The Soql.Selectable to select
		 * @return The parent TypeOf instance for continued chaining
		 */
		global Soql.TypeOf thenSelect(Soql.Selectable field) {
			return this.thenSelect(field, null);
		}
	}
}
