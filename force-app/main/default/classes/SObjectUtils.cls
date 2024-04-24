public abstract class SObjectUtils {
    static Integer numMockIds = 0; 

    public static Id generateMockId(SObjectType objectType) {
        String prefix = objectType?.getDescribe()?.getKeyPrefix();
        String suffix = String.valueOf(numMockIds++);
        String mid = 0?.toString()?.repeat(15 - suffix?.length());
        return prefix + mid + suffix;
    }
}