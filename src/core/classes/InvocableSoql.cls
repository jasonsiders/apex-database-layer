/**
 * @description Flow action that queries records via `DatabaseLayer.Soql`, from a query built in its editor: parent
 * fields, the access level, and values from flow resources. See `InvocableSoqlPlanner` for how a bulk run shares queries
 */
public inherited sharing class InvocableSoql {
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
		return new InvocableSoqlPlanner()?.run(inputs);
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
		for (SObjectField field : InvocableDml.describeFields(objectApiName)) {
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

	// **** INNER **** //
	/** @description A field the editor offers, with what it needs to build conditions on it **/
	public class FieldOption {
		/** @description The field's API name **/
		@AuraEnabled
		public String apiName;
		/** @description Conditions can only use filterable fields **/
		@AuraEnabled
		public Boolean isFilterable;
		/** @description A lookup to several objects, ex: Task.WhoId, takes record collections of any object **/
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
			String parentName = Soql.toEntityName(parents);
			Boolean isId = field?.getType() == Schema.DisplayType.ID;
			this.apiName = field?.getName();
			this.isFilterable = field?.isFilterable();
			this.isPolymorphic = parents?.size() > 1;
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
			description='USER_MODE (default) enforces the running user\'s object permissions, field-level security, and sharing rules. SYSTEM_MODE ignores object permissions and field-level security, but sharing rules still apply.'
		)
		public String accessLevel;

		/** @description JSON, read by `InvocableSoqlQuery`; the action's editor writes it **/
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
		/** @description A text value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Text 6'
			description='A text value for a query condition. The action\'s editor assigns it.'
		)
		public String text6;
		/** @description A text value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Text 7'
			description='A text value for a query condition. The action\'s editor assigns it.'
		)
		public String text7;
		/** @description A text value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Text 8'
			description='A text value for a query condition. The action\'s editor assigns it.'
		)
		public String text8;
		/** @description A text value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Text 9'
			description='A text value for a query condition. The action\'s editor assigns it.'
		)
		public String text9;
		/** @description A text value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Text 10'
			description='A text value for a query condition. The action\'s editor assigns it.'
		)
		public String text10;

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
		/** @description A number value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Number 6'
			description='A number value for a query condition. The action\'s editor assigns it.'
		)
		public Decimal number6;
		/** @description A number value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Number 7'
			description='A number value for a query condition. The action\'s editor assigns it.'
		)
		public Decimal number7;
		/** @description A number value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Number 8'
			description='A number value for a query condition. The action\'s editor assigns it.'
		)
		public Decimal number8;
		/** @description A number value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Number 9'
			description='A number value for a query condition. The action\'s editor assigns it.'
		)
		public Decimal number9;
		/** @description A number value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Number 10'
			description='A number value for a query condition. The action\'s editor assigns it.'
		)
		public Decimal number10;

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
		/** @description A date value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Date 6'
			description='A date value for a query condition. The action\'s editor assigns it.'
		)
		public Date date6;
		/** @description A date value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Date 7'
			description='A date value for a query condition. The action\'s editor assigns it.'
		)
		public Date date7;
		/** @description A date value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Date 8'
			description='A date value for a query condition. The action\'s editor assigns it.'
		)
		public Date date8;
		/** @description A date value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Date 9'
			description='A date value for a query condition. The action\'s editor assigns it.'
		)
		public Date date9;
		/** @description A date value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Date 10'
			description='A date value for a query condition. The action\'s editor assigns it.'
		)
		public Date date10;

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
		/** @description A date/time value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Date/Time 6'
			description='A date/time value for a query condition. The action\'s editor assigns it.'
		)
		public DateTime dateTime6;
		/** @description A date/time value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Date/Time 7'
			description='A date/time value for a query condition. The action\'s editor assigns it.'
		)
		public DateTime dateTime7;
		/** @description A date/time value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Date/Time 8'
			description='A date/time value for a query condition. The action\'s editor assigns it.'
		)
		public DateTime dateTime8;
		/** @description A date/time value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Date/Time 9'
			description='A date/time value for a query condition. The action\'s editor assigns it.'
		)
		public DateTime dateTime9;
		/** @description A date/time value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Date/Time 10'
			description='A date/time value for a query condition. The action\'s editor assigns it.'
		)
		public DateTime dateTime10;

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
		/** @description A time value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Time 6'
			description='A time value for a query condition. The action\'s editor assigns it.'
		)
		public Time time6;
		/** @description A time value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Time 7'
			description='A time value for a query condition. The action\'s editor assigns it.'
		)
		public Time time7;
		/** @description A time value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Time 8'
			description='A time value for a query condition. The action\'s editor assigns it.'
		)
		public Time time8;
		/** @description A time value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Time 9'
			description='A time value for a query condition. The action\'s editor assigns it.'
		)
		public Time time9;
		/** @description A time value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Time 10'
			description='A time value for a query condition. The action\'s editor assigns it.'
		)
		public Time time10;

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
		/** @description A boolean value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Boolean 6'
			description='A boolean value for a query condition. The action\'s editor assigns it.'
		)
		public Boolean boolean6;
		/** @description A boolean value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Boolean 7'
			description='A boolean value for a query condition. The action\'s editor assigns it.'
		)
		public Boolean boolean7;
		/** @description A boolean value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Boolean 8'
			description='A boolean value for a query condition. The action\'s editor assigns it.'
		)
		public Boolean boolean8;
		/** @description A boolean value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Boolean 9'
			description='A boolean value for a query condition. The action\'s editor assigns it.'
		)
		public Boolean boolean9;
		/** @description A boolean value for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Boolean 10'
			description='A boolean value for a query condition. The action\'s editor assigns it.'
		)
		public Boolean boolean10;

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
		/** @description A collection of text values for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Text Collection 6'
			description='A collection of text values for a query condition. The action\'s editor assigns it.'
		)
		public List<String> textCollection6;
		/** @description A collection of text values for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Text Collection 7'
			description='A collection of text values for a query condition. The action\'s editor assigns it.'
		)
		public List<String> textCollection7;
		/** @description A collection of text values for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Text Collection 8'
			description='A collection of text values for a query condition. The action\'s editor assigns it.'
		)
		public List<String> textCollection8;
		/** @description A collection of text values for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Text Collection 9'
			description='A collection of text values for a query condition. The action\'s editor assigns it.'
		)
		public List<String> textCollection9;
		/** @description A collection of text values for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Text Collection 10'
			description='A collection of text values for a query condition. The action\'s editor assigns it.'
		)
		public List<String> textCollection10;

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
		/** @description A collection of number values for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Number Collection 6'
			description='A collection of number values for a query condition. The action\'s editor assigns it.'
		)
		public List<Decimal> numberCollection6;
		/** @description A collection of number values for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Number Collection 7'
			description='A collection of number values for a query condition. The action\'s editor assigns it.'
		)
		public List<Decimal> numberCollection7;
		/** @description A collection of number values for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Number Collection 8'
			description='A collection of number values for a query condition. The action\'s editor assigns it.'
		)
		public List<Decimal> numberCollection8;
		/** @description A collection of number values for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Number Collection 9'
			description='A collection of number values for a query condition. The action\'s editor assigns it.'
		)
		public List<Decimal> numberCollection9;
		/** @description A collection of number values for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Number Collection 10'
			description='A collection of number values for a query condition. The action\'s editor assigns it.'
		)
		public List<Decimal> numberCollection10;

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
		/** @description A collection of date values for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Date Collection 6'
			description='A collection of date values for a query condition. The action\'s editor assigns it.'
		)
		public List<Date> dateCollection6;
		/** @description A collection of date values for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Date Collection 7'
			description='A collection of date values for a query condition. The action\'s editor assigns it.'
		)
		public List<Date> dateCollection7;
		/** @description A collection of date values for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Date Collection 8'
			description='A collection of date values for a query condition. The action\'s editor assigns it.'
		)
		public List<Date> dateCollection8;
		/** @description A collection of date values for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Date Collection 9'
			description='A collection of date values for a query condition. The action\'s editor assigns it.'
		)
		public List<Date> dateCollection9;
		/** @description A collection of date values for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Date Collection 10'
			description='A collection of date values for a query condition. The action\'s editor assigns it.'
		)
		public List<Date> dateCollection10;

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
		/** @description A collection of date/time values for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Date/Time Collection 6'
			description='A collection of date/time values for a query condition. The action\'s editor assigns it.'
		)
		public List<DateTime> dateTimeCollection6;
		/** @description A collection of date/time values for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Date/Time Collection 7'
			description='A collection of date/time values for a query condition. The action\'s editor assigns it.'
		)
		public List<DateTime> dateTimeCollection7;
		/** @description A collection of date/time values for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Date/Time Collection 8'
			description='A collection of date/time values for a query condition. The action\'s editor assigns it.'
		)
		public List<DateTime> dateTimeCollection8;
		/** @description A collection of date/time values for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Date/Time Collection 9'
			description='A collection of date/time values for a query condition. The action\'s editor assigns it.'
		)
		public List<DateTime> dateTimeCollection9;
		/** @description A collection of date/time values for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Date/Time Collection 10'
			description='A collection of date/time values for a query condition. The action\'s editor assigns it.'
		)
		public List<DateTime> dateTimeCollection10;

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
		/** @description A collection of records, matched by their IDs for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Record Collection 6'
			description='A collection of records, matched by their IDs for a query condition. The action\'s editor assigns it.'
		)
		public List<SObject> recordCollection6;
		/** @description A collection of records, matched by their IDs for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Record Collection 7'
			description='A collection of records, matched by their IDs for a query condition. The action\'s editor assigns it.'
		)
		public List<SObject> recordCollection7;
		/** @description A collection of records, matched by their IDs for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Record Collection 8'
			description='A collection of records, matched by their IDs for a query condition. The action\'s editor assigns it.'
		)
		public List<SObject> recordCollection8;
		/** @description A collection of records, matched by their IDs for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Record Collection 9'
			description='A collection of records, matched by their IDs for a query condition. The action\'s editor assigns it.'
		)
		public List<SObject> recordCollection9;
		/** @description A collection of records, matched by their IDs for a condition; the action's editor assigns it **/
		@InvocableVariable(
			label='Record Collection 10'
			description='A collection of records, matched by their IDs for a query condition. The action\'s editor assigns it.'
		)
		public List<SObject> recordCollection10;

		/**
		 * @description Parsed by `InvocableDml.toAccessLevel`, like the DML actions
		 * @return The matching System.AccessLevel
		 * @throws System.IllegalArgumentException When the value isn't blank, USER_MODE, or SYSTEM_MODE
		 */
		public System.AccessLevel getAccessLevel() {
			return InvocableDml.toAccessLevel(this.accessLevel);
		}

		/**
		 * @description Reads a slot by name, since Apex can't read a field by name
		 * @param name The slot's name, ex: "text1"
		 * @return The slot's value
		 * @throws System.IllegalArgumentException When no slot has that name
		 */
		public Object getSlotValue(String name) {
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
				'text6' => this.text6,
				'text7' => this.text7,
				'text8' => this.text8,
				'text9' => this.text9,
				'text10' => this.text10,
				'number1' => this.number1,
				'number2' => this.number2,
				'number3' => this.number3,
				'number4' => this.number4,
				'number5' => this.number5,
				'number6' => this.number6,
				'number7' => this.number7,
				'number8' => this.number8,
				'number9' => this.number9,
				'number10' => this.number10,
				'date1' => this.date1,
				'date2' => this.date2,
				'date3' => this.date3,
				'date4' => this.date4,
				'date5' => this.date5,
				'date6' => this.date6,
				'date7' => this.date7,
				'date8' => this.date8,
				'date9' => this.date9,
				'date10' => this.date10,
				'dateTime1' => this.dateTime1,
				'dateTime2' => this.dateTime2,
				'dateTime3' => this.dateTime3,
				'dateTime4' => this.dateTime4,
				'dateTime5' => this.dateTime5,
				'dateTime6' => this.dateTime6,
				'dateTime7' => this.dateTime7,
				'dateTime8' => this.dateTime8,
				'dateTime9' => this.dateTime9,
				'dateTime10' => this.dateTime10,
				'time1' => this.time1,
				'time2' => this.time2,
				'time3' => this.time3,
				'time4' => this.time4,
				'time5' => this.time5,
				'time6' => this.time6,
				'time7' => this.time7,
				'time8' => this.time8,
				'time9' => this.time9,
				'time10' => this.time10,
				'boolean1' => this.boolean1,
				'boolean2' => this.boolean2,
				'boolean3' => this.boolean3,
				'boolean4' => this.boolean4,
				'boolean5' => this.boolean5,
				'boolean6' => this.boolean6,
				'boolean7' => this.boolean7,
				'boolean8' => this.boolean8,
				'boolean9' => this.boolean9,
				'boolean10' => this.boolean10,
				'textCollection1' => this.textCollection1,
				'textCollection2' => this.textCollection2,
				'textCollection3' => this.textCollection3,
				'textCollection4' => this.textCollection4,
				'textCollection5' => this.textCollection5,
				'textCollection6' => this.textCollection6,
				'textCollection7' => this.textCollection7,
				'textCollection8' => this.textCollection8,
				'textCollection9' => this.textCollection9,
				'textCollection10' => this.textCollection10,
				'numberCollection1' => this.numberCollection1,
				'numberCollection2' => this.numberCollection2,
				'numberCollection3' => this.numberCollection3,
				'numberCollection4' => this.numberCollection4,
				'numberCollection5' => this.numberCollection5,
				'numberCollection6' => this.numberCollection6,
				'numberCollection7' => this.numberCollection7,
				'numberCollection8' => this.numberCollection8,
				'numberCollection9' => this.numberCollection9,
				'numberCollection10' => this.numberCollection10,
				'dateCollection1' => this.dateCollection1,
				'dateCollection2' => this.dateCollection2,
				'dateCollection3' => this.dateCollection3,
				'dateCollection4' => this.dateCollection4,
				'dateCollection5' => this.dateCollection5,
				'dateCollection6' => this.dateCollection6,
				'dateCollection7' => this.dateCollection7,
				'dateCollection8' => this.dateCollection8,
				'dateCollection9' => this.dateCollection9,
				'dateCollection10' => this.dateCollection10,
				'dateTimeCollection1' => this.dateTimeCollection1,
				'dateTimeCollection2' => this.dateTimeCollection2,
				'dateTimeCollection3' => this.dateTimeCollection3,
				'dateTimeCollection4' => this.dateTimeCollection4,
				'dateTimeCollection5' => this.dateTimeCollection5,
				'dateTimeCollection6' => this.dateTimeCollection6,
				'dateTimeCollection7' => this.dateTimeCollection7,
				'dateTimeCollection8' => this.dateTimeCollection8,
				'dateTimeCollection9' => this.dateTimeCollection9,
				'dateTimeCollection10' => this.dateTimeCollection10,
				'recordCollection1' => this.recordCollection1,
				'recordCollection2' => this.recordCollection2,
				'recordCollection3' => this.recordCollection3,
				'recordCollection4' => this.recordCollection4,
				'recordCollection5' => this.recordCollection5,
				'recordCollection6' => this.recordCollection6,
				'recordCollection7' => this.recordCollection7,
				'recordCollection8' => this.recordCollection8,
				'recordCollection9' => this.recordCollection9,
				'recordCollection10' => this.recordCollection10
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
}
