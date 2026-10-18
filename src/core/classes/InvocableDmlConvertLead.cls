/**
 * @description Flow action that converts leads via `DatabaseLayer.Dml`, exposing the access level, all-or-none
 * behavior, and duplicate rule settings
 */
public inherited sharing class InvocableDmlConvertLead {
	// **** PUBLIC **** //
	/**
	 * @description Converts every input's lead in a single DML operation, using the first input's settings, so a bulk
	 * run can't exhaust the DML statement limit
	 * @param inputs One input per flow interview
	 * @return One output per input, in the same order
	 */
	@InvocableMethod(
		category='Database Layer'
		description='Convert one or more leads, with control over the access level, partial success, and duplicate rules.'
		iconName='slds:standard:lead'
		label='Convert Lead'
	)
	public static List<InvocableDmlConvertLead.Output> invoke(List<InvocableDmlConvertLead.Input> inputs) {
		List<InvocableDmlConvertLead.Output> outputs = new List<InvocableDmlConvertLead.Output>{};
		if (inputs?.isEmpty() == false) {
			List<Database.LeadConvertResult> results = InvocableDmlConvertLead.convertLeads(inputs);
			outputs = InvocableDmlConvertLead.initOutputs(results);
		}
		return outputs;
	}

	// **** PRIVATE **** //
	/**
	 * @description Goes through DatabaseLayer.Dml, so plugins and MockDml apply to flows too
	 * @param inputs One input per flow interview; the first one's settings apply to all
	 * @return The results, in input order
	 */
	private static List<Database.LeadConvertResult> convertLeads(List<InvocableDmlConvertLead.Input> inputs) {
		List<Database.LeadConvert> leadsToConvert = new List<Database.LeadConvert>{};
		for (InvocableDmlConvertLead.Input input : inputs) {
			Database.LeadConvert leadToConvert = input?.toLeadConvert();
			leadsToConvert?.add(leadToConvert);
		}
		InvocableDml.Input settings = inputs?.get(0)?.toSettings();
		Database.DmlOptions options = settings?.toDmlOptions();
		System.AccessLevel accessLevel = settings?.toAccessLevel();
		return DatabaseLayer.Dml?.doConvert(leadsToConvert, options, accessLevel);
	}

	/**
	 * @description Each input converts one lead, so outputs map one-to-one with results
	 * @param results The results of the conversion
	 * @return One output per result, in the same order
	 */
	private static List<InvocableDmlConvertLead.Output> initOutputs(List<Database.LeadConvertResult> results) {
		List<InvocableDmlConvertLead.Output> outputs = new List<InvocableDmlConvertLead.Output>{};
		for (Database.LeadConvertResult result : results) {
			InvocableDmlConvertLead.Output output = new InvocableDmlConvertLead.Output(result);
			outputs?.add(output);
		}
		return outputs;
	}

	// **** INNER **** //
	/** @description Flat, primitive inputs, mirroring Database.LeadConvert, so Flow's standard editor can set them **/
	public class Input {
		/** @description Text, not an enum, since Flow can't pass System.AccessLevel **/
		@InvocableVariable(
			label='Access Level'
			description='USER_MODE (default) enforces the running user\'s object permissions, field-level security, and sharing rules. SYSTEM_MODE ignores them.'
		)
		public String accessLevel;
		/** @description Maps to Database.LeadConvert.setAccountId **/
		@InvocableVariable(
			label='Account ID'
			description='An existing account to merge the lead into. When blank, the conversion creates an account.'
		)
		public Id accountId;
		/** @description Defaults to true, matching DML statements, so failures aren't silently ignored **/
		@InvocableVariable(
			label='All or None'
			description='When true (default), any failure rolls back every lead and fails the action. When false, valid leads are converted, and failures are reported in the results.'
		)
		public Boolean allOrNone;
		/** @description Maps to Database.DmlOptions.DuplicateRuleHeader.AllowSave **/
		@InvocableVariable(
			label='Allow Duplicates'
			description='Save accounts and contacts that a duplicate rule would otherwise alert on.'
		)
		public Boolean allowDuplicates;
		/** @description Maps to Database.LeadConvert.setContactId **/
		@InvocableVariable(
			label='Contact ID'
			description='An existing contact to merge the lead into. When blank, the conversion creates a contact.'
		)
		public Id contactId;
		/** @description Maps to Database.LeadConvert.setConvertedStatus, which conversion requires **/
		@InvocableVariable(
			label='Converted Status'
			description='A lead status that counts as converted, ex: "Closed - Converted".'
			required=true
		)
		public String convertedStatus;
		/** @description Maps to Database.LeadConvert.setDoNotCreateOpportunity **/
		@InvocableVariable(label='Don\'t Create Opportunity' description='Convert the lead without an opportunity.')
		public Boolean doNotCreateOpportunity;
		/** @description Maps to Database.LeadConvert.setLeadId **/
		@InvocableVariable(label='Lead ID' description='The lead to convert.' required=true)
		public Id leadId;
		/** @description Maps to Database.LeadConvert.setOpportunityId **/
		@InvocableVariable(
			label='Opportunity ID'
			description='An existing opportunity to merge the lead into. When blank, the conversion creates an opportunity.'
		)
		public Id opportunityId;
		/** @description Maps to Database.LeadConvert.setOpportunityName **/
		@InvocableVariable(
			label='Opportunity Name'
			description='The new opportunity\'s name. When blank, it defaults to the lead\'s company.'
		)
		public String opportunityName;
		/** @description Maps to Database.LeadConvert.setOverwriteLeadSource **/
		@InvocableVariable(
			label='Overwrite Lead Source'
			description='Replace the contact\'s lead source with the lead\'s.'
		)
		public Boolean overwriteLeadSource;
		/** @description Maps to Database.LeadConvert.setOwnerId **/
		@InvocableVariable(
			label='Owner ID'
			description='The owner of the new account, contact, and opportunity. When blank, the lead\'s owner.'
		)
		public Id ownerId;
		/** @description Maps to Database.DmlOptions.DuplicateRuleHeader.RunAsCurrentUser **/
		@InvocableVariable(
			label='Run Duplicate Rules as Current User'
			description='Enforce the running user\'s sharing rules when duplicate rules look for duplicates.'
		)
		public Boolean runDuplicateRulesAsCurrentUser;
		/** @description Maps to Database.LeadConvert.setSendNotificationEmail **/
		@InvocableVariable(label='Send Notification Email' description='Email the owner set by Owner ID.')
		public Boolean sendNotificationEmail;

		/**
		 * @description Unset booleans default to false, matching a new Database.LeadConvert
		 * @return The lead to convert, with this input's options
		 */
		private Database.LeadConvert toLeadConvert() {
			Database.LeadConvert leadToConvert = new Database.LeadConvert();
			leadToConvert.setAccountId(this.accountId);
			leadToConvert.setContactId(this.contactId);
			leadToConvert.setConvertedStatus(this.convertedStatus);
			leadToConvert.setDoNotCreateOpportunity(this.doNotCreateOpportunity ?? false);
			leadToConvert.setLeadId(this.leadId);
			leadToConvert.setOpportunityId(this.opportunityId);
			leadToConvert.setOpportunityName(this.opportunityName);
			leadToConvert.setOverwriteLeadSource(this.overwriteLeadSource ?? false);
			leadToConvert.setOwnerId(this.ownerId);
			leadToConvert.setSendNotificationEmail(this.sendNotificationEmail ?? false);
			return leadToConvert;
		}

		/**
		 * @description Reuses the record actions' settings, so conversions default and validate the same way
		 * @return This input's access level, all-or-none, and duplicate rule settings
		 */
		private InvocableDml.Input toSettings() {
			InvocableDml.Input settings = new InvocableDml.Input();
			settings.accessLevel = this.accessLevel;
			settings.allOrNone = this.allOrNone;
			settings.allowDuplicates = this.allowDuplicates;
			settings.runDuplicateRulesAsCurrentUser = this.runDuplicateRulesAsCurrentUser;
			return settings;
		}
	}

	/** @description The records the conversion created or merged into, and its outcome **/
	public class Output {
		/** @description Maps to Database.LeadConvertResult.getAccountId **/
		@InvocableVariable(label='Account ID' description='The account the lead was converted to.')
		public Id accountId;
		/** @description Maps to Database.LeadConvertResult.getContactId **/
		@InvocableVariable(label='Contact ID' description='The contact the lead was converted to.')
		public Id contactId;
		/** @description Maps to Database.LeadConvertResult.getOpportunityId **/
		@InvocableVariable(
			label='Opportunity ID'
			description='The opportunity the lead was converted to. Blank when no opportunity was created.'
		)
		public Id opportunityId;
		/** @description Lets flows check the outcome when All or None is false **/
		@InvocableVariable(label='Result' description='The result of converting the lead. Its ID is the lead\'s.')
		public InvocableDmlResult result;

		/** @description Invocable variable classes need an accessible no-arg constructor **/
		public Output() {
			this.result = new InvocableDmlResult();
		}

		/**
		 * @description Copies the conversion's outcome into fields Flow can read
		 * @param result The result of converting the lead
		 */
		private Output(Database.LeadConvertResult result) {
			this.accountId = result?.getAccountId();
			this.contactId = result?.getContactId();
			this.opportunityId = result?.getOpportunityId();
			this.result = new InvocableDmlResult(result);
		}
	}
}
