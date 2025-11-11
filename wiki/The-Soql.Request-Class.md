Represents the parameters that the framework uses to process each SOQL statement. All requests include the structure ofthe query being processed, and the operation being processed.

This type cannot be manually constructed, and all of its properties are read-only. The framework auto-generates a `Soql.Request` object whenever you call a `DatabaseLayer.Soql` method.

### Properties:

All properties are read-only, and optional unless otherwise otherwise stated:

<table>
  <thead>
    <tr>
      <th>Property Name</th>
      <th>Data Type</th>
      <th>Details</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>isMockSoql</td>
      <td>Boolean</td>
      <td>True if the request was processed using <code>DatabaseLayer.useMocks()</code>. Else, always False.</td>
    </tr>
    <tr>
      <td>operation</td>
      <td>Soql.Operation</td>
      <td>The type of SOQL operation being processed.</td>
    </tr>
    <tr>
      <td>query</td>
      <td>Soql</td>
      <td>The query object to be processed.</td>
    </tr>
    <tr>
      <td>queryString</td>
      <td>String</td>
      <td>The text of the query to be processed.</td>
    </tr>
  </tbody>
</table>

### JSON-Serialization

For logging purposes, you can safely JSON-serialize the `Dml.Request`, though Some of the properties of this class may be omitted to save on resources, or because they are not supported in JSON.

```json
{
	"queryString": "SELECT Id FROM Account",
	"query": {
		"whereCriteria": {
			"logicType": "ALL_CONDITIONS",
			"criterion": []
		},
		"selectClauses": ["Id"],
		"orderByClauses": [],
		"havingCriteria": {
			"logicType": "ALL_CONDITIONS",
			"criterion": []
		},
		"groupByClauses": [],
		"entity": "Account",
		"binds": {},
		"accessLevelName": "USER_MODE"
	},
	"operation": "QUERY",
	"isMockSoql": false
}
```
