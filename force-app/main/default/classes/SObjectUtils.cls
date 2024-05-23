public abstract class SObjectUtils {
    static Integer numMockIds = 0; 

    public static Id mockRecordId(SObjectType objectType) {
        String prefix = objectType?.getDescribe()?.getKeyPrefix();
        String suffix = String.valueOf(numMockIds++);
        String mid = 0?.toString()?.repeat(15 - suffix?.length());
        return prefix + mid + suffix;
    }

    public static Id mockPlatformEventId(SObjectType objectType) {
        // Note: The Id of Platform Events is always a static/non-unique value across all events
        // It does not need to be incremented for uniqueness
        return objectType?.getDescribe()?.getKeyPrefix() + '0'?.repeat(15); 
    }
}