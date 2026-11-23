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
	/** @description Operators whose rows can be split back to interviews by comparing the field in Apex **/
	private static final Set<String> MERGEABLE_OPERATORS = new Set<String>{
		'CONTAINS',
		'ENDS_WITH',
		'EQUALS',
		'IN',
		'LIKE',
		'STARTS_WITH'
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
	 * @description Treats a single value as a one-item list, so EQUALS and IN values merge alike
	 * @param value A value, or a collection of values
	 * @return The values
	 */
	private static List<Object> toList(Object value) {
		List<Object> values = new List<Object>{};
		if (value instanceof Iterable<Object>) {
			for (Object element : (Iterable<Object>) value) {
				values?.add(element);
			}
		} else {
			values?.add(value);
		}
		return values;
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
		 * @description An ID's Not Equals, ex: `Id != {!$Record.Id}`, can be left out of a merged query and applied to
		 * its rows in Apex, since IDs compare exactly, and SOQL's `!=` keeps null like Apex's. Text can't, since Apex
		 * and SOQL fold some text's case differently
		 * @param index The condition's index
		 * @return Whether a split can apply the condition
		 */
		private Boolean isFilterable(Integer index) {
			Type valueType = this.getValueType(index);
			return this.getOperator(index) == 'NOT_EQUALS' && valueType == Id.class;
		}

		/**
		 * @description Merging interviews unions one condition's values, then splits the rows by that field, which only
		 * gives each interview its own rows when every condition must match. LIMIT and OFFSET apply to each
		 * interview's rows after the split
		 * @param index The condition whose values differ between interviews
		 * @return Whether interviews that differ only in this condition can share one query
		 */
		private Boolean isMergeable(Integer index) {
			Boolean isAllConditions = this.getLogicName() == 'AND';
			Schema.DisplayType fieldType = this.conditionFields?.get(index)?.getType();
			// Equality on a multi-select picklist compares the whole set of values, which a split can't reproduce
			Boolean isMultiPicklist = fieldType == Schema.DisplayType.MULTIPICKLIST;
			// With several currencies, SOQL compares converted amounts but returns each in its record's own currency
			Boolean isConvertedCurrency =
				fieldType == Schema.DisplayType.CURRENCY && UserInfo.isMultiCurrencyOrganization();
			String operator = this.getOperator(index);
			return isAllConditions &&
				isMultiPicklist == false &&
				isConvertedCurrency == false &&
				InvocableSoql.MERGEABLE_OPERATORS?.contains(operator) == true;
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
		 * and without the conditions the split applies
		 * @param values One value per condition, the varying one holding every interview's values
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
			List<SObjectField> lookups = isAllFields ? this.findLookups(fieldName) : null;
			if (isAllFields == false) {
				builder?.addSelect(fieldName);
			} else if (lookups?.isEmpty() == true) {
				builder?.selectAll();
			} else {
				Soql.ParentField lookupField = new Soql.ParentField(lookups);
				builder?.selectAll(lookupField);
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
		 * @description JSON converts flow values and the editor's text alike; Id.valueOf also lengthens 15-character
		 * IDs, so they match the 18-character IDs that queries return
		 * @param value A single value
		 * @param valueType The field's Apex type
		 * @return The value as the field's type
		 */
		private Object coerceValue(Object value, Type valueType) {
			InvocableSoql.checkWholeNumber(value, valueType);
			Boolean isId = valueType == Id.class && value != null;
			// JSON reads a zoneless time, ex: "10:30", in the user's time zone; Time fields hold the time as typed
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
			new InvocableSoql.Filter(this, blankValues, true)?.toString();
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
			String relationshipPath = path?.removeEnd(InvocableSoql.ALL_FIELDS)?.removeEnd('.');
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
		 * @description Finds a parent object's describe through a relationship, ex: Account's for "Account"
		 * @param child The object holding the lookup
		 * @param relationshipName The relationship name
		 * @param path The whole field path, for the error
		 * @return The parent object's describe
		 * @throws System.IllegalArgumentException When the object has no relationship by that name
		 */
		private DescribeSObjectResult describeParent(
			DescribeSObjectResult child,
			String relationshipName,
			String path
		) {
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
			SObjectField lookup = DatabaseLayer.Utils.Schema.findLookup(child, relationshipName);
			if (lookup == null) {
				throw new IllegalArgumentException('Invalid field for ' + this.objectApiName + ': ' + path);
			}
			return lookup?.getDescribe();
		}

		/**
		 * @description Describes the object SOQL resolves a lookup to, per `DatabaseLayerUtils.Schema.toEntityName`
		 * @param lookup The lookup's describe
		 * @return The parent object's describe
		 */
		private DescribeSObjectResult describeReference(DescribeFieldResult lookup) {
			String parentName = DatabaseLayer.Utils.Schema.toEntityName(lookup);
			return DatabaseLayer.Utils.Schema.describeObject(parentName);
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
			Boolean isCollection = InvocableSoql.COLLECTION_OPERATORS?.contains(this.getOperator(index));
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
		/** @description Conditions a merged query leaves out, by index, for the split to apply; only under AND **/
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
				if (this.omitted?.contains(index - 1) == false) {
					numbers?.add(conditionNumber);
				}
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

	/**
	 * @description Runs a batch of `SOQL: Get Record(s)` interviews in as few queries as it can, since Flow sends every
	 * interview at the element in one call. Interviews with the same query, access level, and values share one query.
	 * Interviews whose values differ in exactly one EQUALS, IN, or LIKE-style condition share one merged query, whose
	 * rows are split back to each interview by comparing that field in Apex. An ID's Not Equals may differ too, ex:
	 * `Id != {!$Record.Id}`: the merged query leaves it out, and the split applies it. Everything else runs one query
	 * per distinct set of values; see `InvocableSoql.Query.isMergeable` for when merging applies
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
		/** @description Varying conditions the split applies, which a merged query leaves out, ex: Id != $Record.Id **/
		private Set<Integer> filteredIndexes = new Set<Integer>{};
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
		 * @description Finds the one condition whose values differ between variants, if only one does, besides those a
		 * split can apply, which it records in `filteredIndexes`. When only those differ, finds a shared one instead
		 * @return The condition's index, or null when none can merge or several differ
		 */
		private Integer findVaryingIndex() {
			List<InvocableSoql.Variant> variants = this.variants?.values();
			List<Integer> varying = new List<Integer>{};
			for (Integer index = 0; index < variants?.get(0)?.valueKeys?.size(); index++) {
				Boolean isVarying = this.isVarying(index);
				Boolean isFiltered = isVarying && this.query?.isFilterable(index);
				if (isFiltered) {
					this.filteredIndexes?.add(index);
				} else if (isVarying) {
					varying?.add(index);
				}
			}
			Integer varyingIndex = (varying?.size() == 1) ? varying?.get(0) : null;
			Boolean isOnlyFiltered = varying?.isEmpty() == true && this.filteredIndexes?.isEmpty() == false;
			return isOnlyFiltered ? this.findSharedIndex() : varyingIndex;
		}

		/**
		 * @description When only conditions a split applies differ, ex: contacts with no account, each excluding
		 * itself, finds a bound condition to merge on anyway: every row matches its one shared value
		 * @return The condition's index, or null when none can merge
		 */
		private Integer findSharedIndex() {
			Integer sharedIndex;
			for (Integer index = 0; index < this.query?.conditions?.size(); index++) {
				Boolean isBound = this.query?.conditions?.get(index)?.isBound() == true;
				Boolean isCandidate = isBound && this.filteredIndexes?.contains(index) == false;
				Boolean isShared = sharedIndex == null && isCandidate && this.query?.isMergeable(index) == true;
				sharedIndex = isShared ? index : sharedIndex;
			}
			return sharedIndex;
		}

		/**
		 * @description Whether variants hold different values for a condition
		 * @param index The condition's index
		 * @return Whether its values differ
		 */
		private Boolean isVarying(Integer index) {
			Set<String> keys = new Set<String>{};
			for (InvocableSoql.Variant variant : this.variants?.values()) {
				String key = variant?.valueKeys?.get(index);
				keys?.add(key);
			}
			return keys?.size() > 1;
		}

		/**
		 * @description Lists the variants a merged query can serve: empty text runs alone, and so does a blank LIKE
		 * pattern or one with wildcards in its middle, which a split can't reproduce
		 * @param index The varying condition's index, or null
		 * @return The variants to merge; fewer than two means there's nothing to merge
		 */
		private List<InvocableSoql.Variant> getMergeable(Integer index) {
			List<InvocableSoql.Variant> mergeable = new List<InvocableSoql.Variant>{};
			if (index != null && this.query?.isMergeable(index) == true) {
				for (InvocableSoql.Variant variant : this.variants?.values()) {
					Object value = variant?.values?.get(index);
					if (this.isMergeableValue(index, value) == true) {
						mergeable?.add(variant);
					}
				}
			}
			return mergeable;
		}

		/**
		 * @description Empty text runs alone, and so does a blank LIKE pattern, or one a split can't reproduce. A blank
		 * value merges, since SOQL's IN matches null to blank fields, as `= null` does, and the split keys blanks
		 * together
		 * @param index The varying condition's index
		 * @param value A variant's value for it
		 * @return Whether a merged query can serve the variant
		 */
		private Boolean isMergeableValue(Integer index, Object value) {
			Boolean isPattern = this.query?.isPattern(index);
			Boolean isSimple = (isPattern && value != null)
				? new InvocableSoql.LikePattern((String) value, false)?.isSimple
				: isPattern == false;
			// SOQL matches '' to null, but a split keys '' and null apart, so '' runs alone
			Boolean hasEmptyText = InvocableSoql.toList(value)?.contains('') == true;
			return hasEmptyText == false && isSimple == true;
		}

		/**
		 * @description Merges what it can into one query, runs the remaining variants one query each, then renders each
		 * variant's query string once for all its interviews
		 */
		private void run() {
			Integer index = this.findVaryingIndex();
			List<InvocableSoql.Variant> mergeable = this.getMergeable(index);
			if (mergeable?.size() > 1) {
				this.runMerged(index, mergeable);
			}
			for (InvocableSoql.Variant variant : this.variants?.values()) {
				if (variant?.records == null) {
					Soql builder = this.query?.toSoql(variant?.values, this.accessLevel);
					variant.records = this.runQuery(builder);
				}
				variant.queryString = this.query?.toQueryString(variant?.values, this.accessLevel);
			}
		}

		/**
		 * @description Unions the varying condition's values into one query, then splits its rows by that field. Each
		 * row keeps its query order within each variant
		 * @param index The varying condition's index
		 * @param mergeable The variants to merge
		 */
		private void runMerged(Integer index, List<InvocableSoql.Variant> mergeable) {
			InvocableSoql.Splitter splitter = new InvocableSoql.Splitter(this.query, index, mergeable);
			splitter.filteredIndexes = this.filteredIndexes;
			List<Object> values = mergeable?.get(0)?.values?.clone();
			Object mergedValue = splitter?.getMergedValue();
			values?.set(index, mergedValue);
			Soql merged = this.query?.toMergedSoql(values, this.filteredIndexes, this.accessLevel);
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
		 * @description Matches like SOQL would
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
				isMatch = candidate?.equals(this.key);
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
			this.key = InvocableSoql.toKey(text, isCaseSensitive);
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

	/** @description Splits a merged query's rows back to each variant, by the varying condition's field **/
	private class Splitter {
		/** @description Conditions the merged query left out, which each row must pass for each variant **/
		private Set<Integer> filteredIndexes = new Set<Integer>{};
		private Integer index;
		private Boolean isCaseSensitive;
		private Boolean isPattern;
		/** @description Each variant's LIKE pattern, by position; empty for EQUALS and IN **/
		private List<InvocableSoql.LikePattern> patterns = new List<InvocableSoql.LikePattern>{};
		private InvocableSoql.Query query;
		/** @description Each EQUALS or IN value's variants, by key; positions, so a duplicate value adds a row once **/
		private Map<String, Set<Integer>> variantsByKey = new Map<String, Set<Integer>>{};
		private List<InvocableSoql.Variant> variants;

		/**
		 * @description Indexes each variant's values for matching rows
		 * @param query The query
		 * @param index The varying condition's index
		 * @param variants The variants to split rows between
		 */
		private Splitter(InvocableSoql.Query query, Integer index, List<InvocableSoql.Variant> variants) {
			this.index = index;
			this.isCaseSensitive = query?.isCaseSensitive(index);
			this.isPattern = query?.isPattern(index);
			this.query = query;
			this.variants = variants;
			for (Integer position = 0; position < variants?.size(); position++) {
				this.addVariant(position);
			}
		}

		/**
		 * @description Unions every variant's value, coerced as one list, since SOQL binds are strictly typed. EQUALS
		 * and LIKE bind a list as they would a single value, ex: `Name = :list` matches any of them
		 * @return The merged value
		 */
		private Object getMergedValue() {
			List<Object> merged = new List<Object>{};
			for (InvocableSoql.Variant variant : this.variants) {
				Object value = variant?.values?.get(this.index);
				List<Object> values = InvocableSoql.toList(value);
				merged?.addAll(values);
			}
			return this.query?.coerce(this.index, merged);
		}

		/**
		 * @description Gives each variant the rows that match its values, in query order, then applies OFFSET and LIMIT
		 * @param rows The merged query's rows
		 */
		private void split(List<SObject> rows) {
			for (InvocableSoql.Variant variant : this.variants) {
				variant.records = new List<SObject>{};
			}
			for (SObject row : rows) {
				this.addRow(row);
			}
			for (InvocableSoql.Variant variant : this.variants) {
				variant.records = this.query?.page(variant?.records);
			}
		}

		/**
		 * @description Adds a row to each variant it belongs to
		 * @param row A row from the merged query
		 */
		private void addRow(SObject row) {
			for (InvocableSoql.Variant variant : this.match(row)) {
				if (this.passesFilters(row, variant) == true) {
					variant?.records?.add(row);
				}
			}
		}

		/**
		 * @description Applies each condition the merged query left out: an ID's Not Equals
		 * @param row A row from the merged query
		 * @param variant A variant the row matches by the varying field
		 * @return Whether the row passes them for the variant
		 */
		private Boolean passesFilters(SObject row, InvocableSoql.Variant variant) {
			Boolean isPassing = true;
			for (Integer filteredIndex : this.filteredIndexes) {
				Object fieldValue = this.query?.getFieldValue(row, filteredIndex);
				Object excludedValue = variant?.values?.get(filteredIndex);
				isPassing &= fieldValue != excludedValue;
			}
			return isPassing;
		}

		/**
		 * @description Lists the variants a row belongs to
		 * @param row A row from the merged query
		 * @return The row's variants
		 */
		private List<InvocableSoql.Variant> match(SObject row) {
			Object fieldValue = this.query?.getFieldValue(row, this.index);
			String key = InvocableSoql.toKey(fieldValue, this.isCaseSensitive);
			return this.isPattern ? this.matchPatterns(key) : this.matchKeys(key);
		}

		/**
		 * @description Indexes a variant's value: its pattern, or a key per EQUALS or IN value
		 * @param position The variant's position in `variants`
		 */
		private void addVariant(Integer position) {
			Object value = this.variants?.get(position)?.values?.get(this.index);
			if (this.isPattern == true) {
				InvocableSoql.LikePattern pattern = new InvocableSoql.LikePattern((String) value, this.isCaseSensitive);
				this.patterns?.add(pattern);
			} else {
				for (Object element : InvocableSoql.toList(value)) {
					String key = InvocableSoql.toKey(element, this.isCaseSensitive);
					Set<Integer> positions = this.variantsByKey?.get(key) ?? new Set<Integer>{};
					positions?.add(position);
					this.variantsByKey?.put(key, positions);
				}
			}
		}

		/**
		 * @description Looks up the row's value by key
		 * @param key The row's key for the varying field
		 * @return The variants with that value
		 */
		private List<InvocableSoql.Variant> matchKeys(String key) {
			List<InvocableSoql.Variant> matches = new List<InvocableSoql.Variant>{};
			for (Integer position : this.variantsByKey?.get(key) ?? new Set<Integer>{}) {
				InvocableSoql.Variant variant = this.variants?.get(position);
				matches?.add(variant);
			}
			return matches;
		}

		/**
		 * @description Tests the row's value against each variant's pattern
		 * @param key The row's key for the varying field
		 * @return The variants whose pattern matches
		 */
		private List<InvocableSoql.Variant> matchPatterns(String key) {
			List<InvocableSoql.Variant> matches = new List<InvocableSoql.Variant>{};
			for (Integer position = 0; position < this.patterns?.size(); position++) {
				if (this.patterns?.get(position)?.matches(key) == true) {
					InvocableSoql.Variant variant = this.variants?.get(position);
					matches?.add(variant);
				}
			}
			return matches;
		}
	}

	/** @description A distinct set of values in a batch: the interviews that share it share its query and rows **/
	private class Variant {
		private String queryString;
		/** @description Null until a query fills it, so the batch can tell which variants still need one **/
		private List<SObject> records;
		/** @description Each value as JSON, to tell variants apart and find the condition that differs **/
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
