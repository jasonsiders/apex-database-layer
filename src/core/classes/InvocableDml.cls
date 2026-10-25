/**
 * @description Shared by the DML flow actions: their inputs, outputs, and bulk handling. Each action supplies its DML
 * operation, via `doDml`
 */
public abstract inherited sharing class InvocableDml {
	/** @description Flow passes the access level as text, so each valid value maps to its System.AccessLevel **/
	private static final Map<String, System.AccessLevel> ACCESS_LEVELS = new Map<String, System.AccessLevel>{
		'SYSTEM_MODE' => System.AccessLevel.SYSTEM_MODE,
		'USER_MODE' => System.AccessLevel.USER_MODE
	};

	// **** PUBLIC **** //
	/**
	 * @description Flow bulkifies interviews into one call; they share one DML operation, so a bulk run can't exhaust
	 * the DML statement limit. One operation can only have one set of settings, so the first input's apply to all
	 * @param inputs One input per flow interview
	 * @return One output per input, in the same order
	 */
	public List<InvocableDml.Output> run(List<InvocableDml.Input> inputs) {
		List<InvocableDml.Output> outputs = InvocableDml.initOutputs(inputs);
		List<SObject> records = InvocableDml.collectRecords(outputs);
		if (records?.isEmpty() == false) {
			InvocableDml.Input settings = inputs?.get(0);
			List<InvocableDmlResult> results = this.doDml(records, settings);
			InvocableDml.distributeResults(outputs, results);
		}
		return outputs;
	}

	// **** PROTECTED **** //
	/**
	 * @description The DML operation the action performs, ex: insert
	 * @param records Every input's records
	 * @param settings The input whose settings apply to the operation
	 * @return The results, in record order
	 */
	protected abstract List<InvocableDmlResult> doDml(List<SObject> records, InvocableDml.Input settings);

	// **** PRIVATE **** //
	/**
	 * @description Lists every input's records in one list, so they share one DML operation
	 * @param outputs One output per input
	 * @return Every record, in output order
	 */
	private static List<SObject> collectRecords(List<InvocableDml.Output> outputs) {
		List<SObject> records = new List<SObject>{};
		for (InvocableDml.Output output : outputs) {
			records?.addAll(output?.recordCollection);
		}
		return records;
	}

	/**
	 * @description Results come back in record order, so each output takes the next ones, one per record
	 * @param outputs One output per input
	 * @param results The results of the DML operation, in record order
	 */
	private static void distributeResults(List<InvocableDml.Output> outputs, List<InvocableDmlResult> results) {
		Iterator<InvocableDmlResult> remaining = results?.iterator();
		for (InvocableDml.Output output : outputs) {
			output?.addResults(remaining);
		}
	}

	/**
	 * @description Each output holds its input's records, so results can be matched back to it
	 * @param inputs One input per flow interview
	 * @return One output per input, in the same order
	 */
	private static List<InvocableDml.Output> initOutputs(List<InvocableDml.Input> inputs) {
		List<InvocableDml.Output> outputs = new List<InvocableDml.Output>{};
		for (InvocableDml.Input input : inputs) {
			InvocableDml.Output output = input?.initOutput();
			outputs?.add(output);
		}
		return outputs;
	}

	// **** INNER **** //
	/** @description Flat, primitive inputs, since Flow can't round-trip nested Apex-defined types in an editor **/
	public class Input {
		/** @description Text, not an enum, since Flow can't pass System.AccessLevel **/
		@InvocableVariable(
			label='Access Level'
			description='USER_MODE (default) enforces the running user\'s object permissions, field-level security, and sharing rules. SYSTEM_MODE ignores object permissions and field-level security, but sharing rules still apply.'
		)
		public String accessLevel;

		/** @description Defaults to true, matching DML statements, so failures aren't silently ignored **/
		@InvocableVariable(
			label='All or None'
			description='When true (default), any failure rolls back every record and fails the action. When false, valid records are processed, and failures are reported in the results.'
		)
		public Boolean allOrNone;

		/** @description Maps to Database.DmlOptions.DuplicateRuleHeader.AllowSave **/
		@InvocableVariable(
			label='Allow Duplicates'
			description='Save records that a duplicate rule would otherwise alert on.'
		)
		public Boolean allowDuplicates;

		/** @description Maps to Database.DmlOptions.AllowFieldTruncation **/
		@InvocableVariable(
			label='Allow Field Truncation'
			description='Truncate text values that are too long for their field, instead of failing.'
		)
		public Boolean allowFieldTruncation;

		/** @description Maps to Database.DmlOptions.AssignmentRuleHeader.AssignmentRuleId **/
		@InvocableVariable(
			label='Assignment Rule ID'
			description='The ID of a specific Lead or Case assignment rule to run. Rule IDs differ between orgs, so use a resource, ex: an ID from Get Records on Assignment Rule, instead of typing one in.'
		)
		public Id assignmentRuleId;

		/** @description Text, not an SObjectField, since Flow can't pass one; upserts only **/
		@InvocableVariable(
			label='External ID Field'
			description='The API name of the external ID field that matches records to upsert, ex: "External_Id__c". When blank, records match on their ID.'
		)
		public String externalIdField;

		/** @description Maps to Database.DmlOptions.LocaleOptions **/
		@InvocableVariable(
			label='Locale Options'
			description='The language of any labels returned by the operation, ex: "en_US".'
		)
		public String localeOptions;

		/** @description Separate from the collection, since Flow can't pass a single record to a collection input **/
		@InvocableVariable(label='Record' description='A single record.')
		public SObject record;

		/** @description The action's editor sets this or the single record, never both **/
		@InvocableVariable(label='Record Collection' description='A collection of records.')
		public List<SObject> recordCollection;

		/** @description Maps to Database.DmlOptions.DuplicateRuleHeader.RunAsCurrentUser **/
		@InvocableVariable(
			label='Run Duplicate Rules as Current User'
			description='Enforce the running user\'s sharing rules when duplicate rules look for duplicates.'
		)
		public Boolean runDuplicateRulesAsCurrentUser;

		/** @description Maps to Database.DmlOptions.EmailHeader.TriggerAutoResponseEmail **/
		@InvocableVariable(
			label='Trigger Auto-Response Email'
			description='Send auto-response emails for new Leads and Cases.'
		)
		public Boolean triggerAutoResponseEmail;

		/** @description Maps to Database.DmlOptions.EmailHeader.TriggerOtherEmail **/
		@InvocableVariable(label='Trigger Other Email' description='Send email to recipients outside the org.')
		public Boolean triggerOtherEmail;

		/** @description Maps to Database.DmlOptions.EmailHeader.TriggerUserEmail **/
		@InvocableVariable(
			label='Trigger User Email'
			description='Send email to users in the org, ex: when a Case or Task is assigned.'
		)
		public Boolean triggerUserEmail;

		/** @description Maps to Database.DmlOptions.AssignmentRuleHeader.UseDefaultRule **/
		@InvocableVariable(
			label='Use Default Assignment Rule'
			description='Run the default active assignment rule for Leads and Cases.'
		)
		public Boolean useDefaultAssignmentRule;

		/**
		 * @description Defaults to true, matching DML statements
		 * @return Whether any failure should roll back every record
		 */
		public Boolean getAllOrNone() {
			return this.allOrNone ?? true;
		}

		/**
		 * @description Blank runs in the safer USER_MODE; anything else must name an access level exactly, so a typo
		 * fails instead of running in a mode the flow didn't ask for
		 * @return The matching System.AccessLevel
		 * @throws System.IllegalArgumentException When the value isn't blank, USER_MODE, or SYSTEM_MODE
		 */
		public System.AccessLevel getAccessLevel() {
			String name = String.isBlank(this.accessLevel) ? 'USER_MODE' : this.accessLevel;
			System.AccessLevel level = InvocableDml.ACCESS_LEVELS?.get(name);
			if (level == null) {
				throw new IllegalArgumentException('Invalid access level: ' + name);
			}
			return level;
		}

		/**
		 * @description Unset booleans default to false, matching a new Database.DmlOptions, except OptAllOrNone
		 * @return The DML options
		 */
		public Database.DmlOptions initDmlOptions() {
			Database.DmlOptions options = new Database.DmlOptions();
			options.AllowFieldTruncation = this.allowFieldTruncation ?? false;
			options.AssignmentRuleHeader.AssignmentRuleId = this.assignmentRuleId;
			options.AssignmentRuleHeader.UseDefaultRule = this.useDefaultAssignmentRule ?? false;
			options.DuplicateRuleHeader.AllowSave = this.allowDuplicates ?? false;
			options.DuplicateRuleHeader.RunAsCurrentUser = this.runDuplicateRulesAsCurrentUser ?? false;
			options.EmailHeader.TriggerAutoResponseEmail = this.triggerAutoResponseEmail ?? false;
			options.EmailHeader.TriggerOtherEmail = this.triggerOtherEmail ?? false;
			options.EmailHeader.TriggerUserEmail = this.triggerUserEmail ?? false;
			options.LocaleOptions = this.localeOptions;
			options.OptAllOrNone = this.getAllOrNone();
			return options;
		}

		/**
		 * @description Treats the single record and the collection alike, so the rest of the action handles one list
		 * @return An output holding this input's records until they're processed
		 */
		private InvocableDml.Output initOutput() {
			List<SObject> records = this.record == null ? new List<SObject>{} : new List<SObject>{ this.record };
			records?.addAll(this.recordCollection ?? new List<SObject>{});
			return new InvocableDml.Output(records);
		}
	}

	/** @description Single and collection variants of each output, so flows of either shape can use them directly **/
	public class Output {
		/** @description Lets single-record flows use the record without a collection **/
		@InvocableVariable(label='Record' description='The processed record. For a collection, the first record.')
		public SObject record;

		/** @description Processed records, in input order, since Flow can't see Ids set on its inputs **/
		@InvocableVariable(
			label='Record Collection'
			description='The processed records, in input order. Inserted and upserted records include their new IDs.'
		)
		public List<SObject> recordCollection;

		/** @description Lets single-record flows check the outcome without a collection **/
		@InvocableVariable(label='Result' description='The result for the record. For a collection, the first result.')
		public InvocableDmlResult result;

		/** @description One result per record, in input order, for partial-success handling **/
		@InvocableVariable(label='Result Collection' description='One result per record, in input order.')
		public List<InvocableDmlResult> resultCollection;

		/** @description Invocable variable classes need an accessible no-arg constructor **/
		public Output() {
			this.recordCollection = new List<SObject>{};
			this.resultCollection = new List<InvocableDmlResult>{};
		}

		/**
		 * @description Holds the input's records until they're processed; DML sets their Ids in place
		 * @param records The input's records
		 */
		private Output(List<SObject> records) {
			this();
			this.recordCollection = records;
			this.record = records?.isEmpty() == false ? records?.get(0) : null;
		}

		/**
		 * @description Takes the next result for each of its records; DML already set their Ids in place
		 * @param remaining The results not yet taken, in record order
		 */
		private void addResults(Iterator<InvocableDmlResult> remaining) {
			for (Integer index = 0; index < this.recordCollection?.size(); index++) {
				InvocableDmlResult result = remaining?.next();
				this.resultCollection?.add(result);
			}
			this.result = this.resultCollection?.isEmpty() == false ? this.resultCollection?.get(0) : null;
		}
	}
}
