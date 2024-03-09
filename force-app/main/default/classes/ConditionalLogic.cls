public abstract class ConditionalLogic implements ICriteria {
    protected List<ICriteria> criterion = new List<ICriteria>();
    protected final String predicate;

    public ConditionalLogic(String predicate) {
        this.predicate = predicate;
    }

    public abstract Boolean meetsCriteria(SObject record);

    public ConditionalLogic addCriteria(List<ICriteria> criterion) {
        this.criterion?.addAll(criterion);
        return this; 
    }

    public ConditionalLogic addCriteria(ICriteria criteria) {
        return this.addCriteria(new List<ICriteria>{ criteria });
    }

    public List<ICriteria> getCriteria() {
        return this.criterion;
    }

    public override String toString() {
        String delimiter = ' ' + this.predicate + ' ';
		List<String> criteriaStrings = new List<String>();
		for (ICriteria criteria : this.criterion) {
			// Wrap inner ConditionalLogic objects in parentheses
			String criteriaString = (criteria instanceof ConditionalLogic)
				? '(' + criteria?.toString() + ')'
				: criteria?.toString();
			criteriaStrings?.add(criteriaString);
		}
		return String.join(criteriaStrings, delimiter);
    }
}