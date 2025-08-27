/**
 * @description Utility for managing and initializing plugin implementations.
 */
@SuppressWarnings('PMD.AvoidDebugStatements')
public class DatabaseLayerPlugins {
    /**
     * @description The DML pre and post processor instance for this plugin configuration.
     */
    @SuppressWarnings('PMD.PropertyNamingConventions')
    public Dml.PreAndPostProcessor Dml { get; private set; }
    /**
     * @description The SOQL pre and post processor instance for this plugin configuration.
     */
    @SuppressWarnings('PMD.PropertyNamingConventions')
    public Soql.PreAndPostProcessor Soql { get; private set; }

    /**
     * @description Default constructor that initializes plugin instances.
     * @param factory The DatabaseLayer factory instance
     */
    public DatabaseLayerPlugins(DatabaseLayer factory) {
        this.init();
    }

    /**
     * @description Initializes a plugin instance based on custom metadata configuration.
     * @param field The SObjectField on DatabaseLayerSetting__mdt containing the plugin class name
     * @return The instantiated plugin object, or null if initialization fails
     */
    public Object initPlugin(SObjectField field) {
        String className;
        try {
            className = (String) DatabaseLayer.Utils?.Settings?.get(field);
            return (className != null) ? Type.forName(className)?.newInstance() : null;
        } catch (Exception error) {
            String source = DatabaseLayerPlugins.class.getName();
            String msg = source + ': Invalid ' + field + ': "' + className + '". Details: ' + error;
            System.debug(System.LoggingLevel.WARN, msg);
            return null;
        }
    }

    /**
     * @description Initialize the Dml/Soql plugins based on current DatabaseLayerSetting__mdt values
     */
    /* prettier-ignore */
    @TestVisible
    private void init() {
        this.Dml = (Dml.PreAndPostProcessor) this.initPlugin(DatabaseLayerSetting__mdt.DmlPreAndPostProcessor__c);
        this.Soql = (Soql.PreAndPostProcessor) this.initPlugin(DatabaseLayerSetting__mdt.SoqlPreAndPostProcessor__c);
    }
}