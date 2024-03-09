public virtual class Condition implements ICriteria {
    // **** STATIC **** //
    public static final Operator EQUALS = new EqualsOperator();
	public static final Operator NOT_EQUALS = new NotEqualsOperator();
	public static final Operator IN_COLLECTION = new InCollectionOperator();
	public static final Operator NOT_IN_COLLECTION = new NotInCollectionOperator();
	public static final Operator GREATER_THAN = new GreaterThanOperator();
	public static final Operator GREATER_OR_EQUAL = new GreaterOrEqualOperator();
	public static final Operator LESS_THAN = new LessThanOperator();
	public static final Operator LESS_OR_EQUAL = new LessOrEqualOperator();
	public static final Operator STARTS_WITH = new StartsWithOperator();
	public static final Operator NOT_STARTS_WITH = new NotStartsWithOperator();
	public static final Operator ENDS_WITH = new EndsWithOperator();
	public static final Operator NOT_ENDS_WITH = new NotEndsWithOperator();
	public static final Operator CONTAINS = new ContainsOperator();
	public static final Operator NOT_CONTAINS = new NotContainsOperator();

    // **** MEMBER **** //
    protected final String property;
    protected final Operator operator;
    protected final Object value; 

    public Condition(String property, Operator operator, Object value) {
        this.property = property;
        this.operator = operator;
        this.value = value;
    }

    public Condition(SObject field, Operator operator, Object value) {
        this(field?.toString(), operator, value);
    }

    public Boolean meetsCriteria(SObject record) {
        Object recordValue = record?.get(this.property);
        return this.operator?.meetsCriteria(recordValue, this.value);
    }

    public override String toString() {
        List<String> parts = new List<String>{
			this.property,
			this.operator?.getToken(),
			this.formatValue()
		};
		return String.join(parts, ' ');
    }

    private String formatValue() {
		// Note: System.Type cannot be used directly in switch expressions
        if (this.value == null) {
            return 'null';
        } else if (this.value instanceOf Date) {
            return this.processDate((Date) this.value);
        } else if (this.value instanceOf Iterable<Date>) {
            return this.processDates((Iterable<Date>) this.value);
        } else if (this.value instanceOf DateTime) {
            return this.processDateTime((DateTime) this.value);
        } else if (this.value instanceOf Iterable<DateTime>) {
            return this.processDateTimes((Iterable<DateTime>) this.value);
        } else if (this.value instanceOf String) {
            return this.processString((String) this.value);
        } else if (this.value instanceOf Iterable<String>) {
            return this.processStrings((Iterable<String>) this.value);
        } else if (this.value instanceOf Soql) {
            // Inner queries must be wrapped in parentheses to avoid syntax errors in SOQL
            return String.format('({0})', new List<String>{ this.value?.toString() });
        } else {
            return String.valueOf(this.value);
        }
	}

	private String processString(String value) {
		// Allow special modifiers (bind variables & relative date operators) to pass through unmodified
		Boolean specialModifier = value?.startsWithIgnoreCase('LAST_N_DAYS') || value?.startsWith(':');
		return (specialModifier) ? value : this.operator?.processStringValue(value);
	}

	private String processDate(Date value) {
		String soqlFormat = 'yyyy-MM-dd';
		DateTime dateTimeValue = DateTime.newInstance(value.year(), value.month(), value.day());
		return dateTimeValue?.formatGmt(soqlFormat);
	}

	private String processDateTime(DateTime value) {
		String soqlFormat = 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'';
		return value?.formatGmt(soqlFormat);
	}

	private String processStrings(Iterable<String> items) {
		List<String> results = new List<String>();
		for (String item : items) {
			String result = this.processString(item);
			results.add(result);
		}
		return '(' + String.join(results, ', ') + ')';
	}

	private String processDates(Iterable<Date> items) {
		List<String> results = new List<String>();
		for (Date item : items) {
			results.add(this.processDate(item));
		}
		return '(' + String.join(results, ', ') + ')';
	}

	private String processDateTimes(Iterable<DateTime> items) {
		List<String> results = new List<String>();
		for (DateTime item : items) {
			results.add(this.processDateTime(item));
		}
		return '(' + String.join(results, ', ') + ')';
	}

    // **** STATIC **** //
    static Boolean greaterThan(Object value, Object comparison) {
        if (value instanceOf DateTime && comparison instanceOf DateTime) {
            DateTime dateValue = (DateTime) value;
            DateTime comparisonDate = (DateTime) comparison;
            return (dateValue > comparisonDate);
        } else if (value instanceOf Double && comparison instanceOf Double) {
            Double dubValue = (Double) value;
            Double comparisonDub = (Double) value;
            return dubValue > comparisonDub;
        } else {
            // Types are null or not comparable - return false
            return false;
        }
    }

    static Boolean lessThan(Object value, Object comparison) {
        if (value instanceOf DateTime && comparison instanceOf DateTime) {
            DateTime dateValue = (DateTime) value;
            DateTime comparisonDate = (DateTime) comparison;
            return (dateValue < comparisonDate);
        } else if (value instanceOf Double && comparison instanceOf Double) {
            Double dubValue = (Double) value;
            Double comparisonDub = (Double) value;
            return dubValue < comparisonDub;
        } else {
            // Types are null or not comparable - return false
            return false;
        }
    }

    // **** INNER **** //
    public abstract class Operator {
		public abstract String getToken();
		public abstract Boolean meetsCriteria(Object value, Object comparison);

		public virtual String processStringValue(String value) {
			return '\'' + value + '\'';
		}
	}

	private class EqualsOperator extends Operator {
		public override String getToken() {
			return '=';
		}

		public override Boolean meetsCriteria(Object value, Object comparison) {
			return value == comparison;
		}
	}

	private class NotEqualsOperator extends Operator {
		public override String getToken() {
			return '!=';
		}

		public override Boolean meetsCriteria(Object value, Object comparison) {
			Operator inverse = new EqualsOperator();
			return inverse?.meetsCriteria(value, comparison) == false;
		}
	}

	private class InCollectionOperator extends Operator {
		public override String getToken() {
			return 'IN';
		}

		public override Boolean meetsCriteria(Object value, Object comparison) {
            if (value != null && value instanceOf List<Object>) {
                List<Object> valueList = (List<Object>) comparison;
                return valueList?.contains(value) == true; 
            } else {
                // Note: We cannot convert a Map/Set of a given type to a Map/Set<Object>, ex.:
				// ! Invalid conversion from runtime type Map<Id,Opportunity> to Map<ANY,ANY>
				// Unfortunately, Apex's type system seems to be "broken": https://salesforce.stackexchange.com/questions/106068/apex-string-instanceof-object
				// ...but it still works for lists! If a non-list collection is provided, throw an error
				throw new System.IllegalArgumentException('IN_COLLECTION operations must use a List type');
            }
		}
	}

	private class NotInCollectionOperator extends Operator {
		public override String getToken() {
			return 'NOT IN';
		}

		public override Boolean meetsCriteria(Object value, Object comparison) {
			Operator inverse = new InCollectionOperator();
			return (value != null && comparison != null) ? inverse?.meetsCriteria(value, comparison) == false : false;
		}
	}

	private class GreaterThanOperator extends Operator {
		public override String getToken() {
			return '>';
		}

		public override Boolean meetsCriteria(Object value, Object comparison) {
			return Condition.greaterThan(value, comparison);
		}
	}

	private class GreaterOrEqualOperator extends Operator {
		public override String getToken() {
			return '>=';
		}

		public override Boolean meetsCriteria(Object value, Object comparison) {
			Operator inverse = new LessThanOperator();
			return Condition.greaterThan(value, comparison) || value == comparison;
		}
	}

	private class LessThanOperator extends Operator {
		public override String getToken() {
			return '<';
		}

		public override Boolean meetsCriteria(Object value, Object comparison) {
			return Condition.lessThan(value, comparison);
		}
	}

	private class LessOrEqualOperator extends Operator {
		public override String getToken() {
			return '<=';
		}

		public override Boolean meetsCriteria(Object value, Object comparison) {
			Operator inverse = new GreaterThanOperator();
			return Condition.lessThan(value, comparison) || value == comparison;
		}
	}

	private class StartsWithOperator extends Operator {
		public override String getToken() {
			return 'LIKE';
		}

		public override Boolean meetsCriteria(Object value, Object comparison) {
			// All types (including numbers) must be cast to string for this operation
			String valueString = String.valueOf(value);
			String comparisonString = String.valueOf(comparison);
			return value != null && comparison != null && valueString?.startsWithIgnoreCase(comparisonString);
		}

		public override String processStringValue(String value) {
			return '\'' + value + '%\'';
		}
	}

	private class NotStartsWithOperator extends Operator {
		public override String getToken() {
			return 'NOT LIKE';
		}

		public override Boolean meetsCriteria(Object value, Object comparison) {
			Operator inverse = new StartsWithOperator();
			return (value != null && comparison != null) ? inverse?.meetsCriteria(value, comparison) == false : false;
		}

		public override String processStringValue(String value) {
			return '\'' + value + '%\'';
		}
	}

	private class EndsWithOperator extends Operator {
		public override String getToken() {
			return 'LIKE';
		}

		public override Boolean meetsCriteria(Object value, Object comparison) {
			// All types (including numbers) must be cast to string for this operation
			String valueString = String.valueOf(value);
			String comparisonString = String.valueOf(comparison);
			return value != null && comparison != null && valueString?.endsWithIgnoreCase(comparisonString);
		}

		public override String processStringValue(String value) {
			return '\'%' + value + '\'';
		}
	}

	private class NotEndsWithOperator extends Operator {
		public override String getToken() {
			return 'NOT LIKE';
		}

		public override Boolean meetsCriteria(Object value, Object comparison) {
			Operator inverse = new EndsWithOperator();
			return (value != null && comparison != null) ? inverse?.meetsCriteria(value, comparison) == false : false;
		}

		public override String processStringValue(String value) {
			return '\'%' + value + '\'';
		}
	}

	private class ContainsOperator extends Operator {
		public override String getToken() {
			return 'LIKE';
		}

		public override Boolean meetsCriteria(Object value, Object comparison) {
			// All types (including numbers) must be cast to string for this operation
			String valueString = String.valueOf(value);
			String comparisonString = String.valueOf(comparison);
			return value != null && comparison != null && valueString?.containsIgnoreCase(comparisonString);
		}

		public override String processStringValue(String value) {
			return '\'%' + value + '%\'';
		}
	}

	private class NotContainsOperator extends Operator {
		public override String getToken() {
			return 'NOT LIKE';
		}

		public override Boolean meetsCriteria(Object value, Object comparison) {
			Operator inverse = new ContainsOperator();
			return (value != null && comparison != null) ? inverse?.meetsCriteria(value, comparison) == false : false;
		}

		public override String processStringValue(String value) {
			return '\'%' + value + '%\'';
		}
	}
}