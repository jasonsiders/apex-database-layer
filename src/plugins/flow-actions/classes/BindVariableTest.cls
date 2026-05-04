@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@IsTest
private class BindVariableTest {
	@IsTest
	private static void shouldDeserializeFallbackTextValues() {
		BindVariable stringBind = new BindVariable();
		stringBind.key = 'name';
		stringBind.textValue = null;
		stringBind.typeName = 'String';
		stringBind.isCollection = false;
		BindVariable booleanBind = new BindVariable();
		booleanBind.key = 'active';
		booleanBind.textValue = 'true';
		booleanBind.typeName = 'Boolean';
		booleanBind.isCollection = false;
		BindVariable textCollectionBind = new BindVariable();
		textCollectionBind.key = 'names';
		textCollectionBind.textValue = '["Acme","Beta"]';
		textCollectionBind.typeName = 'String';
		textCollectionBind.isCollection = true;

		Assert.isNull(stringBind.toSoqlBinder().getValue(), 'Null string fallback should stay null');
		Assert.areEqual(true, booleanBind.toSoqlBinder().getValue(), 'Boolean fallback should deserialize');
		Assert.areEqual(
			new List<String>{ 'Acme', 'Beta' },
			textCollectionBind.toSoqlBinder().getValue(),
			'String collection fallback should deserialize'
		);
	}

	@IsTest
	private static void shouldResolveTypedScalarBindValues() {
		Date dateValue = Date.newInstance(2026, 5, 3);
		Datetime datetimeValue = Datetime.newInstance(2026, 5, 3, 12, 30, 0);
		Time timeValue = Time.newInstance(12, 30, 0, 0);

		BindVariable booleanBind = new BindVariable();
		booleanBind.key = 'active';
		booleanBind.booleanValue = true;
		booleanBind.typeName = 'Boolean';
		booleanBind.isCollection = false;
		BindVariable dateBind = new BindVariable();
		dateBind.key = 'closeDate';
		dateBind.dateValue = dateValue;
		dateBind.typeName = 'Date';
		dateBind.isCollection = false;
		BindVariable datetimeBind = new BindVariable();
		datetimeBind.key = 'createdDate';
		datetimeBind.datetimeValue = datetimeValue;
		datetimeBind.typeName = 'Datetime';
		datetimeBind.isCollection = false;
		BindVariable decimalBind = new BindVariable();
		decimalBind.key = 'amount';
		decimalBind.decimalValue = 10.5;
		decimalBind.typeName = 'Decimal';
		decimalBind.isCollection = false;
		BindVariable textBind = new BindVariable();
		textBind.key = 'name';
		textBind.textValue = 'Acme';
		textBind.typeName = 'String';
		textBind.isCollection = false;
		BindVariable timeBind = new BindVariable();
		timeBind.key = 'startTime';
		timeBind.timeValue = timeValue;
		timeBind.typeName = 'Time';
		timeBind.isCollection = false;

		Assert.areEqual(true, booleanBind.toSoqlBinder().getValue(), 'Boolean bind should use typed value');
		Assert.areEqual(dateValue, dateBind.toSoqlBinder().getValue(), 'Date bind should use typed value');
		Assert.areEqual(datetimeValue, datetimeBind.toSoqlBinder().getValue(), 'Datetime bind should use typed value');
		Assert.areEqual(10.5, decimalBind.toSoqlBinder().getValue(), 'Decimal bind should use typed value');
		Assert.areEqual('Acme', textBind.toSoqlBinder().getValue(), 'Text bind should use typed value');
		Assert.areEqual(timeValue, timeBind.toSoqlBinder().getValue(), 'Time bind should use typed value');
	}

	@IsTest
	private static void shouldResolveTypedCollectionBindValues() {
		List<Boolean> booleanValues = new List<Boolean>{ true, false };
		List<Date> dateValues = new List<Date>{ Date.newInstance(2026, 5, 3) };
		List<Datetime> datetimeValues = new List<Datetime>{ Datetime.newInstance(2026, 5, 3, 12, 30, 0) };
		List<Decimal> decimalValues = new List<Decimal>{ 10.5, 20.25 };
		List<String> textValues = new List<String>{ 'Acme', 'Beta' };
		List<Time> timeValues = new List<Time>{ Time.newInstance(12, 30, 0, 0) };

		BindVariable booleanBind = new BindVariable();
		booleanBind.key = 'active';
		booleanBind.booleanValues = booleanValues;
		booleanBind.typeName = 'Boolean';
		booleanBind.isCollection = true;
		BindVariable dateBind = new BindVariable();
		dateBind.key = 'closeDates';
		dateBind.dateValues = dateValues;
		dateBind.typeName = 'Date';
		dateBind.isCollection = true;
		BindVariable datetimeBind = new BindVariable();
		datetimeBind.key = 'createdDates';
		datetimeBind.datetimeValues = datetimeValues;
		datetimeBind.typeName = 'Datetime';
		datetimeBind.isCollection = true;
		BindVariable decimalBind = new BindVariable();
		decimalBind.key = 'amounts';
		decimalBind.decimalValues = decimalValues;
		decimalBind.typeName = 'Decimal';
		decimalBind.isCollection = true;
		BindVariable textBind = new BindVariable();
		textBind.key = 'names';
		textBind.textValues = textValues;
		textBind.typeName = 'String';
		textBind.isCollection = true;
		BindVariable timeBind = new BindVariable();
		timeBind.key = 'startTimes';
		timeBind.timeValues = timeValues;
		timeBind.typeName = 'Time';
		timeBind.isCollection = true;

		Assert.areEqual(
			booleanValues,
			booleanBind.toSoqlBinder().getValue(),
			'Boolean collection should use typed value'
		);
		Assert.areEqual(dateValues, dateBind.toSoqlBinder().getValue(), 'Date collection should use typed value');
		Assert.areEqual(
			datetimeValues,
			datetimeBind.toSoqlBinder().getValue(),
			'Datetime collection should use typed value'
		);
		Assert.areEqual(
			decimalValues,
			decimalBind.toSoqlBinder().getValue(),
			'Decimal collection should use typed value'
		);
		Assert.areEqual(textValues, textBind.toSoqlBinder().getValue(), 'Text collection should use typed value');
		Assert.areEqual(timeValues, timeBind.toSoqlBinder().getValue(), 'Time collection should use typed value');
	}

	@SuppressWarnings('PMD.EmptyCatchBlock')
	@IsTest
	private static void shouldThrowForUndeserializableFallbackValue() {
		BindVariable booleanBind = new BindVariable();
		booleanBind.key = 'active';
		booleanBind.textValue = 'NotABoolean';
		booleanBind.typeName = 'Boolean';
		booleanBind.isCollection = false;

		try {
			booleanBind.toSoqlBinder();
			Assert.fail('Should have thrown an exception');
		} catch (System.IllegalArgumentException expectedError) {
			// Expected
		}
	}

	@SuppressWarnings('PMD.EmptyCatchBlock')
	@IsTest
	private static void shouldThrowForUnknownType() {
		BindVariable unknownBind = new BindVariable();
		unknownBind.key = 'unknown';
		unknownBind.textValue = 'Acme';
		unknownBind.typeName = 'UnknownType123';
		unknownBind.isCollection = false;

		try {
			unknownBind.toSoqlBinder();
			Assert.fail('Should have thrown an exception');
		} catch (System.TypeException expectedError) {
			// Expected
		}
	}
}
