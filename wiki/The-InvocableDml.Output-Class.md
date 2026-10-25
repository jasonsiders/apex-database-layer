One flow interview's output from a record [flow action](./Performing-DML-in-Flow): its processed records, and their results.

[`InvocableDml.run`](./The-InvocableDml-Class) returns one output per [`InvocableDml.Input`](./The-InvocableDml.Input-Class), in the same order. Each output's records and results are in the same order as its input's records.

## Properties

| Property Name    | Data Type                                                        | Details                                                                                     |
| ---------------- | ---------------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| record           | SObject                                                          | The processed record. For a collection, the first record.                                   |
| recordCollection | List&lt;SObject&gt;                                              | The processed records, in input order. Inserted and upserted records include their new IDs. |
| result           | [InvocableDmlResult](./The-InvocableDmlResult-Class)             | The result for the record. For a collection, the first result.                              |
| resultCollection | List&lt;[InvocableDmlResult](./The-InvocableDmlResult-Class)&gt; | One result per record, in input order.                                                      |
