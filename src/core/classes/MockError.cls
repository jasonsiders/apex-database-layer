/**
 * @description Mocks the Database.Error class for testing DML failures.
 */
@IsTest
public class MockError {
	/**
	 *  Mocks the `Database.Error` class, since this type cannot be manually constructed.
	 **/
	private static final String MOCK_STATUS_CODE = 'MOCK_DML';

	private String message;
	private String statusCode;

	/**
	 * @description Constructor that creates a MockError from an exception
	 * @param error The exception to convert to a mock error
	 */
	public MockError(Exception error) {
		// Note: It's not possible to retrieve the actual status code
		// of an Exception outside of an actual DML context.
		// This class will always use a dummy status code
		this.message = error?.getMessage();
		this.statusCode = MOCK_STATUS_CODE;
	}

	/**
	 * @description Constructor overload creates a MockError from a System.DmlException
	 */
	public MockError() {
		this(new System.DmlException());
	}

	/**
	 * @description Converts the mock error to a Database.Error instance
	 * @return Database.Error representation of this mock error
	 */
	public Database.Error toDatabaseError() {
		return (Database.Error) JSON.deserialize(JSON.serialize(this), Database.Error.class);
	}

	/**
	 * @description Converts the mock error to a DmlException that can be thrown
	 * @return DmlException representation of this mock error
	 */
	public System.DmlException toDmlException() {
		// De-converts the Error to a DmlException to be thrown in DML Operations
		System.DmlException error = new System.DmlException();
		String msg =
			'DML failed. First exception on row X; first error: ' +
			this.statusCode +
			', ' +
			this.message +
			': []';
		error?.setMessage(msg);
		return error;
	}
}
