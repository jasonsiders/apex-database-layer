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
        List<SObject> records = request?.records ?? new List<SObject>{};
        String op = this.getDmlOperationName(request?.operation);
        String msg = 'Processing DML ' + op + ' on ' + request?.numRecords + ' ' + request?.sObjectType + ' records';
        Logger.finest(msg)?.addTag(TAG_NAME)?.setRecord(records);
    }

    /**
     * @description Called after successfully executing a DML operation.
     * @param request The DML request that was processed
     * @param databaseResults The results returned from the DML operation
     */
    global void processPostDml(Dml.Request request, List<Object> databaseResults) {
        List<SObject> records = request?.records ?? new List<SObject>{};
        String op = this.getDmlOperationName(request?.operation);
        String msg = 'Processed DML ' + op + ' on ' + request?.numRecords + ' ' + request?.sObjectType + ' records\n\nRequest: ' + JSON.serialize(request) + '\n\nResults:\n' + JSON.serialize(databaseResults);
        Logger.finest(msg)?.addTag(TAG_NAME)?.setRecord(records);
    }

    /**
     * @description Called when a DML operation encounters an error.
     * @param request The DML request that encountered an error
     * @param error The exception that was thrown
     */
    global void processDmlError(Dml.Request request, Exception error) {
        List<SObject> records = request?.records ?? new List<SObject>{};
        String op = this.getDmlOperationName(request?.operation);
        String msg = 'Error processing DML ' + op + ':\n' + error + '\n' + error?.getStackTraceString() + '\n\nRequest: ' + JSON.serialize(request);
        Logger.error(msg)?.addTag(TAG_NAME)?.setRecord(records);
    }

    /**
     * @description Processes SOQL requests before execution.
     * @param request The SOQL request being processed
     */
    global void processPreSoql(Soql.Request request) {
        String msg = 'Processing SOQL ' + request?.operation + ':\n' + request?.queryString;
        Logger.finest(msg)?.addTag(TAG_NAME);
    }

    /**
     * @description Processes SOQL requests after execution.
     * @param request The SOQL request that was processed
     * @param results The results from the SOQL operation
     */
    global void processPostSoql(Soql.Request request, Object results) {
        String msg = 'Processed SOQL ' + request?.operation + ':\n' + request?.queryString + '\nResults: ' + results;
        Logger.finest(msg)?.addTag(TAG_NAME);
    }

    /**
     * @description Processes SOQL errors.
     * @param request The SOQL request that failed
     * @param error The exception that occurred
     */
    global void processSoqlError(Soql.Request request, Exception error) {
        String msg = 'Error processing SOQL ' + request?.operation + ':\n' + error + '\n' + error?.getStackTraceString() + '\n\nRequest: ' + JSON.serialize(request);
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
