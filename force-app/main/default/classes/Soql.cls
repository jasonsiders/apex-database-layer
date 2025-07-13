@SuppressWarnings(
	'PMD.ApexDoc, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.ExcessiveClassLength, PMD.ExcessivePublicCount'
)
public inherited sharing virtual class Soql extends Soql.Builder {
	/**
	 * This class is responsible for performing query operations with the Salesforce database.
	 * While apex allows developers an inline method to directly perform queries against the database,
	 * use of these methods does not facilitate mocking, which can result in slower test times.
	 * Use this class instead of inline SOQL.
	 * Each of this class's methods eventually ties back to an underlying `Database` method,
	 * ex., `query()` -> `Database.query()`.
	 * To mock this instance, use the included `MockSoql` class, or use your own class which extends `Soql`.
	 **/

	// These operators are frequently used in WHERE clauses
	public static final Operator EQUALS = new Soql.Operator('=');
	public static final Operator NOT_EQUALS = new Soql.Operator('!=');
	public static final Operator IN_COLLECTION = new Soql.Operator('IN');
	public static final Operator NOT_IN_COLLECTION = new Soql.Operator('NOT IN');
	public static final Operator GREATER_THAN = new Soql.Operator('>');
	public static final Operator GREATER_OR_EQUAL = new Soql.Operator('>=');
	public static final Operator LESS_THAN = new Soql.Operator('<');
	public static final Operator LESS_OR_EQUAL = new Soql.Operator('<=');
	public static final Operator STARTS_WITH = new Soql.StartsWithOperator('LIKE');
	public static final Operator NOT_STARTS_WITH = new Soql.StartsWithOperator('NOT LIKE');
	public static final Operator ENDS_WITH = new Soql.EndsWithOperator('LIKE');
	public static final Operator NOT_ENDS_WITH = new Soql.EndsWithOperator('NOT LIKE');
	public static final Operator CONTAINS = new Soql.ContainsOperator('LIKE');
	public static final Operator NOT_CONTAINS = new Soql.ContainsOperator('NOT LIKE');
	// Other constants
	private static final Soql.LogicType DEFAULT_LOGIC_TYPE = Soql.LogicType.ALL_CONDITIONS;
	private static final String ID_REFERENCE = 'Id';

	// Member Properties:
	public String identifier { get; private set; }

	public Soql(DatabaseLayer factory) {
		this();
	}

	protected Soql() {
		super();
	}

	public List<Soql.AggregateResult> aggregateQuery() {
		// Call this method for aggregate queries, when not casting to a specific Type.
		// Note: Since the Schema.AggregateResult class cannot be mocked via traditional means,
		// this method returns a decorator object. See the "AggregateResult" inner class.
		return (List<Soql.AggregateResult>) this.initRequest(Soql.Operation.AGGREGATE_QUERY)?.process();
	}

	public Integer countQuery() {
		// Returns the results of a SOQL COUNT() query:
		return (Integer) this.initRequest(Soql.Operation.COUNT_QUERY)?.process();
	}

	public Soql.Cursor getCursor() {
		// Returns the query results as a Soql.Cursor object
		// This type wraps a Database.Cursor, which cannot be mocked
		return (Soql.Cursor) this.initRequest(Soql.Operation.GET_CURSOR)?.process();
	}

	public Soql.QueryLocator getQueryLocator() {
		// Returns the query results as a Soql.QueryLocator object
		// This type wraps a Database.QueryLocator, which cannot be mocked
		return (Soql.QueryLocator) this.initRequest(Soql.Operation.GET_QUERY_LOCATOR)?.process();
	}

	public List<SObject> query() {
		// Perform a standard SOQL query, returning a List<SObject>:
		return (List<SObject>) this.initRequest(Soql.Operation.QUERY)?.process();
	}

	public Object query(Type returnType) {
		// Return the query results as an instance of the returnType
		// Mostly useful for returning Aggregate Query results as a wrapper type
		Object result = this.initRequest(Soql.Operation.QUERY)?.process();
		return JSON.deserialize(JSON.serialize(result), returnType);
	}

	public SObject queryFirst() {
		// Returns the first result of the query, or null if no results returned
		// Facilitates & simplifies assigning query results to a single SObject
		// Temporarily set a LIMIT 1
		Integer originalLimit = this.rowLimit;
		this.setRowLimit(1);
		// Retrieve the query results - should be either 0 or 1
		List<SObject> results = this.query();
		// Now revert to the original row limit
		this.setRowLimit(originalLimit);
		return results?.isEmpty() == false ? results?.get(0) : null;
	}

	public Soql setQueryIdentifier(String identifier) {
		// Use this method to give a name/identifier value that can be referenced in mocks
		this.identifier = identifier;
		return this;
	}

	protected virtual Soql.Request initRequest(Soql.Operation operation) {
		return new Soql.Request(this, operation);
	}

	// **** ENUMS *** //
	public enum Function {
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

	public enum LogicType {
		ALL_CONDITIONS,
		ANY_CONDITIONS
	}

	public enum NullOrder {
		NULLS_FIRST,
		NULLS_LAST
	}

	public enum Operation {
		AGGREGATE_QUERY,
		COUNT_QUERY,
		GET_CURSOR,
		GET_QUERY_LOCATOR,
		QUERY
	}

	public enum Scope {
		// https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql_select_using_scope.htm
		DELEGATED,
		EVERYTHING,
		MINE,
		MINE_AND_MY_GROUPS,
		MY_TERRITORY,
		MY_TEAM_TERRITORY,
		TEAM
	}

	public enum SortDirection {
		ASCENDING,
		DESCENDING
	}

	public enum Usage {
		// https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql_select_for_view.htm
		// https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql_select_for_reference.htm
		// https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql_select_for_update.htm
		ALL_ROWS,
		FOR_VIEW,
		FOR_REFERENCE,
		FOR_UPDATE
	}

	// **** INTERFACE **** //
	public interface Criteria {
		// Mostly a marker interface, but also used to coerce toString()
		// Use this to denote classes that can be used in WHERE/HAVING clauses
		String toString();
	}

	public interface PreAndPostProcessor {
		void processPreSoql(Soql.Request request);
		void processPostSoql(Soql.Request request, Object results);
		void processSoqlError(Soql.Request request, Exception error);
	}

	public interface Selectable {
		// Mostly a marker interface, but also used to coerce toString()
		// Use this to denote classes that can be used in SELECT clauses
		String toString();
	}

	// **** INNER **** //
	public virtual class AggregateResult {
		protected Map<String, Object> params;

		protected AggregateResult(Schema.AggregateResult result) {
			this.params = result?.getPopulatedFieldsAsMap() ?? new Map<String, Object>();
		}

		public Object get(String key) {
			return this.params?.get(key);
		}
	}

	public class Aggregation implements Soql.Selectable {
		private String alias;
		private String innerFieldName;
		private Function function;

		public Aggregation(Soql.Function function, String innerFieldName) {
			this.alias = '';
			this.innerFieldName = innerFieldName;
			this.function = function;
		}

		public Aggregation(Soql.Function function, SObjectField field) {
			this(function, field?.toString());
		}

		public Aggregation(Soql.Function function, Soql.ParentField field) {
			this(function, field?.toString());
		}

		public Aggregation(Soql.Function function) {
			this(function, '');
		}

		public override String toString() {
			String formatted = String.format(
				'{0}({1}) {2}',
				new List<String>{ this.function?.toString(), this.innerFieldName, this.alias }
			);
			return formatted?.trim();
		}

		public Soql.Aggregation withAlias(String alias) {
			this.alias = alias;
			return this;
		}
	}

	public class Binder {
		public String key { get; private set; }
		public Object value { get; private set; }

		public Binder(String key, Object value) {
			this.key = key;
			this.setValue(value);
		}

		public Binder(String key) {
			this(key, null);
		}

		public String getKey() {
			return this.key;
		}

		public Object getValue() {
			return this.value;
		}

		public Soql.Binder setValue(Object value) {
			this.value = value;
			return this;
		}

		public override String toString() {
			return ':' + this.getKey();
		}
	}

	public abstract class Builder {
		public transient System.AccessLevel accessLevel { get; protected set; }
		public Map<String, Object> binds { get; protected set; }
		public String entity { get; protected set; }
		public List<String> groupByClauses { get; protected set; }
		public Soql.ConditionalLogic havingCriteria { get; protected set; }
		public List<String> orderByClauses { get; protected set; }
		public Integer rowLimit { get; protected set; }
		public Integer rowOffset { get; protected set; }
		public Soql.Scope scope { get; protected set; }
		public Set<String> selectClauses { get; protected set; }
		public Soql.Usage usage { get; protected set; }
		public Soql.ConditionalLogic whereCriteria { get; protected set; }
		public String withClause { get; protected set; }
		// Read-only properties included for JSON output:
		public String accessLevelName {
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

		public virtual override String toString() {
			// Outputs a SOQL Query string, following the syntax defined here:
			// https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql_select.htm#:~:text=SOQL%20query%20syntax%20consists%20of,typeOfField%20whenExpression%5B...%5D
			List<String> queryArgs = new List<String>{ this.getSelect(), this.getFrom(), this.getOptionalArgs() };
			return String.format('SELECT {0} FROM {1} {2}', queryArgs)?.trim();
		}

		public Soql.Builder addBind(Map<String, Object> bindMap) {
			this.binds?.putAll(bindMap);
			return this;
		}

		public Soql.Builder addBind(String key, Object value) {
			return this.addBind(new Map<String, Object>{ key => value });
		}

		public Soql.Builder addBind(Soql.Binder binder) {
			return this.addBind(binder?.getKey(), binder?.getValue());
		}

		public Soql.Builder setAccessLevel(System.AccessLevel accessLevel) {
			this.accessLevel = accessLevel;
			return this;
		}

		public Soql.Builder reset() {
			this.accessLevel = System.AccessLevel.USER_MODE;
			this.binds = new Map<String, Object>();
			this.groupByClauses = new List<String>();
			this.havingCriteria = new Soql.ConditionalLogic();
			this.orderByClauses = new List<String>();
			this.selectClauses = new Set<String>{ ID_REFERENCE };
			this.whereCriteria = new Soql.ConditionalLogic();
			return this;
		}

		public Soql.InnerQuery toInnerQuery() {
			return (Soql.InnerQuery) this;
		}

		public Soql toSoql() {
			return (Soql) this;
		}

		public Soql.Subquery toSubquery() {
			return (Soql.Subquery) this;
		}

		// * SELECT *
		@SuppressWarnings('PMD.EagerlyLoadedDescribeSObjectResult')
		public Soql.Builder selectAll() {
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
		public Soql.Builder addSelect(String fieldName, String alias) {
			String clause = String.join(new List<String>{ fieldName, alias }, ' ')?.trim();
			this.selectClauses?.add(clause);
			return this;
		}

		public Soql.Builder addSelect(SObjectField field, String alias) {
			return this.addSelect(field?.toString(), alias);
		}

		public Soql.Builder addSelect(Soql.ParentField field, String alias) {
			return this.addSelect(field?.toString(), alias);
		}

		public Soql.Builder addSelect(String fieldName) {
			return this.addSelect(fieldName, '');
		}

		public Soql.Builder addSelect(List<SObjectField> fields) {
			for (SObjectField field : fields) {
				if (field != null) {
					this.addSelect(field?.toString());
				}
			}
			return this;
		}

		@SuppressWarnings('PMD.ExcessiveParameterList')
		public Soql.Builder addSelect(
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
		public Soql.Builder addSelect(
			SObjectField field1,
			SObjectField field2,
			SObjectField field3,
			SObjectField field4
		) {
			return this.addSelect(field1, field2, field3, field4, null);
		}

		public Soql.Builder addSelect(SObjectField field1, SObjectField field2, SObjectField field3) {
			return this.addSelect(field1, field2, field3, null);
		}

		public Soql.Builder addSelect(SObjectField field1, SObjectField field2) {
			return this.addSelect(field1, field2, null);
		}

		public Soql.Builder addSelect(SObjectField field) {
			SObjectField nullField;
			return this.addSelect(field, nullField);
		}

		public Soql.Builder addSelect(List<Soql.Selectable> fields) {
			for (Soql.Selectable field : fields) {
				if (field != null) {
					this.handleSelectableLogic(field);
					this.addSelect(field?.toString());
				}
			}
			return this;
		}

		@SuppressWarnings('PMD.ExcessiveParameterList')
		public Soql.Builder addSelect(
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
		public Soql.Builder addSelect(
			Soql.Selectable field1,
			Soql.Selectable field2,
			Soql.Selectable field3,
			Soql.Selectable field4
		) {
			return this.addSelect(field1, field2, field3, field4, null);
		}

		public Soql.Builder addSelect(Soql.Selectable field1, Soql.Selectable field2, Soql.Selectable field3) {
			return this.addSelect(field1, field2, field3, null);
		}

		public Soql.Builder addSelect(Soql.Selectable field1, Soql.Selectable field2) {
			return this.addSelect(field1, field2, null);
		}

		public Soql.Builder addSelect(Soql.Selectable field) {
			return this.addSelect(field, null);
		}

		public Soql.Builder deselectAll() {
			// Remove all SELECT fields from the current query
			this.selectClauses?.clear();
			return this;
		}

		public Soql.Builder deselect(String fieldName) {
			// Remove a field from the current query
			this.selectClauses?.remove(fieldName);
			return this;
		}

		public Soql.Builder deselect(SObjectField field) {
			return this.deselect(field?.toString());
		}

		public Soql.Builder deselect(Soql.Selectable selectable) {
			return this.deselect(selectable?.toString());
		}

		// * FROM *
		public Soql.Builder setFrom(SObjectType objectType) {
			this.entity = objectType?.toString();
			return this;
		}

		// * USING SCOPE *
		public Soql.Builder setScope(Soql.Scope scope) {
			this.scope = scope;
			return this;
		}

		// * WHERE *
		public Soql.Builder addWhere(Soql.Criteria criteria) {
			this.whereCriteria?.addCondition(criteria);
			return this;
		}

		public Soql.Builder addWhere(String fieldName, Soql.Operator operator, Object value) {
			// Shorthand overload constructs a Condition object for the caller
			return this.addWhere(new Soql.Condition(fieldName, operator, value));
		}

		public Soql.Builder addWhere(SObjectField field, Soql.Operator operator, Object value) {
			return this.addWhere(field?.toString(), operator, value);
		}

		public Soql.Builder addWhere(Soql.ParentField field, Soql.Operator operator, Object value) {
			return this.addWhere(field?.toString(), operator, value);
		}

		public Soql.Builder addWhere(String fieldName, Soql.Operator operator, Soql.InnerQuery innerQuery) {
			// If the current `value` object is an InnerQuery, add its binds to the parent query:
			this.addBindsFromChildQuery(innerQuery);
			return this.addWhere(fieldName, operator, innerQuery?.toString());
		}

		public Soql.Builder addWhere(SObjectField field, Soql.Operator operator, Soql.InnerQuery innerQuery) {
			return this.addWhere(field?.toString(), operator, innerQuery);
		}

		public Soql.Builder addWhere(String fieldName, Soql.Operator operator, Soql.Binder binder) {
			// If the current `value` object is a Binder, bind the values so that callers don't need to do so manually
			return this.addWhere(fieldName, operator, binder?.toString())?.addBind(binder);
		}

		public Soql.Builder addWhere(SObjectField field, Soql.Operator operator, Soql.Binder binder) {
			return this.addWhere(field?.toString(), operator, binder);
		}

		public Soql.Builder addWhere(Soql.ParentField field, Soql.Operator operator, Soql.Binder binder) {
			return this.addWhere(field?.toString(), operator, binder);
		}

		public Soql.Builder setOuterWhereLogic(Soql.LogicType newLogicType) {
			this.whereCriteria?.setLogicType(newLogicType);
			return this;
		}

		// * WITH *
		public Soql.Builder withSecurityEnforced() {
			this.withClause = 'SECURITY_ENFORCED';
			// Note: Cannot use the WITH SECURITY_ENFORCED clause in queries using USER_MODE access level.
			this.setAccessLevel(System.AccessLevel.SYSTEM_MODE);
			return this;
		}

		// * GROUP BY *
		public Soql.Builder addGroupBy(String fieldName) {
			// Note: GROUP BY queries should never assume an implicit "Id" in the query
			this.deselect(ID_REFERENCE);
			this.groupByClauses?.add(fieldName);
			return this;
		}

		public Soql.Builder addGroupBy(SObjectField field) {
			return this.addGroupBy(field?.toString());
		}

		public Soql.Builder addGroupBy(Soql.ParentField field) {
			return this.addGroupBy(field?.toString());
		}

		// * HAVING *
		public Soql.Builder addHaving(Soql.Aggregation agg, Soql.Operator operator, Object value) {
			// Shorthand overload constructs the AggregateCondition for the caller
			Soql.Condition condition = new Soql.Condition(agg?.toString(), operator, value);
			this.havingCriteria?.addCondition(condition);
			return this;
		}

		public Soql.Builder setOuterHavingLogic(Soql.LogicType newLogicType) {
			this.havingCriteria?.setLogicType(newLogicType);
			return this;
		}

		// * ORDER BY *
		public Soql.Builder addOrderBy(Soql.SortOrder sortOrder) {
			this.orderByClauses?.add(sortOrder?.toString());
			return this;
		}

		public Soql.Builder addOrderBy(String fieldName, Soql.SortDirection direction) {
			Soql.SortOrder sortOrder = new Soql.SortOrder(fieldName, direction);
			return this.addOrderBy(sortOrder);
		}

		public Soql.Builder addOrderBy(SObjectField field, Soql.SortDirection direction) {
			return this.addOrderBy(field?.toString(), direction);
		}

		public Soql.Builder addOrderBy(Soql.ParentField field, Soql.SortDirection direction) {
			return this.addOrderBy(field?.toString(), direction);
		}

		// * LIMIT *
		public Soql.Builder setRowLimit(Integer rowLimit) {
			this.rowLimit = rowLimit;
			return this;
		}

		// * OFFSET *
		public Soql.Builder setRowOffset(Integer rowOffset) {
			this.rowOffset = rowOffset;
			return this;
		}

		// * USAGE *
		public Soql.Builder setUsage(Soql.Usage usage) {
			this.usage = usage;
			return this;
		}

		// **** DEPRECATED **** //
		public Soql.Builder bind(Map<String, Object> bindMap) {
			// ! Deprecated - this method will be removed in a future release
			// ! Replace all instances with the `addBind` method
			return this.addBind(bindMap);
		}

		public Soql.Builder bind(String key, Object value) {
			// ! Deprecated - this method will be removed in a future release
			// ! Replace all instances with the `addBind` method
			return this.addBind(key, value);
		}

		public Soql.Builder bind(Soql.Binder binder) {
			// ! Deprecated - this method will be removed in a future release
			// ! Replace all instances with the `addBind` method
			return this.addBind(binder);
		}

		public Soql.Builder defineAccess(System.AccessLevel accessLevel) {
			// ! Deprecated - this method will be removed in a future release
			// ! Replace all instances with the `setAccessLevel` method
			return this.setAccessLevel(accessLevel);
		}

		public Soql.Builder fromSObject(SObjectType objectType) {
			// ! Deprecated - this method will be removed in a future release
			// ! Replace all instances with the `setFrom` method
			return this.setFrom(objectType);
		}

		public Soql.Builder groupBy(String fieldName) {
			// ! Deprecated - this method will be removed in a future release
			// ! Replace all instances with the `addGroupBy` method
			return this.addGroupBy(fieldName);
		}

		public Soql.Builder groupBy(SObjectField field) {
			// ! Deprecated - this method will be removed in a future release
			// ! Replace all instances with the `addGroupBy` method
			return this.addGroupBy(field);
		}

		public Soql.Builder groupBy(Soql.ParentField field) {
			// ! Deprecated - this method will be removed in a future release
			// ! Replace all instances with the `addGroupBy` method
			return this.addGroupBy(field);
		}

		public Soql.Builder orderBy(Soql.SortOrder sortOrder) {
			// ! Deprecated - this method will be removed in a future release
			// ! Replace all instances with the `addOrderBy` method
			return this.addOrderBy(sortOrder);
		}

		public Soql.Builder orderBy(String fieldName, Soql.SortDirection direction) {
			// ! Deprecated - this method will be removed in a future release
			// ! Replace all instances with the `addOrderBy` method
			Soql.SortOrder sortOrder = new Soql.SortOrder(fieldName, direction);
			return this.addOrderBy(fieldName, direction);
		}

		public Soql.Builder orderBy(SObjectField field, Soql.SortDirection direction) {
			// ! Deprecated - this method will be removed in a future release
			// ! Replace all instances with the `addOrderBy` method
			return this.addOrderBy(field, direction);
		}

		public Soql.Builder orderBy(Soql.ParentField field, Soql.SortDirection direction) {
			// ! Deprecated - this method will be removed in a future release
			// ! Replace all instances with the `addOrderBy` method
			return this.addOrderBy(field, direction);
		}

		public Soql.Builder usingScope(Soql.Scope scope) {
			// ! Deprecated - this method will be removed in a future release
			// ! Replace all instances with the `setScope` method
			return this.setScope(scope);
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

	public virtual class Condition implements Soql.Criteria {
		public final String property { get; protected set; }
		public final Soql.Operator operator { get; protected set; }
		public final Object value { get; protected set; }

		public Condition(String property, Soql.Operator operator, Object value) {
			this.property = property;
			this.operator = operator;
			this.value = value;
		}

		public Condition(SObjectField field, Soql.Operator operator, Object value) {
			this(field?.toString(), operator, value);
		}

		public Condition(Soql.ParentField field, Soql.Operator operator, Object value) {
			this(field?.toString(), operator, value);
		}

		public override String toString() {
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

	public class ConditionalLogic implements Soql.Criteria {
		private List<Soql.Criteria> criterion = new List<Soql.Criteria>();
		private Soql.LogicType logicType = Soql.LogicType.ALL_CONDITIONS;

		public ConditionalLogic addCondition(List<Soql.Criteria> criterion) {
			this.criterion?.addAll(criterion);
			return this;
		}

		public ConditionalLogic addCondition(Soql.Criteria criteria) {
			return this.addCondition(new List<Soql.Criteria>{ criteria });
		}

		public ConditionalLogic addCondition(String fieldName, Soql.Operator operator, Object value) {
			Soql.Condition condition = new Soql.Condition(fieldName, operator, value);
			return this.addCondition(condition);
		}

		public ConditionalLogic addCondition(SObjectField field, Soql.Operator operator, Object value) {
			return this.addCondition(field?.toString(), operator, value);
		}

		public ConditionalLogic addCondition(Soql.ParentField field, Soql.Operator operator, Object value) {
			return this.addCondition(field?.toString(), operator, value);
		}

		public ConditionalLogic setLogicType(Soql.LogicType logicType) {
			this.logicType = logicType;
			return this;
		}

		public override String toString() {
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

	public virtual class ContainsOperator extends Soql.Operator {
		private ContainsOperator(String token) {
			super(token);
		}

		public override String processStringValue(String value) {
			return '\'%' + String.escapeSingleQuotes(value) + '%\'';
		}
	}

	public virtual class Cursor {
		// Decorates a Database.Cursor so that it can be mocked
		// These objects can't be manually constructed;
		// they *can* be serialized, but their query details can't be this way
		protected Database.Cursor cursor;

		protected Cursor(Database.Cursor cursor) {
			this.cursor = cursor;
		}

		public virtual List<SObject> fetch(Integer position, Integer count) {
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

		public Database.Cursor getCursor() {
			return this.cursor;
		}

		public virtual Integer getNumRecords() {
			return this.cursor?.getNumRecords();
		}
	}

	public class EndsWithOperator extends Soql.Operator {
		private EndsWithOperator(String token) {
			super(token);
		}

		public override String processStringValue(String value) {
			return '\'%' + String.escapeSingleQuotes(value) + '\'';
		}
	}

	public virtual class InnerQuery extends Soql.Builder implements Soql.Selectable {
		// Inner queries must contain a single key field, and this is typically not the Id
		// ex., `SELECT AccountId FROM Case WHERE X`
		protected InnerQuery() {
			this.deselect(ID_REFERENCE);
		}

		public InnerQuery(SObjectType objectType) {
			this();
			this.setFrom(objectType);
		}

		public override String toString() {
			return '(' + super.toString() + ')';
		}
	}

	public class InvalidParameterValueException extends Exception {
		// This class wraps System.InvalidParameterValueExceptions thrown by invalid fetch calls in Database.Cursors
	}

	public virtual class Operator {
		private String token;

		protected Operator(String token) {
			// Callers shouldn't construct an Operator object directly;
			// Instead, refer to the static final types listed in this file
			this.token = token;
		}

		public virtual String processStringValue(String value) {
			return '\'' + String.escapeSingleQuotes(value) + '\'';
		}

		public override String toString() {
			return this.token;
		}
	}

	@SuppressWarnings('PMD.ExcessiveParameterCount')
	public class ParentField implements Soql.Selectable {
		// Represents a reference to a SObjectField on a parent (or multi-grandparent) object, ex., "Account.Owner.Profile.Name"
		// SOQL supports querying fields objects up to 5 relationships away from the FROM object
		private String value;

		public ParentField(List<SObjectField> relationshipFieldChain) {
			relationshipFieldChain = relationshipFieldChain ?? new List<SObjectField>();
			this.value = this.computeValue(relationshipFieldChain);
		}

		public ParentField(
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

		public ParentField(
			SObjectField relationship1,
			SObjectField relationship2,
			SObjectField relationship3,
			SObjectField relationship4,
			SObjectField field
		) {
			this(new List<SObjectField>{ relationship1, relationship2, relationship3, relationship4, field });
		}

		public ParentField(
			SObjectField relationship1,
			SObjectField relationship2,
			SObjectField relationship3,
			SObjectField field
		) {
			this(new List<SObjectField>{ relationship1, relationship2, relationship3, field });
		}

		public ParentField(SObjectField relationship1, SObjectField relationship2, SObjectField field) {
			this(new List<SObjectField>{ relationship1, relationship2, field });
		}

		public ParentField(SObjectField relationship1, SObjectField field) {
			this(new List<SObjectField>{ relationship1, field });
		}

		public override String toString() {
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

	public virtual class QueryLocator {
		// Decorates a Database.QueryLocator, so that it can be mocked.
		// These objects can't be serialized, or mocked by other means.
		// See MockSoql.QueryLocator for the mock implementation of this object.
		private Database.QueryLocator locator;

		protected QueryLocator(Database.QueryLocator locator) {
			this.locator = locator;
		}

		public virtual Database.QueryLocator getLocator() {
			return this.locator;
		}

		public virtual String getQuery() {
			return this.locator?.getQuery();
		}

		public virtual System.Iterator<SObject> iterator() {
			return (System.Iterator<SObject>) this.locator?.iterator();
		}
	}

	public virtual class Request {
		public Boolean isMockSoql { get; protected set; }
		public Soql.Operation operation { get; private set; }
		public Soql query { get; private set; }
		protected transient System.AccessLevel accessLevel;
		protected transient Map<String, Object> binds;

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
				String augmentedMsg = error?.getMessage() + '\nQuery: [' + this.query?.toString() + ']';
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
			Soql tempCopy = this.query?.clone()?.deselectAll()?.addSelect(count)?.toSoql();
			return Database.countQueryWithBinds(tempCopy?.toString(), this.binds, this.accessLevel);
		}

		protected virtual Soql.Cursor doGetCursor() {
			Database.Cursor cursor = Database.getCursorWithBinds(this.query?.toString(), this.binds, this.accessLevel);
			return new Soql.Cursor(cursor);
		}

		protected virtual Soql.QueryLocator doGetQueryLocator() {
			Database.QueryLocator locator = Database.getQueryLocatorWithBinds(
				this.query?.toString(),
				this.binds,
				this.accessLevel
			);
			return new Soql.QueryLocator(locator);
		}

		protected virtual Object doQuery() {
			return Database.queryWithBinds(this.query?.toString(), this.binds, this.accessLevel);
		}
	}

	public class SortOrder {
		private List<String> fieldNames = new List<String>();
		private Soql.SortDirection direction = Soql.SortDirection.ASCENDING;
		private Soql.NullOrder nullOrder = Soql.NullOrder.NULLS_LAST;

		public SortOrder(List<String> fieldNames, Soql.SortDirection direction) {
			this.fieldNames = fieldNames;
			this.direction = direction;
		}

		public SortOrder(String fieldName, Soql.SortDirection direction) {
			this(new List<String>{ fieldName }, direction);
		}

		public SortOrder(List<SObjectField> fields, Soql.SortDirection direction) {
			for (SObjectField field : fields) {
				this.fieldNames?.add(field?.toString());
			}
			this.direction = direction;
		}

		public SortOrder(SObjectField field, Soql.SortDirection direction) {
			this(new List<SObjectField>{ field }, direction);
		}

		public SortOrder(List<Soql.ParentField> fields, Soql.SortDirection direction) {
			for (Soql.ParentField field : fields) {
				this.fieldNames?.add(field?.toString());
			}
			this.direction = direction;
		}

		public SortOrder(Soql.ParentField field, Soql.SortDirection direction) {
			this(new List<Soql.ParentField>{ field }, direction);
		}

		public SortOrder setNullOrder(Soql.NullOrder nullOrder) {
			this.nullOrder = nullOrder;
			return this;
		}

		public override String toString() {
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

	public class StartsWithOperator extends Soql.Operator {
		private StartsWithOperator(String token) {
			super(token);
		}

		public override String processStringValue(String value) {
			return '\'' + String.escapeSingleQuotes(value) + '%\'';
		}
	}

	public class Subquery extends Soql.InnerQuery {
		private String relationshipName;

		public Subquery(Schema.ChildRelationship relationship) {
			this.addSelect(ID_REFERENCE);
			this.relationshipName = relationship?.getRelationshipName();
		}

		public Subquery(SObjectField lookupFieldOnChildObject) {
			this(DatabaseLayer.Utils.ChildRelationships.getChildRelationshipFrom(lookupFieldOnChildObject));
		}

		public override String getFrom() {
			return this.relationshipName;
		}
	}
}
