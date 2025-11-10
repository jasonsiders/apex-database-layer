@IsTest
global class MockDuplicates extends Duplicates {
    @SuppressWarnings('PMD.EmptyStatementBlock')
	public MockDuplicates(DatabaseLayer factory) {
		// Note: Only accessible via DatabaseLayer.Duplicates
        super(factory);
	}
}