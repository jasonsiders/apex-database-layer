@IsTest
public class DatabaseLayerTestUtils {
	public static final PreAndPostProcessorSpy DmlPluginSpy = new PreAndPostProcessorSpy();
	public static final PreAndPostProcessorSpy SoqlPluginSpy = new PreAndPostProcessorSpy();

	public static DatabaseLayerSetting__mdt initSettings() {
		// Initialize a DatabaseLayerSetting__mdt settings object,
		// and override the metadata selector's logic to return this object instead of what's in the org:
		DatabaseLayerSetting__mdt setting = new DatabaseLayerSetting__mdt();
		DatabaseLayer.Utils.MetadataSelector.settings = new List<DatabaseLayerSetting__mdt>{ setting };
		return setting;
	}

	// **** INNER **** //
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
			DatabaseLayerTestUtils.SoqlPluginSpy.numPreCalls += 1;
		}

		public void processPostSoql(Soql.Request request, Object results) {
			// Should be able to serialize the query results:
			String resultsJson = JSON.serialize(results);
			DatabaseLayerTestUtils.SoqlPluginSpy.numPostCalls += 1;
		}

		public void processSoqlError(Soql.Request request, Exception error) {
			DatabaseLayerTestUtils.SoqlPluginSpy.numErrorCalls += 1;
		}
	}
}
