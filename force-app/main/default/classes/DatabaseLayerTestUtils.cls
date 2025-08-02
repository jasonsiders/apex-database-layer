/**
 * @description Test utility class providing common functionality and spy implementations for framework testing.
 */
@IsTest
public class DatabaseLayerTestUtils {
	// Note: These properties do not use traditional naming conventions to support a 'namespace-like' API
	@SuppressWarnings('PMD.FieldNamingConventions')
	public static final PreAndPostProcessorSpy DmlPluginSpy = new PreAndPostProcessorSpy();
	@SuppressWarnings('PMD.FieldNamingConventions')
	public static final PreAndPostProcessorSpy SoqlPluginSpy = new PreAndPostProcessorSpy();

	/**
	 * @description Creates a mock DatabaseLayerSetting__mdt for testing and injects it into the metadata selector.
	 * @return The created test settings object
	 */
	public static DatabaseLayerSetting__mdt initSettings() {
		DatabaseLayerSetting__mdt setting = new DatabaseLayerSetting__mdt();
		DatabaseLayer.Utils.MetadataSelector.settings = new List<DatabaseLayerSetting__mdt>{ setting };
		return setting;
	}

	// **** INNER **** //
	/**
	 * @description Spy implementation for tracking plugin method invocations during testing.
	 */
	public class PreAndPostProcessorSpy {
		public Integer numPreCalls { get; private set; }
		public Integer numPostCalls { get; private set; }
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
		public void processPreDml(Dml.Request request) {
			// Should be able to serialize the Dml.Request object:
			JSON.serialize(request, true);
			DatabaseLayerTestUtils.DmlPluginSpy.numPreCalls += 1;
		}

		public void processPostDml(Dml.Request request, List<Object> databaseResults) {
			DatabaseLayerTestUtils.DmlPluginSpy.numPostCalls += 1;
		}

		public void processDmlError(Dml.Request request, Exception error) {
			DatabaseLayerTestUtils.DmlPluginSpy.numErrorCalls += 1;
		}

		public void processPreSoql(Soql.Request request) {
			// Should be able to serialize the Soql.Request object:
			JSON.serialize(request, true);
			DatabaseLayerTestUtils.SoqlPluginSpy.numPreCalls += 1;
		}

		public void processPostSoql(Soql.Request request, Object results) {
			DatabaseLayerTestUtils.SoqlPluginSpy.numPostCalls += 1;
		}

		public void processSoqlError(Soql.Request request, Exception error) {
			DatabaseLayerTestUtils.SoqlPluginSpy.numErrorCalls += 1;
		}
	}
}
