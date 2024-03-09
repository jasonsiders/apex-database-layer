public interface ICriteria {
    Boolean meetsCriteria(SObject record);
    String toString();
}