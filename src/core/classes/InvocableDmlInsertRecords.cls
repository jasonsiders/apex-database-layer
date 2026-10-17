/**
 * @description Flow action that inserts records via `DatabaseLayer.Dml`, exposing the access level, all-or-none
 * behavior, and every `Database.DmlOptions` setting. Inputs that share the same settings are inserted together,
 * in a single DML operation.
 */
public inherited sharing class InvocableDmlInsertRecords {
	// **** CONSTANTS **** //
	/** @description Flow passes the access level as text, which must map to a System.AccessLevel **/
	private static final Map<String, System.AccessLevel> ACCESS_LEVELS = new Map<String, System.AccessLevel>{
		'SYSTEM_MODE' => System.AccessLevel.SYSTEM_MODE,
		'USER_MODE' => System.AccessLevel.USER_MODE
	};

	// **** PUBLIC **** //
	/**
	 * @description Flow bulkifies interviews into one call; sharing a DML operation per group of matching settings
	 * keeps a bulk run from exhausting the DML statement limit
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
		List<InvocableDmlInsertRecords.Output> outputs = InvocableDmlInsertRecords.initOutputs(inputs);
		Map<String, List<InvocableDmlInsertRecords.Output>> groups = InvocableDmlInsertRecords.groupBySettings(outputs);
		for (List<InvocableDmlInsertRecords.Output> outputGroup : groups?.values()) {
			InvocableDmlInsertRecords.insertRecords(outputGroup);
		}
		return outputs;
	}

	// **** PRIVATE **** //
	/**
	 * @description Pools the group's records, so they can be inserted in one DML operation
	 * @param outputs Outputs whose inputs share the same settings
	 * @return Every record in the group, in output order
	 */
	private static List<SObject> collectRecords(List<InvocableDmlInsertRecords.Output> outputs) {
		List<SObject> records = new List<SObject>{};
		for (InvocableDmlInsertRecords.Output output : outputs) {
			records?.addAll(output?.recordCollection);
		}
		return records;
	}

	/**
	 * @description Results come back for the pooled records, so each output takes its share in order
	 * @param outputs Outputs whose records were pooled, in the order they were pooled
	 * @param results The results of the pooled DML operation
	 */
	private static void distributeResults(
		List<InvocableDmlInsertRecords.Output> outputs,
		List<Database.SaveResult> results
	) {
		Iterator<Database.SaveResult> resultIterator = results?.iterator();
		for (InvocableDmlInsertRecords.Output output : outputs) {
			output?.addResults(resultIterator);
		}
	}

	/**
	 * @description Inputs with identical settings can share a DML operation
	 * @param outputs The outputs to group
	 * @return The outputs, keyed by their inputs' settings
	 */
	private static Map<String, List<InvocableDmlInsertRecords.Output>> groupBySettings(
		List<InvocableDmlInsertRecords.Output> outputs
	) {
		Map<String, List<InvocableDmlInsertRecords.Output>> groups = new Map<String, List<InvocableDmlInsertRecords.Output>>{};
		for (InvocableDmlInsertRecords.Output output : outputs) {
			String settingsKey = output?.input?.getSettingsKey();
			List<InvocableDmlInsertRecords.Output> outputGroup = groups?.get(settingsKey) ??
				new List<InvocableDmlInsertRecords.Output>{};
			outputGroup?.add(output);
			groups?.put(settingsKey, outputGroup);
		}
		return groups;
	}

	/**
	 * @description Each output carries its input, so results can be matched back to it after pooling
	 * @param inputs One input per flow interview
	 * @return One output per input, in the same order
	 */
	private static List<InvocableDmlInsertRecords.Output> initOutputs(List<InvocableDmlInsertRecords.Input> inputs) {
		List<InvocableDmlInsertRecords.Output> outputs = new List<InvocableDmlInsertRecords.Output>{};
		for (InvocableDmlInsertRecords.Input input : inputs) {
			InvocableDmlInsertRecords.Output output = input?.toOutput();
			outputs?.add(output);
		}
		return outputs;
	}

	/**
	 * @description Skips DML entirely for groups with no records, so empty collections cost nothing
	 * @param outputs Outputs whose inputs share the same settings
	 */
	private static void insertRecords(List<InvocableDmlInsertRecords.Output> outputs) {
		List<SObject> records = InvocableDmlInsertRecords.collectRecords(outputs);
		if (records?.isEmpty() == false) {
			InvocableDmlInsertRecords.Input settings = outputs?.get(0)?.input;
			List<Database.SaveResult> results = settings?.insertRecords(records);
			InvocableDmlInsertRecords.distributeResults(outputs, results);
		}
	}

	// **** INNER **** //
	/** @description Flat, primitive inputs, since Flow can't round-trip nested Apex-defined types in an editor **/
	public class Input {
		/** @description Text, not an enum, since Flow can't pass System.AccessLevel **/
		@InvocableVariable(
			label='Access Level'
			description='USER_MODE (default) enforces the running user\'s object permissions, field-level security, and sharing rules. SYSTEM_MODE ignores them.'
		)
		public String accessLevel;
		/** @description Defaults to true, matching DML statements, so failures aren't silently ignored **/
		@InvocableVariable(
			label='All or None'
			description='When true (default), any failure rolls back every record and fails the action. When false, valid records are inserted, and failures are reported in the results.'
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
			description='The Id of a specific Lead or Case assignment rule to run.'
		)
		public Id assignmentRuleId;
		/** @description Maps to Database.DmlOptions.LocaleOptions **/
		@InvocableVariable(
			label='Locale Options'
			description='The language of any labels returned by the operation, ex: "en_US".'
		)
		public String localeOptions;
		/** @description Separate from the collection, since Flow can't pass a single record to a collection input **/
		@InvocableVariable(label='Record' description='A single record to insert.')
		public SObject record;
		/** @description Records to insert; the editor sets this or the single record, never both **/
		@InvocableVariable(label='Record Collection' description='A collection of records to insert.')
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
		 * @description Treats the single record and the collection alike, so the rest of the action handles one list
		 * @return Every record to insert
		 */
		private List<SObject> getRecords() {
			List<SObject> records = new List<SObject>{};
			if (this.record != null) {
				records?.add(this.record);
			}
			records?.addAll(this.recordCollection ?? new List<SObject>{});
			return records;
		}

		/**
		 * @description Inputs with the same key can share a DML operation
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
		 * @description Goes through DatabaseLayer.Dml, so plugins and MockDml apply to flows too
		 * @param records The records to insert
		 * @return The results, in record order
		 */
		private List<Database.SaveResult> insertRecords(List<SObject> records) {
			Database.DmlOptions options = this.toDmlOptions();
			System.AccessLevel accessLevel = this.toAccessLevel();
			return DatabaseLayer.Dml?.doInsert(records, options, accessLevel);
		}

		/**
		 * @description Defaults to USER_MODE, like the rest of the library, and rejects unknown names
		 * @return The matching System.AccessLevel
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
		 * @description Unset booleans default to false, matching a new Database.DmlOptions, except OptAllOrNone
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

		/**
		 * @description The output keeps this input, so its results can be matched back after pooling
		 * @return An output holding this input's records, before they're inserted
		 */
		private InvocableDmlInsertRecords.Output toOutput() {
			List<SObject> records = this.getRecords();
			return new InvocableDmlInsertRecords.Output(this, records);
		}
	}

	/** @description Single and collection variants of each output, so flows of either shape can use them directly **/
	public class Output {
		/** @description Lets single-record flows use the new Id without a collection **/
		@InvocableVariable(label='Record' description='The inserted record. For a collection, the first record.')
		public SObject record;
		/** @description Inserted records, in input order, since Flow can't see Ids set on its inputs **/
		@InvocableVariable(
			label='Record Collection'
			description='The inserted records, in input order, with their new Ids.'
		)
		public List<SObject> recordCollection;
		/** @description Lets single-record flows check the outcome without a collection **/
		@InvocableVariable(
			label='Result'
			description='The result of inserting the record. For a collection, the first result.'
		)
		public InvocableDmlResult result;
		/** @description One result per record, in input order, for partial-success handling **/
		@InvocableVariable(label='Result Collection' description='One result per record, in input order.')
		public List<InvocableDmlResult> resultCollection;
		/** @description The input whose records this output reports on, used to group and match results **/
		private InvocableDmlInsertRecords.Input input;

		/** @description Invocable variable classes need an accessible no-arg constructor **/
		public Output() {
			this.recordCollection = new List<SObject>{};
			this.resultCollection = new List<InvocableDmlResult>{};
		}

		/**
		 * @description Holds the input's records until they're inserted; insert sets their Ids in place
		 * @param input The input this output reports on
		 * @param records The input's records
		 */
		private Output(InvocableDmlInsertRecords.Input input, List<SObject> records) {
			this();
			this.input = input;
			this.recordCollection = records;
			this.record = records?.isEmpty() ? null : records?.get(0);
		}

		/**
		 * @description Pooled results arrive in record order, so each output takes the next one per record
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
