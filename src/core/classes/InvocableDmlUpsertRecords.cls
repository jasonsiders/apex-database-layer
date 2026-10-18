/**
 * @description Flow action that upserts records via `DatabaseLayer.Dml`, exposing the external ID field, access level, and
 * all-or-none behavior
 */
public inherited sharing class InvocableDmlUpsertRecords extends InvocableDml {
	// **** PUBLIC **** //
	/**
	 * @description Upserts every input's records in a single DML operation, using the first input's settings
	 * @param inputs One input per flow interview
	 * @return One output per input, in the same order
	 */
	@InvocableMethod(
		category='Database Layer'
		configurationEditor='c-dml-records-editor'
		description='Insert or update one or more records, matched by ID or an external ID field, with control over the access level and partial success.'
		iconName='slds:standard:record'
		label='Upsert Records'
	)
	public static List<InvocableDml.Output> invoke(List<InvocableDml.Input> inputs) {
		return new InvocableDmlUpsertRecords()?.run(inputs);
	}

	/**
	 * @description Lists the fields the action's editor offers to match records on, like Flow Builder's own upsert;
	 * Apex, unlike UI API, can tell which standard fields are ID lookups
	 * @param objectApiName The object to upsert, ex: "Account"
	 * @return The object's accessible external ID fields and standard ID lookup fields, except Id
	 */
	@AuraEnabled(cacheable=true)
	public static List<InvocableDmlUpsertRecords.MatchField> getMatchFields(String objectApiName) {
		List<InvocableDmlUpsertRecords.MatchField> matchFields = new List<InvocableDmlUpsertRecords.MatchField>{};
		for (SObjectField field : InvocableDmlUpsertRecords.describeFields(objectApiName)) {
			DescribeFieldResult describe = field?.getDescribe();
			if (InvocableDmlUpsertRecords.isMatchable(describe)) {
				InvocableDmlUpsertRecords.MatchField matchField = new InvocableDmlUpsertRecords.MatchField(describe);
				matchFields?.add(matchField);
			}
		}
		return matchFields;
	}

	// **** PROTECTED **** //
	/**
	 * @description Goes through DatabaseLayer.Dml, so plugins and MockDml apply to flows too
	 * @param records The records to upsert
	 * @param settings The input whose settings apply to the operation
	 * @return The results, in record order
	 */
	protected override List<InvocableDmlResult> doDml(List<SObject> records, InvocableDml.Input settings) {
		SObjectField externalIdField = InvocableDmlUpsertRecords.getExternalIdField(records, settings?.externalIdField);
		Boolean allOrNone = settings?.toAllOrNone();
		System.AccessLevel accessLevel = settings?.toAccessLevel();
		List<Database.UpsertResult> results = DatabaseLayer.Dml
			?.doUpsert(records, externalIdField, allOrNone, accessLevel);
		return InvocableDmlResult.fromList(results);
	}

	// **** PRIVATE **** //
	/**
	 * @description The editor calls this through Lightning, which only shows an AuraHandledException's message
	 * @param objectApiName The object to describe
	 * @return The object's fields
	 * @throws System.AuraHandledException When the object doesn't exist
	 */
	private static List<SObjectField> describeFields(String objectApiName) {
		List<String> objectApiNames = new List<String>{ objectApiName };
		try {
			List<DescribeSObjectResult> objects = Schema.describeSObjects(
				objectApiNames,
				SObjectDescribeOptions.DEFERRED
			);
			return objects?.get(0)?.fields?.getMap()?.values();
		} catch (System.InvalidParameterValueException error) {
			throw new System.AuraHandledException(error?.getMessage());
		}
	}

	/**
	 * @description Upserts can match on external ID fields and standard ID lookup fields; Id is the default, so the
	 * editor offers it separately
	 * @param field The field to check
	 * @return Whether the running user can upsert on the field
	 */
	private static Boolean isMatchable(DescribeFieldResult field) {
		Boolean isStandardLookup =
			field?.isIdLookup() == true &&
			field?.isCustom() == false &&
			field?.getName() != 'Id';
		return field?.isAccessible() == true && (field?.isExternalId() == true || isStandardLookup);
	}

	/**
	 * @description Flow passes the field by name; an unknown name throws, since upserting on Ids instead could duplicate
	 * records
	 * @param records The records to upsert; the first one supplies the object
	 * @param fieldName The external ID field API name, or blank to match on Id
	 * @return The field, or null when the name is blank
	 */
	private static SObjectField getExternalIdField(List<SObject> records, String fieldName) {
		SObjectField field;
		if (String.isNotBlank(fieldName)) {
			SObjectType objectType = records?.get(0)?.getSObjectType();
			Map<String, SObjectField> fields = objectType
				?.getDescribe(SObjectDescribeOptions.DEFERRED)
				?.fields
				?.getMap();
			String trimmedName = fieldName?.trim();
			field = fields?.get(trimmedName);
			if (field == null) {
				throw new IllegalArgumentException('Invalid external ID field for ' + objectType + ': ' + fieldName);
			}
		}
		return field;
	}

	// **** INNER **** //
	/** @description A field the editor offers to match records on **/
	public class MatchField {
		/** @description The editor lists fields by API name, like Flow Builder **/
		@AuraEnabled
		public String apiName;
		/** @description Splits the editor's External ID and Standard Field lists **/
		@AuraEnabled
		public Boolean isExternalId;
		/** @description Shown under the API name **/
		@AuraEnabled
		public String label;

		/**
		 * @description Copies the describe details the editor needs
		 * @param field The field's describe
		 */
		private MatchField(DescribeFieldResult field) {
			this.apiName = field?.getName();
			this.isExternalId = field?.isExternalId();
			this.label = field?.getLabel();
		}
	}
}
