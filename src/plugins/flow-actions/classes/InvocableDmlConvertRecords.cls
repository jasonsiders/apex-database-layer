public abstract class InvocableDmlConvertRecords {
	@InvocableMethod(
		category='Database Layer'
		label='Convert Record(s)'
		iconName='slds:standard:maintenance_work_rule'
		configurationEditor='c-dml-property
	)
	public static List<InvocableDmlConvertRecords.Output> invoke(List<InvocableDmlConvertRecords.Input> inputs) {
		return new List<InvocableDmlConvertRecords.Output>{};
	}

	public class Input {
		@InvocableVariable(
			label='Access Level'
			defaultValue='USER_MODE'
			description='Specifies whether the method runs in SYSTEM_MODE or USER_MODE [default]. In system mode, the object and field-level permissions of the current user are ignored, and the record sharing rules are controlled the flow. In user mode, the object permissions, field-level security, and sharing rules of the current user are enforced.'
		)
		public String accessLevelName;

		@InvocableVariable(
			label='All Or None'
			defaultValue='true'
			description='Specifies whether the operation allows partial success. If set to false and any record fails, the remainder of the DML operation can still succeed. If true [default] and any record fails, an exception is thrown.'
		)
		public Boolean allOrNone;

		@InvocableVariable(label='DML Options' description='Specifies additional data for the transaction')
		public FlowDmlOptions dmlOptions;

		@InvocableVariable(label='Lead ID' description='The ID of the Lead to be converted')
		public Id leadId;

		@InvocableVariable(
			label='Account ID'
			description='The ID of an existing Account to merge the converted lead into. If not specified, a new Account is created.'
		)
		public Id accountId;

		@InvocableVariable(
			label='Account Name'
			description='The name of the Account to create during lead conversion. Ignored if Account ID is specified.'
		)
		public String accountName;

		@InvocableVariable(
			label='Contact ID'
			description='The ID of an existing Contact to merge the converted lead into. If not specified, a new Contact is created.'
		)
		public Id contactId;

		@InvocableVariable(
			label='Converted Status'
			description='The Lead status value to set on conversion. Must be a Lead status with the "Converted" category.'
		)
		public String convertedStatus;

		@InvocableVariable(
			label='Do Not Create Opportunity'
			defaultValue='false'
			description='If true, no Opportunity is created when the lead is converted.'
		)
		public Boolean doNotCreateOpportunity;

		@InvocableVariable(
			label='Opportunity ID'
			description='The ID of an existing Opportunity to attach the converted lead to.'
		)
		public Id opportunityId;

		@InvocableVariable(
			label='Opportunity Name'
			description='The name of the Opportunity to create during lead conversion. Ignored if Do Not Create Opportunity is true or Opportunity ID is specified.'
		)
		public String opportunityName;

		@InvocableVariable(
			label='Overwrite Lead Source'
			defaultValue='false'
			description='If true, overwrites the LeadSource field on the target Contact and Account with the value from the Lead.'
		)
		public Boolean overwriteLeadSource;

		@InvocableVariable(
			label='Owner ID'
			description='The ID of the user to own any newly-created records. Defaults to the owner of the Lead.'
		)
		public Id ownerId;

		@InvocableVariable(
			label='Send Notification Email'
			defaultValue='false'
			description='If true, sends a notification email to the owner of the Account, Contact, or Opportunity.'
		)
		public Boolean sendNotificationEmail;

		public Input() {
			this.accessLevelName = System.AccessLevel.USER_MODE.toString();
			this.allOrNone = true;
			this.doNotCreateOpportunity = false;
			this.overwriteLeadSource = false;
			this.sendNotificationEmail = false;
		}
	}

	public class Output {
		@InvocableVariable(label='Leads')
		public List<Lead> leads;

		@InvocableVariable(label='Results')
		public List<FlowDmlConvertResult> results;

		public Output() {
			this.leads = new List<Lead>{};
			this.results = new List<FlowDmlConvertResult>{};
		}
	}
}
