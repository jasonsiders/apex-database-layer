public inherited sharing virtual class Soql extends Soql.Builder {
    public static final Operator EQUALS = new Soql.EqualsOperator();
	public static final Operator NOT_EQUALS = new Soql.NotEqualsOperator();
	public static final Operator IN_COLLECTION = new Soql.InCollectionOperator();
	public static final Operator NOT_IN_COLLECTION = new Soql.NotInCollectionOperator();
	public static final Operator GREATER_THAN = new Soql.GreaterThanOperator();
	public static final Operator GREATER_OR_EQUAL = new Soql.GreaterOrEqualOperator();
	public static final Operator LESS_THAN = new Soql.LessThanOperator();
	public static final Operator LESS_OR_EQUAL = new Soql.LessOrEqualOperator();
	public static final Operator STARTS_WITH = new Soql.StartsWithOperator();
	public static final Operator NOT_STARTS_WITH = new Soql.NotStartsWithOperator();
	public static final Operator ENDS_WITH = new Soql.EndsWithOperator();
	public static final Operator NOT_ENDS_WITH = new Soql.NotEndsWithOperator();
	public static final Operator CONTAINS = new Soql.ContainsOperator();
	public static final Operator NOT_CONTAINS = new Soql.NotContainsOperator();
    static final Soql.LogicType DEFAULT_LOGIC_TYPE = Soql.LogicType.ALL_CONDITIONS;
	static final String ID_REFERENCE = 'Id';

    @TestVisible
	protected Soql(SObjectType objectType) {
        super();
        this.fromEntity(objectType);
	}

    public virtual Integer countQuery() {
        try {
            return Database.countQueryWithBinds(this.toString(), this.binds, this.accessLevel);
        } catch (System.QueryException error) {
			this.handleQueryError(error);
            throw error;
		}
    }

    public virtual Database.QueryLocator getQueryLocator() {
        try {
            return Database.getQueryLocatorWithBinds(this.toString(), this.binds, this.accessLevel);
        } catch (System.QueryException error) {
            this.handleQueryError(error);
            throw error;
        }
    }

	public virtual List<SObject> query() {
		try {
			return Database.queryWithBinds(this.toString(), this.binds, this.accessLevel);
		} catch (System.QueryException error) {
			this.handleQueryError(error);
            throw error;
		}
	}

	public virtual Object query(Type returnType) {
		// Return the query results as an instance of the returnType
		// Mostly useful for returning Aggregate Query results as a wrapper type
		return JSON.deserialize(JSON.serialize(this.query()), returnType);
	}

    private void handleQueryError(Exception error) {
        // Attach the original query to the Exception for easier debugging
        String augmentedMsg = error?.getMessage() + '\nQuery: [' + this.toString() + ']';
        error?.setMessage(augmentedMsg);
    }

    // **** STATIC **** //
    static Schema.ChildRelationship getChildRelationshipFrom(SObjectField lookupField) {
        // TODO: Consider moving this to some utility class
        List<ChildRelationship> relationships = lookupField?.getDescribe()?.getSObjectType()?.getDescribe()?.getChildRelationships();
        relationships = relationships ?? new List<ChildRelationship>();
        for (ChildRelationship relationship : relationships) {
            // Unfortunately, no way of telling if a Schema.ChildRelationship matches w/out manually iterating & checking their fields
            SObjectField relationshipField = relationship?.getField();
            if (relationshipField == lookupField) {
                return relationship;
            }
        }
        return null;
    }

	// **** ENUMS *** //
    public enum AggregateFunction {
        AVG,
		COUNT,
		COUNT_DISTINCT,
		FORMAT,
		MIN,
		MAX,
		SUM
    }

    public enum Context {
        // Note: Believe it or not, SYSTEM_MODE and USER_MODE aren't enum values; 
        // they're static properties of the AccessLevel class!
        SECURITY_ENFORCED,
        SYSTEM_MODE,
        USER_MODE
    }

    public enum LogicType {
        ALL_CONDITIONS,
        ANY_CONDITIONS
    }

    public enum NullOrder {
        NULLS_FIRST,
        NULLS_LAST
    }

    public enum SortOrder {
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
    public interface ICriteria {
        // Mostly a marker interface, but also used to coerce toString()
        String toString();
    }

    // **** INNER **** //
    public class Aggregation {
        AggregateFunction function;
        String fieldName;
        String alias;

        public Aggregation(AggregateFunction function, String fieldName, String alias) {
            this.function = function;
            this.fieldName = fieldName;
            this.alias = alias;
        }

        public Aggregation(AggregateFunction function, String fieldName) {
            this(function, fieldName, '');
        }

        public Aggregation(AggregateFunction function, SObjectField field, String alias) {
            this(function, field?.toString(), alias);
        }
    
        public Aggregation(AggregateFunction function, SObjectField field) {
            this(function, field?.toString());
        }

        public override String toString() {
            String formatted = String.format(
                '{0}({1}) {2}',
                new List<String>{ this.function?.toString(), this.fieldName, this.alias }
            );
            return formatted?.trim();
        }
    }

    public class AggregateCondition extends Soql.Condition {
        public AggregateCondition(Soql.Aggregation agg, Soql.Operator operator, Object value) {
			super(agg?.toString(), operator, value);
		}
    }

    public class Binder {
        public String key { get; private set; }
        List<Object> values { get; private set; }

        public Binder(String key) {
            this.key = key;
        }

        public Binder(String key, List<Object> values) {
            this(key);
            this.setValues(values);
        }

        public String getKey() {
            return this.key;
        }

        public List<Object> getValues() {
            return this.values ?? new List<Object>();
        }

        public Binder setValues(List<Object> values) {
            this.values = values;
            return this; 
        }

        public override String toString() {
            return ':' + this.getKey();
        }

        public override Integer hashCode() {
            return this.key?.hashCode();
        }
    }

    public abstract class Builder {
        public Set<String> selectClauses { get; protected set; }
        public String entity { get; protected set; }
        public Soql.Scope scope { get; protected set; }
        public Soql.ConditionalLogic whereCriteria { get; protected set; }
        public WithClause withClause { get; protected set; }
        public List<String> groupByClauses { get; protected set; }
        public Soql.ConditionalLogic havingCriteria { get; protected set; }
        public Soql.OrderByClause orderByClause { get; protected set; }
        public Integer rowLimit { get; protected set; }
        public Integer rowOffset { get; protected set; }
        public Soql.Usage usage { get; protected set; }
        public System.AccessLevel accessLevel { get; protected set; }
        public Map<String, Object> binds { get; protected set; }

        protected Builder() {
            this.clear();
        }

        public virtual override String toString() {
            // Outputs a SOQL Query string, following the syntax defined here:
            // https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql_select.htm#:~:text=SOQL%20query%20syntax%20consists%20of,typeOfField%20whenExpression%5B...%5D
            List<String> queryArgs = new List<String>{ this.getSelect(), this.getFrom(), this.getOptionalArgs() };
            return String.format('SELECT {0} FROM {1} {2}', queryArgs)?.trim();
        }

        public Soql.Builder bind(Map<String, Object> bindMap) {
            this.binds?.putAll(bindMap); 
            return this;
        }

        public Soql.Builder bind(String key, Object value) {
            return this.bind(new Map<String, Object>{ key => value });
        }

        public Soql.Builder bind(Soql.Binder binder) {
            return this.bind(binder?.getKey(), binder?.getValues());
        }

        public Soql.Builder clear() {
            this.selectClauses = new Set<String>{ ID_REFERENCE };
            this.whereCriteria = new Soql.ConditionalLogic(DEFAULT_LOGIC_TYPE);
            this.groupByClauses = new List<String>();
            this.havingCriteria = new Soql.ConditionalLogic(DEFAULT_LOGIC_TYPE);
            this.accessLevel = System.AccessLevel.USER_MODE;
            this.binds = new Map<String, Object>(); 
            return this;
        }

        public Soql.Builder deselect(String fieldName) {
            // Remove a field from the current query
            this.selectClauses?.remove(fieldName);
            return this;
        }

        public Soql.Builder defineAccess(System.AccessLevel accessLevel) {
            this.accessLevel = accessLevel;
            return this;
        }

        public Soql.Builder deselect(SObjectField field) {
            return this.deselect(field?.toString());
        }
    
        // * SELECT *
        public Soql.Builder selectAll() {
            List<DescribeSObjectResult> describes = Schema.describeSObjects(new List<String>{ this.entity });
            DescribeSObjectResult describe = describes?.isEmpty() == false ? describes[0] : null;
            List<SObjectField> allFields = describe?.fields?.getMap()?.values() ?? new List<SObjectField>();
            for (SObjectField field : allFields) {
                this.selecting(field);
            }
            return this;
        }
    
        public Soql.Builder selecting(SObjectField field) {
            this.selectClauses.add(field?.toString());
            return this; 
        }
    
        public Soql.Builder selecting(String fieldName) {
            this.selectClauses.add(fieldName);
            return this; 
        }
    
        public Soql.Builder selecting(Soql.Aggregation aggregation) {
            // Note: Id should never be included in the SELECT clause for Aggregate queries
            return this.deselect(ID_REFERENCE)?.selecting(aggregation?.toString());
        }
    
        public Soql.Builder selecting(Soql.SubQuery subQuery) {
            return this.selecting(subQuery.toString());
        }
    
        // * FROM *
        public Soql.Builder fromEntity(SObjectType objectType) {
            this.entity = objectType?.toString();
            return this;
        }
    
        // * USING SCOPE *
        public Soql.Builder usingScope(Scope scope) {
            this.scope = scope;
            return this;
        }
    
        // * WHERE *
        public Soql.Builder given(Soql.ICriteria criteria) {
            this.whereCriteria?.addCriteria(criteria);
            return this; 
        }

        public Soql.Builder given(String fieldName, Soql.Operator operator, Object value) {
            // Shorthand overload constructs a Condition object for the caller
            return this.given(new Soql.Condition(fieldName, operator, value));
        }

        public Soql.Builder given(SObjectField field, Soql.Operator operator, Object value) {
            // Shorthand overload constructs a Condition object for the caller
            return this.given(field?.toString(), operator, value);
        }

        public Soql.Builder given(String fieldName, Soql.Operator operator, Soql.Binder binder) {
            // If the current object is a Binder, bind the values so that callers don't need to do so manually
            return this.given(fieldName, operator, binder?.toString())?.bind(binder);
        }

        public Soql.Builder given(SObjectField field, Soql.Operator operator, Soql.Binder binder) {
            return this.given(field?.toString(), operator, binder); 
        }

        public Soql.Builder setWhereLogic(Soql.LogicType newLogicType) {
            this.whereCriteria?.setLogicType(newLogicType);
            return this;
        }

        // * WITH *
        public Soql.Builder with(WithClause withClause) {
            this.withClause = withClause;
            return this; 
        }

        // * GROUP BY *
        public Soql.Builder groupBy(SObjectField field) {
            this.groupByClauses?.add(field?.toString());
            return this;
        }

        // * HAVING *
        public Soql.Builder has(Soql.AggregateCondition aggregateCriteria) {
            this.havingCriteria?.addCriteria(aggregateCriteria);
            return this;
        }

        public Soql.Builder has(Soql.Aggregation agg, Soql.Operator operator, Object value) {
            // Shorthand overload constructs the AggregateCondition for the caller
            return this.has(new Soql.AggregateCondition(agg, operator, value));
        }

        public Soql.Builder setHavingLogic(Soql.LogicType newLogicType) {
            this.havingCriteria?.setLogicType(newLogicType);
            return this;
        }
    
        // * ORDER BY * 
        public Soql.Builder orderBy(Soql.OrderByClause orderByClause) {
            this.orderByClause = orderByClause;
            return this;
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
        protected String constructClause(String prefix, Object value) {
            // Returns a specific SOQL clause (ex., "WHERE {value}"), provided that `value` is not null
            return (value != null) ? (prefix + ' ' + value?.toString()) : null;
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
                this.constructClause('ORDER BY', this.orderByClause),
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

    public virtual class Condition implements Soql.ICriteria {
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
                this.operator?.getToken(),
                this.formatValue()
            };
            return String.join(parts, ' ');
        }
        
        protected String formatValue() {
            // Note: System.Type cannot be used directly in switch expressions
            if (this.value == null) {
                return 'null';
            } else if (this.value instanceOf Date) {
                return this.processDate((Date) this.value);
            } else if (this.value instanceOf Iterable<Date>) {
                return this.processDates((Iterable<Date>) this.value);
            } else if (this.value instanceOf DateTime) {
                return this.processDateTime((DateTime) this.value);
            } else if (this.value instanceOf Iterable<DateTime>) {
                return this.processDateTimes((Iterable<DateTime>) this.value);
            } else if (this.value instanceOf String) {
                return this.processString((String) this.value);
            } else if (this.value instanceOf Iterable<String>) {
                return this.processStrings((Iterable<String>) this.value);
            } else if (this.value instanceOf Soql) {
                // Inner queries must be wrapped in parentheses to avoid syntax errors in SOQL
                return String.format('({0})', new List<String>{ this.value?.toString() });
            } else {
                return String.valueOf(this.value);
            }
        }
    
        private String processString(String value) {
            // Allow special modifiers (bind variables & relative date operators) to pass through unmodified
            Boolean specialModifier = value?.startsWithIgnoreCase('LAST_N_DAYS') || value?.startsWith(':');
            return (specialModifier) ? value : this.operator?.processStringValue(value);
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
    
        private String processStrings(Iterable<String> items) {
            List<String> results = new List<String>();
            for (String item : items) {
                String result = this.processString(item);
                results.add(result);
            }
            return '(' + String.join(results, ', ') + ')';
        }
    
        private String processDates(Iterable<Date> items) {
            List<String> results = new List<String>();
            for (Date item : items) {
                results.add(this.processDate(item));
            }
            return '(' + String.join(results, ', ') + ')';
        }
    
        private String processDateTimes(Iterable<DateTime> items) {
            List<String> results = new List<String>();
            for (DateTime item : items) {
                results.add(this.processDateTime(item));
            }
            return '(' + String.join(results, ', ') + ')';
        }
    }

    public class ConditionalLogic implements Soql.ICriteria {
        List<Soql.ICriteria> criterion = new List<Soql.ICriteria>();
        Soql.LogicType logicType;

        public ConditionalLogic(Soql.LogicType logicType) {
            this.setLogicType(logicType);
        }

        public ConditionalLogic addCriteria(List<Soql.ICriteria> criterion) {
            this.criterion?.addAll(criterion);
            return this; 
        }

        public ConditionalLogic addCriteria(Soql.ICriteria criteria) {
            return this.addCriteria(new List<Soql.ICriteria>{ criteria });
        }

        public ConditionalLogic setLogicType(Soql.LogicType logicType) {
            this.logicType = logicType; 
            return this;
        }

        public override String toString() {
            String delimiter = ' ' + this.getPredicate() + ' ';
            List<String> criteriaStrings = new List<String>();
            for (Soql.ICriteria criteria : this.criterion) {
                // Wrap inner ConditionalLogic objects in parentheses
                String criteriaString = (criteria instanceof ConditionalLogic)
                    ? '(' + criteria?.toString() + ')'
                    : criteria?.toString();
                criteriaStrings?.add(criteriaString);
            }
            return String.join(criteriaStrings, delimiter);
        }

        private String getPredicate() {
            return (logicType == Soql.LogicType.ANY_CONDITIONS) ? 'OR' : 'AND';
        }
    }

    public class ContainsOperator extends Soql.Operator {
		public override String getToken() {
			return 'LIKE';
		}

		public override String processStringValue(String value) {
			return '\'%' + value + '%\'';
		}
	}

    public class EndsWithOperator extends Soql.Operator {
		public override String getToken() {
			return 'LIKE';
		}

		public override String processStringValue(String value) {
			return '\'%' + value + '\'';
		}
	}

    public class EqualsOperator extends Soql.Operator {
		public override String getToken() {
			return '=';
		}
	}

    public class GreaterOrEqualOperator extends Soql.Operator {
		public override String getToken() {
			return '>=';
		}
	}

    public class GreaterThanOperator extends Soql.Operator {
		public override String getToken() {
			return '>';
		}
	}

    public class InCollectionOperator extends Soql.Operator {
		public override String getToken() {
			return 'IN';
		}
	}

    public class InnerQuery extends Soql.Builder {
        // Inner queries must contain a single key field, and this is typically not the Id
        // ex., `SELECT AccountId FROM Case WHERE X`
        public InnerQuery() {
            this.deselect(ID_REFERENCE);
        }
    }

    public class LessOrEqualOperator extends Soql.Operator {
		public override String getToken() {
			return '<=';
		}
	}

    public class LessThanOperator extends Soql.Operator {
		public override String getToken() {
			return '<';
		}
	}

    public class NotContainsOperator extends Soql.Operator {
		public override String getToken() {
			return 'NOT LIKE';
		}

		public override String processStringValue(String value) {
			return '\'%' + value + '%\'';
		}
	}

    public class NotEndsWithOperator extends Soql.Operator {
		public override String getToken() {
			return 'NOT LIKE';
		}

		public override String processStringValue(String value) {
			return '\'%' + value + '\'';
		}
	}

    public class NotEqualsOperator extends Soql.Operator {
		public override String getToken() {
			return '!=';
		}
	}

    public class NotInCollectionOperator extends Soql.Operator {
		public override String getToken() {
			return 'NOT IN';
		}
	}

    public class NotStartsWithOperator extends Soql.Operator {
		public override String getToken() {
			return 'NOT LIKE';
		}

		public override String processStringValue(String value) {
			return '\'' + value + '%\'';
		}
	}

    public abstract class Operator {
        protected Operator() {
            // Callers shouldn't construct an Operator object directly;
            // Instead, refer to the static final types listed in this file
        }

        public abstract String getToken();

		public virtual String processStringValue(String value) {
			return '\'' + value + '\'';
		}
    }

    public class OrderByClause {
        List<String> fieldNames = new List<String>();
        SortOrder direction = SortOrder.ASCENDING;
        NullOrder nullBehavior = NullOrder.NULLS_LAST;

        public OrderByClause(List<String> fieldNames, SortOrder direction) {
            this.fieldNames = fieldNames;
            this.direction = direction;
        }

        public OrderByClause(String fieldName, SortOrder direction) {
            this(new List<String>{ fieldName }, direction);
        }

        public OrderByClause(List<SObjectField> fields, SortOrder direction) {
            for (SObjectField field : fields) {
                this.fieldNames?.add(field?.toString());
            }
            this.direction = direction;
        }

        public OrderByClause(SObjectField field, SortOrder direction) {
            this(new List<SObjectField>{ field }, direction);
        }

        public OrderByClause setNullBehavior(NullOrder nullBehavior) {
            this.nullBehavior = nullBehavior;
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
            return this.nullBehavior?.name()?.replace('_', '');
        }
    }

    public class StartsWithOperator extends Soql.Operator {
		public override String getToken() {
			return 'LIKE';
		}

		public override String processStringValue(String value) {
			return '\'' + value + '%\'';
		}
	}

    public class Subquery extends Soql.Builder {
        String relationshipName;

        public SubQuery(Schema.ChildRelationship relationship) {
            this.relationshipName = relationship?.getRelationshipName();
        }

        public SubQuery(SObjectField lookupField) {
            this(Soql.getChildRelationshipFrom(lookupField));
        }

        public override String toString() {
            return '(' + super.toString() + ')';
        }

        public override String getFrom() {
            return this.relationshipName;
        }
    }

    public class WithClause {
        String clause; 

        public WithClause(Soql.Context context) {
            this.clause = context?.name();
        }

        public WithClause(Soql.ICriteria dataCategoryCriteria) {
            this.clause = dataCategoryCriteria?.toString();
        }

        public override String toString() {
            return this.clause;
        }
    }
}