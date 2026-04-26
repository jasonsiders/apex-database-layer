The `FlowUntypedVariable` class represents a loosely-typed variable passed from a Salesforce Flow. This class provides Flows a way to flexibly pass untyped objects to Apex actions, enabling dynamic type resolution at runtime.

This class is particularly useful in Flow actions where the exact type of data being passed may vary, allowing for more flexible Flow-to-Apex integrations.

## Properties

### `key`

The variable's identifier within the Flow.

- **Type:** `String`
- **Access:** `global`

### `textValue`

The variable's value, serialized as a JSON string.

- **Type:** `String`
- **Access:** `global`

### `typeName`

The Apex type name to deserialize the value into (e.g., `String`, `Integer`, `Account`).

- **Type:** `String`
- **Access:** `global`

### `isCollection`

When `true`, the value is deserialized as a `List` of the specified type.

- **Type:** `Boolean`
- **Access:** `global`

## Constructors

### `FlowUntypedVariable()`

Initializes the variable with `isCollection` defaulting to `false`.

```apex
FlowUntypedVariable var = new FlowUntypedVariable();
// var.isCollection is automatically set to false
```

## Methods

### `getValue`

Deserializes `textValue` into the Apex type described by `typeName` and `isCollection`.

- **Signature:** `global Object getValue()`
- **Returns:** The deserialized value as its resolved Apex type

**Example Usage:**

```apex
// Create a variable for a String value
FlowUntypedVariable stringVar = new FlowUntypedVariable();
stringVar.typeName = 'String';
stringVar.textValue = '"Hello World"'; // JSON-serialized string
String result = (String) stringVar.getValue();

// Create a variable for a collection of Integers
FlowUntypedVariable intListVar = new FlowUntypedVariable();
intListVar.typeName = 'Integer';
intListVar.isCollection = true;
intListVar.textValue = '[1, 2, 3, 4, 5]'; // JSON-serialized list
List<Integer> intList = (List<Integer>) intListVar.getValue();

// Create a variable for an Account record
FlowUntypedVariable accountVar = new FlowUntypedVariable();
accountVar.typeName = 'Account';
accountVar.textValue = '{"Name": "Acme Corp", "Type": "Customer"}';
Account account = (Account) accountVar.getValue();
```

**Exceptions:**
- Throws `System.IllegalArgumentException` if the `textValue` cannot be deserialized into the specified type
- Throws `System.TypeException` if the `typeName` does not resolve to a valid Apex type