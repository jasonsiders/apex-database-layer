public inherited sharing virtual class Soql {
    public Set<String> selectClauses { get; private set; }
	public String fromSObjectName { get; private set; }
	public Soql.Scope scope { get; private set; }
	public Soql.WithExpression withExpression { get; private set; }
	public ICriteria whereCriteria { get; private set; }
	public List<String> groupByClauses { get; private set; }
	public ICriteria havingCriteria { get; private set; }
	public Soql.OrderBy orderByClause { get; private set; }
	public Integer rowLimit { get; private set; }
	public Integer rowOffset { get; private set; }
	public Soql.Usage usage { get; private set; }
	public System.AccessLevel accessLevel { get; private set; }
	public Map<String, Object> binds { get; private set; }

    // **** Constructors **** //
    public Soql() {
        this.accessLevel = System.AccessLevel.USER_MODE;
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
            // Add the text of the query to the Exception details, for easier debugging
			String augmentedMessage = error?.getMessage() + '\nQuery: [' + theQuery + ']';
			error?.setMessage(augmentedMessage);
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
    

    // **** PRIVATE **** //
    protected String constructClause(String prefix, Object value) {
        return (value != null) ? (prefix + ' ' + value?.toString()) : null;
    }

    protected virtual String getFrom() {
        return this.fromSObjectName;
    }

    protected String getGroupBy() {
        return (this.groupByClauses?.isEmpty() == false) ? 'GROUP BY ' + String.join(this.groupByClauses, ', ') : null;
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

    protected String getUsage() {
        return this.usage?.toString()?.replace('_', ' ');
    }

    // **** INNER **** // 
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
    
    public class OrderBy {
        // TODO!
    }

    public class Subquery extends Soql {
        // TODO!
    }

    public class WithExpression {
        // TODO!
    }
}