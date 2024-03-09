public virtual class AndLogic extends ConditionalLogic {
	static final String AND_PREDICATE = 'AND';

	public AndLogic() {
		super(AND_PREDICATE); 
	}

	public override Boolean meetsCriteria(SObject record) {
        // Returns true if ALL of the criterion returns true
		for (ICriteria criteria : this.getCriteria()) {
			if (criteria?.meetsCriteria(record) == false) {
				return false;
			}
		}
		return true;
	}
}