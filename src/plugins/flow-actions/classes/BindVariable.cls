/**
 * @description Apex-defined Flow type for a named SOQL bind variable.
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class BindVariable {
	/**
	 * @description Bind variable name referenced by the SOQL query.
	 */
	@AuraEnabled
	global String key { get; set; }
	/**
	 * @description JSON-compatible text value used for scalar text values and literal fallback parsing.
	 */
	@AuraEnabled
	global String textValue { get; set; }
	/**
	 * @description Text collection bind value supplied directly by Flow.
	 */
	@AuraEnabled
	global List<String> textValues { get; set; }
	/**
	 * @description Boolean bind value supplied directly by Flow.
	 */
	@AuraEnabled
	global Boolean booleanValue { get; set; }
	/**
	 * @description Boolean collection bind value supplied directly by Flow.
	 */
	@AuraEnabled
	global List<Boolean> booleanValues { get; set; }
	/**
	 * @description Date bind value supplied directly by Flow.
	 */
	@AuraEnabled
	global Date dateValue { get; set; }
	/**
	 * @description Date collection bind value supplied directly by Flow.
	 */
	@AuraEnabled
	global List<Date> dateValues { get; set; }
	/**
	 * @description Date/time bind value supplied directly by Flow.
	 */
	@AuraEnabled
	global Datetime datetimeValue { get; set; }
	/**
	 * @description Date/time collection bind value supplied directly by Flow.
	 */
	@AuraEnabled
	global List<Datetime> datetimeValues { get; set; }
	/**
	 * @description Number bind value supplied directly by Flow.
	 */
	@AuraEnabled
	global Decimal decimalValue { get; set; }
	/**
	 * @description Number collection bind value supplied directly by Flow.
	 */
	@AuraEnabled
	global List<Decimal> decimalValues { get; set; }
	/**
	 * @description Time bind value supplied directly by Flow.
	 */
	@AuraEnabled
	global Time timeValue { get; set; }
	/**
	 * @description Time collection bind value supplied directly by Flow.
	 */
	@AuraEnabled
	global List<Time> timeValues { get; set; }
	/**
	 * @description Apex type name used to deserialize literal fallback values.
	 */
	@AuraEnabled
	global String typeName { get; set; }
	/**
	 * @description Whether the bind value should resolve as a List of the configured type.
	 */
	@AuraEnabled
	global Boolean isCollection { get; set; }

	/**
	 * @description Resolves the target Apex type, wrapping in List<> when isCollection is true.
	 * @return The resolved Apex Type
	 */
	public Type getType() {
		String resolvedName = this.resolveTypeName();
		Type type = Type.forName(resolvedName);
		if (type == null) {
			throw new System.TypeException('Invalid type: ' + resolvedName);
		}
		return type;
	}

	/**
	 * @description Resolves the bind value from typed Flow fields or text fallback.
	 * @return The resolved bind value as its configured Apex type
	 */
	public Object getValue() {
		Object typedValue = this.getTypedValue();
		if (typedValue != null) {
			return typedValue;
		}
		Type type = this.getType();
		return this.convertFromTextTo(type);
	}

	/**
	 * @description Converts the BindVariable to a formal Soql.Binder object.
	 * @return A Soql.Binder representation of the current object
	 */
	public Soql.Binder toSoqlBinder() {
		return new Soql.Binder(this.key, this.getValue());
	}

	/**
	 * @description Deserializes textValue into the given Apex type.
	 * @param type The target Apex type to deserialize into
	 * @return The deserialized object
	 */
	private Object convertFromTextTo(Type type) {
		try {
			// prettier-ignore
			return (this.isCollection != true && this.typeName == 'String')
				? this.textValue
				: JSON.deserialize(this.textValue, type);
		} catch (System.JsonException error) {
			String msg = 'Invalid ' + type + ' value: ' + this.textValue + '\n' + error;
			throw new System.IllegalArgumentException(msg);
		}
	}

	/**
	 * @description Resolves a collection value supplied by Flow.
	 * @return The typed collection value, or null if no typed collection field is populated
	 */
	private Object getTypedCollectionValue() {
		switch on this.typeName {
			when 'Boolean' {
				return this.booleanValues;
			}
			when 'Date' {
				return this.dateValues;
			}
			when 'Datetime' {
				return this.datetimeValues;
			}
			when 'Decimal' {
				return this.decimalValues;
			}
			when 'Time' {
				return this.timeValues;
			}
			when else {
				return this.textValues;
			}
		}
	}

	/**
	 * @description Resolves a scalar value supplied by Flow.
	 * @return The typed scalar value, or null if no typed scalar field is populated
	 */
	private Object getTypedScalarValue() {
		switch on this.typeName {
			when 'Boolean' {
				return this.booleanValue;
			}
			when 'Date' {
				return this.dateValue;
			}
			when 'Datetime' {
				return this.datetimeValue;
			}
			when 'Decimal' {
				return this.decimalValue;
			}
			when 'String' {
				return this.textValue;
			}
			when 'Time' {
				return this.timeValue;
			}
			when else {
				return null;
			}
		}
	}

	/**
	 * @description Resolves the typed Flow value that matches typeName and isCollection.
	 * @return The typed Flow value, or null when the bind uses text fallback
	 */
	private Object getTypedValue() {
		return (this.isCollection == true) ? this.getTypedCollectionValue() : this.getTypedScalarValue();
	}

	/**
	 * @description Builds the Apex type name string, prepending List<> when isCollection is true.
	 * @return The resolved type name string
	 */
	private String resolveTypeName() {
		return (this.isCollection == true) ? 'List<' + this.typeName + '>' : this.typeName;
	}
}
