/**
 * @description Adapter class that integrates Nebula Logger with the Apex Database Layer framework.
 *              Implements both DML and SOQL pre/post processors to log database operations.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global class DatabaseLayerNebulaLoggerAdapter implements Dml.PreAndPostProcessor, Soql.PreAndPostProcessor {
	public static final String TAG_NAME = 'apex-database-layer';

	/**
	 * @description Configure Nebula Logger to ignore database layer framework classes in log stack traces
	 */
	global DatabaseLayerNebulaLoggerAdapter() {
		this.omitFrameworkFromLogStackTrace();
	}

	/**
	 * @description Called before executing a DML operation.
	 * @param request The DML request to be processed
	 */
	global void processPreDml(Dml.Request request) {
		List<String> lines = new List<String>{
			'⏳ Processing DML ' +
			this.getDmlOperationName(request?.operation) +
			'...',
			'Request:\n' + JSON.serialize(request)
		};
		String msg = String.join(lines, '\n\n');
		Logger.finest(msg)?.addTag(TAG_NAME)?.setRecord(request?.records);
	}

	/**
	 * @description Called after successfully executing a DML operation.
	 * @param request The DML request that was processed
	 * @param results The Database.*Results returned from the DML operation
	 */
	global void processPostDml(Dml.Request request, List<Object> results) {
		List<String> lines = new List<String>{
			'✅ Processed DML ' + this.getDmlOperationName(request?.operation),
			'Request:\n' + JSON.serialize(request),
			'Results:\n' + JSON.serialize(results)
		};
		String msg = String.join(lines, '\n\n');
		Logger.finest(msg)?.addTag(TAG_NAME)?.setRecord(request?.records);
	}

	/**
	 * @description Called when a DML operation encounters an error.
	 * @param request The DML request that encountered an error
	 * @param error The exception that was thrown
	 */
	global void processDmlError(Dml.Request request, Exception error) {
		List<String> lines = new List<String>{
			'🚨 Error processing DML ' + this.getDmlOperationName(request?.operation),
			'Error:\n' +
			error +
			'\n' +
			error?.getStackTraceString(),
			'Request:\n' + JSON.serialize(request)
		};
		String msg = String.join(lines, '\n\n');
		Logger.error(msg)?.addTag(TAG_NAME)?.setRecord(request?.records);
	}

	/**
	 * @description Processes SOQL requests before execution.
	 * @param request The SOQL request being processed
	 */
	global void processPreSoql(Soql.Request request) {
		List<String> lines = new List<String>{
			'⏳ Processing SOQL ' +
			request?.operation +
			'...',
			'Query:\n' + request?.queryString
		};
		String msg = String.join(lines, '\n\n');
		Logger.finest(msg)?.addTag(TAG_NAME);
	}

	/**
	 * @description Processes SOQL requests after execution.
	 * @param request The SOQL request that was processed
	 * @param results The results from the SOQL operation
	 */
	global void processPostSoql(Soql.Request request, Object results) {
		List<String> lines = new List<String>{
			'✅ Processed SOQL ' +
			request?.operation +
			':',
			'Query:\n' + request?.queryString,
			'Results:\n' + results
		};
		String msg = String.join(lines, '\n\n');
		Logger.finest(msg)?.addTag(TAG_NAME);
	}

	/**
	 * @description Processes SOQL errors.
	 * @param request The SOQL request that failed
	 * @param error The exception that occurred
	 */
	global void processSoqlError(Soql.Request request, Exception error) {
		List<String> lines = new List<String>{
			'🚨 Error processing SOQL ' +
			request?.operation +
			':',
			'Error:\n' +
			error +
			'\n' +
			error?.getStackTraceString(),
			'Query:\n' + request?.queryString
		};
		String msg = String.join(lines, '\n\n');
		Logger.error(msg)?.addTag(TAG_NAME);
	}

	private String getDmlOperationName(Dml.Operation operation) {
		return operation?.name()?.removeStart('DO_');
	}

	private void omitFrameworkFromLogStackTrace() {
		// Prevent framework-specific method calls from polluting Nebula Logger's stack trace
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
}
