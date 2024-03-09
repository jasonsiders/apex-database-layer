public inherited sharing virtual class Soql {
	static final String ID_REFERENCE = 'Id';

	public Set<String> selectClauses { get; private set; }
	public String fromSObject { get; private set; }
	public Soql.Scope scope { get; private set; }
	public Soql.WithClause withExpression { get; private set; }
	public ConditionalLogic whereCriteria { get; private set; }
	public List<String> groupByClauses { get; private set; }
	public ConditionalLogic havingCriteria { get; private set; }
	public Soql.OrderBy orderByClause { get; private set; }
	public Integer rowLimit { get; private set; }
	public Integer rowOffset { get; private set; }
	public Soql.Usage usage { get; private set; }
	public System.AccessLevel accessLevel { get; private set; }
	public Map<String, Object> binds { get; private set; }

	public Soql(SObjectType objectType) {
		this(); 
		this.fromSObject(objectType);
	}

	protected Soql() {
		this.selectClauses = new Set<String>{ID_REFERENCE};
		this.whereCriteria = new AndLogic();
		this.groupByClauses = new List<String>();
		this.havingCriteria = new AndLogic(); 
		this.accessLevel = System.AccessLevel.USER_MODE;
		this.binds = new Map<String, Object>(); 
	}

	// **** Running a Query **** //
	public virtual List<SObject> query() {
		// Run the current query object through the database
		String theQuery = this.toString();
		try {
			return this.binds?.isEmpty() == false
				? Database.queryWithBinds(theQuery, this.binds, this.accessLevel)
				: Database.query(theQuery, this.accessLevel);
		} catch (System.QueryException error) {
            // Attach the original query to the Exception for easier debugging
			String augmentedMsg = error?.getMessage() + '\nQuery: [' + theQuery + ']';
			error?.setMessage(augmentedMsg);
			throw error;
		}
	}

	public virtual Object query(Type returnType) {
		// Return the query results as an instance of the returnType
		// Mostly useful for returning Aggregate Query results as a wrapper type
		return JSON.deserialize(JSON.serialize(this.query()), returnType);
	}

	public virtual override String toString() {
		// Outputs a SOQL Query string, following the syntax defined here:
		// https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql_select.htm#:~:text=SOQL%20query%20syntax%20consists%20of,typeOfField%20whenExpression%5B...%5D
		List<String> queryArgs = new List<String>{ this.getSelect(), this.getFrom(), this.getOptionalArgs() };
		return String.format('SELECT {0} FROM {1} {2}', queryArgs)?.trim();
	}

	// **** Building a Query **** //
    public Soql deselectId() {
		// By default, Id will always be included in queries
		// Occasionally, (i.e., aggregate & inner queries), this isn't desirable
		this.selectClauses?.remove(ID_REFERENCE);
		return this;
	}

    public Soql selectAll() {
        List<DescribeSObjectResult> describes = Schema.describeSObjects(new List<String>{ this.fromSObject });
        DescribeSObjectResult describe = describes?.isEmpty() == false ? describes[0] : null;
        List<SObjectField> allFields = describe?.fields?.getMap()?.values() ?? new List<SObjectField>();
        for (SObjectField field : allFields) {
            this.selecting(field);
        }
		return this;
	}

	public Soql selecting(SObjectField field) {
		this.selectClauses.add(field?.toString());
        return this; 
	}

	public Soql selecting(String fieldName) {
		this.selectClauses.add(fieldName);
        return this; 
	}

	public Soql selecting(Soql.Aggregation aggregation) {
		// Note: Id should never be included in the SELECT clause for Aggregate queries
		return this.deselectId()?.selecting(aggregation?.toString());
	}

    public Soql selecting(Soql.SubQuery subQuery) {
		return this.selecting(subQuery.toString());
	}

	public Soql fromSObject(SObjectType objectType) {
		this.fromSObject = objectType?.toString();
		return this;
	}

	public Soql usingScope(Scope scope) {
		this.scope = scope;
		return this;
	}

	public Soql with(Soql.WithClause withExpression) {
		this.withExpression = withExpression;
		return this;
	}

	public Soql given(ICriteria criteria) {
		this.whereCriteria?.addCriteria(criteria);
        return this; 
	}

	public Soql groupBy(SObjectField field) {
		this.groupByClauses?.add(field?.toString());
        return this;
	}

	public Soql andHaving(Soql.AggregateFilter aggregateCriteria) {
		this.havingCriteria?.addCriteria(aggregateCriteria);
		return this;
	}

    public Soql orderBy(Soql.OrderBy orderByClause) {
		this.orderByClause = orderByClause;
		return this;
	}

	public Soql setHavingLogic(Type newLogicType) {
		List<ICriteria> filters = this.havingCriteria?.getCriteria();
        ConditionalLogic newLogic = (ConditionalLogic) newLogicType?.newInstance();
        newLogic?.addCriteria(filters);
        this.havingCriteria = newLogic;
		return this;
	}

    public Soql setWhereLogic(Type newLogicType) {
		List<ICriteria> filters = this.whereCriteria?.getCriteria();
        ConditionalLogic newLogic = (ConditionalLogic) newLogicType?.newInstance();
        newLogic?.addCriteria(filters);
        this.whereCriteria = newLogic;
		return this;
	}

	public Soql setRowLimit(Integer rowLimit) {
		this.rowLimit = rowLimit;
		return this;
	}

	public Soql setRowOffset(Integer rowOffset) {
		this.rowOffset = rowOffset;
		return this;
	}

	public Soql withUsage(Soql.Usage usage) {
		this.usage = usage;
		return this;
	}

	public Soql bind(String key, Object value) {
		this.binds?.put(key, value);
        return this;
	}

	public Soql setAccessLevel(System.AccessLevel accessLevel) {
		this.accessLevel = accessLevel;
		return this;
	}

	// **** PRIVATE **** //
    protected String constructClause(String prefix, Object value) {
        // Returns a specific SOQL clause (ex., "WHERE {value}"), provided that `value` is not null
        return (value != null) ? (prefix + ' ' + value?.toString()) : null;
    }

	protected String getOptionalArgs() {
        List<String> args = new List<String>();
        for (String arg : new List<String>{
            this.constructClause('USING SCOPE', this.scope),
            this.constructClause('WHERE', this.whereCriteria),
            this.constructClause('WITH', this.withExpression),
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

	protected virtual String getFrom() {
		return this.fromSObject?.toString();
	}

	protected virtual String getGroupBy() {
		return (this.groupByClauses?.isEmpty() == false) ? 'GROUP BY ' + String.join(this.groupByClauses, ', ') : null;
	}

	protected virtual String getUsage() {
		return this.usage?.toString()?.replace('_', ' ');
	}

	// **** INNER *** //
    public enum AggregateFunction {
        AVG,
		COUNT,
		COUNT_DISTINCT,
		FORMAT,
		MIN,
		MAX,
		SUM
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

    public class AggregateFilter extends Condition {
        public AggregateFilter(Soql.Aggregation agg, Condition.Operator operator, Object value) {
			super(agg?.toString(), operator, value);
		}
    }

    public class OrderBy {
        // TODO!
    }

    public class Subquery extends Soql {
        // TODO!
    }

    public class WithClause {
        // TODO!
    }
}