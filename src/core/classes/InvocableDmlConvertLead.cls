/**
 * @description Flow action that converts leads via `DatabaseLayer.Dml`, exposing the access level, all-or-none
 * behavior, and duplicate rule settings
 */
public inherited sharing class InvocableDmlConvertLead {
	// **** VARIABLES **** //
	// Salesforce caps Database.convertLead at 100 leads per call
	private static final Integer MAX_LEADS_PER_CALL = 100;

	// **** PUBLIC **** //
	/**
	 * @description Converts every input's lead in as few DML operations as convertLead's per-call cap allows, using the
	 * first input's settings, so a bulk run can't exhaust the DML statement limit
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
			Map<Id, Database.LeadConvertResult> resultsByLeadId = InvocableDmlConvertLead.convertLeads(inputs);
			outputs = InvocableDmlConvertLead.initOutputs(inputs, resultsByLeadId);
		}
		return outputs;
	}

	// **** PRIVATE **** //
	/**
	 * @description One call per chunk, since convertLead rejects more leads than its cap
	 * @param leadsToConvert Every lead to convert
	 * @param settings The input whose settings apply to every chunk
	 * @return Each lead's result, by lead Id
	 */
	private static Map<Id, Database.LeadConvertResult> convertChunks(
		List<Database.LeadConvert> leadsToConvert,
		InvocableDml.Input settings
	) {
		Database.DmlOptions options = settings?.toDmlOptions();
		System.AccessLevel accessLevel = settings?.toAccessLevel();
		Map<Id, Database.LeadConvertResult> resultsByLeadId = new Map<Id, Database.LeadConvertResult>{};
		for (Integer start = 0; start < leadsToConvert?.size(); start += MAX_LEADS_PER_CALL) {
			List<Database.LeadConvert> chunk = InvocableDmlConvertLead.getChunk(leadsToConvert, start);
			List<Database.LeadConvertResult> results = DatabaseLayer.Dml?.doConvert(chunk, options, accessLevel);
			InvocableDmlConvertLead.mapResults(chunk, results, resultsByLeadId);
		}
		return resultsByLeadId;
	}

	/**
	 * @description Goes through DatabaseLayer.Dml, so plugins and MockDml apply to flows too. A failure in a later chunk
	 * rolls back the earlier ones, so the action fails as a whole, like a single call
	 * @param inputs One input per flow interview; the first one's settings apply to all
	 * @return Each lead's result, by lead Id
	 */
	private static Map<Id, Database.LeadConvertResult> convertLeads(List<InvocableDmlConvertLead.Input> inputs) {
		List<Database.LeadConvert> leadsToConvert = InvocableDmlConvertLead.initLeadConverts(inputs);
		InvocableDml.Input settings = inputs?.get(0)?.toSettings();
		Boolean isChunked = leadsToConvert?.size() > MAX_LEADS_PER_CALL;
		System.Savepoint savepoint = isChunked ? DatabaseLayer.Dml?.setSavepoint() : null;
		try {
			return InvocableDmlConvertLead.convertChunks(leadsToConvert, settings);
		} catch (Exception error) {
			if (savepoint != null) {
				DatabaseLayer.Dml?.rollback(savepoint);
			}
			throw error;
		}
	}

	/**
	 * @description Copies up to the per-call cap of leads, since Apex lists have no slice method
	 * @param leadsToConvert Every lead to convert
	 * @param start The index of the chunk's first lead
	 * @return The chunk's leads
	 */
	private static List<Database.LeadConvert> getChunk(List<Database.LeadConvert> leadsToConvert, Integer start) {
		List<Database.LeadConvert> chunk = new List<Database.LeadConvert>{};
		Integer size = leadsToConvert?.size();
		Integer stop = Math.min(start + MAX_LEADS_PER_CALL, size);
		for (Integer index = start; index < stop; index++) {
			Database.LeadConvert leadToConvert = leadsToConvert?.get(index);
			chunk?.add(leadToConvert);
		}
		return chunk;
	}

	/**
	 * @description Inputs that convert the same lead share one conversion, since converting a lead twice in one call
	 * fails it; the first such input's options apply
	 * @param inputs One input per flow interview
	 * @return One lead to convert per distinct lead Id
	 */
	private static List<Database.LeadConvert> initLeadConverts(List<InvocableDmlConvertLead.Input> inputs) {
		Map<Id, Database.LeadConvert> leadsToConvert = new Map<Id, Database.LeadConvert>{};
		for (InvocableDmlConvertLead.Input input : inputs) {
			if (leadsToConvert?.containsKey(input?.leadId) == false) {
				Database.LeadConvert leadToConvert = input?.toLeadConvert();
				leadsToConvert?.put(input?.leadId, leadToConvert);
			}
		}
		return leadsToConvert?.values();
	}

	/**
	 * @description Each input takes its lead's result, so inputs that share a lead share its result
	 * @param inputs One input per flow interview
	 * @param resultsByLeadId Each lead's result, by lead Id
	 * @return One output per input, in the same order
	 */
	private static List<InvocableDmlConvertLead.Output> initOutputs(
		List<InvocableDmlConvertLead.Input> inputs,
		Map<Id, Database.LeadConvertResult> resultsByLeadId
	) {
		List<InvocableDmlConvertLead.Output> outputs = new List<InvocableDmlConvertLead.Output>{};
		for (InvocableDmlConvertLead.Input input : inputs) {
			Database.LeadConvertResult result = resultsByLeadId?.get(input?.leadId);
			InvocableDmlConvertLead.Output output = new InvocableDmlConvertLead.Output(result);
			outputs?.add(output);
		}
		return outputs;
	}

	/**
	 * @description Results come back in the chunk's order, so each lines up with its lead by position
	 * @param chunk The leads converted in one call
	 * @param results That call's results
	 * @param resultsByLeadId Collects each lead's result, by lead Id
	 */
	private static void mapResults(
		List<Database.LeadConvert> chunk,
		List<Database.LeadConvertResult> results,
		Map<Id, Database.LeadConvertResult> resultsByLeadId
	) {
		for (Integer index = 0; index < chunk?.size(); index++) {
			Id leadId = chunk?.get(index)?.getLeadId();
			Database.LeadConvertResult result = results?.get(index);
			resultsByLeadId?.put(leadId, result);
		}
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
