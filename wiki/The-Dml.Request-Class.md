Represents the parameters that the framework uses to process each DML statement. All requests include the records being processed, the DML operation being processed, and additional/optional configuration details.

This type cannot be manually constructed, and all of its properties are read-only. The framework auto-generates a `Dml.Request` object whenever you call a `DatabaseLayer.Dml` method.

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
      <td>accessLevel</td>
      <td>System.AccessLevel</td>
      <td>Determines if the DML operation is processed via SYSTEM_MODE or USER_MODE. Defaults to USER_MODE.</td>
    </tr>
    <tr>
      <td>accessLevelName</td>
      <td>String</td>
      <td>Outputs the name of the <em>accessLevel</em> property in JSON, since <code>System.AccessLevel</code> objects are not supported in JSON.</td>
    </tr>
    <tr>
      <td>deleteCallback</td>
      <td>String</td>
      <td>Prints the string-value of the <em>deleteCallback</em> property, which is omitted from JSON since its implementation may or may not be supported in JSON.</td>
    </tr>
    <tr>
      <td>saveCallback</td>
      <td>String</td>
      <td>Prints the string-value of the <em>saveCallback</em> property, which is omitted from JSON since its implementation may or may not be supported in JSON.</td>
    </tr>
    <tr>
      <td>asyncDeleteCallback</td>
      <td>DataSource.AsyncDeleteCallback</td>
      <td>A callback object that can optionally be passed to async DML delete methods that support external objects, ex. <code>DatabaseLayer.Dml.doDeleteAsync()</code>.</td>
    </tr>
    <tr>
      <td>externalIdFieldName</td>
      <td>String</td>
      <td>Prints the API Name of the <em>externalIdField</em>.</td>
    </tr>
    <tr>
      <td>externalIdField</td>
      <td>SObjectField</td>
      <td>An optional primary key field to be used in upsert operations.</td>
    </tr>
    <tr>
      <td>isMockDml</td>
      <td>Boolean</td>
      <td>True if the request was processed using <code>DatabaseLayer.useMocks()</code>. Else, always False.</td>
    </tr>
    <tr>
      <td>isOperationAsync</td>
      <td>Boolean</td>
      <td>True for async DML methods that support external objects, like <code>DatabaseLayer.Dml.doInsertAsync()</code>. Else, always False.</td>
    </tr>
    <tr>
      <td>isOperationImmediate</td>
      <td>Boolean</td>
      <td>True for synchronous DML methods that support external objects, like <code>DatabaseLayer.Dml.doInsertImmediate()</code>. Else, always False.</td>
    </tr>
    <tr>
      <td>leadsToConvert</td>
      <td>List&lt;Database.LeadConvert&gt;</td>
      <td>Leads to be converted; only present in a DO_CONVERT operation.</td>
    </tr>
    <tr>
      <td>numRecords</td>
      <td>Integer</td>
      <td>Outputs the number of records being processed. This can be useful, since <em>records</em> and <em>leadsToConvert</em> are always omitted from JSON output to conserve resources.</td>
    </tr>
    <tr>
      <td>operation</td>
      <td>Dml.Operation</td>
      <td>The type of DML operation being processed. This is always present.</td>
    </tr>
    <tr>
      <td>options</td>
      <td>Database.DmlOptions</td>
      <td>Stores advanced configuration options for the DML operation. The most common property is <em>OptAllOrNone</em>, which determines if partial failures are allowed.</td>
    </tr>
    <tr>
      <td>records</td>
      <td>List&lt;SObject&gt;</td>
      <td>The record(s) being processed. This is present in all operations, except DO_CONVERT.</td>
    </tr>
    <tr>
      <td>asyncSaveCallback</td>
      <td>DataSource.AsyncSaveCallback</td>
      <td>A callback object that can optionally be passed to async DML insert/update methods that support external objects, ex. <code>DatabaseLayer.Dml.doInsertAsync()</code>.</td>
    </tr>
    <tr>
      <td>sObjectType</td>
      <td>String</td>
      <td>Outputs the API Name of the SObjectType being processed, if known. For DO_CONVERT, outputs "Database.LeadConvert". When unknown, outputs "SObject".</td>
    </tr>
  </tbody>
</table>

### JSON-Serialization

For logging purposes, you can safely JSON-serialize the `Dml.Request`, though Some of the properties of this class may be omitted to save on resources, or because they are not supported in JSON.

Example:

```json
{
	"sObjectType": "Account",
	"options": {
		"OptAllOrNone": true,
		"EmailHeader": {},
		"DuplicateRuleHeader": {},
		"AssignmentRuleHeader": {}
	},
	"operation": "DO_INSERT",
	"numRecords": 1,
	"isOperationImmediate": false,
	"isOperationAsync": false,
	"isMockDml": false,
	"saveCallback": "EmptySaveCallback:[]",
	"deleteCallback": "EmptyDeleteCallback:[]",
	"accessLevelName": "USER_MODE"
}
```
