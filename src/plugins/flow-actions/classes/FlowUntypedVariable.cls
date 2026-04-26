@SuppressWarnings('PMD.AvoidGlobalModifier')
/**
 * @description Represents a loosely-typed variable passed from a Flow, carrying a value as serialized text along with metadata needed to deserialize it into the correct Apex type
 */
global class FlowUntypedVariable {
	/** @description The variable's identifier within the Flow */
	@AuraEnabled
	global String key;
	/** @description The variable's value, serialized as a JSON string */
	@AuraEnabled
	global String textValue;
	/** @description The Apex type name to deserialize the value into (e.g., `String`, `Integer`, `Account`) */
	@AuraEnabled
	global String typeName;
	/** @description When `true`, the value is deserialized as a `List` of the specified type */
	@AuraEnabled
	global Boolean isCollection;

	/**
	 * @description Initializes the variable with `isCollection` defaulting to `false`
	 */
	global FlowUntypedVariable() {
		this.isCollection = false;
	}

	/**
	 * @description Deserializes `textValue` into the Apex type described by `typeName` and `isCollection`
	 * @return The deserialized value as its resolved Apex type
	 */
	global Object getValue() {
		Type type = this.determineType();
		return this.convertFromTextTo(type);
	}

	/**
	 * @description Deserializes `textValue` into the given Apex type
	 * @param type The target Apex type to deserialize into
	 * @return The deserialized object
	 */
	private Object convertFromTextTo(Type type) {
		try {
			return JSON.deserialize(textValue, type);
		} catch (System.JsonException error) {
			String msg = 'Invalid ' + type + ' value: ' + this.textValue + '\n' + error;
			throw new System.IllegalArgumentException(msg);
		}
	}

	/**
	 * @description Resolves the target Apex type from `typeName`, wrapping it in `List<>` when `isCollection` is `true`
	 * @return The resolved Apex `Type`
	 */
	private Type determineType() {
		String typeName = (this.isCollection) ? 'List<' + this.typeName + '>' : this.typeName;
		Type type = Type.forName(typeName);
		if (type != null) {
			return type;
		} else {
			throw new System.TypeException('Invalid type: ' + typeName);
		}
	}
}
