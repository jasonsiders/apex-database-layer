/**
 * @description Flow Builder's own picker drills into record fields; `flowResourcePicker` needs these describes to do
 * the same, at any depth, which the getObjectInfo wire adapter can't fetch on demand
 */
public with sharing class FlowResourcePickerController {
	// **** PUBLIC **** //
	/**
	 * @description Cacheable, so repeat describes of an object are served from the client cache
	 * @param objectApiName The API name of the object to describe
	 * @return The object's labels and fields
	 * @throws System.AuraHandledException if the object doesn't exist
	 */
	@AuraEnabled(cacheable=true)
	public static FlowResourcePickerController.ObjectDescribe describeObject(String objectApiName) {
		try {
			Schema.DescribeSObjectResult describe = FlowResourcePickerController.describe(objectApiName);
			return new FlowResourcePickerController.ObjectDescribe(describe);
		} catch (System.InvalidParameterValueException error) {
			String message = error?.getMessage();
			throw new System.AuraHandledException(message);
		}
	}

	// **** PRIVATE **** //
	/**
	 * @description Defers child relationships, which the picker never shows
	 * @param objectApiName The API name of the object to describe
	 * @return The object's schema describe
	 */
	private static Schema.DescribeSObjectResult describe(String objectApiName) {
		List<String> objectApiNames = new List<String>{ objectApiName };
		return Schema.describeSObjects(objectApiNames, SObjectDescribeOptions.DEFERRED)?.get(0);
	}

	/**
	 * @description The picker lists every field, so each one is described
	 * @param describe The object's schema describe
	 * @return The object's fields
	 */
	private static List<FlowResourcePickerController.FieldDescribe> describeFields(
		Schema.DescribeSObjectResult describe
	) {
		List<FlowResourcePickerController.FieldDescribe> fields = new List<FlowResourcePickerController.FieldDescribe>{};
		for (Schema.SObjectField field : describe?.fields?.getMap()?.values()) {
			Schema.DescribeFieldResult fieldDescribe = field?.getDescribe();
			FlowResourcePickerController.FieldDescribe fieldDetails = new FlowResourcePickerController.FieldDescribe(
				fieldDescribe
			);
			fields?.add(fieldDetails);
		}
		return fields;
	}

	/**
	 * @description SObjectTypes don't serialize to LWC, so lookups report their targets by name
	 * @param objectTypes The objects a lookup can point to
	 * @return The objects' API names
	 */
	private static List<String> toObjectNames(List<Schema.SObjectType> objectTypes) {
		List<String> objectNames = new List<String>{};
		for (Schema.SObjectType objectType : objectTypes) {
			String objectName = objectType?.toString();
			objectNames?.add(objectName);
		}
		return objectNames;
	}

	// **** INNER **** //
	/** @description Just what the picker shows, since full describes are large and don't serialize **/
	public class ObjectDescribe {
		/** @description Identifies the object when resolving drilled references **/
		@AuraEnabled
		public String apiName;
		/** @description Listed when drilling into a record **/
		@AuraEnabled
		public List<FlowResourcePickerController.FieldDescribe> fields;
		/** @description Labels single-record Get Records outputs, ex: "Account from Get Account" **/
		@AuraEnabled
		public String label;
		/** @description Labels Get Records collection outputs, ex: "Accounts from Get Accounts" **/
		@AuraEnabled
		public String labelPlural;

		/**
		 * @description Copies the object's labels and fields into serializable properties
		 * @param describe The object's schema describe
		 */
		private ObjectDescribe(Schema.DescribeSObjectResult describe) {
			this.apiName = describe?.getName();
			this.fields = FlowResourcePickerController.describeFields(describe);
			this.label = describe?.getLabel();
			this.labelPlural = describe?.getLabelPlural();
		}
	}

	/** @description Just what the picker shows for a field, and what it needs to drill through lookups **/
	public class FieldDescribe {
		/** @description The last segment of a drilled reference, ex: `Email` **/
		@AuraEnabled
		public String apiName;
		/** @description The Schema.DisplayType name, ex: `STRING`, which the picker maps to Flow's data types **/
		@AuraEnabled
		public String dataType;
		/** @description Shown in the menu and in pill labels **/
		@AuraEnabled
		public String label;
		/** @description For lookups, the objects to drill into **/
		@AuraEnabled
		public List<String> referenceTo;
		/** @description For lookups, the merge field segment, ex: `Owner` in `{!accountVar.Owner.Email}` **/
		@AuraEnabled
		public String relationshipName;

		/**
		 * @description Copies the field's label, type, and lookup details into serializable properties
		 * @param describe The field's schema describe
		 */
		private FieldDescribe(Schema.DescribeFieldResult describe) {
			List<Schema.SObjectType> objectTypes = describe?.getReferenceTo();
			this.apiName = describe?.getName();
			this.dataType = describe?.getType()?.name();
			this.label = describe?.getLabel();
			this.referenceTo = FlowResourcePickerController.toObjectNames(objectTypes);
			this.relationshipName = describe?.getRelationshipName();
		}
	}
}
