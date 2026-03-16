/**
 * @description Adapter class that integrates Nebula Logger with the Apex Database Layer framework.
 * Implements both DML and SOQL pre/post processors to log database operations.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global class DatabaseLayerNebulaLoggerAdapter implements Dml.PreAndPostProcessor, Soql.PreAndPostProcessor {
	@TestVisible
	private static final String TAG_NAME = 'apex-database-layer';
	private static final String DELIMITER = '\n---\n';
	private static final Boolean ORIGINAL_DEBUG_FLAG_VALUE;
	private static final LoggerSettings__c SETTINGS;

	static {
		SETTINGS = Logger.getUserSettings();
		ORIGINAL_DEBUG_FLAG_VALUE = SETTINGS?.IsApexSystemDebugLoggingEnabled__c ?? false;
	}

	/**
	 * @description Configure Nebula Logger to ignore this framework's internal classes in log stack traces
	 */
	global DatabaseLayerNebulaLoggerAdapter() {
		Logger.ignoreOrigin(DatabaseLayerNebulaLoggerAdapter.class);
		Logger.ignoreOrigin(DatabaseLayer.class);
		Logger.ignoreOrigin(DatabaseLayerUtils.class);
		Logger.ignoreOrigin(DatabaseLayerTestUtils.class);
		Logger.ignoreOrigin(Dml.class);
		Logger.ignoreOrigin(MockDml.class);
		Logger.ignoreOrigin(MockRecord.class);
		Logger.ignoreOrigin(MockSoql.class);
		Logger.ignoreOrigin(Soql.class);
	}

	/**
	 * @description Logs DML requests before execution
	 * @param request The DML request to be processed
	 */
	global void processPreDml(Dml.Request request) {
		String op = this.getDmlOperationName(request?.operation);
		this.log(System.LoggingLevel.FINEST)
			?.addLine('⏳ DML: Processing ' + op + '...')
			?.addLine('Request:\n' + JSON.serialize(request))
			?.setRecords(request?.records)
			?.build();
	}

	/**
	 * @description Logs a successful DML operation
	 * @param request The DML request that was processed
	 * @param results The Database.*Results returned from the DML operation
	 */
	global void processPostDml(Dml.Request request, List<Object> results) {
		String op = this.getDmlOperationName(request?.operation);
		this.log(System.LoggingLevel.FINEST)
			?.addLine('✅ DML: Processed ' + op)
			?.addLine('Request: ' + JSON.serialize(request))
			?.setDatabaseResults(results)
			?.setRecords(request?.records)
			?.build();
	}

	/**
	 * @description Logs DML errors
	 * @param request The DML request that encountered an error
	 * @param error The exception that was thrown
	 */
	global void processDmlError(Dml.Request request, Exception error) {
		String op = this.getDmlOperationName(request?.operation);
		this.log(System.LoggingLevel.ERROR)
			?.addLine('🚨 DML: Error processing ' + op)
			?.addLine(error?.toString())
			?.addLine('Request:\n' + JSON.serialize(request))
			?.setRecords(request?.records)
			?.build();
	}

	/**
	 * @description Logs SOQL requests before execution.
	 * @param request The SOQL request being processed
	 */
	global void processPreSoql(Soql.Request request) {
		this.log(System.LoggingLevel.FINEST)
			?.addLine('⏳ SOQL: Processing ' + request?.operation + '...')
			?.addLine(request?.queryString)
			?.build();
	}

	/**
	 * @description Logs SOQL requests after execution.
	 * @param request The SOQL request that was processed
	 * @param results The results from the SOQL operation
	 */
	global void processPostSoql(Soql.Request request, Object results) {
		this.log(System.LoggingLevel.FINEST)
			?.addLine('✅ SOQL: Processed ' + request?.operation)
			?.addLine(request?.queryString)
			?.setRecords(results)
			?.build();
	}

	/**
	 * @description Logs SOQL errors.
	 * @param request The SOQL request that failed
	 * @param error The exception that occurred
	 */
	global void processSoqlError(Soql.Request request, Exception error) {
		this.log(System.LoggingLevel.ERROR)
			?.addLine('🚨 SOQL: Error processing ' + request?.operation)
			?.addLine(request?.queryString)
			?.addLine(error?.toString())
			?.build();
	}

	// **** PRIVATE **** //
	private String getDmlOperationName(Dml.Operation operation) {
		return operation?.name()?.removeStart('DO_');
	}

	private LogBuilder log(System.LoggingLevel level) {
		return new DatabaseLayerNebulaLoggerAdapter.LogBuilder(level);
	}

	// **** INNER **** //
	private class LogBuilder {
		private LogEntryEventBuilder entry;
		private List<String> lines;

		/**
		 * @description Creates a new LogBuilder instance with the specified logging level
		 * @param level The logging level for this log entry
		 */
		public LogBuilder(System.LoggingLevel level) {
			this.createLogEntry(level);
			this.lines = new List<String>{};
		}

		/**
		 * @description Adds a line to the log message
		 * @param line The line to add to the log message
		 * @return This LogBuilder instance for method chaining
		 */
		public LogBuilder addLine(String line) {
			this.lines?.add(line);
			return this;
		}

		/**
		 * @description Builds the final log entry with all accumulated lines
		 * @return The LogEntryEventBuilder with the complete log message
		 */
		public LogEntryEventBuilder build() {
			String msg = String.join(this.lines, DELIMITER);
			return this.entry?.setMessage(msg);
		}

		/**
		 * @description Sets database operation results on the log entry
		 * @param obj List of database results (DeleteResult, SaveResult, etc.)
		 * @return This LogBuilder instance for method chaining
		 */
		public LogBuilder setDatabaseResults(List<Object> obj) {
			if (obj instanceof List<Database.DeleteResult>) {
				List<Database.DeleteResult> databaseResults = (List<Database.DeleteResult>) obj;
				this.entry?.setDatabaseResult(databaseResults);
			} else if (obj instanceof List<Database.LeadConvertResult>) {
				List<Database.LeadConvertResult> databaseResults = (List<Database.LeadConvertResult>) obj;
				this.entry?.setDatabaseResult(databaseResults);
			} else if (obj instanceof List<Database.SaveResult>) {
				List<Database.SaveResult> databaseResults = (List<Database.SaveResult>) obj;
				this.entry?.setDatabaseResult(databaseResults);
			} else if (obj instanceof List<Database.UndeleteResult>) {
				List<Database.UndeleteResult> databaseResults = (List<Database.UndeleteResult>) obj;
				this.entry?.setDatabaseResult(databaseResults);
			} else if (obj instanceof List<Database.UpsertResult>) {
				List<Database.UpsertResult> databaseResults = (List<Database.UpsertResult>) obj;
				this.entry?.setDatabaseResult(databaseResults);
			}
			return this;
		}

		/**
		 * @description Sets records or query results on the log entry
		 * @param obj Records to log (SObject list, QueryLocator, or other results)
		 * @return This LogBuilder instance for method chaining
		 */
		public LogBuilder setRecords(Object obj) {
			if (obj instanceof List<SObject>) {
				List<SObject> records = (List<SObject>) obj;
				this.entry?.setRecord(records);
			} else if (obj instanceof Soql.QueryLocator) {
				Soql.QueryLocator locator = (Soql.QueryLocator) obj;
				this.lines?.add('Results:\n' + locator);
			} else {
				this.lines?.add('Results:\n' + JSON.serialize(obj));
			}
			return this;
		}

		private void createLogEntry(System.LoggingLevel level) {
			// Create a basic/empty log entry object for the builder to hydrate with log lines & other information
			// Special care must be taken to prevent committing unnecessary '' log lines to System.debug logs:
			SETTINGS.IsApexSystemDebugLoggingEnabled__c = false;
			this.entry = Logger.newEntry(level, '')?.addTag(TAG_NAME);
			SETTINGS.IsApexSystemDebugLoggingEnabled__c = ORIGINAL_DEBUG_FLAG_VALUE;
		}
	}
}
