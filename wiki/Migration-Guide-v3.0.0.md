Starting in `v3.0.0`, several deprecated methods and objects will be removed. These breaking changes will require planning and forethought to implement, if these deprecated artifacts are used in your codebase.

### Migration Steps

Follow these steps to succesfully migrate your package to `v3.0.0`:

#### 1. Install `v2.5.1`

This is the latest version of the package before `v3.0.0`. It contains _both_ the deprecated artifacts, and their replacements, making it suitable for migration.

You can find instructions to install this package [**here**](https://github.com/jasonsiders/apex-database-layer/releases/tag/version-2.5.1).

#### 2. Replace all references to the following methods:

<table>
  <thead>
    <tr>
      <th>Class</th>
      <th>Old Method</th>
      <th>New Method</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><a href="./The-MockDml-Class"><code>MockDml</code></a></td>
      <td><code>clearFailures</code></td>
      <td><code>shouldSucceed</code></td>
    </tr>
    <tr>
      <td><a href="./The-MockDml-Class"><code>MockDml</code></a></td>
      <td><code>fail</code></td>
      <td><code>shouldFail</code></td>
    </tr>
    <tr>
      <td><a href="./The-MockDml-Class"><code>MockDml</code></a></td>
      <td><code>failIf</code></td>
      <td><code>shouldFailIf</code></td>
    </tr>
    <tr>
      <td><code><a href="./The-MockDml.History-Class"><code>MockDml.History</code></a></code></td>
      <td><code>eraseHistory</code></td>
      <td><code>MockDml.eraseAllHistories</code></td>
    </tr>
    <tr>
      <td><code><a href="./The-MockDml.RecordHistory-Class"><code>MockDml.RecordHistory</code></a></code></td>
      <td><code>getRecord</code></td>
      <td><code>MockDml.get</code></td>
    </tr>
    <tr>
      <td><code><a href="./The-Soql-Class"><code>Soql</code></a></code></td>
      <td><code>bind</code></td>
      <td><code>addBind</code></td>
    </tr>
    <tr>
      <td><code><a href="./The-Soql-Class"><code>Soql</code></a></code></td>
      <td><code>defineAccess</code></td>
      <td><code>setAccessLevel</code></td>
    </tr>
    <tr>
      <td><code><a href="./The-Soql-Class"><code>Soql</code></a></code></td>
      <td><code>fromSObject</code></td>
      <td><code>setFrom</code></td>
    </tr>
    <tr>
      <td><code><a href="./The-Soql-Class"><code>Soql</code></a></code></td>
      <td><code>groupBy</code></td>
      <td><code>addGroupBy</code></td>
    </tr>
    <tr>
      <td><code><a href="./The-Soql-Class"><code>Soql</code></a></code></td>
      <td><code>orderBy</code></td>
      <td><code>addOrderBy</code></td>
    </tr>
    <tr>
      <td><code><a href="./The-Soql-Class"><code>Soql</code></a></code></td>
      <td><code>usingScope</code></td>
      <td><code>setScope</code></td>
    </tr>
  </tbody>
</table>

#### 3. Add `Dml.Operation` Method to `MockDml.ConditionalFailure`:

The [Dml.Operation](./The-Dml.Operation-Enum) enum replaces the `MockDml.Operation`. These enums have identical values.

Prior to `v3.0.0`, the `MockDml.ConditionalFailure`'s interface method references the _old_ enum:

```apex
public class MyImplementation implements MockDml.ConditionalFailure {
	public Exception checkFailure(MockDml.Operation operation, SObject record) {
		// Your implementaiton here!
	}
}
```

In `v3.0.0`, the `MockDml.ConditionalFailure` interface references the _new_ enum. The _old_ enum is removed in `v3.1.0` and later versions.

Therefore, you will need to (temporarily) create a duplicate method in your implementation, that is identical to the existing method, aside from the enum type that is used:

```apex
public class MyImplementation implements MockDml.ConditionalFailure {
	public Exception checkFailure(MockDml.Operation operation, SObject record) {
		// Old implementation, can be unchanged (for now)
	}

	public Exception checkFailure(Dml.Operation operation, SObject record) {
		// Duplicate the old implementation, `operation` type aside:
	}
}
```

#### 4. Install `v3.0.0`

`v3.0.0` removes most of the deprecated artifacts, with the exception of `MockDml.Operation`. Install this package here:

You can find instructions to install this package [**here**](https://github.com/jasonsiders/apex-database-layer/releases/tag/v3.0.0).

#### 5. Remove `MockDml.Operation` from `MockDml.ConditionalFailure`

Now that `v3.0.0` has been installed, you can safely remove the old `MockDml.Operation` method from your `MockDml.ConditionalFailure` implementation:

```apex
public class MyImplementation implements MockDml.ConditionalFailure {
	public Exception checkFailure(Dml.Operation operation, SObject record) {
		// Your implementation here
	}
}
```

:tada: Congrats! If you made it this far, your installation has been successfully upgraded.
