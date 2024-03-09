public virtual class Repository {
    public final Dml dml { get; protected set; }
    public final Soql soql { get; protected set; }

    public Repository() {
        this.dml = new Dml();
        this.soql = new Soql();
    }
}