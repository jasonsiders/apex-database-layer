@IsTest
private class DummyClass {
	@IsTest
	static void shouldFail() {
		Assert.fail('Sheeeeeeeeeeeesh');
	}
}
