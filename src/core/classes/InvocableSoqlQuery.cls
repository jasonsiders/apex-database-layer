/**
 * @description A `SOQL: Get Record(s)` query, parsed from the JSON its editor writes. Builds the query, binding every
 * value, and resolves each interview's values for it
 */
// Each method is small; the class totals cover parsing, rendering, and coercion, like Soql
@SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity')
public inherited sharing class InvocableSoqlQuery {
	// **** CONSTANTS **** //
	/** @description Ends a stored field that selects every field of its object, ex: "*" or "Account.Owner.*" **/
	public static final String ALL_FIELDS = '*';
	private static final String BIND_PREFIX = 'bind';
	/** @description Only condition numbers, AND, OR, NOT, and parentheses, so custom logic can't add SOQL **/
	private static final Pattern CUSTOM_LOGIC_PATTERN = Pattern.compile('(?i)^(\\s|\\d+|AND|OR|NOT|\\(|\\))*$');
	private static final Set<String> COLLECTION_OPERATORS = new Set<String>{ 'IN', 'NOT_IN' };
	/** @description SOQL can't bind INCLUDES or EXCLUDES values, so they're literals only **/
	private static final Set<String> LITERAL_OPERATORS = new Set<String>{ 'EXCLUDES', 'INCLUDES' };
	/** @description Operators whose rows can be split back to interviews by comparing the field in Apex **/
	private static final Set<String> MERGEABLE_OPERATORS = new Set<String>{
		'CONTAINS',
		'ENDS_WITH',
		'EQUALS',
		'IN',
		'LIKE',
		'STARTS_WITH'
	};
	private static final Set<String> NULL_OPERATORS = new Set<String>{ 'IS_NOT_NULL', 'IS_NULL' };
	private static final Pattern TOKEN_PATTERN = Pattern.compile('(?i)\\d+|AND|OR|NOT|\\(|\\)');
	private static final Map<String, String> TOKENS = new Map<String, String>{
		'CONTAINS' => 'LIKE',
		'ENDS_WITH' => 'LIKE',
		'EQUALS' => '=',
		'EXCLUDES' => 'EXCLUDES',
		'GREATER_OR_EQUAL' => '>=',
		'GREATER_THAN' => '>',
		'IN' => 'IN',
		'INCLUDES' => 'INCLUDES',
		'IS_NOT_NULL' => '!=',
		'IS_NULL' => '=',
		'LESS_OR_EQUAL' => '<=',
		'LESS_THAN' => '<',
		'LIKE' => 'LIKE',
		'NOT_EQUALS' => '!=',
		'NOT_IN' => 'NOT IN',
		'STARTS_WITH' => 'LIKE'
	};
	/** @description SOQL binds are strictly typed, ex: a Decimal can't bind to an Integer field; the rest are text **/
	private static final Map<Schema.DisplayType, Type> VALUE_TYPES = new Map<Schema.DisplayType, Type>{
		Schema.DisplayType.BOOLEAN => Boolean.class,
		Schema.DisplayType.CURRENCY => Decimal.class,
		Schema.DisplayType.DATE => Date.class,
		Schema.DisplayType.DATETIME => DateTime.class,
		Schema.DisplayType.DOUBLE => Decimal.class,
		Schema.DisplayType.ID => Id.class,
		Schema.DisplayType.INTEGER => Integer.class,
		Schema.DisplayType.LONG => Long.class,
		Schema.DisplayType.PERCENT => Decimal.class,
		Schema.DisplayType.REFERENCE => Id.class,
		Schema.DisplayType.TIME => Time.class
	};

	// **** JSON **** //
	/** @description Filters, combined by `conditionLogic` **/
	public List<InvocableSoqlQuery.Condition> conditions;
	/** @description Blank or AND (default) for all conditions, OR for any, or custom, ex: "1 AND (2 OR 3)" **/
	public String conditionLogic;
	/** @description Field API names to select, including parent fields, ex: "Account.Owner.Name"; Id is implied **/
	public List<String> fields;
	/** @description The object to query, ex: "Contact" **/
	public String objectApiName;
	/** @description ORDER BY fields, in order **/
	public List<InvocableSoqlQuery.SortOrder> orderBy;
	/** @description LIMIT, when set **/
	public Integer rowLimit;
	/** @description OFFSET, when set **/
	public Integer rowOffset;
	/** @description A `Soql.Usage` name, ex: ALL_ROWS or FOR_UPDATE; SOQL allows one at a time **/
	public String usage;

	// **** RESOLVED **** //
	/** @description Each condition's field, in condition order, for coercing values and splitting merged results **/
	private transient List<DescribeFieldResult> conditionFields;
	/** @description Each condition's field path, split once, since a merged query reads it from every row **/
	private transient List<List<String>> conditionPaths;
	private transient DescribeSObjectResult objectDescribe;
	/** @description The expanded SELECT clauses, by access level, since user mode omits fields the user can't read **/
	private transient Map<System.AccessLevel, Set<String>> selectClausesByAccessLevel;

	// **** PUBLIC **** //
	/**
	 * @description Parses and checks a query from the action's editor, describing its object and condition fields
	 * @param definition The query, as JSON
	 * @return The parsed query
	 * @throws System.IllegalArgumentException When the definition is blank, or names an unknown field or operator
	 */
	public static InvocableSoqlQuery parse(String definition) {
		if (String.isBlank(definition)) {
			throw new IllegalArgumentException('Missing query definition');
		}
		InvocableSoqlQuery query = (InvocableSoqlQuery) JSON.deserialize(definition, InvocableSoqlQuery.class);
		return query?.describe();
	}

	/**
	 * @description Coerces a value to its condition field's type, since SOQL binds are strictly typed
	 * @param index The condition's index
	 * @param value A value, or a collection of values
	 * @return The value as the field's type; a collection becomes a list of that type
	 */
	public Object coerce(Integer index, Object value) {
		Type valueType = this.getValueType(index);
		return (value instanceof Iterable<Object>)
			? this.coerceList((Iterable<Object>) value, valueType)
			: this.coerceValue(value, valueType);
	}

	/**
	 * @description Reads a condition's field from a record, following parent relationships
	 * @param record A record from this query
	 * @param index The condition's index
	 * @return The field's value, or null if a parent is blank
	 */
	public Object getFieldValue(SObject record, Integer index) {
		List<String> names = this.conditionPaths?.get(index);
		Integer lastIndex = names?.size() - 1;
		SObject parent = record;
		for (Integer position = 0; position < lastIndex; position++) {
			String relationshipName = names?.get(position);
			parent = parent?.getSObject(relationshipName);
		}
		String fieldName = names?.get(lastIndex);
		return parent?.get(fieldName);
	}

	/**
	 * @description The condition's operator, ex: EQUALS
	 * @param index The condition's index
	 * @return The operator's name
	 */
	private String getOperator(Integer index) {
		return this.conditions?.get(index)?.operator;
	}

	/**
	 * @description SOQL compares text case-insensitively, except on case-sensitive fields
	 * @param index The condition's index
	 * @return Whether the condition's field compares text case-sensitively
	 */
	public Boolean isCaseSensitive(Integer index) {
		return this.conditionFields?.get(index)?.isCaseSensitive() == true;
	}

	/**
	 * @description Merging interviews unions one condition's values, then splits the rows by that field, which only
	 * gives each interview its own rows when every condition must match, and no row is cut by LIMIT or OFFSET
	 * @param index The condition whose values differ between interviews
	 * @return Whether interviews that differ only in this condition can share one query
	 */
	public Boolean isMergeable(Integer index) {
		Boolean isAllConditions = this.getLogicName() == 'AND';
		// Equality on a multi-select picklist compares the whole set of values, which a split can't reproduce
		Boolean isMultiPicklist = this.conditionFields?.get(index)?.getType() == Schema.DisplayType.MULTIPICKLIST;
		String operator = this.getOperator(index);
		return isAllConditions &&
			this.rowLimit == null &&
			this.rowOffset == null &&
			isMultiPicklist == false &&
			InvocableSoqlQuery.MERGEABLE_OPERATORS?.contains(operator) == true;
	}

	/**
	 * @description Contains, Starts With, Ends With, and Like bind a LIKE pattern; the rest bind values
	 * @param index The condition's index
	 * @return Whether the condition's value is a LIKE pattern
	 */
	public Boolean isPattern(Integer index) {
		String operator = this.getOperator(index);
		return InvocableSoqlQuery.TOKENS?.get(operator) == 'LIKE';
	}

	/**
	 * @description Resolves an interview's value for each condition, from its slot or the definition
	 * @param input The interview's input
	 * @return One value per condition, in condition order; null for conditions without a bound value
	 */
	public List<Object> resolveValues(InvocableSoql.Input input) {
		List<Object> values = new List<Object>{};
		for (Integer index = 0; index < this.conditions?.size(); index++) {
			Object value = this.resolveValue(index, input);
			values?.add(value);
		}
		return values;
	}

	/**
	 * @description Builds the query, binding every value, so values never become SOQL text
	 * @param values One value per condition, from `resolveValues`
	 * @param accessLevel The access level to query in
	 * @return The query, ready to run
	 */
	public Soql toSoql(List<Object> values, System.AccessLevel accessLevel) {
		InvocableSoqlQuery.Filter whereClause = new InvocableSoqlQuery.Filter(this, values, false);
		Map<String, Object> binds = this.initBinds(values);
		return (Soql) this.initSoql(whereClause, accessLevel)?.addBind(binds);
	}

	/**
	 * @description Renders the query with values in place of binds, for Flow's debug panel
	 * @param values One value per condition, from `resolveValues`
	 * @param accessLevel The access level to query in, which decides the fields that all-field selections include
	 * @return The query, with values filled in
	 */
	public String toQueryString(List<Object> values, System.AccessLevel accessLevel) {
		InvocableSoqlQuery.Filter whereClause = new InvocableSoqlQuery.Filter(this, values, true);
		return this.initSoql(whereClause, accessLevel)?.toString();
	}

	// **** PRIVATE **** //
	/**
	 * @description Adds each ORDER BY field
	 * @param builder The query being built
	 */
	private void addOrderBy(Soql builder) {
		for (InvocableSoqlQuery.SortOrder sortOrder : this.orderBy ?? new List<InvocableSoqlQuery.SortOrder>{}) {
			Soql.SortOrder order = sortOrder?.toSortOrder();
			builder?.addOrderBy(order);
		}
	}

	/**
	 * @description Adds the SELECT clauses, expanded once per access level, since a batch builds a query and a query
	 * string for each variant, and each all-field selection describes every field of its object
	 * @param builder The query being built
	 */
	private void addSelect(Soql builder) {
		System.AccessLevel accessLevel = builder?.accessLevel;
		Set<String> cached = this.selectClausesByAccessLevel?.get(accessLevel);
		if (cached == null) {
			this.addFields(builder);
			Set<String> clauses = builder?.selectClauses;
			this.selectClausesByAccessLevel?.put(accessLevel, clauses?.clone());
		} else {
			for (String clause : cached) {
				builder?.addSelect(clause);
			}
		}
	}

	/**
	 * @description Adds each field to SELECT, plus each condition's field, so merged results can be split by it
	 * @param builder The query being built
	 */
	private void addFields(Soql builder) {
		List<String> fieldNames = new List<String>(this.fields ?? new List<String>{});
		for (InvocableSoqlQuery.Condition condition : this.conditions) {
			fieldNames?.add(condition?.field);
		}
		for (String fieldName : fieldNames) {
			this.addField(builder, fieldName);
		}
	}

	/**
	 * @description Adds a field to SELECT, or every field of its object for a path ending in `*`
	 * @param builder The query being built
	 * @param fieldName A field path, ex: "Account.Name", or "Account.*" for every field of the account
	 */
	private void addField(Soql builder, String fieldName) {
		if (fieldName?.endsWith(InvocableSoqlQuery.ALL_FIELDS) == true) {
			List<SObjectField> lookups = this.findLookups(fieldName);
			builder?.selectAll(lookups);
		} else {
			builder?.addSelect(fieldName);
		}
	}

	/**
	 * @description Coerces each value in a collection, since a list can't be converted to another element type
	 * @param values The values
	 * @param valueType The field's Apex type
	 * @return A list of the field's type
	 */
	private List<Object> coerceList(Iterable<Object> values, Type valueType) {
		String listTypeName = 'List<' + valueType?.getName() + '>';
		Type listType = Type.forName(listTypeName);
		List<Object> coerced = (List<Object>) listType?.newInstance();
		for (Object value : values) {
			Object element = this.coerceValue(value, valueType);
			coerced?.add(element);
		}
		return coerced;
	}

	/**
	 * @description JSON converts flow values and the editor's text alike; Id.valueOf also lengthens 15-character IDs,
	 * so they match the 18-character IDs that queries return
	 * @param value A single value
	 * @param valueType The field's Apex type
	 * @return The value as the field's type
	 */
	private Object coerceValue(Object value, Type valueType) {
		InvocableSoqlQuery.checkWholeNumber(value, valueType);
		Boolean isId = valueType == Id.class && value != null;
		// JSON reads a time without a zone, ex: "10:30", in the user's time zone; Time fields hold the time as typed
		Boolean isLocalTime =
			value instanceof String &&
			valueType == Time.class &&
			((String) value).endsWith('Z') == false;
		Object zoned = isLocalTime ? value + 'Z' : value;
		String text = String.valueOf(value);
		String serialized = isId ? null : JSON.serialize(zoned);
		return isId ? Id.valueOf(text) : JSON.deserialize(serialized, valueType);
	}

	/**
	 * @description Describes the object and each condition's field once, checking every name and operator
	 * @return This query
	 * @throws System.IllegalArgumentException When the definition names an unknown field or operator
	 */
	private InvocableSoqlQuery describe() {
		this.conditions = this.conditions ?? new List<InvocableSoqlQuery.Condition>{};
		this.objectDescribe = this.describeObject();
		this.selectClausesByAccessLevel = new Map<System.AccessLevel, Set<String>>{};
		this.conditionFields = new List<DescribeFieldResult>{};
		this.conditionPaths = new List<List<String>>{};
		for (InvocableSoqlQuery.Condition condition : this.conditions) {
			condition?.validate();
			DescribeFieldResult field = this.describeField(condition?.field);
			this.conditionFields?.add(field);
			List<String> path = condition?.field?.split('\\.');
			this.conditionPaths?.add(path);
		}
		this.describeOtherFields();
		// Renders the WHERE clause once, so bad condition logic fails before any query runs
		List<Object> blankValues = new List<Object>(this.conditions?.size());
		new InvocableSoqlQuery.Filter(this, blankValues, true)?.toString();
		return this;
	}

	/**
	 * @description Checks the selected and sorted fields, like the condition fields, since each becomes SOQL text
	 * @throws System.IllegalArgumentException When a field doesn't exist
	 */
	private void describeOtherFields() {
		List<String> paths = new List<String>(this.fields ?? new List<String>{});
		for (InvocableSoqlQuery.SortOrder sortOrder : this.orderBy ?? new List<InvocableSoqlQuery.SortOrder>{}) {
			paths?.add(sortOrder?.field);
		}
		for (String path : paths) {
			this.describePath(path);
		}
	}

	/**
	 * @description Checks a selected or sorted path: its lookups for a path ending in `*`, or else its field
	 * @param path A field path, ex: "Account.Name" or "Account.*"
	 * @throws System.IllegalArgumentException When a relationship or field doesn't exist
	 */
	private void describePath(String path) {
		if (path?.endsWith(InvocableSoqlQuery.ALL_FIELDS) == true) {
			this.findLookups(path);
		} else {
			this.describeField(path);
		}
	}

	/**
	 * @description Follows a path's relationships, ex: "Account.Owner.*", to the lookups that lead to its object
	 * @param path A path ending in `*`
	 * @return The lookups, in order; empty for the queried object itself
	 * @throws System.IllegalArgumentException When a relationship doesn't exist
	 */
	private List<SObjectField> findLookups(String path) {
		String relationshipPath = path?.removeEnd(InvocableSoqlQuery.ALL_FIELDS)?.removeEnd('.');
		Boolean isTop = String.isBlank(relationshipPath);
		List<String> relationshipNames = isTop ? new List<String>{} : relationshipPath?.split('\\.');
		List<SObjectField> lookups = new List<SObjectField>{};
		DescribeSObjectResult parent = this.objectDescribe;
		for (String relationshipName : relationshipNames) {
			DescribeFieldResult lookup = this.findLookup(parent, relationshipName, path);
			lookups?.add(lookup?.getSObjectField());
			parent = this.describeReference(lookup);
		}
		return lookups;
	}

	/**
	 * @description Follows a field path's relationships to its field
	 * @param path A field API name, ex: "Account.Owner.Name"
	 * @return The field's describe
	 * @throws System.IllegalArgumentException When a relationship or field doesn't exist
	 */
	private DescribeFieldResult describeField(String path) {
		List<String> names = path?.split('\\.') ?? new List<String>{ null };
		Integer lastIndex = names?.size() - 1;
		String fieldName = names?.remove(lastIndex);
		DescribeSObjectResult parent = this.objectDescribe;
		for (String relationshipName : names) {
			parent = this.describeParent(parent, relationshipName, path);
		}
		SObjectField field = parent?.fields?.getMap()?.get(fieldName);
		if (field == null) {
			throw new IllegalArgumentException('Invalid field for ' + this.objectApiName + ': ' + path);
		}
		return field?.getDescribe();
	}

	/**
	 * @description Validated by Schema.describeSObjects, which throws for an unknown object
	 * @return The object's describe
	 * @throws System.IllegalArgumentException When the object is blank
	 */
	private DescribeSObjectResult describeObject() {
		if (String.isBlank(this.objectApiName)) {
			throw new IllegalArgumentException('Missing object');
		}
		List<String> objectApiNames = new List<String>{ this.objectApiName };
		return Schema.describeSObjects(objectApiNames, SObjectDescribeOptions.DEFERRED)?.get(0);
	}

	/**
	 * @description Finds a parent object's describe through a relationship, ex: Account's for "Account"
	 * @param child The object holding the lookup
	 * @param relationshipName The relationship name
	 * @param path The whole field path, for the error
	 * @return The parent object's describe
	 * @throws System.IllegalArgumentException When the object has no relationship by that name
	 */
	private DescribeSObjectResult describeParent(DescribeSObjectResult child, String relationshipName, String path) {
		DescribeFieldResult lookup = this.findLookup(child, relationshipName, path);
		return this.describeReference(lookup);
	}

	/**
	 * @description Finds the lookup with the relationship name, ex: AccountId for "Account"
	 * @param child The object holding the lookup
	 * @param relationshipName The relationship name
	 * @param path The whole field path, for the error
	 * @return The lookup's describe
	 * @throws System.IllegalArgumentException When the object has no relationship by that name
	 */
	private DescribeFieldResult findLookup(DescribeSObjectResult child, String relationshipName, String path) {
		DescribeFieldResult lookup;
		for (SObjectField field : child?.fields?.getMap()?.values()) {
			DescribeFieldResult describe = field?.getDescribe();
			String candidate = describe?.getRelationshipName();
			lookup = (relationshipName?.equalsIgnoreCase(candidate) == true) ? describe : lookup;
		}
		if (lookup == null) {
			throw new IllegalArgumentException('Invalid field for ' + this.objectApiName + ': ' + path);
		}
		return lookup;
	}

	/**
	 * @description Describes the object a lookup points to. A polymorphic lookup, ex: Who, describes as the Name
	 * object, since SOQL only allows its fields on one without TYPEOF
	 * @param lookup The lookup's describe
	 * @return The parent object's describe
	 */
	private DescribeSObjectResult describeReference(DescribeFieldResult lookup) {
		List<SObjectType> parentTypes = lookup?.getReferenceTo();
		String parentName = Soql.toEntityName(parentTypes);
		List<String> parentNames = new List<String>{ parentName };
		return Schema.describeSObjects(parentNames, SObjectDescribeOptions.DEFERRED)?.get(0);
	}

	/**
	 * @description Contains, Starts With, and Ends With match their text literally, so `%` and `_` in it are escaped
	 * before the wildcards are added
	 * @param index The condition's index
	 * @param value The coerced value
	 * @return The LIKE pattern, or the value for other operators
	 */
	private Object addWildcards(Integer index, Object value) {
		String operator = this.getOperator(index);
		Boolean isLeading = operator == 'CONTAINS' || operator == 'ENDS_WITH';
		Boolean isTrailing = operator == 'CONTAINS' || operator == 'STARTS_WITH';
		Boolean isPattern = (isLeading || isTrailing) && value instanceof String;
		String text = isPattern ? ((String) value).replace('\\', '\\\\').replace('%', '\\%').replace('_', '\\_') : null;
		String pattern = (isLeading ? '%' : '') + text + (isTrailing ? '%' : '');
		return isPattern ? pattern : value;
	}

	/**
	 * @description Unset collections bind as empty, since SOQL can't bind null to IN
	 * @param index The condition's index
	 * @param value The interview's value: a record collection binds as its records' IDs
	 * @return The value, ready to bind
	 */
	private Object prepareValue(Integer index, Object value) {
		Boolean isCollection = InvocableSoqlQuery.COLLECTION_OPERATORS?.contains(this.getOperator(index));
		Object collection = (value == null && isCollection) ? new List<Object>{} : value;
		Object recordIds = (collection instanceof List<SObject>) ? this.getRecordIds((List<SObject>) collection) : null;
		Object coerced = this.coerce(index, recordIds ?? collection);
		return this.addWildcards(index, coerced);
	}

	/**
	 * @description Binds a Record Collection slot by its records' IDs. Duplicates collapse, since IN ignores them
	 * anyway; a record with no ID throws, since it can't match anything and usually means an unsaved record
	 * @param records The collection from a Record Collection slot
	 * @return The records' IDs
	 * @throws System.IllegalArgumentException When a record has no ID
	 */
	private Set<Id> getRecordIds(List<SObject> records) {
		Map<Id, SObject> recordsById = new Map<Id, SObject>();
		recordsById?.putAll(records);
		// After putAll from a typed list, ex: List<Account>, containsKey(null) misses the null key; keySet() finds it
		if (recordsById?.keySet()?.contains(null) == true) {
			throw new IllegalArgumentException('Record Collection contains a record with no ID');
		}
		return recordsById?.keySet();
	}

	/**
	 * @description The condition logic, upper-cased; blank means AND
	 * @return AND, OR, or custom logic
	 */
	private String getLogicName() {
		String logic = this.conditionLogic?.trim()?.toUpperCase();
		return String.isBlank(logic) ? 'AND' : logic;
	}

	/**
	 * @description Fields of other types bind as text, ex: picklists
	 * @param index The condition's index
	 * @return The Apex type the condition's field binds as
	 */
	private Type getValueType(Integer index) {
		Schema.DisplayType fieldType = this.conditionFields?.get(index)?.getType();
		return InvocableSoqlQuery.VALUE_TYPES?.get(fieldType) ?? String.class;
	}

	/**
	 * @description Binds each condition's value by its index, ex: `:bind0`
	 * @param values One value per condition
	 * @return The binds
	 */
	private Map<String, Object> initBinds(List<Object> values) {
		Map<String, Object> binds = new Map<String, Object>{};
		for (Integer index = 0; index < this.conditions?.size(); index++) {
			if (this.conditions?.get(index)?.isBound() == true) {
				Object value = values?.get(index);
				binds?.put(InvocableSoqlQuery.BIND_PREFIX + index, value);
			}
		}
		return binds;
	}

	/**
	 * @description Builds everything but the binds, shared by the query and its debug string
	 * @param whereClause The WHERE clause, with binds or values
	 * @param accessLevel The access level to query in
	 * @return The query
	 */
	private Soql initSoql(InvocableSoqlQuery.Filter whereClause, System.AccessLevel accessLevel) {
		SObjectType objectType = this.objectDescribe?.getSObjectType();
		Soql builder = (Soql) DatabaseLayer.Soql?.newQuery(objectType)?.setAccessLevel(accessLevel);
		this.addSelect(builder);
		this.addOrderBy(builder);
		Soql.Usage usageType = String.isBlank(this.usage) ? null : Soql.Usage.valueOf(this.usage);
		return (Soql) builder
			?.addWhere(whereClause)
			?.setRowLimit(this.rowLimit)
			?.setRowOffset(this.rowOffset)
			?.setUsage(usageType);
	}

	/**
	 * @description Conditions bind their value from a slot, or else from the definition
	 * @param index The condition's index
	 * @param input The interview's input
	 * @return The value, ready to bind, or null when the condition doesn't bind one
	 */
	private Object resolveValue(Integer index, InvocableSoql.Input input) {
		InvocableSoqlQuery.Condition condition = this.conditions?.get(index);
		Boolean isBound = condition?.isBound() == true;
		Boolean hasSlot = isBound && condition?.slot != null;
		Object staticValue = (isBound && hasSlot == false) ? condition?.getStaticValue() : null;
		Object value = hasSlot ? input?.getSlotValue(condition?.slot) : staticValue;
		return isBound ? this.prepareValue(index, value) : null;
	}

	/**
	 * @description JSON would truncate a fraction for a whole-number field, ex: `< 42.5` would run as `< 42`, so it fails
	 * instead
	 * @param value A value for a condition
	 * @param valueType The field's Apex type
	 * @throws System.IllegalArgumentException When a whole-number field gets a value with a fraction
	 */
	private static void checkWholeNumber(Object value, Type valueType) {
		Boolean isWholeType = valueType == Integer.class || valueType == Long.class;
		String text = String.valueOf(value);
		Decimal amount = (isWholeType && value != null) ? Decimal.valueOf(text) : null;
		if (amount != null && amount != amount.round(System.RoundingMode.DOWN)) {
			throw new IllegalArgumentException('Whole-number fields take no fractions: ' + value);
		}
	}

	/**
	 * @description Joins tokens with spaces, except inside parentheses, ex: `(A OR B)`
	 * @param output The criteria so far
	 * @param token The next token
	 * @return The criteria, with the token
	 */
	private static String appendToken(String output, String token) {
		Boolean isTight = output == '' || output?.endsWith('(') == true || token == ')';
		return output + (isTight ? '' : ' ') + token;
	}

	/**
	 * @description Checks custom logic's grammar: operands, ex: `1`, `NOT 1`, or `(1 OR 2)`, joined by AND or OR, with
	 * balanced parentheses, since SOQL fails every query that isn't, on a syntax error that doesn't name the logic
	 * @param logic The custom logic, holding only numbers, AND, OR, NOT, and parentheses
	 * @return True if the logic is well formed
	 */
	private static Boolean isWellFormed(String logic) {
		Integer depth = 0;
		Boolean isOperandNext = true;
		Boolean isValid = true;
		Matcher tokens = InvocableSoqlQuery.TOKEN_PATTERN.matcher(logic);
		while (tokens?.find() == true) {
			String token = tokens?.group()?.toUpperCase();
			Boolean isOperand = token == 'NOT' || token == '(' || token?.isNumeric() == true;
			depth += (token == '(') ? 1 : 0;
			depth -= (token == ')') ? 1 : 0;
			isValid = isValid && isOperand == isOperandNext && depth >= 0;
			isOperandNext = token == 'AND' || token == 'OR' || token == 'NOT' || token == '(';
		}
		return isValid && isOperandNext == false && depth == 0;
	}

	/**
	 * @description Renders a LIKE pattern, escaping only quotes, since its backslashes are LIKE escapes, ex: `\%`
	 * @param value The pattern
	 * @return The literal
	 */
	private static String formatPattern(Object value) {
		String pattern = String.valueOf(value)?.replace('\'', '\\\'');
		return (value == null) ? 'null' : '\'' + pattern + '\'';
	}

	/**
	 * @description Renders a value as a SOQL literal. Dates format directly, not via a DateTime, which would shift them
	 * a day in time zones ahead of GMT
	 * @param value The value
	 * @return The literal
	 */
	private static String formatLiteral(Object value) {
		String literal;
		if (value == null) {
			literal = 'null';
		} else if (value instanceof Iterable<Object>) {
			literal = InvocableSoqlQuery.formatList((Iterable<Object>) value);
		} else if (value instanceof Date) {
			// Checked before DateTime, since a Date is also an instanceof DateTime
			literal = String.valueOf((Date) value);
		} else if (value instanceof DateTime) {
			literal = ((DateTime) value)?.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
		} else if (value instanceof String) {
			literal = '\'' + String.escapeSingleQuotes((String) value) + '\'';
		} else {
			literal = String.valueOf(value);
		}
		return literal;
	}

	/**
	 * @description Renders a collection as a SOQL list, ex: `('a', 'b')`
	 * @param values The values
	 * @return The list
	 */
	private static String formatList(Iterable<Object> values) {
		List<String> literals = new List<String>{};
		for (Object value : values) {
			String literal = InvocableSoqlQuery.formatLiteral(value);
			literals?.add(literal);
		}
		return '(' + String.join(literals, ', ') + ')';
	}

	// **** INNER **** //
	/** @description A filter on one field **/
	public class Condition {
		/** @description A date literal, ex: "LAST_N_DAYS:30", used instead of a value **/
		public String dateLiteral;
		/** @description The field API name, including parent fields, ex: "Account.Name" **/
		public String field;
		/** @description A key of `TOKENS`, ex: EQUALS **/
		public String operator;
		/** @description The slot holding the value, ex: "text1", when it comes from a flow resource **/
		public String slot;
		/** @description A static value, as text, when it doesn't come from a slot **/
		public String value;
		/** @description Static values, for IN, NOT_IN, INCLUDES, and EXCLUDES **/
		public List<String> values;

		/**
		 * @description Null checks, date literals, INCLUDES, and EXCLUDES are rendered in place; everything else binds
		 * @return Whether the condition binds a value
		 */
		public Boolean isBound() {
			Boolean isLiteral =
				InvocableSoqlQuery.LITERAL_OPERATORS?.contains(this.operator) == true ||
				InvocableSoqlQuery.NULL_OPERATORS?.contains(this.operator) == true;
			return isLiteral == false && String.isBlank(this.dateLiteral);
		}

		/**
		 * @description The definition holds collections in `values`, and anything else in `value`
		 * @return The static value or values
		 */
		private Object getStaticValue() {
			return this.values ?? (Object) this.value;
		}

		/**
		 * @description Renders the operand: a bind or value, a date literal, INCLUDES or EXCLUDES values, or null
		 * @param index The condition's index, which names its bind
		 * @param value The condition's value
		 * @param isLiteral Whether to render values in place of binds
		 * @return The operand
		 */
		private String renderOperand(Integer index, Object value, Boolean isLiteral) {
			// Values are only formatted for the debug string; the query binds them
			String operand;
			if (InvocableSoqlQuery.NULL_OPERATORS?.contains(this.operator) == true) {
				operand = 'null';
			} else if (String.isNotBlank(this.dateLiteral)) {
				operand = this.dateLiteral;
			} else if (InvocableSoqlQuery.LITERAL_OPERATORS?.contains(this.operator) == true) {
				operand = InvocableSoqlQuery.formatLiteral(this.values);
			} else if (isLiteral == false) {
				operand = ':' + InvocableSoqlQuery.BIND_PREFIX + index;
			} else if (InvocableSoqlQuery.TOKENS?.get(this.operator) == 'LIKE') {
				operand = InvocableSoqlQuery.formatPattern(value);
			} else {
				operand = InvocableSoqlQuery.formatLiteral(value);
			}
			return operand;
		}

		/**
		 * @description Renders the condition, ex: `Name = :bind0`
		 * @param index The condition's index, which names its bind
		 * @param value The condition's value
		 * @param isLiteral Whether to render values in place of binds
		 * @return The condition, as SOQL
		 */
		private String render(Integer index, Object value, Boolean isLiteral) {
			String token = InvocableSoqlQuery.TOKENS?.get(this.operator);
			String operand = this.renderOperand(index, value, isLiteral);
			return this.field + ' ' + token + ' ' + operand;
		}

		/**
		 * @description Checks the parts that become SOQL text: the operator and any date literal
		 * @throws System.IllegalArgumentException When the operator is unknown, or the date literal is malformed
		 */
		private void validate() {
			if (InvocableSoqlQuery.TOKENS?.containsKey(this.operator) == false) {
				throw new IllegalArgumentException('Invalid operator: ' + this.operator);
			}
			// Date literals are rendered as-is, since SOQL can't bind them, so only SOQL's own literals are allowed
			if (this.dateLiteral != null && !Soql.DATE_LITERAL_PATTERN.matcher(this.dateLiteral).matches()) {
				throw new IllegalArgumentException('Invalid date literal: ' + this.dateLiteral);
			}
		}
	}

	/** @description An ORDER BY field **/
	public class SortOrder {
		/** @description ASCENDING (default) or DESCENDING **/
		public String direction;
		/** @description The field API name, including parent fields **/
		public String field;
		/** @description NULLS_FIRST or NULLS_LAST; blank uses `Soql.SortOrder`'s default **/
		public String nullOrder;

		/**
		 * @description Converts to the builder's sort order
		 * @return The sort order
		 */
		private Soql.SortOrder toSortOrder() {
			Soql.SortDirection sortDirection = Soql.SortDirection.valueOf(this.direction ?? 'ASCENDING');
			Soql.SortOrder order = new Soql.SortOrder(this.field, sortDirection);
			Soql.NullOrder nullOrderType = String.isBlank(this.nullOrder)
				? null
				: Soql.NullOrder.valueOf(this.nullOrder);
			return (nullOrderType == null) ? order : order?.setNullOrder(nullOrderType);
		}
	}

	/**
	 * @description The WHERE clause, rendered from the condition logic. `Soql.ConditionalLogic` only joins with one of
	 * AND or OR, so custom logic needs its own criteria
	 */
	private class Filter implements Soql.Criteria {
		private Boolean isLiteral;
		private InvocableSoqlQuery query;
		private List<Object> values;

		/**
		 * @description Holds what rendering needs
		 * @param query The query
		 * @param values One value per condition
		 * @param isLiteral Whether to render values in place of binds
		 */
		private Filter(InvocableSoqlQuery query, List<Object> values, Boolean isLiteral) {
			this.isLiteral = isLiteral;
			this.query = query;
			this.values = values;
		}

		/**
		 * @description Renders the logic token by token, replacing each condition number with its condition. SOQL only
		 * allows NOT at the start of a group, ex: `A AND (NOT B)`, so each NOT and its operand are wrapped in parentheses.
		 * Soql omits a blank WHERE
		 * @return The WHERE clause's criteria
		 */
		public override String toString() {
			String output = '';
			Integer depth = 0;
			// The depth of each NOT still waiting for its operand to end
			List<Integer> openNots = new List<Integer>{};
			Matcher tokens = InvocableSoqlQuery.TOKEN_PATTERN.matcher(this.getLogic());
			while (tokens?.find() == true) {
				String token = tokens?.group()?.toUpperCase();
				depth += (token == '(') ? 1 : 0;
				depth -= (token == ')') ? 1 : 0;
				String rendered = this.renderToken(token);
				output = InvocableSoqlQuery.appendToken(output, rendered);
				Boolean isOperandEnd = token == ')' || token?.isNumeric() == true;
				output = isOperandEnd ? this.closeNots(output, openNots, depth) : output;
				if (token == 'NOT') {
					openNots?.add(depth);
				}
			}
			return output;
		}

		/**
		 * @description Closes each NOT whose operand just ended at this depth
		 * @param output The criteria so far
		 * @param openNots The depth of each open NOT, innermost last; closed ones are removed
		 * @param depth The current parenthesis depth
		 * @return The criteria, with a closing parenthesis per closed NOT
		 */
		private String closeNots(String output, List<Integer> openNots, Integer depth) {
			String closed = output;
			Integer lastIndex = openNots?.size() - 1;
			while (lastIndex >= 0 && openNots?.get(lastIndex) == depth) {
				openNots?.remove(lastIndex);
				closed = InvocableSoqlQuery.appendToken(closed, ')');
				lastIndex--;
			}
			return closed;
		}

		/**
		 * @description Renders one token of the logic
		 * @param token A condition number, AND, OR, NOT, or a parenthesis
		 * @return The token as SOQL
		 */
		private String renderToken(String token) {
			String keyword = (token == 'NOT') ? '(NOT' : token;
			return token?.isNumeric() == true ? this.renderCondition(token) : keyword;
		}

		/**
		 * @description AND and OR join every condition; anything else is custom logic
		 * @return The logic, by condition number, ex: "1 AND 2"
		 * @throws System.IllegalArgumentException When custom logic holds anything but numbers, AND, OR, NOT, and
		 * parentheses, or isn't well formed
		 */
		private String getLogic() {
			String logic = this.query?.getLogicName();
			List<String> numbers = new List<String>{};
			for (Integer index = 1; index <= this.query?.conditions?.size(); index++) {
				String conditionNumber = String.valueOf(index);
				numbers?.add(conditionNumber);
			}
			Boolean isPreset = logic == 'AND' || logic == 'OR';
			Boolean isValidCustom =
				InvocableSoqlQuery.CUSTOM_LOGIC_PATTERN.matcher(logic).matches() &&
				InvocableSoqlQuery.isWellFormed(logic);
			if (isPreset == false && isValidCustom == false) {
				throw new IllegalArgumentException('Invalid condition logic: ' + this.query?.conditionLogic);
			}
			return isPreset ? String.join(numbers, ' ' + logic + ' ') : logic;
		}

		/**
		 * @description Renders a condition by its number in the logic
		 * @param conditionNumber The condition's number, starting at 1
		 * @return The condition, as SOQL
		 * @throws System.IllegalArgumentException When no condition has that number
		 */
		private String renderCondition(String conditionNumber) {
			Integer index = Integer.valueOf(conditionNumber) - 1;
			if (index < 0 || index >= this.query?.conditions?.size()) {
				throw new IllegalArgumentException('Invalid condition logic: ' + this.query?.conditionLogic);
			}
			Object value = this.values?.get(index);
			return this.query?.conditions?.get(index)?.render(index, value, this.isLiteral);
		}
	}
}
