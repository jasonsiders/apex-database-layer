public abstract class InvocableDmlConvertRecords {
    @InvocableMethod(category='Database Layer' label='Convert Record(s)' iconName='slds:standard:maintenance_work_rule')
    public static List<InvocableDml.ConvertOutput> invoke(List<InvocableDml.ConvertInput> inputs) {
        return new List<InvocableDml.ConvertOutput>{};
    }
}
