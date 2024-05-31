@SuppressWarnings('PMD.CognitiveComplexity, PMD.ExcessivePublicCount')
public inherited sharing virtual class Soql extends Soql.Builder {
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
    static final Soql.LogicType DEFAULT_LOGIC_TYPE = Soql.LogicType.ALL_CONDITIONS;
	static final String ID_REFERENCE = 'Id';

    // **** MEMBER **** //
    @TestVisible
	protected Soql(SObjectType objectType) {
        super();
        this.fromEntity(objectType);
	}

    @TestVisible
    protected Soql(String queryString) {
        super();
        this.setQueryString(queryString);
    }

    public virtual List<Soql.AggregateResult> aggregateQuery() {
        try {
            // Call this method for aggregate queries, when not casting to a specific Type.
            // Note: Since the Schema.AggregateResult class cannot be mocked via traditional means,
            // this method returns a decorator object. See the "AggregateResult" inner class.
            List<Soql.AggregateResult> wrappers = new List<Soql.AggregateResult>();
            List<Schema.AggregateResult> aggResults = (List<Schema.AggregateResult>) this.query();
            for (Schema.AggregateResult aggResult : aggResults) {
                Soql.AggregateResult wrapper = new Soql.AggregateResult(aggResult);
                wrappers?.add(wrapper);
            }
            return wrappers;
        } catch (Exception error) {
            this.handleQueryError(error);
            throw error;
        }
    }

    public virtual Integer countQuery() {
        try {
            // Note: A count query must not contain any fields, other than COUNT() aggregation
            // Avoid errors and simplify query construction by handling this in a temporary copy of the current query
            Soql.Aggregation count = new Soql.Aggregation(Soql.Function.COUNT);
            Soql tempCopy = (Soql) this.clone()?.deselectAll()?.addSelect(count);
            return Database.countQueryWithBinds(tempCopy?.toString(), this.binds, this.accessLevel);
        } catch (Exception error) {
			this.handleQueryError(error);
            throw error;
		}
    }

    public virtual Soql.QueryLocator getQueryLocator() {
        try {
            Database.QueryLocator cursor = Database.getQueryLocatorWithBinds(
                this.toString(), 
                this.binds, 
                this.accessLevel
            );
            return new Soql.QueryLocator(cursor); 
        } catch (Exception error) {
            this.handleQueryError(error);
            throw error;
        }
    }

	public virtual List<SObject> query() {
		try {
			return Database.queryWithBinds(this.toString(), this.binds, this.accessLevel);
		} catch (Exception error) {
			this.handleQueryError(error);
            throw error;
		}
	}

    public virtual Object query(Type returnType) {
		// Return the query results as an instance of the returnType
		// Mostly useful for returning Aggregate Query results as a wrapper type
        return JSON.deserialize(JSON.serialize(this.query()), returnType);
	}

    protected void handleQueryError(Exception error) {
        // Attach the original query to the Exception for easier debugging
        String augmentedMsg = error?.getMessage() + '\nQuery: [' + this.toString() + ']';
        error?.setMessage(augmentedMsg);
    }

	// **** ENUMS *** //
    public enum Function {
        AVG,
		COUNT,
		COUNT_DISTINCT,
		FORMAT,
		MIN,
		MAX,
		SUM
    }

    public enum LogicType {
        ALL_CONDITIONS,
        ANY_CONDITIONS
    }

    public enum NullOrder {
        NULLS_FIRST,
        NULLS_LAST
    }

    public enum SortDirection {
        ASCENDING,
        DESCENDING
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
    
    public class Aggregation {
        String alias;
        String innerFieldName;
        Function function;

        public Aggregation(Soql.Function function, String innerFieldName) {
            this.alias = '';
            this.innerFieldName = innerFieldName;
            this.function = function;
        }
    
        public Aggregation(Soql.Function function, SObjectField field) {
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

        public Aggregation withAlias(String alias) {
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

        public Binder setValue(Object value) {
            this.value = value;
            return this; 
        }

        public override String toString() {
            return ':' + this.getKey();
        }
    }

    public abstract class Builder {
        public Set<String> selectClauses { get; protected set; }
        public String entity { get; protected set; }
        public Soql.Scope scope { get; protected set; }
        public Soql.ConditionalLogic whereCriteria { get; protected set; }
        public String withClause { get; protected set; }
        public List<String> groupByClauses { get; protected set; }
        public Soql.ConditionalLogic havingCriteria { get; protected set; }
        public List<String> orderByClauses { get; protected set; }
        public Integer rowLimit { get; protected set; }
        public Integer rowOffset { get; protected set; }
        public Soql.Usage usage { get; protected set; }
        public System.AccessLevel accessLevel { get; protected set; }
        public Map<String, Object> binds { get; protected set; }
        public String queryString { get; protected set; }

        protected Builder() {
            this.reset();
        }

        public virtual override String toString() {
            // Return the user-defined query string if one is provided, or build a query string if not
            String queryString = this.queryString ?? this.buildQueryString();
            return queryString?.trim();
        }

        public Soql.Builder bind(Map<String, Object> bindMap) {
            this.binds?.putAll(bindMap); 
            return this;
        }

        public Soql.Builder bind(String key, Object value) {
            return this.bind(new Map<String, Object>{ key => value });
        }

        public Soql.Builder bind(Soql.Binder binder) {
            return this.bind(binder?.getKey(), binder?.getValue());
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

        public Soql.Builder defineAccess(System.AccessLevel accessLevel) {
            this.accessLevel = accessLevel;
            return this;
        }

        public Soql.Builder reset() {
            this.accessLevel = System.AccessLevel.USER_MODE;
            this.binds = new Map<String, Object>(); 
            this.groupByClauses = new List<String>();
            this.havingCriteria = new Soql.ConditionalLogic();
            this.orderByClauses = new List<String>();
            this.queryString = null;
            this.selectClauses = new Set<String>{ ID_REFERENCE };
            this.whereCriteria = new Soql.ConditionalLogic();
            return this;
        }

        public Soql.Builder setQueryString(String queryString) {
            this.queryString = queryString;
            return this; 
        }
    
        // * SELECT *
        public Soql.Builder selectAll() {
            List<DescribeSObjectResult> describes = Schema.describeSObjects(new List<String>{ this.entity });
            DescribeSObjectResult describe = describes?.isEmpty() == false ? describes[0] : null;
            List<SObjectField> allFields = describe?.fields?.getMap()?.values() ?? new List<SObjectField>();
            for (SObjectField field : allFields) {
                this.addSelect(field);
            }
            return this;
        }

        public Soql.Builder addSelect(String fieldName, String alias) {
            String clause = String.join(new List<String>{ fieldName, alias }, ' ')?.trim();
            this.selectClauses?.add(clause);
            return this;
        }

        public Soql.Builder addSelect(SObjectField field, String alias) {
            return this.addSelect(field?.toString(), alias);
        }

        public Soql.Builder addSelect(String fieldName) {
            return this.addSelect(fieldName, '');
        }
    
        public Soql.Builder addSelect(SObjectField field) {
            return this.addSelect(field?.toString());
        }
    
        public Soql.Builder addSelect(Soql.Aggregation aggregation) {
            // Note: Id should never be included in the SELECT clause for Aggregate queries
            return this.deselect(ID_REFERENCE)?.addSelect(aggregation?.toString());
        }
    
        public Soql.Builder addSelect(Soql.SubQuery subQuery) {
            return this.addSelect(subQuery.toString());
        }
    
        // * FROM *
        public Soql.Builder fromEntity(SObjectType objectType) {
            this.entity = objectType?.toString();
            return this;
        }
    
        // * USING SCOPE *
        public Soql.Builder usingScope(Soql.Scope scope) {
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
            // Shorthand overload constructs a Condition object for the caller
            return this.addWhere(field?.toString(), operator, value);
        }

        public Soql.Builder addWhere(String fieldName, Soql.Operator operator, Soql.Binder binder) {
            // If the current object is a Binder, bind the values so that callers don't need to do so manually
            return this.addWhere(fieldName, operator, binder?.toString())?.bind(binder);
        }

        public Soql.Builder addWhere(SObjectField field, Soql.Operator operator, Soql.Binder binder) {
            return this.addWhere(field?.toString(), operator, binder); 
        }

        public Soql.Builder setWhereLogic(Soql.LogicType newLogicType) {
            this.whereCriteria?.setLogicType(newLogicType);
            return this;
        }

        // * WITH *
        public Soql.Builder withSecurityEnforced() {
            this.withClause = 'SECURITY_ENFORCED';
            // Note: Cannot use the WITH SECURITY_ENFORCED clause in queries using USER_MODE access level.
            this.defineAccess(System.AccessLevel.SYSTEM_MODE);
            return this; 
        }

        // * GROUP BY *
        public Soql.Builder groupBy(String fieldName) {
            // Note: GROUP BY queries should never assume an implicit "Id" in the query
            this.deselect(ID_REFERENCE);
            this.groupByClauses?.add(fieldName);
            return this; 
        }

        public Soql.Builder groupBy(SObjectField field) {
            return this.groupBy(field?.toString());
        }

        // * HAVING *
        public Soql.Builder addHaving(Soql.Aggregation agg, Soql.Operator operator, Object value) {
            // Shorthand overload constructs the AggregateCondition for the caller
            Soql.Condition condition = new Soql.Condition(agg?.toString(), operator, value);
            this.havingCriteria?.addCondition(condition);
            return this; 
        }

        public Soql.Builder setHavingLogic(Soql.LogicType newLogicType) {
            this.havingCriteria?.setLogicType(newLogicType);
            return this;
        }
    
        // * ORDER BY * 
        public Soql.Builder orderBy(Soql.SortOrder sortOrder) {
            this.orderByClauses?.add(sortOrder?.toString());
            return this;
        }

        public Soql.Builder orderBy(String fieldName, Soql.SortDirection direction) {
            Soql.SortOrder sortOrder = new Soql.SortOrder(fieldName, direction); 
            return this.orderBy(sortOrder); 
        }

        public Soql.Builder orderBy(SObjectField field, Soql.SortDirection direction) {
            return this.orderBy(field?.toString(), direction); 
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
    
        // **** PRIVATE **** //
        protected String buildQueryString() {
            // Outputs a SOQL Query string, following the syntax defined here:
            // https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql_select.htm#:~:text=SOQL%20query%20syntax%20consists%20of,typeOfField%20whenExpression%5B...%5D
            List<String> queryArgs = new List<String>{ this.getSelect(), this.getFrom(), this.getOptionalArgs() };
            return String.format('SELECT {0} FROM {1} {2}', queryArgs)?.trim();
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
            return (this.groupByClauses?.isEmpty() == false) ? 'GROUP BY ' + String.join(this.groupByClauses, ', ') : null;
        }
    
        protected String getOptionalArgs() {
            List<String> args = new List<String>();
            for (String arg : new List<String>{
                this.constructClause('USING SCOPE', this.scope),
                this.constructClause('WHERE', this.whereCriteria),
                this.constructClause('WITH', this.withClause),
                this.getGroupBy(),
                this.constructClause('HAVING', this.havingCriteria),
                this.constructClause('ORDER BY', String.join(this.orderByClauses, ', ')),
                this.constructClause('LIMIT', this.rowLimit),
                this.constructClause('OFFSET', this.rowOffset),
                this.getUsage()
            }) {
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
			} else if (value instanceOf Date) {
				return this.processDate((Date) value);
			} else if (value instanceOf DateTime) {
				return this.processDateTime((DateTime) value);
			} else if (value instanceOf Iterable<Object>) {
				return this.processIterable((Iterable<Object>) value);
			} else if (value instanceOf String) {
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
            // Allow special modifiers (bind variables & relative date operators) to pass through unmodified
            Boolean specialModifier = value?.startsWithIgnoreCase('LAST_N_DAYS') || value?.startsWith(':');
            return (specialModifier) ? value : this.operator?.processStringValue(value);
        }
    }

    public class ConditionalLogic implements Soql.Criteria {
        List<Soql.Criteria> criterion = new List<Soql.Criteria>();
        Soql.LogicType logicType = Soql.LogicType.ALL_CONDITIONS;

        public ConditionalLogic addConditions(List<Soql.Criteria> criterion) {
            this.criterion?.addAll(criterion);
            return this; 
        }

        public ConditionalLogic addCondition(Soql.Criteria criteria) {
            return this.addConditions(new List<Soql.Criteria>{ criteria });
        }

        public ConditionalLogic addCondition(String fieldName, Soql.Operator operator, Object value) {
            Soql.Condition condition = new Soql.Condition(fieldName, operator, value); 
            return this.addCondition(condition); 
        }

        public ConditionalLogic addCondition(SObjectField field, Soql.Operator operator, Object value) {
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

    public class EndsWithOperator extends Soql.Operator {
		private EndsWithOperator(String token) {
            super(token);
		}

		public override String processStringValue(String value) {
			return '\'%' + String.escapeSingleQuotes(value) + '\'';
		}
	}

    public virtual class InnerQuery extends Soql.Builder {
        // Inner queries must contain a single key field, and this is typically not the Id
        // ex., `SELECT AccountId FROM Case WHERE X`
        protected InnerQuery() {
            this.deselect(ID_REFERENCE);
        }

        public InnerQuery(SObjectType objectType) {
            this();
            this.fromEntity(objectType);
        }

        public override String toString() {
            return '(' + super.toString() + ')';
        }
    }

    public virtual class Operator {
        String token;

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

    public virtual class QueryLocator {
        // Decorates a Database.QueryLocator, so that it can be mocked. 
        // These objects can't be serialized, or mocked by other means.
        // See MockSoql.QueryLocator for the mock implementation of this object.
        Database.QueryLocator locator;

        protected QueryLocator(Database.QueryLocator locator) {
            this.locator = locator;
        }

        public virtual Database.QueryLocator getCursor() {
            return this.locator;
        }
        
        public virtual String getQuery() {
            return this.locator?.getQuery();
        }

        public virtual System.Iterator<SObject> iterator() {
            return (System.Iterator<SObject>) this.locator?.iterator();
        }
    }

    public class SortOrder {
        List<String> fieldNames = new List<String>();
        Soql.SortDirection direction = Soql.SortDirection.ASCENDING;
        Soql.NullOrder nullOrder = Soql.NullOrder.NULLS_LAST;

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
        String relationshipName;

        public SubQuery(Schema.ChildRelationship relationship) {
            this.addSelect(ID_REFERENCE);
            this.relationshipName = relationship?.getRelationshipName();
        }

        public SubQuery(SObjectField lookupField) {
            this(SObjectUtils.getChildRelationshipFrom(lookupField));
        }

        public override String getFrom() {
            return this.relationshipName;
        }
    }
}