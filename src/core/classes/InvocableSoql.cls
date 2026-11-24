/**
 * @description Flow action that queries records via `DatabaseLayer.Soql`, from a query built in its editor: parent
 * fields, the access level, and values from flow resources. See `InvocableSoql.Planner` for how a bulk run shares
 * queries
 */
@SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.NcssCount')
public inherited sharing class InvocableSoql {
	// **** CONSTANTS **** //
	/** @description Ends a stored field that selects every field of its object, ex: "*" or "Account.Owner.*" **/
	public static final String ALL_FIELDS = '*';
	private static final String BIND_PREFIX = 'bind';
	/** @description Only condition numbers, AND, OR, NOT, and parentheses, so custom logic can't add SOQL **/
	private static final Pattern CUSTOM_LOGIC_PATTERN = Pattern.compile('(?i)^(\\s|\\d+|AND|OR|NOT|\\(|\\))*$');
	private static final Set<String> COLLECTION_OPERATORS = new Set<String>{ 'IN', 'NOT_IN' };
	/** @description SOQL can't bind INCLUDES or EXCLUDES values, so they're literals only **/
	private static final Set<String> LITERAL_OPERATORS = new Set<String>{ 'EXCLUDES', 'INCLUDES' };
	/** @description The most rows SOQL's OFFSET can skip **/
	private static final Integer MAX_OFFSET = 2000;
	/** @description Ordered as days since this date, so dates compare as numbers **/
	private static final Date EPOCH = Date.newInstance(1970, 1, 1);
	/** @description Operators Apex checks by key: whether the field's value is, or isn't, one of the values **/
	private static final Set<String> KEY_OPERATORS = new Set<String>{ 'EQUALS', 'IN', 'NOT_EQUALS', 'NOT_IN' };
	/** @description Matches no variants; shared, so it's never changed **/
	private static final Set<Integer> NO_POSITIONS = new Set<Integer>{};
	/** @description Field types Apex orders like SOQL; text follows SOQL's sort order, which Apex can't reproduce **/
	private static final Set<Type> ORDERED_TYPES = new Set<Type>{
		Date.class,
		DateTime.class,
		Decimal.class,
		Integer.class,
		Long.class,
		Time.class
	};
	private static final Set<String> RANGE_OPERATORS = new Set<String>{
		'GREATER_OR_EQUAL',
		'GREATER_THAN',
		'LESS_OR_EQUAL',
		'LESS_THAN'
	};
	/** @description Takes true or false, like Get Records: false finds the records whose field has a value **/
	private static final String NULL_CHECK = 'IS_NULL';
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

	// **** PUBLIC **** //
	/**
	 * @description Runs each interview's query, sharing queries across interviews where it can, so a bulk run doesn't
	 * spend one query per interview
	 * @param inputs One input per flow interview
	 * @return One output per input, in the same order
	 */
	@InvocableMethod(
		category='Database Layer'
		configurationEditor='c-soql-query-editor'
		description='Get records that meet conditions, with parent fields, control over the access level, and values from flow resources.'
		iconName='slds:standard:record_lookup'
		label='SOQL: Get Record(s)'
	)
	public static List<InvocableSoql.Output> invoke(List<InvocableSoql.Input> inputs) {
		return new InvocableSoql.Planner()?.run(inputs);
	}

	/**
	 * @description Lists the objects the action's editor offers, like Get Records. DEFERRED skips each object's fields
	 * and child relationships, which the list doesn't need
	 * @return The running user's queryable objects
	 */
	@AuraEnabled(cacheable=true)
	public static List<InvocableSoql.ObjectOption> getObjects() {
		List<InvocableSoql.ObjectOption> options = new List<InvocableSoql.ObjectOption>{};
		for (SObjectType objectType : Schema.getGlobalDescribe()?.values()) {
			DescribeSObjectResult describe = objectType?.getDescribe(SObjectDescribeOptions.DEFERRED);
			if (describe?.isQueryable() == true && describe?.isDeprecatedAndHidden() == false) {
				InvocableSoql.ObjectOption option = new InvocableSoql.ObjectOption(describe);
				options?.add(option);
			}
		}
		return options;
	}

	/**
	 * @description Lists an object's fields for the action's editor, with what it needs to offer them: types for
	 * operators and values, relationships for drilling into parent fields, and picklist values
	 * @param objectApiName The object, ex: "Contact"
	 * @return The running user's accessible fields
	 * @throws System.AuraHandledException When the object doesn't exist
	 */
	@AuraEnabled(cacheable=true)
	public static List<InvocableSoql.FieldOption> getFields(String objectApiName) {
		List<InvocableSoql.FieldOption> options = new List<InvocableSoql.FieldOption>{};
		for (SObjectField field : DatabaseLayer.Utils.Schema.describeFields(objectApiName)) {
			DescribeFieldResult describe = field?.getDescribe();
			if (describe?.isAccessible() == true) {
				InvocableSoql.FieldOption option = new InvocableSoql.FieldOption(describe, objectApiName);
				options?.add(option);
			}
		}
		return options;
	}

	// **** PRIVATE **** //
	/**
	 * @description Lists a field's active picklist values
	 * @param entries The field's picklist entries; empty for other fields
	 * @return The active values, in the field's order
	 */
	private static List<InvocableSoql.PicklistOption> initPicklistOptions(List<Schema.PicklistEntry> entries) {
		List<InvocableSoql.PicklistOption> options = new List<InvocableSoql.PicklistOption>{};
		for (Schema.PicklistEntry entry : entries) {
			if (entry?.isActive() == true) {
				InvocableSoql.PicklistOption option = new InvocableSoql.PicklistOption(entry);
				options?.add(option);
			}
		}
		return options;
	}

	/**
	 * @description Parses and checks a query from the action's editor, describing its object and condition fields
	 * @param definition The query, as JSON
	 * @return The parsed query
	 * @throws System.IllegalArgumentException When the definition is blank, or names an unknown field or operator
	 */
	@TestVisible
	private static InvocableSoql.Query parseQuery(String definition) {
		if (String.isBlank(definition)) {
			throw new IllegalArgumentException('Missing query definition');
		}
		InvocableSoql.Query query = (InvocableSoql.Query) JSON.deserialize(definition, InvocableSoql.Query.class);
		return query?.describe();
	}

	/**
	 * @description JSON would truncate a fraction for a whole-number field, ex: `< 42.5` would run as `< 42`, so it
	 * fails instead
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
	 * @description Builds an empty list of a field's type, since SOQL can't bind a `List<Object>`
	 * @param valueType The field's Apex type
	 * @return The list
	 */
	private static List<Object> initList(Type valueType) {
		String listTypeName = 'List<' + valueType?.getName() + '>';
		return (List<Object>) Type.forName(listTypeName)?.newInstance();
	}

	/**
	 * @description Whether a typed list takes the values as they are, the same as `InvocableSoql.Query.coerceValue`
	 * would convert them: a `List<Id>` checks and lengthens each ID it's given, and text and numbers already of their
	 * field's type need no conversion
	 * @param values A collection of values
	 * @param valueType The field's Apex type
	 * @return True if the values can be added to the field's list as they are
	 */
	private static Boolean isNativeList(Iterable<Object> values, Type valueType) {
		Boolean isText = valueType == String.class && values instanceof List<String>;
		Boolean isNumber = valueType == Decimal.class && values instanceof List<Decimal>;
		return valueType == Id.class || isText || isNumber;
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
	 * @description Whether logic joins anything with OR outside parentheses, ex: `1 OR 2` but not `1 AND (2 OR 3)`
	 * @param logic The logic, by condition number
	 * @return True if any OR is outside parentheses
	 */
	private static Boolean hasTopLevelOr(String logic) {
		Integer depth = 0;
		Boolean hasOr = false;
		Matcher tokens = InvocableSoql.TOKEN_PATTERN.matcher(logic);
		while (tokens?.find() == true) {
			String token = tokens?.group()?.toUpperCase();
			depth += (token == '(') ? 1 : 0;
			depth -= (token == ')') ? 1 : 0;
			hasOr = hasOr || (token == 'OR' && depth == 0);
		}
		return hasOr;
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
		Matcher tokens = InvocableSoql.TOKEN_PATTERN.matcher(logic);
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
			literal = InvocableSoql.formatList((Iterable<Object>) value);
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
			String literal = InvocableSoql.formatLiteral(value);
			literals?.add(literal);
		}
		return '(' + String.join(literals, ', ') + ')';
	}

	/**
	 * @description Normalizes a value so equal values match: decimals ignore scale, ex: 100 and 100.00, and text
	 * ignores case unless its field is case-sensitive, like SOQL. IDs are already 18 characters, via
	 * `InvocableSoql.Query.coerce`, so their case-insensitive form is still unique
	 * @param value A field value, or a value the field was compared to
	 * @param isCaseSensitive Whether the field compares text case-sensitively
	 * @return The value's key, or null for a null value
	 */
	@TestVisible
	private static String toKey(Object value, Boolean isCaseSensitive) {
		String text = (value instanceof Decimal)
			? ((Decimal) value)?.stripTrailingZeros()?.toPlainString()
			: String.valueOf(value);
		return (isCaseSensitive == true) ? text : text?.toLowerCase();
	}

	/**
	 * @description Converts a value to a number that orders like it, so ranges compare numbers, dates, date/times,
	 * and times alike
	 * @param value A number, date, date/time, or time
	 * @return The value's order, or null for a null value
	 */
	private static Decimal toOrdinal(Object value) {
		Decimal ordinal;
		if (value instanceof Time) {
			ordinal = DateTime.newInstanceGmt(InvocableSoql.EPOCH, (Time) value)?.getTime();
		} else if (value instanceof Date) {
			// Checked before DateTime, since a Date is also an instanceof DateTime
			ordinal = InvocableSoql.EPOCH.daysBetween((Date) value);
		} else if (value instanceof DateTime) {
			// SOQL drops a bound's milliseconds, and stores none, so date/times compare whole seconds
			Decimal milliseconds = ((DateTime) value)?.getTime();
			ordinal = (milliseconds / 1000)?.round(System.RoundingMode.FLOOR);
		} else {
			ordinal = (Decimal) value;
		}
		return ordinal;
	}

	/**
	 * @description Treats a single value as a one-item list, so EQUALS and IN values merge alike. In values are
	 * lists, via `InvocableSoql.Query.coerce`, and come back as is, so callers only read the result
	 * @param value A value, or a list of values
	 * @return The values
	 */
	private static List<Object> toList(Object value) {
		Boolean isList = value instanceof List<Object>;
		return isList ? (List<Object>) value : new List<Object>{ value };
	}

	// **** INNER **** //
	/** @description A field the editor offers, with what it needs to build conditions on it **/
	public class FieldOption {
		/** @description The field's API name **/
		@AuraEnabled
		public String apiName;
		/** @description Conditions can only use filterable fields **/
		@AuraEnabled
		public Boolean isFilterable;
		/** @description A lookup to several objects, or that SOQL resolves to Name, ex: Task.WhoId, takes any records **/
		@AuraEnabled
		public Boolean isPolymorphic;
		/** @description ORDER BY can only use sortable fields **/
		@AuraEnabled
		public Boolean isSortable;
		/** @description Shown beside the API name **/
		@AuraEnabled
		public String label;
		/** @description Offered as values for picklist conditions; active values only **/
		@AuraEnabled
		public List<InvocableSoql.PicklistOption> picklistValues;
		/**
		 * @description The object whose IDs the field holds: a lookup's parent, which the editor drills into, or the
		 * field's own object for its ID. A polymorphic lookup holds the Name object, like Apex
		 */
		@AuraEnabled
		public String referenceTo;
		/** @description The lookup's relationship name, ex: "Account" for AccountId; blank for other fields **/
		@AuraEnabled
		public String relationshipName;
		/** @description A `Schema.DisplayType` name, ex: "PICKLIST", which picks the operators and value type **/
		@AuraEnabled
		public String type;

		/**
		 * @description Copies the describe details the editor needs
		 * @param field The field's describe
		 * @param objectApiName The field's object
		 */
		private FieldOption(DescribeFieldResult field, String objectApiName) {
			List<SObjectType> parents = field?.getReferenceTo();
			List<Schema.PicklistEntry> entries = field?.getPicklistValues();
			String parentName = DatabaseLayer.Utils.Schema.toEntityName(field);
			Boolean isId = field?.getType() == Schema.DisplayType.ID;
			this.apiName = field?.getName();
			this.isFilterable = field?.isFilterable();
			String firstParent = parents?.isEmpty() == false ? parents?.get(0)?.toString() : null;
			// A lookup that resolves to Name drills into an object that holds no records, so it takes any object's
			this.isPolymorphic = parents?.size() > 1 || parentName != firstParent;
			this.isSortable = field?.isSortable();
			this.label = field?.getLabel();
			this.picklistValues = InvocableSoql.initPicklistOptions(entries);
			this.referenceTo = isId ? objectApiName : parentName;
			this.relationshipName = field?.getRelationshipName();
			this.type = field?.getType()?.name();
		}
	}

	/** @description An object the editor offers **/
	public class ObjectOption {
		/** @description The object's API name **/
		@AuraEnabled
		public String apiName;
		/** @description Shown in the list, like Get Records **/
		@AuraEnabled
		public String label;

		/**
		 * @description Copies the describe details the editor needs
		 * @param describe The object's describe
		 */
		private ObjectOption(DescribeSObjectResult describe) {
			this.apiName = describe?.getName();
			this.label = describe?.getLabel();
		}
	}

	/** @description A picklist value the editor offers **/
	public class PicklistOption {
		/** @description Shown in the list **/
		@AuraEnabled
		public String label;
		/** @description Saved in the condition **/
		@AuraEnabled
		public String value;

		/**
		 * @description Copies a picklist entry
		 * @param entry The entry
		 */
		private PicklistOption(Schema.PicklistEntry entry) {
			this.label = entry?.getLabel();
			this.value = entry?.getValue();
		}
	}

	/**
	 * @description The query, plus typed slots for its values. Flow can't pass values of any type through one input, so
	 * the editor assigns each resource to a free slot of its type, and the query names the slot
	 */
	// Flow can't pass values of any type through one input, so each type needs its own slots
	@SuppressWarnings('PMD.ExcessivePublicCount,PMD.TooManyFields')
	public class Input {
		/** @description Text, not an enum, since Flow can't pass System.AccessLevel **/
		@InvocableVariable(
			label='Access Level'
			description='USER_MODE (default) enforces the running user\'s object permissions, field-level security, and sharing rules. SYSTEM_MODE ignores all three, like Get Records in a flow that runs in system context without sharing.'
		)
		public String accessLevel;

		/** @description JSON, read by `InvocableSoql.Query`; the action's editor writes it **/
		@InvocableVariable(
			label='Query Definition'
			description='The query to run, as JSON. The action\'s editor writes it.'
			required=true
		)
		public String queryDefinition;

		/** @description Built on first use, since an interview can read several slots **/
		private transient Map<String, Object> slotValues;

		// * Text *
		/** @description A text value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Text 1'
			description='A text value for a query condition. The action\'s editor assigns it.'
		)
		public String text1;
		/** @description A text value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Text 2'
			description='A text value for a query condition. The action\'s editor assigns it.'
		)
		public String text2;
		/** @description A text value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Text 3'
			description='A text value for a query condition. The action\'s editor assigns it.'
		)
		public String text3;
		/** @description A text value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Text 4'
			description='A text value for a query condition. The action\'s editor assigns it.'
		)
		public String text4;
		/** @description A text value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Text 5'
			description='A text value for a query condition. The action\'s editor assigns it.'
		)
		public String text5;

		// * Number *
		/** @description A number value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Number 1'
			description='A number value for a query condition. The action\'s editor assigns it.'
		)
		public Decimal number1;
		/** @description A number value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Number 2'
			description='A number value for a query condition. The action\'s editor assigns it.'
		)
		public Decimal number2;
		/** @description A number value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Number 3'
			description='A number value for a query condition. The action\'s editor assigns it.'
		)
		public Decimal number3;
		/** @description A number value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Number 4'
			description='A number value for a query condition. The action\'s editor assigns it.'
		)
		public Decimal number4;
		/** @description A number value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Number 5'
			description='A number value for a query condition. The action\'s editor assigns it.'
		)
		public Decimal number5;

		// * Date *
		/** @description A date value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Date 1'
			description='A date value for a query condition. The action\'s editor assigns it.'
		)
		public Date date1;
		/** @description A date value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Date 2'
			description='A date value for a query condition. The action\'s editor assigns it.'
		)
		public Date date2;
		/** @description A date value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Date 3'
			description='A date value for a query condition. The action\'s editor assigns it.'
		)
		public Date date3;
		/** @description A date value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Date 4'
			description='A date value for a query condition. The action\'s editor assigns it.'
		)
		public Date date4;
		/** @description A date value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Date 5'
			description='A date value for a query condition. The action\'s editor assigns it.'
		)
		public Date date5;

		// * Date/Time *
		/** @description A date/time value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Date/Time 1'
			description='A date/time value for a query condition. The action\'s editor assigns it.'
		)
		public DateTime dateTime1;
		/** @description A date/time value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Date/Time 2'
			description='A date/time value for a query condition. The action\'s editor assigns it.'
		)
		public DateTime dateTime2;
		/** @description A date/time value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Date/Time 3'
			description='A date/time value for a query condition. The action\'s editor assigns it.'
		)
		public DateTime dateTime3;
		/** @description A date/time value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Date/Time 4'
			description='A date/time value for a query condition. The action\'s editor assigns it.'
		)
		public DateTime dateTime4;
		/** @description A date/time value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Date/Time 5'
			description='A date/time value for a query condition. The action\'s editor assigns it.'
		)
		public DateTime dateTime5;

		// * Time *
		/** @description A time value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Time 1'
			description='A time value for a query condition. The action\'s editor assigns it.'
		)
		public Time time1;
		/** @description A time value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Time 2'
			description='A time value for a query condition. The action\'s editor assigns it.'
		)
		public Time time2;
		/** @description A time value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Time 3'
			description='A time value for a query condition. The action\'s editor assigns it.'
		)
		public Time time3;
		/** @description A time value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Time 4'
			description='A time value for a query condition. The action\'s editor assigns it.'
		)
		public Time time4;
		/** @description A time value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Time 5'
			description='A time value for a query condition. The action\'s editor assigns it.'
		)
		public Time time5;

		// * Boolean *
		/** @description A boolean value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Boolean 1'
			description='A boolean value for a query condition. The action\'s editor assigns it.'
		)
		public Boolean boolean1;
		/** @description A boolean value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Boolean 2'
			description='A boolean value for a query condition. The action\'s editor assigns it.'
		)
		public Boolean boolean2;
		/** @description A boolean value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Boolean 3'
			description='A boolean value for a query condition. The action\'s editor assigns it.'
		)
		public Boolean boolean3;
		/** @description A boolean value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Boolean 4'
			description='A boolean value for a query condition. The action\'s editor assigns it.'
		)
		public Boolean boolean4;
		/** @description A boolean value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Boolean 5'
			description='A boolean value for a query condition. The action\'s editor assigns it.'
		)
		public Boolean boolean5;

		// * Text Collection *
		/** @description A collection of text values for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Text Collection 1'
			description='A collection of text values for a query condition. The action\'s editor assigns it.'
		)
		public List<String> textCollection1;
		/** @description A collection of text values for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Text Collection 2'
			description='A collection of text values for a query condition. The action\'s editor assigns it.'
		)
		public List<String> textCollection2;
		/** @description A collection of text values for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Text Collection 3'
			description='A collection of text values for a query condition. The action\'s editor assigns it.'
		)
		public List<String> textCollection3;
		/** @description A collection of text values for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Text Collection 4'
			description='A collection of text values for a query condition. The action\'s editor assigns it.'
		)
		public List<String> textCollection4;
		/** @description A collection of text values for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Text Collection 5'
			description='A collection of text values for a query condition. The action\'s editor assigns it.'
		)
		public List<String> textCollection5;

		// * Number Collection *
		/** @description A collection of number values for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Number Collection 1'
			description='A collection of number values for a query condition. The action\'s editor assigns it.'
		)
		public List<Decimal> numberCollection1;
		/** @description A collection of number values for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Number Collection 2'
			description='A collection of number values for a query condition. The action\'s editor assigns it.'
		)
		public List<Decimal> numberCollection2;
		/** @description A collection of number values for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Number Collection 3'
			description='A collection of number values for a query condition. The action\'s editor assigns it.'
		)
		public List<Decimal> numberCollection3;
		/** @description A collection of number values for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Number Collection 4'
			description='A collection of number values for a query condition. The action\'s editor assigns it.'
		)
		public List<Decimal> numberCollection4;
		/** @description A collection of number values for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Number Collection 5'
			description='A collection of number values for a query condition. The action\'s editor assigns it.'
		)
		public List<Decimal> numberCollection5;

		// * Date Collection *
		/** @description A collection of date values for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Date Collection 1'
			description='A collection of date values for a query condition. The action\'s editor assigns it.'
		)
		public List<Date> dateCollection1;
		/** @description A collection of date values for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Date Collection 2'
			description='A collection of date values for a query condition. The action\'s editor assigns it.'
		)
		public List<Date> dateCollection2;
		/** @description A collection of date values for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Date Collection 3'
			description='A collection of date values for a query condition. The action\'s editor assigns it.'
		)
		public List<Date> dateCollection3;
		/** @description A collection of date values for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Date Collection 4'
			description='A collection of date values for a query condition. The action\'s editor assigns it.'
		)
		public List<Date> dateCollection4;
		/** @description A collection of date values for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Date Collection 5'
			description='A collection of date values for a query condition. The action\'s editor assigns it.'
		)
		public List<Date> dateCollection5;

		// * Date/Time Collection *
		/** @description A collection of date/time values for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Date/Time Collection 1'
			description='A collection of date/time values for a query condition. The action\'s editor assigns it.'
		)
		public List<DateTime> dateTimeCollection1;
		/** @description A collection of date/time values for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Date/Time Collection 2'
			description='A collection of date/time values for a query condition. The action\'s editor assigns it.'
		)
		public List<DateTime> dateTimeCollection2;
		/** @description A collection of date/time values for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Date/Time Collection 3'
			description='A collection of date/time values for a query condition. The action\'s editor assigns it.'
		)
		public List<DateTime> dateTimeCollection3;
		/** @description A collection of date/time values for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Date/Time Collection 4'
			description='A collection of date/time values for a query condition. The action\'s editor assigns it.'
		)
		public List<DateTime> dateTimeCollection4;
		/** @description A collection of date/time values for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Date/Time Collection 5'
			description='A collection of date/time values for a query condition. The action\'s editor assigns it.'
		)
		public List<DateTime> dateTimeCollection5;

		// * Record Collection *
		/** @description A collection of records, matched by their IDs for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Record Collection 1'
			description='A collection of records, matched by their IDs for a query condition. The action\'s editor assigns it.'
		)
		public List<SObject> recordCollection1;
		/** @description A collection of records, matched by their IDs for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Record Collection 2'
			description='A collection of records, matched by their IDs for a query condition. The action\'s editor assigns it.'
		)
		public List<SObject> recordCollection2;
		/** @description A collection of records, matched by their IDs for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Record Collection 3'
			description='A collection of records, matched by their IDs for a query condition. The action\'s editor assigns it.'
		)
		public List<SObject> recordCollection3;
		/** @description A collection of records, matched by their IDs for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Record Collection 4'
			description='A collection of records, matched by their IDs for a query condition. The action\'s editor assigns it.'
		)
		public List<SObject> recordCollection4;
		/** @description A collection of records, matched by their IDs for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Record Collection 5'
			description='A collection of records, matched by their IDs for a query condition. The action\'s editor assigns it.'
		)
		public List<SObject> recordCollection5;

		/**
		 * @description Parsed by `DatabaseLayerUtils.AccessLevels.parse`, like the DML actions
		 * @return The matching System.AccessLevel
		 * @throws System.IllegalArgumentException When the value isn't blank, USER_MODE, or SYSTEM_MODE
		 */
		private System.AccessLevel getAccessLevel() {
			return DatabaseLayer.Utils.AccessLevels.parse(this.accessLevel);
		}

		/**
		 * @description Reads a slot by name, since Apex can't read a field by name
		 * @param name The slot's name, ex: "text1"
		 * @return The slot's value
		 * @throws System.IllegalArgumentException When no slot has that name
		 */
		private Object getSlotValue(String name) {
			this.slotValues = this.slotValues ?? this.initSlotValues();
			if (this.slotValues?.containsKey(name) == false) {
				throw new IllegalArgumentException('Invalid slot: ' + name);
			}
			return this.slotValues?.get(name);
		}

		/**
		 * @description Lists every slot by name
		 * @return Each slot's value, by name
		 */
		private Map<String, Object> initSlotValues() {
			return new Map<String, Object>{
				'text1' => this.text1,
				'text2' => this.text2,
				'text3' => this.text3,
				'text4' => this.text4,
				'text5' => this.text5,
				'number1' => this.number1,
				'number2' => this.number2,
				'number3' => this.number3,
				'number4' => this.number4,
				'number5' => this.number5,
				'date1' => this.date1,
				'date2' => this.date2,
				'date3' => this.date3,
				'date4' => this.date4,
				'date5' => this.date5,
				'dateTime1' => this.dateTime1,
				'dateTime2' => this.dateTime2,
				'dateTime3' => this.dateTime3,
				'dateTime4' => this.dateTime4,
				'dateTime5' => this.dateTime5,
				'time1' => this.time1,
				'time2' => this.time2,
				'time3' => this.time3,
				'time4' => this.time4,
				'time5' => this.time5,
				'boolean1' => this.boolean1,
				'boolean2' => this.boolean2,
				'boolean3' => this.boolean3,
				'boolean4' => this.boolean4,
				'boolean5' => this.boolean5,
				'textCollection1' => this.textCollection1,
				'textCollection2' => this.textCollection2,
				'textCollection3' => this.textCollection3,
				'textCollection4' => this.textCollection4,
				'textCollection5' => this.textCollection5,
				'numberCollection1' => this.numberCollection1,
				'numberCollection2' => this.numberCollection2,
				'numberCollection3' => this.numberCollection3,
				'numberCollection4' => this.numberCollection4,
				'numberCollection5' => this.numberCollection5,
				'dateCollection1' => this.dateCollection1,
				'dateCollection2' => this.dateCollection2,
				'dateCollection3' => this.dateCollection3,
				'dateCollection4' => this.dateCollection4,
				'dateCollection5' => this.dateCollection5,
				'dateTimeCollection1' => this.dateTimeCollection1,
				'dateTimeCollection2' => this.dateTimeCollection2,
				'dateTimeCollection3' => this.dateTimeCollection3,
				'dateTimeCollection4' => this.dateTimeCollection4,
				'dateTimeCollection5' => this.dateTimeCollection5,
				'recordCollection1' => this.recordCollection1,
				'recordCollection2' => this.recordCollection2,
				'recordCollection3' => this.recordCollection3,
				'recordCollection4' => this.recordCollection4,
				'recordCollection5' => this.recordCollection5
			};
		}
	}

	/** @description Single and collection variants of the results, so flows of either shape can use them directly **/
	public class Output {
		/** @description The query as it ran for this interview, since Flow's debug panel can't show binds **/
		@InvocableVariable(
			label='Query String'
			description='The query, with this interview\'s values filled in. For debugging only: the action binds values instead of running this text.'
		)
		public String queryString;

		/** @description Lets single-record flows use the record without a collection **/
		@InvocableVariable(label='Record' description='The first record found, or blank if none were found.')
		public SObject record;

		/** @description Empty, not null, when nothing matches, so flows can loop or count without a null check **/
		@InvocableVariable(label='Records' description='The records found, in query order.')
		public List<SObject> records;

		/** @description Invocable variable classes need an accessible no-arg constructor **/
		public Output() {
			this.records = new List<SObject>{};
		}

		/**
		 * @description Copies the records, so one interview's changes to the collection don't reach another's
		 * @param records The records found for this interview
		 * @param queryString This interview's query, with its values filled in
		 */
		public Output(List<SObject> records, String queryString) {
			this();
			this.queryString = queryString;
			this.records?.addAll(records);
			this.record = records?.isEmpty() == false ? records?.get(0) : null;
		}
	}

	/**
	 * @description A `SOQL: Get Record(s)` query, parsed from the JSON its editor writes. Builds the query, binding
	 * every value, and resolves each interview's values for it
	 */
	public class Query {
		/** @description Filters, combined by `conditionLogic` **/
		public List<InvocableSoql.Condition> conditions;
		/** @description Blank or AND (default) for all conditions, OR for any, or custom, ex: "1 AND (2 OR 3)" **/
		public String conditionLogic;
		/** @description Field API names to select, including parent fields, ex: "Account.Owner.Name"; Id is implied **/
		public List<String> fields;
		/** @description The object to query, ex: "Contact" **/
		public String objectApiName;
		/** @description ORDER BY fields, in order **/
		public List<InvocableSoql.SortOrder> orderBy;
		/** @description LIMIT, when set **/
		public Integer rowLimit;
		/** @description OFFSET, when set **/
		public Integer rowOffset;
		/** @description A `Soql.Usage` name, ex: ALL_ROWS or FOR_UPDATE; SOQL allows one at a time **/
		public String usage;

		/** @description Each condition's field, in order, for coercing values and splitting merged results **/
		private transient List<DescribeFieldResult> conditionFields;
		/** @description Each condition's field path, split once, since a merged query reads it from every row **/
		private transient List<List<String>> conditionPaths;
		/** @description The condition logic, parsed once, which a merged query checks for each variant **/
		private transient InvocableSoql.LogicNode logicTree;
		private transient DescribeSObjectResult objectDescribe;
		/** @description Expanded SELECT clauses by access level, since user mode omits fields the user can't read **/
		private transient Map<System.AccessLevel, Set<String>> selectClausesByAccessLevel;

		/**
		 * @description Coerces a value to its condition field's type, since SOQL binds are strictly typed
		 * @param index The condition's index
		 * @param value A value, or a collection of values
		 * @return The value as the field's type; a collection becomes a list of that type
		 */
		private Object coerce(Integer index, Object value) {
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
		private Object getFieldValue(SObject record, Integer index) {
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
		private Boolean isCaseSensitive(Integer index) {
			return this.conditionFields?.get(index)?.isCaseSensitive() == true;
		}

		/**
		 * @description Whether Apex can check the condition on a row as SOQL would. Date literals, Includes, and
		 * Excludes can't be, nor can multi-select picklists, which compare sets of values; currencies in an org with
		 * several, which SOQL converts; or text ranges, which follow SOQL's sort order
		 * @param index The condition's index
		 * @return Whether a merged query's split can check the condition
		 */
		private Boolean isCheckable(Integer index) {
			InvocableSoql.Condition condition = this.conditions?.get(index);
			String operator = condition?.operator;
			Boolean isNullCheck = operator == InvocableSoql.NULL_CHECK;
			Boolean hasValue = condition?.isBound() == true || isNullCheck;
			Schema.DisplayType fieldType = this.conditionFields?.get(index)?.getType();
			Boolean isMultiPicklist = fieldType == Schema.DisplayType.MULTIPICKLIST;
			Boolean isConvertedCurrency =
				fieldType == Schema.DisplayType.CURRENCY && UserInfo.isMultiCurrencyOrganization();
			Type valueType = this.getValueType(index);
			Boolean isRange =
				InvocableSoql.RANGE_OPERATORS?.contains(operator) && InvocableSoql.ORDERED_TYPES?.contains(valueType);
			Boolean isKnown =
				InvocableSoql.KEY_OPERATORS?.contains(operator) ||
				this.isPattern(index) ||
				isNullCheck ||
				isRange;
			return hasValue && isKnown && isMultiPicklist == false && isConvertedCurrency == false;
		}

		/**
		 * @description Whether Apex can check a variant's value for the condition: not a LIKE pattern with wildcards in
		 * its middle, which only SOQL can match. SOQL treats a blank range bound as true, and a blank pattern as Is
		 * Null, but both as false under NOT. A varying condition is never under NOT, so only its blanks are checkable
		 * @param index The condition's index
		 * @param value A variant's value for it
		 * @param isVarying Whether the condition's values differ between variants
		 * @return Whether a merged query's split can check the value
		 */
		private Boolean isCheckableValue(Integer index, Object value, Boolean isVarying) {
			String operator = this.getOperator(index);
			Boolean isRange = InvocableSoql.RANGE_OPERATORS?.contains(operator);
			Boolean isPattern = this.isPattern(index);
			String pattern = isPattern ? (String) value : null;
			Boolean isBlank = isPattern ? String.isEmpty(pattern) : value == null;
			Boolean isSimple = isPattern == false || new InvocableSoql.LikePattern(pattern, false)?.isSimple == true;
			Boolean hasBlankBound = isBlank && (isRange || isPattern);
			return hasBlankBound ? isVarying : isSimple;
		}

		/**
		 * @description Contains, Starts With, Ends With, and Like bind a LIKE pattern; the rest bind values
		 * @param index The condition's index
		 * @return Whether the condition's value is a LIKE pattern
		 */
		private Boolean isPattern(Integer index) {
			String operator = this.getOperator(index);
			return InvocableSoql.TOKENS?.get(operator) == 'LIKE';
		}

		/**
		 * @description Resolves an interview's value for each condition, from its slot or the definition
		 * @param input The interview's input
		 * @return One value per condition, in condition order: Is Null's true or false, else null for conditions that
		 * don't bind one
		 */
		@TestVisible
		private List<Object> resolveValues(InvocableSoql.Input input) {
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
		@TestVisible
		private Soql toSoql(List<Object> values, System.AccessLevel accessLevel) {
			InvocableSoql.Filter whereClause = new InvocableSoql.Filter(this, values, false);
			Map<String, Object> binds = this.initBinds(values);
			return (Soql) this.initSoql(whereClause, accessLevel)?.addBind(binds);
		}

		/**
		 * @description Builds a merged query: without LIMIT and OFFSET, which `page` applies to each interview's rows,
		 * and without the conditions the split applies alone
		 * @param values One value per condition, each varying one widened to cover every interview's values
		 * @param omitted The indexes of the conditions the split applies
		 * @param accessLevel The access level to query in
		 * @return The query, ready to run
		 */
		private Soql toMergedSoql(List<Object> values, Set<Integer> omitted, System.AccessLevel accessLevel) {
			InvocableSoql.Filter whereClause = new InvocableSoql.Filter(this, values, false);
			whereClause.omitted = omitted;
			Map<String, Object> binds = this.initBinds(values);
			for (Integer index : omitted) {
				binds?.remove(InvocableSoql.BIND_PREFIX + index);
			}
			Soql builder = this.initSoql(whereClause, accessLevel);
			return (Soql) builder?.setRowLimit(null)?.setRowOffset(null)?.addBind(binds);
		}

		/**
		 * @description Applies OFFSET and LIMIT to one interview's rows from a merged query, which keeps query order
		 * @param rows The interview's rows
		 * @return The rows OFFSET and LIMIT keep
		 */
		private List<SObject> page(List<SObject> rows) {
			Integer first = this.rowOffset ?? 0;
			Integer size = rows?.size();
			Integer last = Math.min(size, first + (this.rowLimit ?? size));
			List<SObject> kept = new List<SObject>{};
			for (Integer position = first; position < last; position++) {
				SObject row = rows?.get(position);
				kept?.add(row);
			}
			return kept;
		}

		/**
		 * @description Renders the query with values in place of binds, for Flow's debug panel
		 * @param values One value per condition, from `resolveValues`
		 * @param accessLevel The access level to query in, which decides the fields that all-field selections include
		 * @return The query, with values filled in
		 */
		@TestVisible
		private String toQueryString(List<Object> values, System.AccessLevel accessLevel) {
			InvocableSoql.Filter whereClause = new InvocableSoql.Filter(this, values, true);
			return this.initSoql(whereClause, accessLevel)?.toString();
		}

		/**
		 * @description Adds each ORDER BY field
		 * @param builder The query being built
		 */
		private void addOrderBy(Soql builder) {
			for (InvocableSoql.SortOrder sortOrder : this.orderBy ?? new List<InvocableSoql.SortOrder>{}) {
				Soql.SortOrder order = sortOrder?.toSortOrder();
				builder?.addOrderBy(order);
			}
		}

		/**
		 * @description Adds the SELECT clauses, expanded once per access level, since a batch builds a query and a
		 * query string for each variant, and each all-field selection describes every field of its object
		 * @param builder The query being built
		 */
		private void addSelect(Soql builder) {
			System.AccessLevel accessLevel = builder?.accessLevel;
			Set<String> cached = this.selectClausesByAccessLevel?.get(accessLevel);
			if (cached == null) {
				this.addFields(builder);
				Set<String> clauses = builder?.selectClauses?.clone();
				this.selectClausesByAccessLevel?.put(accessLevel, clauses);
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
			for (InvocableSoql.Condition condition : this.conditions) {
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
			Boolean isAllFields = fieldName?.endsWith(InvocableSoql.ALL_FIELDS) == true;
			String relationshipPath = isAllFields ? this.toRelationshipPath(fieldName) : null;
			if (isAllFields == false) {
				builder?.addSelect(fieldName);
			} else if (String.isBlank(relationshipPath)) {
				builder?.selectAll();
			} else {
				builder?.selectAll(relationshipPath);
			}
		}

		/**
		 * @description Adds the WHERE clause, unless there are no conditions, since a blank one would leave a dangling
		 * AND before any condition a SOQL plugin adds
		 * @param builder The query being built
		 * @param whereClause The WHERE clause, with binds or values
		 */
		private void addWhere(Soql builder, InvocableSoql.Filter whereClause) {
			if (this.conditions?.isEmpty() == false) {
				builder?.addWhere(whereClause);
			}
		}

		/**
		 * @description Coerces each value in a collection, since a list can't be converted to another element type.
		 * Values a typed list takes as they are skip `coerceValue`, which costs about 100 times as much per value
		 * @param values The values
		 * @param valueType The field's Apex type
		 * @return A list of the field's type
		 */
		private List<Object> coerceList(Iterable<Object> values, Type valueType) {
			List<Object> coerced = InvocableSoql.initList(valueType);
			Boolean isNative = InvocableSoql.isNativeList(values, valueType);
			for (Object value : values) {
				Object element = isNative ? value : this.coerceValue(value, valueType);
				coerced?.add(element);
			}
			return coerced;
		}

		/**
		 * @description JSON converts flow values and the editor's text alike; Id.valueOf also lengthens 15-character
		 * IDs, so they match the 18-character IDs that queries return. A blank stays null, since JSON can't read null
		 * as a date, date/time, or time
		 * @param value A single value
		 * @param valueType The field's Apex type
		 * @return The value as the field's type
		 */
		private Object coerceValue(Object value, Type valueType) {
			Object coerced;
			if (value != null) {
				InvocableSoql.checkWholeNumber(value, valueType);
				Boolean isId = valueType == Id.class;
				// JSON reads a zoneless time, ex: "10:30", in the user's time zone; Time fields hold the time as typed
				Boolean isLocalTime =
					value instanceof String &&
					valueType == Time.class &&
					((String) value).endsWith('Z') == false;
				Object zoned = isLocalTime ? value + 'Z' : value;
				String text = String.valueOf(value);
				String serialized = isId ? null : JSON.serialize(zoned);
				coerced = isId ? Id.valueOf(text) : JSON.deserialize(serialized, valueType);
			}
			return coerced;
		}

		/**
		 * @description Describes the object and each condition's field once, checking every name and operator
		 * @return This query
		 * @throws System.IllegalArgumentException When the definition names an unknown field or operator
		 */
		private InvocableSoql.Query describe() {
			this.conditions = this.conditions ?? new List<InvocableSoql.Condition>{};
			this.objectDescribe = this.describeObject();
			this.selectClausesByAccessLevel = new Map<System.AccessLevel, Set<String>>{};
			this.conditionFields = new List<DescribeFieldResult>{};
			this.conditionPaths = new List<List<String>>{};
			for (InvocableSoql.Condition condition : this.conditions) {
				condition?.validate();
				DescribeFieldResult field = this.describeField(condition?.field);
				this.conditionFields?.add(field);
				List<String> path = condition?.field?.split('\\.');
				this.conditionPaths?.add(path);
			}
			this.describeOtherFields();
			this.validatePaging();
			// Renders the WHERE clause once, so bad condition logic fails before any query runs
			List<Object> blankValues = new List<Object>(this.conditions?.size());
			InvocableSoql.Filter blankFilter = new InvocableSoql.Filter(this, blankValues, true);
			blankFilter?.toString();
			String logic = blankFilter?.getLogic();
			this.logicTree = new InvocableSoql.LogicParser(logic)?.parse();
			return this;
		}

		/**
		 * @description Checks the selected and sorted fields, like the condition fields, since each becomes SOQL text
		 * @throws System.IllegalArgumentException When a field doesn't exist
		 */
		private void describeOtherFields() {
			List<String> paths = new List<String>(this.fields ?? new List<String>{});
			for (InvocableSoql.SortOrder sortOrder : this.orderBy ?? new List<InvocableSoql.SortOrder>{}) {
				paths?.add(sortOrder?.field);
			}
			for (String path : paths) {
				this.describePath(path);
			}
		}

		/**
		 * @description Checks LIMIT and OFFSET as SOQL would, since a merged query leaves them out, so SOQL never sees
		 * them and the same definition would fail alone but run merged
		 * @throws System.IllegalArgumentException When the limit is negative, the offset is outside 0 to 2,000, or FOR
		 * UPDATE has an offset
		 */
		private void validatePaging() {
			Integer offset = this.rowOffset ?? 0;
			if ((this.rowLimit ?? 0) < 0) {
				throw new IllegalArgumentException('Invalid limit: ' + this.rowLimit);
			}
			if (offset < 0 || offset > InvocableSoql.MAX_OFFSET) {
				throw new IllegalArgumentException('Invalid offset, outside 0 to 2,000: ' + this.rowOffset);
			}
			if (this.usage == 'FOR_UPDATE' && this.rowOffset != null) {
				throw new IllegalArgumentException('FOR UPDATE cannot be used with an offset');
			}
		}

		/**
		 * @description Checks a selected or sorted path: its lookups for a path ending in `*`, or else its field
		 * @param path A field path, ex: "Account.Name" or "Account.*"
		 * @throws System.IllegalArgumentException When a relationship or field doesn't exist
		 */
		private void describePath(String path) {
			if (path?.endsWith(InvocableSoql.ALL_FIELDS) == true) {
				String relationshipPath = this.toRelationshipPath(path);
				DatabaseLayer.Utils.Schema.findLookups(this.objectDescribe, relationshipPath);
			} else {
				this.describeField(path);
			}
		}

		/**
		 * @description Strips the `*` from a path, ex: "Account.Owner" for "Account.Owner.*"
		 * @param path A path ending in `*`
		 * @return The relationships to the path's object; blank for the queried object itself
		 */
		private String toRelationshipPath(String path) {
			return path?.removeEnd(InvocableSoql.ALL_FIELDS)?.removeEnd('.');
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
			String relationshipPath = String.join(names, '.');
			DescribeSObjectResult parent = this.describePathObject(relationshipPath);
			SObjectField field = parent?.fields?.getMap()?.get(fieldName);
			if (field == null) {
				throw new IllegalArgumentException('Invalid field for ' + this.objectApiName + ': ' + path);
			}
			return field?.getDescribe();
		}

		/**
		 * @description Describes the object at the end of a relationship path
		 * @param relationshipPath Relationship names joined by dots
		 * @return The object's describe; the queried object's for a blank path
		 * @throws System.IllegalArgumentException When a relationship doesn't exist
		 */
		private DescribeSObjectResult describePathObject(String relationshipPath) {
			List<SObjectField> lookups = DatabaseLayer.Utils.Schema.findLookups(this.objectDescribe, relationshipPath);
			Integer lastIndex = lookups?.size() - 1;
			SObjectField lookup = (lastIndex >= 0) ? lookups?.get(lastIndex) : null;
			return (lookup != null) ? DatabaseLayer.Utils.Schema.describeParent(lookup) : this.objectDescribe;
		}

		/**
		 * @description Validated by `DatabaseLayerUtils.Schema.describeObject`, which throws for an unknown object
		 * @return The object's describe
		 * @throws System.IllegalArgumentException When the object is blank
		 */
		private DescribeSObjectResult describeObject() {
			if (String.isBlank(this.objectApiName)) {
				throw new IllegalArgumentException('Missing object');
			}
			return DatabaseLayer.Utils.Schema.describeObject(this.objectApiName);
		}

		/**
		 * @description Contains, Starts With, and Ends With match their text literally, so `%` and `_` in it are
		 * escaped before the wildcards are added
		 * @param index The condition's index
		 * @param value The coerced value
		 * @return The LIKE pattern, or the value for other operators
		 */
		private Object addWildcards(Integer index, Object value) {
			String operator = this.getOperator(index);
			Boolean isLeading = operator == 'CONTAINS' || operator == 'ENDS_WITH';
			Boolean isTrailing = operator == 'CONTAINS' || operator == 'STARTS_WITH';
			Boolean isPattern = (isLeading || isTrailing) && value instanceof String;
			String text = isPattern
				? ((String) value).replace('\\', '\\\\').replace('%', '\\%').replace('_', '\\_')
				: null;
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
			String operator = this.getOperator(index);
			Boolean isCollection = InvocableSoql.COLLECTION_OPERATORS?.contains(operator);
			Object collection = (value == null && isCollection) ? new List<Object>{} : value;
			Object recordIds = (collection instanceof List<SObject>)
				? this.getRecordIds((List<SObject>) collection)
				: null;
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
			// After putAll from a typed list, ex: List<Account>, containsKey(null) misses null; keySet() finds it
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
			return InvocableSoql.VALUE_TYPES?.get(fieldType) ?? String.class;
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
					binds?.put(InvocableSoql.BIND_PREFIX + index, value);
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
		private Soql initSoql(InvocableSoql.Filter whereClause, System.AccessLevel accessLevel) {
			SObjectType objectType = this.objectDescribe?.getSObjectType();
			Soql builder = (Soql) DatabaseLayer.Soql?.newQuery(objectType)?.setAccessLevel(accessLevel);
			this.addSelect(builder);
			this.addWhere(builder, whereClause);
			this.addOrderBy(builder);
			Soql.Usage usageType = String.isBlank(this.usage) ? null : Soql.Usage.valueOf(this.usage);
			return (Soql) builder?.setRowLimit(this.rowLimit)?.setRowOffset(this.rowOffset)?.setUsage(usageType);
		}

		/**
		 * @description Conditions take their value from a slot, or else from the definition
		 * @param index The condition's index
		 * @param input The interview's input
		 * @return The value, ready to bind; Is Null's true or false; or null when the condition takes no value
		 */
		private Object resolveValue(Integer index, InvocableSoql.Input input) {
			InvocableSoql.Condition condition = this.conditions?.get(index);
			Boolean isBound = condition?.isBound() == true;
			Boolean isNullCheck = condition?.operator == InvocableSoql.NULL_CHECK;
			Boolean hasSlot = (isBound || isNullCheck) && condition?.slot != null;
			Object value = hasSlot ? input?.getSlotValue(condition?.slot) : condition?.getStaticValue();
			Object boundValue = isBound ? this.prepareValue(index, value) : null;
			// Anything but false checks for null, including no value
			return isNullCheck ? this.coerceValue(value, Boolean.class) != false : boundValue;
		}
	}

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
		private Boolean isBound() {
			Boolean isLiteral =
				InvocableSoql.LITERAL_OPERATORS?.contains(this.operator) == true ||
				this.operator == InvocableSoql.NULL_CHECK;
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
			if (this.operator == InvocableSoql.NULL_CHECK) {
				operand = 'null';
			} else if (String.isNotBlank(this.dateLiteral)) {
				operand = this.dateLiteral;
			} else if (InvocableSoql.LITERAL_OPERATORS?.contains(this.operator) == true) {
				operand = InvocableSoql.formatLiteral(this.values);
			} else if (isLiteral == false) {
				operand = ':' + InvocableSoql.BIND_PREFIX + index;
			} else if (InvocableSoql.TOKENS?.get(this.operator) == 'LIKE') {
				operand = InvocableSoql.formatPattern(value);
			} else {
				operand = InvocableSoql.formatLiteral(value);
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
			Boolean isNotNull = this.operator == InvocableSoql.NULL_CHECK && value == false;
			String tokenKey = isNotNull ? 'NOT_EQUALS' : this.operator;
			String token = InvocableSoql.TOKENS?.get(tokenKey);
			String operand = this.renderOperand(index, value, isLiteral);
			return this.field + ' ' + token + ' ' + operand;
		}

		/**
		 * @description Checks the parts that become SOQL text: the operator and any date literal
		 * @throws System.IllegalArgumentException When the operator is unknown, or the date literal is malformed
		 */
		private void validate() {
			if (InvocableSoql.TOKENS?.containsKey(this.operator) == false) {
				throw new IllegalArgumentException('Invalid operator: ' + this.operator);
			}
			if (this.dateLiteral != null && DatabaseLayer.Utils.isDateLiteral(this.dateLiteral) == false) {
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
		/** @description Conditions a merged query leaves out, by index, for the split to apply **/
		private Set<Integer> omitted = new Set<Integer>{};
		private InvocableSoql.Query query;
		private List<Object> values;

		/**
		 * @description Holds what rendering needs
		 * @param query The query
		 * @param values One value per condition
		 * @param isLiteral Whether to render values in place of binds
		 */
		private Filter(InvocableSoql.Query query, List<Object> values, Boolean isLiteral) {
			this.isLiteral = isLiteral;
			this.query = query;
			this.values = values;
		}

		/**
		 * @description Renders the logic token by token, replacing each condition number with its condition. SOQL only
		 * allows NOT at the start of a group, ex: `A AND (NOT B)`, so each NOT and its operand are wrapped in
		 * parentheses. Logic with OR outside parentheses is wrapped in its own, so a condition that a SOQL plugin adds
		 * with AND applies to all of it
		 * @return The WHERE clause's criteria
		 */
		public override String toString() {
			String output = '';
			Integer depth = 0;
			// The depth of each NOT still waiting for its operand to end
			List<Integer> openNots = new List<Integer>{};
			String logic = this.getLogic();
			Matcher tokens = InvocableSoql.TOKEN_PATTERN.matcher(logic);
			while (tokens?.find() == true) {
				String token = tokens?.group()?.toUpperCase();
				depth += (token == '(') ? 1 : 0;
				depth -= (token == ')') ? 1 : 0;
				String rendered = this.renderToken(token);
				output = InvocableSoql.appendToken(output, rendered);
				Boolean isOperandEnd = token == ')' || token?.isNumeric() == true;
				output = isOperandEnd ? this.closeNots(output, openNots, depth) : output;
				if (token == 'NOT') {
					openNots?.add(depth);
				}
			}
			Boolean isGrouped = InvocableSoql.hasTopLevelOr(logic);
			return isGrouped ? '(' + output + ')' : output;
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
				closed = InvocableSoql.appendToken(closed, ')');
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
				InvocableSoql.CUSTOM_LOGIC_PATTERN.matcher(logic).matches() && InvocableSoql.isWellFormed(logic);
			if (isPreset == false && isValidCustom == false) {
				throw new IllegalArgumentException('Invalid condition logic: ' + this.query?.conditionLogic);
			}
			return isPreset ? String.join(numbers, ' ' + logic + ' ') : logic;
		}

		/**
		 * @description Renders a condition by its number in the logic. A left-out condition renders as one every row
		 * passes, which keeps the logic around it, ex: under OR
		 * @param conditionNumber The condition's number, starting at 1
		 * @return The condition, as SOQL
		 * @throws System.IllegalArgumentException When no condition has that number
		 */
		private String renderCondition(String conditionNumber) {
			Integer index = Integer.valueOf(conditionNumber) - 1;
			if (index < 0 || index >= this.query?.conditions?.size()) {
				throw new IllegalArgumentException('Invalid condition logic: ' + this.query?.conditionLogic);
			}
			Boolean isOmitted = this.omitted?.contains(index) == true;
			Object value = this.values?.get(index);
			return isOmitted ? 'Id != null' : this.query?.conditions?.get(index)?.render(index, value, this.isLiteral);
		}
	}

	/**
	 * @description Runs a batch of `SOQL: Get Record(s)` interviews in as few queries as it can, since Flow sends every
	 * interview at the element in one call. Interviews with the same query, access level, and values share one query.
	 * The rest share one merged query, whose rows Apex checks against each interview's conditions, like Get Records;
	 * see `InvocableSoql.Splitter` for when merging applies
	 */
	private class Planner {
		/** @description Interviews that share a query definition and access level, by both **/
		private Map<String, InvocableSoql.Batch> batches = new Map<String, InvocableSoql.Batch>{};

		/**
		 * @description Groups the interviews, runs each group's queries, then gives each interview its rows
		 * @param inputs One input per flow interview
		 * @return One output per input, in the same order
		 */
		private List<InvocableSoql.Output> run(List<InvocableSoql.Input> inputs) {
			List<InvocableSoql.Variant> variants = this.addInputs(inputs);
			for (InvocableSoql.Batch batch : this.batches?.values()) {
				batch?.run();
			}
			return this.initOutputs(variants);
		}

		/**
		 * @description Adds each interview to its batch
		 * @param inputs One input per flow interview
		 * @return Each interview's variant, in input order
		 */
		private List<InvocableSoql.Variant> addInputs(List<InvocableSoql.Input> inputs) {
			List<InvocableSoql.Variant> variants = new List<InvocableSoql.Variant>{};
			for (InvocableSoql.Input input : inputs) {
				InvocableSoql.Variant variant = this.addInput(input);
				variants?.add(variant);
			}
			return variants;
		}

		/**
		 * @description Gives each interview its variant's rows and query string
		 * @param variants Each interview's variant, in input order
		 * @return One output per interview, in the same order
		 */
		private List<InvocableSoql.Output> initOutputs(List<InvocableSoql.Variant> variants) {
			List<InvocableSoql.Output> outputs = new List<InvocableSoql.Output>{};
			for (InvocableSoql.Variant variant : variants) {
				InvocableSoql.Output output = new InvocableSoql.Output(variant?.records, variant?.queryString);
				outputs?.add(output);
			}
			return outputs;
		}

		/**
		 * @description Adds an interview to the batch for its query and access level
		 * @param input The interview's input
		 * @return The interview's distinct set of values, which receives its rows
		 */
		private InvocableSoql.Variant addInput(InvocableSoql.Input input) {
			System.AccessLevel accessLevel = input?.getAccessLevel();
			String levelName = DatabaseLayer.Utils.AccessLevels.getName(accessLevel);
			String key = levelName + ':' + input?.queryDefinition;
			InvocableSoql.Batch batch = this.batches?.get(key) ?? new InvocableSoql.Batch(input, accessLevel);
			this.batches?.put(key, batch);
			return batch?.addInput(input);
		}
	}

	/** @description Interviews with the same query and access level, which can share queries **/
	private class Batch {
		private System.AccessLevel accessLevel;
		private InvocableSoql.Query query;
		/** @description Each distinct set of values, by its JSON **/
		private Map<String, InvocableSoql.Variant> variants = new Map<String, InvocableSoql.Variant>{};

		/**
		 * @description Parses the query once for every interview that shares it
		 * @param input The first interview's input
		 * @param accessLevel The interviews' access level
		 */
		private Batch(InvocableSoql.Input input, System.AccessLevel accessLevel) {
			this.accessLevel = accessLevel;
			this.query = InvocableSoql.parseQuery(input?.queryDefinition);
		}

		/**
		 * @description Interviews with the same values share a variant, and so a query
		 * @param input The interview's input
		 * @return The interview's variant
		 */
		private InvocableSoql.Variant addInput(InvocableSoql.Input input) {
			List<Object> values = this.query?.resolveValues(input);
			InvocableSoql.Variant candidate = new InvocableSoql.Variant(values);
			String key = String.join(candidate?.valueKeys, '\n');
			InvocableSoql.Variant variant = this.variants?.get(key) ?? candidate;
			this.variants?.put(key, variant);
			return variant;
		}

		/**
		 * @description Merges what it can into one query, runs the remaining variants one query each, then renders each
		 * variant's query string once for all its interviews
		 */
		private void run() {
			List<InvocableSoql.Variant> candidates = this.variants?.values();
			InvocableSoql.Splitter splitter = (candidates?.size() > 1)
				? new InvocableSoql.Splitter(this.query, candidates)
				: null;
			if (splitter?.variants?.size() > 1) {
				this.runMerged(splitter);
			}
			for (InvocableSoql.Variant variant : candidates) {
				if (variant?.records == null) {
					Soql builder = this.query?.toSoql(variant?.values, this.accessLevel);
					variant.records = this.runQuery(builder);
				}
				variant.queryString = this.query?.toQueryString(variant?.values, this.accessLevel);
			}
		}

		/**
		 * @description Runs one query for the splitter's variants, then splits its rows between them
		 * @param splitter The variants to merge, and how
		 */
		private void runMerged(InvocableSoql.Splitter splitter) {
			List<Object> values = splitter?.getMergedValues();
			Integer rowLimit = splitter?.getMergedLimit();
			Soql merged = this.query?.toMergedSoql(values, splitter?.droppedIndexes, this.accessLevel);
			merged?.setRowLimit(rowLimit);
			List<SObject> rows = this.runQuery(merged);
			splitter?.split(rows);
		}

		/**
		 * @description Runs SYSTEM_MODE queries without sharing, like Get Records in a flow that runs in system
		 * context. `Soql` inherits sharing from its caller, and Flow calls the action with none, so it would run with
		 * sharing. USER_MODE enforces sharing itself
		 * @param builder The query
		 * @return The rows
		 */
		private List<SObject> runQuery(Soql builder) {
			Boolean isSystemMode = this.accessLevel == System.AccessLevel.SYSTEM_MODE;
			return isSystemMode ? new InvocableSoql.SystemModeRunner().run(builder) : builder?.query();
		}
	}

	/**
	 * @description A simple LIKE pattern: text with an optional `%` at either end, ex: `abc%`. Escaped wildcards, ex:
	 * `\%`, are literal text. Any other wildcard makes the pattern complex, which only SOQL can match
	 */
	@TestVisible
	private class LikePattern {
		private Boolean isLeading;
		private Boolean isSimple;
		private Boolean isTrailing;
		/** @description The literal text, as a key, so each row is only compared, not normalized again **/
		private String key;

		/**
		 * @description Parses the pattern
		 * @param pattern The pattern, as bound
		 * @param isCaseSensitive Whether the field compares text case-sensitively
		 */
		@TestVisible
		private LikePattern(String pattern, Boolean isCaseSensitive) {
			this.parse(pattern, isCaseSensitive);
		}

		/**
		 * @description Matches like SOQL would: a blank pattern, as `LIKE null` or `LIKE ''`, matches blank values
		 * @param candidate A field value's key, from `InvocableSoql.toKey`
		 * @return Whether the value matches
		 */
		@TestVisible
		private Boolean matches(String candidate) {
			Boolean isMatch;
			if (this.isLeading && this.isTrailing) {
				isMatch = candidate?.contains(this.key);
			} else if (this.isLeading) {
				isMatch = candidate?.endsWith(this.key);
			} else if (this.isTrailing) {
				isMatch = candidate?.startsWith(this.key);
			} else {
				isMatch = (candidate ?? '').equals(this.key);
			}
			return isMatch == true;
		}

		/**
		 * @description Reads the pattern's wildcards and literal text
		 * @param pattern The pattern, as bound
		 * @param isCaseSensitive Whether the field compares text case-sensitively
		 */
		private void parse(String pattern, Boolean isCaseSensitive) {
			this.isLeading = pattern?.startsWith('%') == true;
			String rest = this.isLeading ? pattern?.substring(1) : pattern;
			// Escaped backslashes go first, so `\\%` ends in a wildcard, and `\%` in a literal %
			String withoutEscapedBackslashes = rest?.replace('\\\\', '');
			this.isTrailing =
				withoutEscapedBackslashes?.endsWith('%') == true &&
				withoutEscapedBackslashes?.endsWith('\\%') == false;
			String body = this.isTrailing ? rest?.removeEnd('%') : rest;
			String unescaped = body?.replace('\\\\', '')?.replace('\\%', '')?.replace('\\_', '');
			this.isSimple = unescaped?.containsAny('%_\\') == false;
			String text = this.unescape(body);
			this.key = InvocableSoql.toKey(text, isCaseSensitive) ?? '';
		}

		/**
		 * @description Resolves escapes, ex: `\%` to `%`. Escaped backslashes are split out first, so `\\%` isn't read
		 * as an escaped wildcard
		 * @param body The pattern, without its leading and trailing wildcards
		 * @return The literal text
		 */
		private String unescape(String body) {
			List<String> pieces = new List<String>{};
			for (String piece : body?.split('\\\\\\\\', -1) ?? new List<String>{}) {
				String literal = piece?.replace('\\%', '%')?.replace('\\_', '_');
				pieces?.add(literal);
			}
			return String.join(pieces, '\\');
		}
	}

	/**
	 * @description Finds the simple LIKE patterns a value matches by looking up its prefixes, suffixes, and
	 * substrings, one per pattern length, instead of testing every pattern: 200 Contains values over 5,000 rows were
	 * a million tests, over the CPU limit
	 */
	@TestVisible
	private class LikePatternIndex {
		/** @description Patterns without wildcards, ex: `abc`, by key **/
		private Map<String, Set<Integer>> exact = new Map<String, Set<Integer>>{};
		/** @description Patterns like `abc%`, by key, by key length **/
		private Map<Integer, Map<String, Set<Integer>>> prefixes = new Map<Integer, Map<String, Set<Integer>>>{};
		/** @description Patterns like `%abc%`, by key, by key length **/
		private Map<Integer, Map<String, Set<Integer>>> substrings = new Map<Integer, Map<String, Set<Integer>>>{};
		/** @description Each distinct `%abc%` key, to test a long value against when that's less work than lookups **/
		private List<String> substringKeys = new List<String>{};
		/** @description Patterns like `%abc`, by key, by key length **/
		private Map<Integer, Map<String, Set<Integer>>> suffixes = new Map<Integer, Map<String, Set<Integer>>>{};

		/**
		 * @description Adds a pattern
		 * @param pattern A simple pattern
		 * @param position The position its matches report
		 */
		@TestVisible
		private void add(InvocableSoql.LikePattern pattern, Integer position) {
			Map<String, Set<Integer>> keyed = this.findKeyed(pattern);
			Set<Integer> positions = keyed?.get(pattern?.key);
			Boolean isNewSubstring = positions == null && pattern?.isLeading && pattern?.isTrailing;
			if (isNewSubstring) {
				this.substringKeys?.add(pattern?.key);
			}
			positions = positions ?? new Set<Integer>{};
			positions?.add(position);
			keyed?.put(pattern?.key, positions);
		}

		/**
		 * @description Lists the patterns a value matches. A prefix or suffix longer than the value is the whole
		 * value, which can't equal a key of that length, so it needs no length check
		 * @param key A field value's key, from `InvocableSoql.toKey`
		 * @return The matching patterns' positions; only blank patterns for a null key, as SOQL matches `LIKE null`
		 */
		@TestVisible
		private Set<Integer> match(String key) {
			Set<Integer> positions = new Set<Integer>{};
			this.addMatches(positions, this.exact, key ?? '');
			if (key != null) {
				for (Integer length : this.prefixes?.keySet()) {
					Map<String, Set<Integer>> keyed = this.prefixes?.get(length);
					String prefix = key?.left(length);
					this.addMatches(positions, keyed, prefix);
				}
				for (Integer length : this.suffixes?.keySet()) {
					Map<String, Set<Integer>> keyed = this.suffixes?.get(length);
					String suffix = key?.right(length);
					this.addMatches(positions, keyed, suffix);
				}
				this.matchSubstrings(positions, key);
			}
			return positions;
		}

		/**
		 * @description Picks the map a pattern belongs in, by its wildcards and key length
		 * @param pattern A simple pattern
		 * @return The map of its kind and length
		 */
		private Map<String, Set<Integer>> findKeyed(InvocableSoql.LikePattern pattern) {
			Map<Integer, Map<String, Set<Integer>>> byLength;
			if (pattern?.isLeading && pattern?.isTrailing) {
				byLength = this.substrings;
			} else if (pattern?.isLeading) {
				byLength = this.suffixes;
			} else if (pattern?.isTrailing) {
				byLength = this.prefixes;
			}
			Integer length = pattern?.key?.length();
			Map<String, Set<Integer>> keyed = byLength?.get(length) ?? new Map<String, Set<Integer>>{};
			byLength?.put(length, keyed);
			return (byLength == null) ? this.exact : keyed;
		}

		/**
		 * @description Looks up each of the value's substrings of each pattern length, unless that's more work than
		 * testing each pattern, ex: a long value against a few patterns
		 * @param positions The matches so far, which receive these
		 * @param key A field value's key
		 */
		private void matchSubstrings(Set<Integer> positions, String key) {
			Integer keyLength = key?.length();
			Integer lookups = 0;
			for (Integer length : this.substrings?.keySet()) {
				lookups += Math.max(keyLength - length + 1, 0);
			}
			if (lookups <= this.substringKeys?.size()) {
				this.lookUpSubstrings(positions, key);
			} else {
				this.testSubstrings(positions, key);
			}
		}

		/**
		 * @description Looks up each of the value's substrings of each pattern length
		 * @param positions The matches so far, which receive these
		 * @param key A field value's key
		 */
		private void lookUpSubstrings(Set<Integer> positions, String key) {
			for (Integer length : this.substrings?.keySet()) {
				Map<String, Set<Integer>> keyed = this.substrings?.get(length);
				for (Integer start = 0; start + length <= key?.length(); start++) {
					String substring = key?.substring(start, start + length);
					this.addMatches(positions, keyed, substring);
				}
			}
		}

		/**
		 * @description Tests the value against each `%abc%` pattern
		 * @param positions The matches so far, which receive these
		 * @param key A field value's key
		 */
		private void testSubstrings(Set<Integer> positions, String key) {
			for (String substring : this.substringKeys) {
				if (key?.contains(substring) == true) {
					Integer length = substring?.length();
					Map<String, Set<Integer>> keyed = this.substrings?.get(length);
					this.addMatches(positions, keyed, substring);
				}
			}
		}

		/**
		 * @description Adds the positions of the patterns with a key
		 * @param positions The matches so far, which receive these
		 * @param keyed Patterns by key
		 * @param key The key to look up
		 */
		private void addMatches(Set<Integer> positions, Map<String, Set<Integer>> keyed, String key) {
			Set<Integer> matches = keyed?.get(key) ?? InvocableSoql.NO_POSITIONS;
			positions?.addAll(matches);
		}
	}

	/** @description Runs queries without sharing, which `Soql` inherits, since it's `inherited sharing` **/
	private without sharing class SystemModeRunner {
		/**
		 * @description Runs the query
		 * @param builder A SYSTEM_MODE query
		 * @return The rows
		 */
		private List<SObject> run(Soql builder) {
			return builder?.query();
		}
	}

	/**
	 * @description Merges variants into one query that matches any of their values, then splits its rows back to each
	 * variant by checking each row against the variant's logic in Apex, as Get Records does in memory. A condition
	 * whose values vary widens in the query: Equals, In, and LIKE-style conditions match any variant's values, ranges
	 * read past the loosest bound, and Not Equals, Not In, and Is Null drop out. Apex checks each condition that
	 * widens, and each one a row could pass without, ex: under OR; the query guarantees the rest. Variants can't merge
	 * when a condition Apex must check is one it can't (see `InvocableSoql.Query.isCheckable`), or a varying
	 * condition is under NOT, which narrows what widening widens. A variant with a value Apex can't check runs alone
	 */
	private class Splitter {
		/**
		 * @description Every merged variant's position, until it fills, and the split stops at none; matches that hold
		 * all of them share it
		 */
		private Set<Integer> allPositions = new Set<Integer>{};
		/** @description The rows each variant keeps, OFFSET plus LIMIT; null without a limit **/
		private Integer capacity;
		/** @description Conditions Apex checks, by index: those not in a part of the logic the query guarantees **/
		private Set<Integer> checkedIndexes = new Set<Integer>{};
		/** @description Conditions the merged query leaves out, ex: each interview's `Id != {!$Record.Id}` **/
		private Set<Integer> droppedIndexes = new Set<Integer>{};
		/**
		 * @description Each condition's checker, listed once, since `Map.values()` builds a new list on each call, and
		 * here that costs CPU in proportion to everything the checkers hold: per row, it was most of the split's
		 */
		private List<InvocableSoql.ConditionMatcher> matchers = new List<InvocableSoql.ConditionMatcher>{};
		/** @description A checker for each condition Apex checks, by index **/
		private Map<Integer, InvocableSoql.ConditionMatcher> matchersByIndex = new Map<Integer, InvocableSoql.ConditionMatcher>{};
		private InvocableSoql.Query query;
		/** @description Conditions every row must pass, those joined to the rest only by AND, by index **/
		private Set<Integer> requiredIndexes = new Set<Integer>{};
		/** @description Conditions in the logic whose values differ between variants, by index **/
		private Set<Integer> varyingIndexes = new Set<Integer>{};
		/** @description The variants the merged query serves, by position; fewer than two when none can merge **/
		private List<InvocableSoql.Variant> variants = new List<InvocableSoql.Variant>{};

		/**
		 * @description Plans the merge: which variants it serves, and how Apex checks each condition
		 * @param query The query
		 * @param candidates Every variant in the batch
		 */
		private Splitter(InvocableSoql.Query query, List<InvocableSoql.Variant> candidates) {
			InvocableSoql.LogicNode root = query?.logicTree;
			this.query = query;
			this.capacity = (query?.rowLimit == null) ? null : query?.rowLimit + (query?.rowOffset ?? 0);
			this.findVaryingIndexes(root, candidates);
			Boolean isMergeable = root != null && this.plan(root, true, false) && this.isLockable();
			this.findCheckedIndexes(root);
			List<InvocableSoql.Variant> checkable = isMergeable
				? this.findCheckable(candidates)
				: new List<InvocableSoql.Variant>{};
			if (checkable?.size() > 1) {
				this.variants = checkable;
				this.initMatchers();
			}
		}

		/**
		 * @description Limits the merged query when only exclusions by ID vary. Each ID excludes one row at most, so
		 * every variant finds the rows it keeps within its limit and offset, plus the IDs it excludes
		 * @return The limit, or null to read every row any variant could need
		 */
		private Integer getMergedLimit() {
			Integer mergedLimit = this.capacity;
			for (Integer index : this.varyingIndexes) {
				Integer excluded = this.matchersByIndex?.get(index)?.countMostExcluded();
				mergedLimit = (mergedLimit == null || excluded == null) ? null : mergedLimit + excluded;
			}
			return mergedLimit;
		}

		/**
		 * @description Whether merging keeps For Update's locks to the rows the interviews lock on their own: only one
		 * varying Equals or In reads no other rows, with no limit, or for Equals on the ID joined to the rest only by
		 * AND, which finds one row at most, with any limit
		 * @return Whether the variants can merge, as far as locking goes
		 */
		private Boolean isLockable() {
			List<Integer> indexes = new List<Integer>(this.varyingIndexes);
			InvocableSoql.Condition varying = (indexes?.size() == 1) ? this.query?.conditions?.get(indexes[0]) : null;
			Boolean isUnion = varying?.operator == 'EQUALS' || varying?.operator == 'IN';
			// Under OR, the rest of the logic can find rows past the ID's, which the merged query reads with no limit
			Boolean isRequired = this.requiredIndexes?.containsAll(this.varyingIndexes);
			Boolean isIdLookup = varying?.operator == 'EQUALS' && varying?.field == 'Id' && isRequired;
			// No offset to check: `validatePaging` already rejects one with For Update
			return this.query?.usage != 'FOR_UPDATE' || (isUnion && (this.capacity == null || isIdLookup));
		}

		/**
		 * @description Widens each varying condition, starting from the first variant's values, since the rest are
		 * the same for every variant
		 * @return One value per condition, ready to bind; left-out conditions keep a value they don't bind
		 */
		private List<Object> getMergedValues() {
			List<Object> values = this.variants?.get(0)?.values?.clone();
			for (Integer index : this.varyingIndexes) {
				Boolean isDropped = this.droppedIndexes?.contains(index);
				Object merged = isDropped ? null : this.matchersByIndex?.get(index)?.getMergedValue();
				values?.set(index, merged);
			}
			return values;
		}

		/**
		 * @description Gives each variant the rows that pass its logic, in query order, then applies OFFSET and LIMIT.
		 * With a limit, it stops once every variant has the rows it keeps, ex: for a limit of 1 over a whole table
		 * @param rows The merged query's rows
		 */
		private void split(List<SObject> rows) {
			for (InvocableSoql.Variant variant : this.variants) {
				variant.records = new List<SObject>{};
			}
			Integer next = 0;
			while (this.capacity != 0 && this.allPositions?.isEmpty() == false && next < rows?.size()) {
				SObject row = rows?.get(next++);
				this.addRow(row);
			}
			for (InvocableSoql.Variant variant : this.variants) {
				variant.records = this.query?.page(variant?.records);
			}
		}

		/**
		 * @description Adds a row to each variant whose logic it passes
		 * @param row A row from the merged query
		 */
		private void addRow(SObject row) {
			for (InvocableSoql.ConditionMatcher matcher : this.matchers) {
				matcher?.prepare(row);
			}
			List<Integer> filled = new List<Integer>{};
			for (Integer position : this.matchNode(this.query?.logicTree)) {
				List<SObject> records = this.variants?.get(position)?.records;
				Boolean isFilled = this.addRecord(records, row);
				if (isFilled) {
					filled?.add(position);
				}
			}
			// Closed after the row, since its matches can be the very sets that closing changes
			for (Integer position : filled) {
				this.close(position);
			}
		}

		/**
		 * @description Adds a row to a variant's records, unless it already has every row its limit keeps
		 * @param records The variant's records so far
		 * @param row A row the variant's logic passes
		 * @return Whether this row filled the variant
		 */
		private Boolean addRecord(List<SObject> records, SObject row) {
			Boolean isOpen = this.capacity == null || records?.size() < this.capacity;
			if (isOpen) {
				records?.add(row);
			}
			return isOpen && records?.size() == this.capacity;
		}

		/**
		 * @description Stops looking for rows for a variant that has every row its limit keeps, so checkers that look
		 * through every variant for each row skip it
		 * @param position The variant's position
		 */
		private void close(Integer position) {
			this.allPositions?.remove(position);
			for (InvocableSoql.ConditionMatcher matcher : this.matchers) {
				matcher?.close(position);
			}
		}

		/**
		 * @description Checks a part of the logic for one variant. Like SOQL, a range on a blank field is unknown,
		 * neither true nor false, so NOT of it is unknown too. A part without varying conditions passes for every
		 * variant or none, so any position stands for all; the parts the query guarantees pass
		 * @param node A part of the logic
		 * @param position The variant's position
		 * @return True or false, or null when unknown
		 */
		private Boolean evaluate(InvocableSoql.LogicNode node, Integer position) {
			Boolean result;
			if (node?.isSkipped == true) {
				result = true;
			} else if (node?.index != null) {
				result = this.matchersByIndex?.get(node?.index)?.test(position);
			} else if (node?.operator == 'NOT') {
				InvocableSoql.LogicNode negated = node?.children?.get(0);
				Boolean value = this.evaluate(negated, position);
				result = (value == null) ? null : value == false;
			} else {
				result = this.evaluateJoined(node, position);
			}
			return result;
		}

		/**
		 * @description Joins the checks of an AND's or OR's parts, in three-valued logic: an AND is false if any part
		 * is false, else unknown if any part is unknown; an OR is true if any part is true, else unknown if any is
		 * @param node An AND or OR
		 * @param position The variant's position
		 * @return True or false, or null when unknown
		 */
		private Boolean evaluateJoined(InvocableSoql.LogicNode node, Integer position) {
			Boolean isAnd = node?.operator == 'AND';
			Boolean result = isAnd;
			for (InvocableSoql.LogicNode child : node?.children) {
				Boolean value = this.evaluate(child, position);
				Boolean isDecisive = value == (isAnd == false);
				Boolean isDecided = result == (isAnd == false);
				result = (isDecided || isDecisive) ? isAnd == false : ((value == null) ? null : result);
			}
			return result;
		}

		/**
		 * @description Picks the part of each varying AND that rows are looked up by, once for every row, and lists
		 * its other varying parts, which Apex then checks for just the variants the lookup finds
		 * @param node A part of the logic
		 */
		private void findDrivers(InvocableSoql.LogicNode node) {
			Boolean isVaryingAnd = node?.operator == 'AND' && node?.isUniform == false;
			node.driver = isVaryingAnd ? this.findDriver(node) : null;
			node.others = new List<InvocableSoql.LogicNode>{};
			for (InvocableSoql.LogicNode child : node?.children) {
				if (isVaryingAnd && child != node?.driver && child?.isUniform == false) {
					node?.others?.add(child);
				}
				this.findDrivers(child);
			}
		}

		/**
		 * @description Finds a part of an AND to look rows up by, preferring a condition whose lookup finds few
		 * variants, ex: Equals over Not Equals
		 * @param node An AND with varying conditions
		 * @return The varying part to look up
		 */
		private InvocableSoql.LogicNode findDriver(InvocableSoql.LogicNode node) {
			InvocableSoql.LogicNode driver;
			for (InvocableSoql.LogicNode child : node?.children) {
				Boolean isVarying = child?.isUniform == false;
				Boolean isBetter = driver == null || (this.isSelective(child) && this.isSelective(driver) == false);
				driver = (isVarying && isBetter) ? child : driver;
			}
			return driver;
		}

		/**
		 * @description Records the varying conditions under a part of the logic
		 * @param node A part of the logic
		 * @param candidates Every variant in the batch
		 */
		private void findVaryingIndexes(InvocableSoql.LogicNode node, List<InvocableSoql.Variant> candidates) {
			if (node?.index != null && this.isVarying(node?.index, candidates)) {
				this.varyingIndexes?.add(node?.index);
			}
			for (InvocableSoql.LogicNode child : node?.children ?? new List<InvocableSoql.LogicNode>{}) {
				this.findVaryingIndexes(child, candidates);
			}
		}

		/**
		 * @description Records the conditions Apex checks: every one outside a part the query guarantees
		 * @param node A part of the logic
		 */
		private void findCheckedIndexes(InvocableSoql.LogicNode node) {
			Boolean isChecked = node?.isSkipped == false;
			if (node?.index != null && isChecked) {
				this.checkedIndexes?.add(node?.index);
			}
			for (InvocableSoql.LogicNode child : isChecked ? node?.children : new List<InvocableSoql.LogicNode>{}) {
				this.findCheckedIndexes(child);
			}
		}

		/**
		 * @description Lists the variants whose values Apex can check for every condition it checks
		 * @param candidates Every variant in the batch
		 * @return The variants that can merge
		 */
		private List<InvocableSoql.Variant> findCheckable(List<InvocableSoql.Variant> candidates) {
			List<InvocableSoql.Variant> checkable = new List<InvocableSoql.Variant>{};
			for (InvocableSoql.Variant variant : candidates) {
				Boolean isCheckable = true;
				for (Integer index : this.checkedIndexes) {
					Object value = variant?.values?.get(index);
					Boolean isVarying = this.varyingIndexes?.contains(index);
					isCheckable &= this.query?.isCheckableValue(index, value, isVarying);
				}
				if (isCheckable) {
					checkable?.add(variant);
				}
			}
			return checkable;
		}

		/**
		 * @description Builds a checker for each condition Apex checks, records the varying ones the query leaves
		 * out, then picks how each AND looks rows up
		 */
		private void initMatchers() {
			for (Integer position = 0; position < this.variants?.size(); position++) {
				this.allPositions?.add(position);
			}
			for (Integer index : this.checkedIndexes) {
				InvocableSoql.ConditionMatcher matcher = this.initMatcher(index);
				this.matchers?.add(matcher);
				this.matchersByIndex?.put(index, matcher);
				if (matcher?.isDropped == true && this.varyingIndexes?.contains(index) == true) {
					this.droppedIndexes?.add(index);
				}
			}
			this.findDrivers(this.query?.logicTree);
		}

		/**
		 * @description Picks the checker for a condition's operator
		 * @param index The condition's index
		 * @return The checker
		 */
		private InvocableSoql.ConditionMatcher initMatcher(Integer index) {
			String operator = this.query?.getOperator(index);
			List<Object> values = new List<Object>{};
			for (InvocableSoql.Variant variant : this.variants) {
				Object value = variant?.values?.get(index);
				values?.add(value);
			}
			InvocableSoql.ConditionMatcher matcher;
			if (operator == InvocableSoql.NULL_CHECK) {
				matcher = new InvocableSoql.NullCheckMatcher(this.query, index, values);
			} else if (InvocableSoql.RANGE_OPERATORS?.contains(operator) == true) {
				matcher = new InvocableSoql.RangeMatcher(this.query, index, values);
			} else if (this.query?.isPattern(index) == true) {
				matcher = new InvocableSoql.PatternMatcher(this.query, index, values);
			} else {
				matcher = new InvocableSoql.KeyMatcher(this.query, index, values);
			}
			return matcher;
		}

		/**
		 * @description Whether a part of the logic is a condition whose lookup finds few variants
		 * @param node A part of the logic
		 * @return Whether looking it up narrows rows to a few variants
		 */
		private Boolean isSelective(InvocableSoql.LogicNode node) {
			return node?.index != null && this.matchersByIndex?.get(node?.index)?.isSelective == true;
		}

		/**
		 * @description Whether variants hold different values for a condition
		 * @param index The condition's index
		 * @param candidates Every variant in the batch
		 * @return Whether its values differ
		 */
		private Boolean isVarying(Integer index, List<InvocableSoql.Variant> candidates) {
			Set<String> keys = new Set<String>{};
			for (InvocableSoql.Variant variant : candidates) {
				String key = variant?.valueKeys?.get(index);
				keys?.add(key);
			}
			return keys?.size() > 1;
		}

		/**
		 * @description Finds the variants whose logic the current row passes, by looking up its varying conditions
		 * @param node A part of the logic
		 * @return The positions of the variants it passes for; never changed by the caller
		 */
		private Set<Integer> matchNode(InvocableSoql.LogicNode node) {
			Set<Integer> matched;
			if (node?.isUniform == true) {
				matched = (this.evaluate(node, 0) == true) ? this.allPositions : InvocableSoql.NO_POSITIONS;
			} else if (node?.index != null) {
				matched = this.matchersByIndex?.get(node?.index)?.match();
			} else if (node?.operator == 'OR') {
				matched = this.matchAny(node);
			} else {
				matched = this.matchAll(node);
			}
			return matched;
		}

		/**
		 * @description An AND looks up one varying part, then checks the rest for just those variants
		 * @param node An AND with varying conditions
		 * @return The positions of the variants every part passes for
		 */
		private Set<Integer> matchAll(InvocableSoql.LogicNode node) {
			Boolean isUniformPassing = true;
			for (InvocableSoql.LogicNode child : node?.children) {
				isUniformPassing &= child?.isUniform == false || this.evaluate(child, 0) == true;
			}
			Set<Integer> candidates = isUniformPassing ? this.matchNode(node?.driver) : InvocableSoql.NO_POSITIONS;
			return (node?.others?.isEmpty() == true) ? candidates : this.testOthers(node, candidates);
		}

		/**
		 * @description An OR unites its parts' matches
		 * @param node An OR with varying conditions
		 * @return The positions of the variants any part passes for
		 */
		private Set<Integer> matchAny(InvocableSoql.LogicNode node) {
			Set<Integer> matched = new Set<Integer>{};
			for (InvocableSoql.LogicNode child : node?.children) {
				Set<Integer> childMatches = this.matchNode(child);
				matched?.addAll(childMatches);
			}
			return matched;
		}

		/**
		 * @description Keeps the variants an AND's lookup found whose other varying parts pass too
		 * @param node An AND with varying conditions besides its driver
		 * @param candidates The variants its driver's lookup found
		 * @return The positions of the variants every part passes for
		 */
		private Set<Integer> testOthers(InvocableSoql.LogicNode node, Set<Integer> candidates) {
			Set<Integer> matched = new Set<Integer>{};
			for (Integer position : candidates) {
				if (this.passesOthers(node, position)) {
					matched?.add(position);
				}
			}
			return matched;
		}

		/**
		 * @description Checks an AND's varying parts, besides its driver, for one variant. Varying conditions are
		 * never under NOT, so an unknown result fails like false
		 * @param node An AND with varying conditions besides its driver
		 * @param position The variant's position
		 * @return Whether every other varying part passes
		 */
		private Boolean passesOthers(InvocableSoql.LogicNode node, Integer position) {
			Boolean isPassing = true;
			for (InvocableSoql.LogicNode other : node?.others) {
				isPassing &= this.evaluate(other, position) == true;
			}
			return isPassing;
		}

		/**
		 * @description Marks the parts of the logic the query guarantees, those without varying conditions, and the
		 * conditions every row must pass, then checks that Apex can check the rest
		 * @param node A part of the logic
		 * @param isRequired Whether every row must pass it, as for a part joined to the rest only by AND
		 * @param isNegated Whether it's under NOT
		 * @return Whether the variants can merge, as far as this part goes
		 */
		private Boolean plan(InvocableSoql.LogicNode node, Boolean isRequired, Boolean isNegated) {
			Boolean isChildRequired = isRequired && node?.operator == 'AND';
			Boolean isChildNegated = isNegated || node?.operator == 'NOT';
			Boolean isMergeable = true;
			node.isUniform = node?.index == null || this.varyingIndexes?.contains(node?.index) == false;
			for (InvocableSoql.LogicNode child : node?.children) {
				isMergeable &= this.plan(child, isChildRequired, isChildNegated);
				node.isUniform &= child?.isUniform;
			}
			node.isSkipped = isRequired && node?.isUniform;
			if (isRequired && node?.index != null) {
				this.requiredIndexes?.add(node?.index);
			}
			// A varying condition widens, which NOT would turn into narrowing
			Boolean isCheckable =
				node?.index == null ||
				(this.query?.isCheckable(node?.index) && (node?.isUniform || isNegated == false));
			return node?.isSkipped || (isMergeable && isCheckable);
		}
	}

	/** @description A part of the condition logic: a condition, or an AND, OR, or NOT of other parts **/
	private class LogicNode {
		private List<InvocableSoql.LogicNode> children = new List<InvocableSoql.LogicNode>{};
		/** @description For an AND with varying conditions, the part a merged query's rows are looked up by **/
		private InvocableSoql.LogicNode driver;
		/** @description The condition's index, for a condition **/
		private Integer index;
		/** @description Whether the merged query guarantees every row passes it, so Apex needn't check it **/
		private Boolean isSkipped = false;
		/** @description Whether it holds no varying conditions, so it passes for every variant or none **/
		private Boolean isUniform = true;
		/** @description AND, OR, or NOT; blank for a condition **/
		private String operator;
		/** @description For an AND with varying conditions, the varying parts besides its driver **/
		private List<InvocableSoql.LogicNode> others = new List<InvocableSoql.LogicNode>{};

		/**
		 * @description Builds a part of the logic
		 * @param operator AND, OR, or NOT; blank for a condition
		 * @param index The condition's index, for a condition
		 */
		private LogicNode(String operator, Integer index) {
			this.index = index;
			this.operator = operator;
		}
	}

	/**
	 * @description Parses condition logic into `InvocableSoql.LogicNode`s. SOQL rejects AND and OR side by side
	 * without parentheses, so which binds first doesn't matter
	 */
	private class LogicParser {
		private Integer position = 0;
		private List<String> tokens = new List<String>{};

		/**
		 * @description Splits the logic into tokens
		 * @param logic Well-formed logic, by condition number, ex: "1 AND (2 OR NOT 3)"
		 */
		private LogicParser(String logic) {
			Matcher matcher = InvocableSoql.TOKEN_PATTERN.matcher(logic ?? '');
			while (matcher?.find() == true) {
				this.tokens?.add(matcher?.group()?.toUpperCase());
			}
		}

		/**
		 * @description Parses the logic
		 * @return Its root, or null for logic without conditions
		 */
		private InvocableSoql.LogicNode parse() {
			return this.tokens?.isEmpty() == true ? null : this.parseGroup();
		}

		/**
		 * @description Parses operands joined by AND or OR, joining a run of the same one into one part
		 * @return The part
		 */
		private InvocableSoql.LogicNode parseGroup() {
			InvocableSoql.LogicNode result = this.parseOperand();
			InvocableSoql.LogicNode joined;
			while (this.isJoinNext()) {
				String operator = this.next();
				InvocableSoql.LogicNode operand = this.parseOperand();
				if (joined?.operator != operator) {
					joined = new InvocableSoql.LogicNode(operator, null);
					joined?.children?.add(result);
					result = joined;
				}
				joined?.children?.add(operand);
			}
			return result;
		}

		/**
		 * @description Parses a condition number, NOT and its operand, or a parenthesized group
		 * @return The part
		 */
		private InvocableSoql.LogicNode parseOperand() {
			String token = this.next();
			InvocableSoql.LogicNode operand;
			if (token == 'NOT') {
				operand = new InvocableSoql.LogicNode(token, null);
				InvocableSoql.LogicNode negated = this.parseOperand();
				operand?.children?.add(negated);
			} else if (token == '(') {
				operand = this.parseGroup();
				// Skips the closing parenthesis
				this.next();
			} else {
				Integer index = Integer.valueOf(token) - 1;
				operand = new InvocableSoql.LogicNode(null, index);
			}
			return operand;
		}

		/**
		 * @description Whether AND or OR comes next
		 * @return True if the next token joins operands
		 */
		private Boolean isJoinNext() {
			String token = (this.position < this.tokens?.size()) ? this.tokens?.get(this.position) : null;
			return token == 'AND' || token == 'OR';
		}

		/**
		 * @description Reads the next token
		 * @return The token
		 */
		private String next() {
			return this.tokens?.get(this.position++);
		}
	}

	/**
	 * @description Checks one condition on a merged query's rows, for each variant. It holds no reference back to the
	 * splitter, whose variants collect every row, so what it reaches doesn't grow as the split runs
	 */
	private abstract class ConditionMatcher {
		protected Integer index;
		protected Boolean isCaseSensitive;
		/** @description Whether the merged query leaves the condition out when its values vary **/
		protected Boolean isDropped = false;
		/** @description Whether a lookup finds few variants, so an AND can check the rest for just those **/
		protected Boolean isSelective = false;
		/** @description The variants still short of the rows they keep, by position **/
		protected Set<Integer> openPositions = new Set<Integer>{};
		protected InvocableSoql.Query query;
		/** @description The current row's value for the condition's field **/
		protected Object rowValue;
		/** @description Each variant's value for the condition, by position **/
		protected List<Object> values;

		/**
		 * @description Holds what checking needs
		 * @param query The query
		 * @param index The condition's index
		 * @param values Each variant's value for the condition, by position
		 */
		protected ConditionMatcher(InvocableSoql.Query query, Integer index, List<Object> values) {
			this.index = index;
			this.isCaseSensitive = query?.isCaseSensitive(index);
			this.query = query;
			this.values = values;
			for (Integer position = 0; position < values?.size(); position++) {
				this.openPositions?.add(position);
			}
		}

		/**
		 * @description Unions every variant's values into one list of the field's type, since SOQL binds are strictly
		 * typed. Equals and LIKE bind a list as they would a single value, ex: `Name = :list` matches any of them
		 * @return The merged value
		 */
		public virtual Object getMergedValue() {
			Type valueType = this.query?.getValueType(this.index);
			List<Object> merged = InvocableSoql.initList(valueType);
			for (Object value : this.values) {
				List<Object> elements = InvocableSoql.toList(value);
				merged?.addAll(elements);
			}
			return merged;
		}

		/**
		 * @description The most rows the condition excludes for any variant, when that's known
		 * @return The count, or null when it can exclude any number of rows
		 */
		public virtual Integer countMostExcluded() {
			return null;
		}

		/**
		 * @description Stops matching a variant that has every row it keeps. Lookups by key or pattern find few
		 * variants, so only checkers that look through every variant drop it
		 * @param position The variant's position
		 */
		public virtual void close(Integer position) {
			this.openPositions?.remove(position);
		}

		/**
		 * @description Reads the row's value for the condition's field, once for every check of the row
		 * @param row A row from the merged query
		 */
		public virtual void prepare(SObject row) {
			this.rowValue = this.query?.getFieldValue(row, this.index);
		}

		/**
		 * @description Finds the variants the current row passes the condition for
		 * @return Their positions; never changed by the caller
		 */
		public abstract Set<Integer> match();

		/**
		 * @description Checks the current row for one variant
		 * @param position The variant's position
		 * @return True or false, or null when unknown, ex: a range on a blank field
		 */
		public abstract Boolean test(Integer position);
	}

	/** @description Checks Equals, In, Not Equals, and Not In by key, so a row's key looks up its variants **/
	private class KeyMatcher extends InvocableSoql.ConditionMatcher {
		private Boolean isNegated;
		/** @description Each key's variants **/
		private Map<String, Set<Integer>> positionsByKey = new Map<String, Set<Integer>>{};
		/** @description The variants with the current row's key, looked up once for every check of the row **/
		private Set<Integer> rowPositions;

		/**
		 * @description Indexes each variant's values by key
		 * @param query The query
		 * @param index The condition's index
		 * @param values Each variant's value for the condition, by position
		 */
		private KeyMatcher(InvocableSoql.Query query, Integer index, List<Object> values) {
			super(query, index, values);
			String operator = query?.getOperator(index);
			this.isNegated = operator == 'NOT_EQUALS' || operator == 'NOT_IN';
			this.isDropped = this.isNegated;
			this.isSelective = this.isNegated == false;
			for (Integer position = 0; position < values?.size(); position++) {
				this.addVariant(position);
			}
		}

		/**
		 * @description Not Equals and Not In on the queried object's ID exclude one row per ID at most, ex:
		 * `Id != {!$Record.Id}`
		 * @return The most IDs any variant excludes, or null for other conditions
		 */
		public override Integer countMostExcluded() {
			Boolean isIdField = this.query?.conditions?.get(this.index)?.field == 'Id';
			Integer most = 0;
			for (Object value : this.values) {
				Integer excluded = InvocableSoql.toList(value)?.size();
				most = Math.max(most, excluded);
			}
			return (this.isNegated && isIdField) ? most : null;
		}

		/**
		 * @description Finds the variants with the row's key, or for Not Equals and Not In, the other open ones
		 * @return Their positions
		 */
		public override Set<Integer> match() {
			Set<Integer> others = this.isNegated ? this.openPositions?.clone() : null;
			others?.removeAll(this.rowPositions);
			return others ?? this.rowPositions;
		}

		/**
		 * @description Looks up the variants with the row's key
		 * @param row A row from the merged query
		 */
		public override void prepare(SObject row) {
			super.prepare(row);
			String rowKey = this.toKey(this.rowValue);
			this.rowPositions = this.positionsByKey?.get(rowKey) ?? InvocableSoql.NO_POSITIONS;
		}

		/**
		 * @description Checks whether the variant holds the row's key
		 * @param position The variant's position
		 * @return Whether the row passes
		 */
		public override Boolean test(Integer position) {
			return this.rowPositions?.contains(position) != this.isNegated;
		}

		/**
		 * @description Indexes a variant's value, or each of its values for In and Not In
		 * @param position The variant's position
		 */
		private void addVariant(Integer position) {
			Object value = this.values?.get(position);
			for (Object element : InvocableSoql.toList(value)) {
				String key = this.toKey(element);
				Set<Integer> positions = this.positionsByKey?.get(key) ?? new Set<Integer>{};
				positions?.add(position);
				this.positionsByKey?.put(key, positions);
			}
		}

		/**
		 * @description Keys a value per `InvocableSoql.toKey`, with '' as null, since SOQL matches '' to blank fields
		 * @param value A value
		 * @return Its key
		 */
		private String toKey(Object value) {
			String key = InvocableSoql.toKey(value, this.isCaseSensitive);
			return String.isEmpty(key) ? null : key;
		}
	}

	/** @description Checks Is Null: whether the field is blank, for true, or has a value, for false **/
	private class NullCheckMatcher extends InvocableSoql.ConditionMatcher {
		/** @description Each check's variants: true finds blank fields, false filled ones **/
		private Map<Boolean, Set<Integer>> positionsByCheck = new Map<Boolean, Set<Integer>>{
			true => new Set<Integer>{},
			false => new Set<Integer>{}
		};

		/**
		 * @description Groups the variants by check
		 * @param query The query
		 * @param index The condition's index
		 * @param values Each variant's value for the condition, by position
		 */
		private NullCheckMatcher(InvocableSoql.Query query, Integer index, List<Object> values) {
			super(query, index, values);
			this.isDropped = true;
			for (Integer position = 0; position < values?.size(); position++) {
				Boolean isNullCheck = (Boolean) this.values?.get(position);
				this.positionsByCheck?.get(isNullCheck)?.add(position);
			}
		}

		/**
		 * @description Drops a variant that has every row it keeps
		 * @param position The variant's position
		 */
		public override void close(Integer position) {
			super.close(position);
			for (Set<Integer> positions : this.positionsByCheck?.values()) {
				positions?.remove(position);
			}
		}

		/**
		 * @description Finds the variants whose check the row's value passes
		 * @return Their positions
		 */
		public override Set<Integer> match() {
			return this.positionsByCheck?.get(this.rowValue == null);
		}

		/**
		 * @description Checks the row's value against the variant's check
		 * @param position The variant's position
		 * @return Whether the row passes
		 */
		public override Boolean test(Integer position) {
			return this.values?.get(position) == (this.rowValue == null);
		}
	}

	/** @description Checks Starts With, Ends With, Contains, and simple Like patterns **/
	private class PatternMatcher extends InvocableSoql.ConditionMatcher {
		private InvocableSoql.LikePatternIndex patternIndex = new InvocableSoql.LikePatternIndex();
		/** @description Each variant's pattern, by position **/
		private List<InvocableSoql.LikePattern> patterns = new List<InvocableSoql.LikePattern>{};
		private String rowKey;

		/**
		 * @description Parses and indexes each variant's pattern
		 * @param query The query
		 * @param index The condition's index
		 * @param values Each variant's value for the condition, by position
		 */
		private PatternMatcher(InvocableSoql.Query query, Integer index, List<Object> values) {
			super(query, index, values);
			this.isSelective = true;
			for (Integer position = 0; position < values?.size(); position++) {
				String value = (String) this.values?.get(position);
				InvocableSoql.LikePattern pattern = new InvocableSoql.LikePattern(value, this.isCaseSensitive);
				this.patterns?.add(pattern);
				this.patternIndex?.add(pattern, position);
			}
		}

		/**
		 * @description Looks up the patterns the row's value matches
		 * @return Their variants' positions
		 */
		public override Set<Integer> match() {
			return this.patternIndex?.match(this.rowKey);
		}

		/**
		 * @description Keys the row's value
		 * @param row A row from the merged query
		 */
		public override void prepare(SObject row) {
			super.prepare(row);
			this.rowKey = InvocableSoql.toKey(this.rowValue, this.isCaseSensitive);
		}

		/**
		 * @description Matches the row's value against the variant's pattern
		 * @param position The variant's position
		 * @return Whether the row passes
		 */
		public override Boolean test(Integer position) {
			return this.patterns?.get(position)?.matches(this.rowKey);
		}
	}

	/** @description Checks Greater Than, Less Than, and their Or Equal forms on numbers, dates, date/times, and times **/
	private class RangeMatcher extends InvocableSoql.ConditionMatcher {
		/** @description Each variant's bound, by position **/
		private List<InvocableSoql.RangeBound> bounds = new List<InvocableSoql.RangeBound>{};
		/** @description Whether a value equal to the bound passes, as for Greater or Equal **/
		private Boolean isInclusive;
		/** @description Whether values above the bound pass, as for Greater Than **/
		private Boolean isUpward;
		/** @description Each variant's bound, loosest first, so a row passes a run of them from the start **/
		private List<InvocableSoql.RangeBound> loosestFirst = new List<InvocableSoql.RangeBound>{};
		private Decimal rowOrdinal;
		/** @description The variants without a bound, which SOQL passes every row for, even a blank field **/
		private Set<Integer> unbounded = new Set<Integer>{};

		/**
		 * @description Orders each variant's bound
		 * @param query The query
		 * @param index The condition's index
		 * @param values Each variant's value for the condition, by position
		 */
		private RangeMatcher(InvocableSoql.Query query, Integer index, List<Object> values) {
			super(query, index, values);
			String operator = query?.getOperator(index);
			this.isInclusive = operator?.endsWith('OR_EQUAL') == true;
			this.isUpward = operator?.startsWith('GREATER') == true;
			// Greater Than's loosest bound is its lowest, and Less Than's its highest
			Integer direction = this.isUpward ? 1 : -1;
			for (Integer position = 0; position < values?.size(); position++) {
				Object value = this.values?.get(position);
				Decimal ordinal = InvocableSoql.toOrdinal(value);
				InvocableSoql.RangeBound bound = new InvocableSoql.RangeBound(ordinal, position, direction);
				this.bounds?.add(bound);
				if (ordinal == null) {
					this.unbounded?.add(position);
				} else {
					this.loosestFirst?.add(bound);
				}
			}
			this.loosestFirst?.sort();
			// A variant without a bound needs every row, so the merged query can't bound the field
			this.isDropped = this.unbounded?.isEmpty() == false;
		}

		/**
		 * @description Drops a variant that has every row it keeps, so rows stop running past its bound
		 * @param position The variant's position
		 */
		public override void close(Integer position) {
			super.close(position);
			Boolean isUnbounded = this.unbounded?.remove(position) == true;
			if (isUnbounded == false) {
				InvocableSoql.RangeBound bound = this.bounds?.get(position);
				Integer next = this.loosestFirst?.indexOf(bound);
				this.loosestFirst?.remove(next);
			}
		}

		/**
		 * @description The loosest bound, so the query reads every row any variant needs
		 * @return The loosest variant's value
		 */
		public override Object getMergedValue() {
			Integer loosest = this.loosestFirst?.get(0)?.position;
			return this.values?.get(loosest);
		}

		/**
		 * @description Collects the bounds the row's value passes, from the loosest until one fails, and the variants
		 * without one
		 * @return Their variants' positions; only those without a bound for a blank field
		 */
		public override Set<Integer> match() {
			Set<Integer> matched = this.unbounded?.clone();
			Integer next = 0;
			Boolean isPassing = this.rowOrdinal != null;
			while (isPassing && next < this.loosestFirst?.size()) {
				InvocableSoql.RangeBound bound = this.loosestFirst?.get(next++);
				isPassing = this.passes(bound?.ordinal);
				if (isPassing) {
					matched?.add(bound?.position);
				}
			}
			return matched;
		}

		/**
		 * @description Orders the row's value
		 * @param row A row from the merged query
		 */
		public override void prepare(SObject row) {
			super.prepare(row);
			this.rowOrdinal = InvocableSoql.toOrdinal(this.rowValue);
		}

		/**
		 * @description Compares the row's value with the variant's bound
		 * @param position The variant's position
		 * @return Whether the row passes: always without a bound; null for a blank field, which SOQL treats as unknown
		 */
		public override Boolean test(Integer position) {
			Decimal bound = this.bounds?.get(position)?.ordinal;
			Boolean isPassing;
			if (bound == null) {
				isPassing = true;
			} else if (this.rowOrdinal != null) {
				isPassing = this.passes(bound);
			}
			return isPassing;
		}

		/**
		 * @description Compares the row's value with a bound by the operator
		 * @param bound A bound, per `InvocableSoql.toOrdinal`
		 * @return Whether the row's value passes
		 */
		private Boolean passes(Decimal bound) {
			return (this.rowOrdinal == bound) ? this.isInclusive : (this.rowOrdinal > bound) == this.isUpward;
		}
	}

	/** @description A variant's range bound, sorted loosest first **/
	private class RangeBound implements Comparable {
		/** @description 1 to sort lowest first, or -1 for highest first **/
		private Integer direction;
		private Decimal ordinal;
		private Integer position;

		/**
		 * @description Holds a bound
		 * @param ordinal The bound, per `InvocableSoql.toOrdinal`
		 * @param position Its variant's position
		 * @param direction 1 to sort lowest first, or -1 for highest first
		 */
		private RangeBound(Decimal ordinal, Integer position, Integer direction) {
			this.direction = direction;
			this.ordinal = ordinal;
			this.position = position;
		}

		/**
		 * @description Sorts by bound, in the direction
		 * @param other Another bound
		 * @return Negative to sort this first, positive to sort it after, or 0
		 */
		public Integer compareTo(Object other) {
			Decimal otherOrdinal = ((InvocableSoql.RangeBound) other)?.ordinal;
			Integer order = (this.ordinal > otherOrdinal) ? 1 : 0;
			order = (this.ordinal < otherOrdinal) ? -1 : order;
			return order * this.direction;
		}
	}

	/** @description A distinct set of values in a batch: the interviews that share it share its query and rows **/
	private class Variant {
		private String queryString;
		/** @description Null until a query fills it, so the batch can tell which variants still need one **/
		private List<SObject> records;
		/** @description Each value as JSON, to tell variants apart and find the conditions that differ **/
		private List<String> valueKeys = new List<String>{};
		private List<Object> values;

		/**
		 * @description Serializes each value once, for comparing variants
		 * @param values One value per condition
		 */
		private Variant(List<Object> values) {
			this.values = values;
			for (Object value : values) {
				String valueKey = JSON.serialize(value);
				this.valueKeys?.add(valueKey);
			}
		}
	}
}
