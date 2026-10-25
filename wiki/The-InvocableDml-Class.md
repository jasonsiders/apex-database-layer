The base class of the record [flow actions](./Performing-DML-in-Flow): Insert Record(s), Update Record(s), Upsert Record(s), Delete Record(s), Undelete Record(s), and Empty Recycle Bin. It combines a batch of flow interviews into one DML operation, and returns each interview's records and results to it.

Each action extends `InvocableDml`, and implements `doDml` to perform its operation through [`DatabaseLayer.Dml`](./The-Dml-Class). Convert Lead takes a lead ID instead of records, so it doesn't extend this class.

## Methods

### `run`

Performs one DML operation on every input's records, using the first input's settings. Returns one [`InvocableDml.Output`](./The-InvocableDml.Output-Class) per [`InvocableDml.Input`](./The-InvocableDml.Input-Class), in the same order. When no input has records, it returns the outputs without performing DML.

Records are passed to the DML operation as they are. Like Apex DML, the operation rejects a record listed twice, so callers must remove duplicates first.

- `List<InvocableDml.Output> run(List<InvocableDml.Input> inputs)`

```apex
InvocableDml.Input input = new InvocableDml.Input();
input.recordCollection = new List<Account>{ new Account(Name = 'Acme') };
List<InvocableDml.Input> inputs = new List<InvocableDml.Input>{ input };
List<InvocableDml.Output> outputs = new InvocableDmlInsertRecords().run(inputs);
```

### `doDml`

Performs the action's DML operation. `run` calls it once, with every input's records and the first input's settings. It must return one result per record, in record order.

- `protected abstract List<InvocableDmlResult> doDml(List<SObject> records, InvocableDml.Input settings)`

```apex
public inherited sharing class InvocableDmlInsertRecords extends InvocableDml {
	@InvocableMethod(category='Database Layer' label='DML: Insert Record(s)')
	public static List<InvocableDml.Output> invoke(List<InvocableDml.Input> inputs) {
		return new InvocableDmlInsertRecords().run(inputs);
	}

	protected override List<InvocableDmlResult> doDml(List<SObject> records, InvocableDml.Input settings) {
		Database.DmlOptions options = settings?.initDmlOptions();
		System.AccessLevel accessLevel = settings?.getAccessLevel();
		List<Database.SaveResult> results = DatabaseLayer.Dml?.doInsert(records, options, accessLevel);
		return InvocableDmlResult.fromList(results);
	}
}
```
