@SuppressWarnings('PMD.AvoidGlobalModifier')
global class DatabaseLayerNebulaLoggerAdapter implements Dml.PreAndPostProcessor, Soql.PreAndPostProcessor {
    public static final String SCENARIO_NAME = 'apex-database-layer';

    /**
     * @description Called before executing a DML operation.
     * @param request The DML request to be processed
     */
    global void processPreDml(Dml.Request request) {
        // TODO
    }

    /**
     * @description Called after successfully executing a DML operation.
     * @param request The DML request that was processed
     * @param databaseResults The results returned from the DML operation
     */
    global void processPostDml(Dml.Request request, List<Object> databaseResults) {
        // TODO
    }

    /**
     * @description Called when a DML operation encounters an error.
     * @param request The DML request that encountered an error
     * @param error The exception that was thrown
     */
    global void processDmlError(Dml.Request request, Exception error) {
        // TODO
    }


    /**
     * @description Processes SOQL requests before execution.
     * @param request The SOQL request being processed
     */
    global void processPreSoql(Soql.Request request) {
        // TODO
    }

    /**
     * @description Processes SOQL requests after execution.
     * @param request The SOQL request that was processed
     * @param results The results from the SOQL operation
     */
    global void processPostSoql(Soql.Request request, Object results) {
        // TODO
    }

    /**
     * @description Processes SOQL errors.
     * @param request The SOQL request that failed
     * @param error The exception that occurred
     */
    global void processSoqlError(Soql.Request request, Exception error) {
        // TODO
    }

}
