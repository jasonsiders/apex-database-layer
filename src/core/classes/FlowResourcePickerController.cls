/**
 * @description Describes objects for the `flowResourcePicker` component, so it can drill into record fields the way
 * Flow Builder's own resource picker does.
 */
public with sharing class FlowResourcePickerController {
	/**
	 * @description Describes an object's labels and fields.
	 * @param objectApiName The API name of the object to describe
	 * @return The object's describe
	 * @throws System.AuraHandledException if the object doesn't exist
	 */
	@AuraEnabled(cacheable=true)
	public static FlowResourcePickerController.ObjectDescribe describeObject(String objectApiName) {
		try {
			List<String> objectApiNames = new List<String>{ objectApiName };
			Schema.DescribeSObjectResult describe = Schema.describeSObjects(objectApiNames)?.get(0);
			return new FlowResourcePickerController.ObjectDescribe(describe);
		} catch (System.InvalidParameterValueException error) {
			throw new System.AuraHandledException(error?.getMessage());
		}
	}

	// **** INNER **** //
	/**
	 * @description An object's labels and fields.
	 */
	public class ObjectDescribe {
		/**
		 * @description The object's API name.
		 */
		@AuraEnabled
		public String apiName;
		/**
		 * @description The object's fields.
		 */
		@AuraEnabled
		public List<FlowResourcePickerController.FieldDescribe> fields;
		/**
		 * @description The object's singular label.
		 */
		@AuraEnabled
		public String label;
		/**
		 * @description The object's plural label.
		 */
		@AuraEnabled
		public String labelPlural;

		/**
		 * @description Creates a describe from the object's schema.
		 * @param describe The object's schema describe
		 */
		private ObjectDescribe(Schema.DescribeSObjectResult describe) {
			this.apiName = describe?.getName();
			this.fields = new List<FlowResourcePickerController.FieldDescribe>();
			this.label = describe?.getLabel();
			this.labelPlural = describe?.getLabelPlural();
			for (Schema.SObjectField field : describe?.fields?.getMap()?.values()) {
				Schema.DescribeFieldResult fieldDescribe = field?.getDescribe();
				this.fields?.add(new FlowResourcePickerController.FieldDescribe(fieldDescribe));
			}
		}
	}

	/**
	 * @description A field's label, type, and lookup details.
	 */
	public class FieldDescribe {
		/**
		 * @description The field's API name.
		 */
		@AuraEnabled
		public String apiName;
		/**
		 * @description The field's `Schema.DisplayType` name, ex: `STRING`.
		 */
		@AuraEnabled
		public String dataType;
		/**
		 * @description The field's label.
		 */
		@AuraEnabled
		public String label;
		/**
		 * @description For lookups, the API names of the objects it can point to.
		 */
		@AuraEnabled
		public List<String> referenceTo;
		/**
		 * @description For lookups, the relationship name used in merge fields, ex: `Owner`.
		 */
		@AuraEnabled
		public String relationshipName;

		/**
		 * @description Creates a describe from the field's schema.
		 * @param describe The field's schema describe
		 */
		private FieldDescribe(Schema.DescribeFieldResult describe) {
			this.apiName = describe?.getName();
			this.dataType = describe?.getType()?.name();
			this.label = describe?.getLabel();
			this.referenceTo = new List<String>();
			this.relationshipName = describe?.getRelationshipName();
			for (Schema.SObjectType objectType : describe?.getReferenceTo()) {
				this.referenceTo?.add(objectType?.toString());
			}
		}
	}
}
