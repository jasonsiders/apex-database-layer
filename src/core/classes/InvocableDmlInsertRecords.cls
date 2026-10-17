/**
 * @description Flow action that inserts records via `DatabaseLayer.Dml`, exposing the access level, all-or-none
 * behavior, and every `Database.DmlOptions` setting. Inputs that share the same settings are inserted together,
 * in a single DML operation.
 */
public inherited sharing class InvocableDmlInsertRecords {
	private static final Map<String, System.AccessLevel> ACCESS_LEVELS = new Map<String, System.AccessLevel>{
		'SYSTEM_MODE' => System.AccessLevel.SYSTEM_MODE,
		'USER_MODE' => System.AccessLevel.USER_MODE
	};

	/**
	 * @description Inserts the records from each input. Inputs with matching settings share one DML operation.
	 * @param inputs One input per flow interview
	 * @return One output per input, in the same order
	 */
	@InvocableMethod(
		category='Database Layer'
		configurationEditor='c-dml-insert-records-editor'
		description='Insert one or more records, with control over the access level, partial success, and DML options.'
		iconName='slds:standard:record_create'
		label='Insert Records'
	)
	public static List<InvocableDmlInsertRecords.Output> invoke(List<InvocableDmlInsertRecords.Input> inputs) {
		List<InvocableDmlInsertRecords.Output> outputs = new List<InvocableDmlInsertRecords.Output>();
		for (InvocableDmlInsertRecords.Input input : inputs) {
			InvocableDmlInsertRecords.Output output = new InvocableDmlInsertRecords.Output(input);
			outputs?.add(output);
		}
		Map<String, List<InvocableDmlInsertRecords.Output>> groups = InvocableDmlInsertRecords.groupBySettings(outputs);
		for (List<InvocableDmlInsertRecords.Output> outputGroup : groups?.values()) {
			InvocableDmlInsertRecords.insertRecords(outputGroup);
		}
		return outputs;
	}

	// **** STATIC **** //
	/**
	 * @description Groups outputs whose inputs share the same settings, so each group needs only one DML operation.
	 * @param outputs The outputs to group
	 * @return The outputs, keyed by their inputs' settings
	 */
	private static Map<String, List<InvocableDmlInsertRecords.Output>> groupBySettings(
		List<InvocableDmlInsertRecords.Output> outputs
	) {
		Map<String, List<InvocableDmlInsertRecords.Output>> groups = new Map<String, List<InvocableDmlInsertRecords.Output>>();
		for (InvocableDmlInsertRecords.Output output : outputs) {
			String settingsKey = output?.input?.getSettingsKey();
			List<InvocableDmlInsertRecords.Output> outputGroup = groups?.get(settingsKey) ??
				new List<InvocableDmlInsertRecords.Output>();
			outputGroup?.add(output);
			groups?.put(settingsKey, outputGroup);
		}
		return groups;
	}

	/**
	 * @description Inserts the records of every output in the group in one DML operation, then hands each output its results.
	 * @param outputs Outputs whose inputs share the same settings
	 */
	private static void insertRecords(List<InvocableDmlInsertRecords.Output> outputs) {
		InvocableDmlInsertRecords.Input settings = outputs?.get(0)?.input;
		List<SObject> records = new List<SObject>();
		for (InvocableDmlInsertRecords.Output output : outputs) {
			records?.addAll(output?.recordCollection);
		}
		if (records?.isEmpty() == false) {
			Database.DmlOptions options = settings?.toDmlOptions();
			System.AccessLevel accessLevel = settings?.toAccessLevel();
			List<Database.SaveResult> results = DatabaseLayer.Dml?.doInsert(records, options, accessLevel);
			Iterator<Database.SaveResult> resultIterator = results?.iterator();
			for (InvocableDmlInsertRecords.Output output : outputs) {
				output?.addResults(resultIterator);
			}
		}
	}

	// **** INNER **** //
	/**
	 * @description The records to insert, and the settings that control how they're inserted.
	 */
	public class Input {
		/**
		 * @description `USER_MODE` (default) or `SYSTEM_MODE`.
		 */
		@InvocableVariable(
			label='Access Level'
			description='USER_MODE (default) enforces the running user\'s object permissions, field-level security, and sharing rules. SYSTEM_MODE ignores them.'
		)
		public String accessLevel;
		/**
		 * @description When true (default), any failure fails the whole operation.
		 */
		@InvocableVariable(
			label='All or None'
			description='When true (default), any failure rolls back every record and fails the action. When false, valid records are inserted, and failures are reported in the results.'
		)
		public Boolean allOrNone;
		/**
		 * @description Maps to `Database.DmlOptions.DuplicateRuleHeader.AllowSave`.
		 */
		@InvocableVariable(
			label='Allow Duplicates'
			description='Save records that a duplicate rule would otherwise alert on.'
		)
		public Boolean allowDuplicates;
		/**
		 * @description Maps to `Database.DmlOptions.AllowFieldTruncation`.
		 */
		@InvocableVariable(
			label='Allow Field Truncation'
			description='Truncate text values that are too long for their field, instead of failing.'
		)
		public Boolean allowFieldTruncation;
		/**
		 * @description Maps to `Database.DmlOptions.AssignmentRuleHeader.AssignmentRuleId`.
		 */
		@InvocableVariable(
			label='Assignment Rule ID'
			description='The Id of a specific Lead or Case assignment rule to run.'
		)
		public Id assignmentRuleId;
		/**
		 * @description Maps to `Database.DmlOptions.LocaleOptions`.
		 */
		@InvocableVariable(
			label='Locale Options'
			description='The language of any labels returned by the operation, ex: "en_US".'
		)
		public String localeOptions;
		/**
		 * @description A single record to insert.
		 */
		@InvocableVariable(label='Record' description='A single record to insert.')
		public SObject record;
		/**
		 * @description A collection of records to insert.
		 */
		@InvocableVariable(label='Record Collection' description='A collection of records to insert.')
		public List<SObject> recordCollection;
		/**
		 * @description Maps to `Database.DmlOptions.DuplicateRuleHeader.RunAsCurrentUser`.
		 */
		@InvocableVariable(
			label='Run Duplicate Rules as Current User'
			description='Enforce the running user\'s sharing rules when duplicate rules look for duplicates.'
		)
		public Boolean runDuplicateRulesAsCurrentUser;
		/**
		 * @description Maps to `Database.DmlOptions.EmailHeader.TriggerAutoResponseEmail`.
		 */
		@InvocableVariable(
			label='Trigger Auto-Response Email'
			description='Send auto-response emails for new Leads and Cases.'
		)
		public Boolean triggerAutoResponseEmail;
		/**
		 * @description Maps to `Database.DmlOptions.EmailHeader.TriggerOtherEmail`.
		 */
		@InvocableVariable(label='Trigger Other Email' description='Send email to recipients outside the org.')
		public Boolean triggerOtherEmail;
		/**
		 * @description Maps to `Database.DmlOptions.EmailHeader.TriggerUserEmail`.
		 */
		@InvocableVariable(
			label='Trigger User Email'
			description='Send email to users in the org, ex: when a Case or Task is assigned.'
		)
		public Boolean triggerUserEmail;
		/**
		 * @description Maps to `Database.DmlOptions.AssignmentRuleHeader.UseDefaultRule`.
		 */
		@InvocableVariable(
			label='Use Default Assignment Rule'
			description='Run the default active assignment rule for Leads and Cases.'
		)
		public Boolean useDefaultAssignmentRule;

		/**
		 * @description Combines the single record and the record collection.
		 * @return Every record to insert
		 */
		private List<SObject> getRecords() {
			List<SObject> records = new List<SObject>();
			if (this.record != null) {
				records?.add(this.record);
			}
			records?.addAll(this.recordCollection ?? new List<SObject>());
			return records;
		}

		/**
		 * @description Identifies the settings that affect the DML operation. Inputs with the same key can share one.
		 * @return A key unique to this input's settings
		 */
		private String getSettingsKey() {
			List<Object> settings = new List<Object>{
				this.accessLevel,
				this.allOrNone,
				this.allowDuplicates,
				this.allowFieldTruncation,
				this.assignmentRuleId,
				this.localeOptions,
				this.runDuplicateRulesAsCurrentUser,
				this.triggerAutoResponseEmail,
				this.triggerOtherEmail,
				this.triggerUserEmail,
				this.useDefaultAssignmentRule
			};
			return JSON.serialize(settings);
		}

		/**
		 * @description Resolves the access level name, defaulting to `USER_MODE`.
		 * @return The matching `System.AccessLevel`
		 * @throws System.IllegalArgumentException if the name isn't a valid access level
		 */
		private System.AccessLevel toAccessLevel() {
			String levelName = String.isBlank(this.accessLevel) ? 'USER_MODE' : this.accessLevel?.trim()?.toUpperCase();
			System.AccessLevel level = ACCESS_LEVELS?.get(levelName);
			if (level == null) {
				String msg = 'Invalid Access Level: "' + this.accessLevel + '". Use USER_MODE or SYSTEM_MODE.';
				throw new System.IllegalArgumentException(msg);
			}
			return level;
		}

		/**
		 * @description Builds the `Database.DmlOptions` from this input's settings.
		 * @return The DML options
		 */
		private Database.DmlOptions toDmlOptions() {
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
			options.OptAllOrNone = this.allOrNone ?? true;
			return options;
		}
	}

	/**
	 * @description The inserted records, and the result of inserting each one.
	 */
	public class Output {
		/**
		 * @description The inserted record. For a collection, the first record.
		 */
		@InvocableVariable(label='Record' description='The inserted record. For a collection, the first record.')
		public SObject record;
		/**
		 * @description The inserted records, in input order.
		 */
		@InvocableVariable(
			label='Record Collection'
			description='The inserted records, in input order, with their new Ids.'
		)
		public List<SObject> recordCollection;
		/**
		 * @description The result of inserting the record. For a collection, the first result.
		 */
		@InvocableVariable(
			label='Result'
			description='The result of inserting the record. For a collection, the first result.'
		)
		public InvocableDmlResult result;
		/**
		 * @description One result per record, in input order.
		 */
		@InvocableVariable(label='Result Collection' description='One result per record, in input order.')
		public List<InvocableDmlResult> resultCollection;
		private InvocableDmlInsertRecords.Input input;

		/**
		 * @description Creates an output for the given input, before its records are inserted.
		 * @param input The input this output reports on
		 */
		private Output(InvocableDmlInsertRecords.Input input) {
			this.input = input;
			this.recordCollection = input?.getRecords();
			this.record = this.recordCollection?.isEmpty() ? null : this.recordCollection?.get(0);
			this.resultCollection = new List<InvocableDmlResult>();
		}

		/**
		 * @description Takes the next result for each of this output's records.
		 * @param resultIterator Results for the whole DML operation, positioned at this output's first record
		 */
		private void addResults(Iterator<Database.SaveResult> resultIterator) {
			for (Integer i = 0; i < this.recordCollection?.size(); i++) {
				Database.SaveResult saveResult = resultIterator?.next();
				InvocableDmlResult result = new InvocableDmlResult(saveResult);
				this.resultCollection?.add(result);
			}
			this.result = this.resultCollection?.isEmpty() ? null : this.resultCollection?.get(0);
		}
	}
}
