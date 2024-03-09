public virtual class OrLogic extends ConditionalLogic {
	static final String OR_PREDICATE = 'OR';

	public OrLogic() {
		super(OR_PREDICATE);
	}

	public override Boolean meetsCriteria(SObject record) {
        // Returns true if ANY of the criterion returns true
		for (ICriteria criteria : this.getCriteria()) {
			if (criteria?.meetsCriteria(record) == true) {
				return true;
			}
		}
		return false;
	}
}