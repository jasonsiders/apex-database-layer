global virtual class Repository {
    global final Dml dml { get; protected set; }
    global final Soql soql { get; protected set; }

    global Repository() {
        this.dml = new Dml();
        this.soql = new Soql();
    }
}