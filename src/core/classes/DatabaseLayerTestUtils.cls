/**
 * @description Test utility class providing common functionality and spy implementations for framework testing.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
@IsTest
global class DatabaseLayerTestUtils {
	// Note: These properties do not use traditional naming conventions to support a 'namespace-like' API
	@SuppressWarnings('PMD.FieldNamingConventions')
	public static final PreAndPostProcessorSpy DmlPluginSpy = new PreAndPostProcessorSpy();
	@SuppressWarnings('PMD.FieldNamingConventions')
	public static final PreAndPostProcessorSpy SoqlPluginSpy = new PreAndPostProcessorSpy();

	/**
	 * @description Mocks DatabaseLayerParameter__mdt records for DML and SOQL plugins and re-initializes plugins.
	 * @param className The fully-qualified Apex class name to use for both DML and SOQL pre/post processing
	 */
	global static void initDmlAndSoqlPlugins(String className) {
		DatabaseLayerParameter__mdt dmlParam = new DatabaseLayerParameter__mdt(
			DeveloperName = 'DmlPreAndPostProcessor',
			Value__c = className
		);
		DatabaseLayerParameter__mdt soqlParam = new DatabaseLayerParameter__mdt(
			DeveloperName = 'SoqlPreAndPostProcessor',
			Value__c = className
		);
		MockCmdt.mock(DatabaseLayerParameter__mdt.SObjectType)?.add(dmlParam)?.add(soqlParam);
		DatabaseLayer.Utils.Plugins.init();
	}

	// **** INNER **** //
	/**
	 * @description Spy implementation for tracking plugin method invocations during testing.
	 */
	public class PreAndPostProcessorSpy {
		/**
		 * @description Number of times the pre-processing method was called.
		 */
		public Integer numPreCalls { get; private set; }
		/**
		 * @description Number of times the post-processing method was called.
		 */
		public Integer numPostCalls { get; private set; }
		/**
		 * @description Number of times the error processing method was called.
		 */
		public Integer numErrorCalls { get; private set; }

		private PreAndPostProcessorSpy() {
			this.numPreCalls = 0;
			this.numPostCalls = 0;
			this.numErrorCalls = 0;
		}
	}

	/**
	 * @description Sample plugin implementation for testing both DML and SOQL processing hooks.
	 */
	public class SamplePlugin implements Dml.PreAndPostProcessor, Soql.PreAndPostProcessor {
		/**
		 * @description Processes DML requests before execution for testing purposes.
		 * @param request The DML request being processed
		 */
		public void processPreDml(Dml.Request request) {
			// Should be able to serialize the Dml.Request object:
			JSON.serialize(request, true);
			DatabaseLayerTestUtils.DmlPluginSpy.numPreCalls += 1;
		}

		/**
		 * @description Processes DML requests after execution for testing purposes.
		 * @param request The DML request that was processed
		 * @param databaseResults The results from the DML operation
		 */
		public void processPostDml(Dml.Request request, List<Object> databaseResults) {
			DatabaseLayerTestUtils.DmlPluginSpy.numPostCalls += 1;
		}

		/**
		 * @description Processes DML errors for testing purposes.
		 * @param request The DML request that failed
		 * @param error The exception that occurred
		 */
		public void processDmlError(Dml.Request request, Exception error) {
			DatabaseLayerTestUtils.DmlPluginSpy.numErrorCalls += 1;
		}

		/**
		 * @description Processes SOQL requests before execution for testing purposes.
		 * @param request The SOQL request being processed
		 */
		public void processPreSoql(Soql.Request request) {
			// Should be able to serialize the Soql.Request object:
			JSON.serialize(request, true);
			DatabaseLayerTestUtils.SoqlPluginSpy.numPreCalls += 1;
		}

		/**
		 * @description Processes SOQL requests after execution for testing purposes.
		 * @param request The SOQL request that was processed
		 * @param results The results from the SOQL operation
		 */
		public void processPostSoql(Soql.Request request, Object results) {
			DatabaseLayerTestUtils.SoqlPluginSpy.numPostCalls += 1;
		}

		/**
		 * @description Processes SOQL errors for testing purposes.
		 * @param request The SOQL request that failed
		 * @param error The exception that occurred
		 */
		public void processSoqlError(Soql.Request request, Exception error) {
			DatabaseLayerTestUtils.SoqlPluginSpy.numErrorCalls += 1;
		}
	}
}
