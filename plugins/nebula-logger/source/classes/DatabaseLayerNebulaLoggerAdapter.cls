/**
 * @description Adapter class that integrates Nebula Logger with the Apex Database Layer framework.
 *              Implements both DML and SOQL pre/post processors to log database operations.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global class DatabaseLayerNebulaLoggerAdapter implements Dml.PreAndPostProcessor, Soql.PreAndPostProcessor {
	@TestVisible
	private static final String TAG_NAME = 'apex-database-layer';
	private static final String DELIMITER = '\n---\n';

	/**
	 * @description Configure Nebula Logger to ignore database layer framework classes in log stack traces
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
		// prettier-ignore
		List<String> lines = new List<String>{
			'⏳ DML: Processing ' + this.getDmlOperationName(request?.operation) + '...',
			'Request:\n' + JSON.serialize(request)
		};
		String msg = String.join(lines, DELIMITER);
		Logger.finest(msg)?.addTag(TAG_NAME)?.setRecord(request?.records);
	}

	/**
	 * @description Logs a successful DML operation
	 * @param request The DML request that was processed
	 * @param results The Database.*Results returned from the DML operation
	 */
	global void processPostDml(Dml.Request request, List<Object> results) {
		// prettier-ignore
		List<String> lines = new List<String>{
			'✅ DML: Processed ' + this.getDmlOperationName(request?.operation),
			'Request:\n' + JSON.serialize(request)
		};
		String msg = String.join(lines, DELIMITER);
		LogEntryEventBuilder log = Logger.finest(msg)?.addTag(TAG_NAME)?.setRecord(request?.records);
		this.logDmlResults(log, results);
	}

	/**
	 * @description Logs DML errors
	 * @param request The DML request that encountered an error
	 * @param error The exception that was thrown
	 */
	global void processDmlError(Dml.Request request, Exception error) {
		// prettier-ignore
		List<String> lines = new List<String>{
			'🚨 DML: Error processing ' + this.getDmlOperationName(request?.operation),
			error + '\n' + error?.getStackTraceString(),
			'Request:\n' + JSON.serialize(request)
		};
		String msg = String.join(lines, DELIMITER);
		Logger.error(msg)?.addTag(TAG_NAME)?.setRecord(request?.records);
	}

	/**
	 * @description Logs SOQL requests before execution.
	 * @param request The SOQL request being processed
	 */
	global void processPreSoql(Soql.Request request) {
		// prettier-ignore
		List<String> lines = new List<String>{
			'⏳ SOQL: Processing ' + request?.operation + '...',
			'Query:\n' + request?.queryString
		};
		String msg = String.join(lines, DELIMITER);
		Logger.finest(msg)?.addTag(TAG_NAME);
	}

	/**
	 * @description Logs SOQL requests after execution.
	 * @param request The SOQL request that was processed
	 * @param results The results from the SOQL operation
	 */
	global void processPostSoql(Soql.Request request, Object results) {
		LogEntryEventBuilder log = Logger.finest('')?.addTag(TAG_NAME);
		// prettier-ignore
		List<String> lines = new List<String>{
			'✅ SOQL: Processed ' + request?.operation,
			request?.queryString
		};
		// Add the query results to the log, depending on their type
		if (results instanceOf List<SObject>) {
			// SObjects can be added to the log's related records, via the `setRecord` method
			// All other types will be appended to the log body itself
			List<SObject> records = (List<SObject>) results;
			log?.setRecord(records);
		} else if (results instanceOf Soql.QueryLocator) {
            // QueryLocators aren't serializable, and there isn't a performant way to determine the number of results:
			Soql.QueryLocator locator = (Soql.QueryLocator) results;
			lines?.add('Results:\n' + locator?.getLocator());
        } else {
            // All other possible query operations return serializable results:
			lines?.add('Results:\n' + JSON.serialize(results));
        }
		log?.setMessage(String.join(lines, DELIMITER));
	}

	/**
	 * @description Logs SOQL errors.
	 * @param request The SOQL request that failed
	 * @param error The exception that occurred
	 */
	global void processSoqlError(Soql.Request request, Exception error) {
		// prettier-ignore
		List<String> lines = new List<String>{
			'🚨 SOQL: Error processing ' + request?.operation,
			request?.queryString, 
            error + '\n' + error?.getStackTraceString()
		};
		String msg = String.join(lines, DELIMITER);
		Logger.error(msg)?.addTag(TAG_NAME);
	}

	// **** PRIVATE **** //
	private String getDmlOperationName(Dml.Operation operation) {
		return operation?.name()?.removeStart('DO_');
	}

	private void logDmlResults(LogEntryEventBuilder log, List<Object> objList) {
		// Note: Nebula Logger doesn't accept an untyped List<Object> in `setDatabaseResult`:
		if (objList instanceof List<Database.DeleteResult>) {
			List<Database.DeleteResult> results = (List<Database.DeleteResult>) objList;
			log?.setDatabaseResult(results);
		} else if (objList instanceof List<Database.LeadConvertResult>) {
			List<Database.LeadConvertResult> results = (List<Database.LeadConvertResult>) objList;
			log?.setDatabaseResult(results);
		} else if (objList instanceof List<Database.SaveResult>) {
			List<Database.SaveResult> results = (List<Database.SaveResult>) objList;
			log?.setDatabaseResult(results);
		} else if (objList instanceof List<Database.UndeleteResult>) {
			List<Database.UndeleteResult> results = (List<Database.UndeleteResult>) objList;
			log?.setDatabaseResult(results);
		} else if (objList instanceof List<Database.UpsertResult>) {
			List<Database.UpsertResult> results = (List<Database.UpsertResult>) objList;
			log?.setDatabaseResult(results);
		}
	}
}
