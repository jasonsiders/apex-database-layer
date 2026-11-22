/**
 * @description Runs a batch of `SOQL: Get Record(s)` interviews in as few queries as it can, since Flow sends every
 * interview at the element in one call. Interviews with the same query, access level, and values share one query.
 * Interviews whose values differ in exactly one EQUALS, IN, or LIKE-style condition share one merged query, whose rows
 * are split back to each interview by comparing that field in Apex. Everything else runs one query per distinct set of
 * values; see `InvocableSoqlQuery.isMergeable` for when merging applies
 */
public inherited sharing class InvocableSoqlPlanner {
	/** @description Operators whose rows are split by exact value; the rest are LIKE patterns **/
	private static final Set<String> EQUALITY_OPERATORS = new Set<String>{ 'EQUALS', 'IN' };

	/** @description Interviews that share a query definition and access level, by both **/
	private Map<String, InvocableSoqlPlanner.Batch> batches = new Map<String, InvocableSoqlPlanner.Batch>{};

	// **** PUBLIC **** //
	/**
	 * @description Groups the interviews, runs each group's queries, then gives each interview its rows
	 * @param inputs One input per flow interview
	 * @return One output per input, in the same order
	 */
	public List<InvocableSoql.Output> run(List<InvocableSoql.Input> inputs) {
		List<InvocableSoqlPlanner.Variant> variants = new List<InvocableSoqlPlanner.Variant>{};
		for (InvocableSoql.Input input : inputs) {
			InvocableSoqlPlanner.Variant variant = this.addInput(input);
			variants?.add(variant);
		}
		for (InvocableSoqlPlanner.Batch batch : this.batches?.values()) {
			batch?.run();
		}
		List<InvocableSoql.Output> outputs = new List<InvocableSoql.Output>{};
		for (InvocableSoqlPlanner.Variant variant : variants) {
			outputs?.add(variant?.toOutput());
		}
		return outputs;
	}

	// **** PRIVATE **** //
	/**
	 * @description Adds an interview to the batch for its query and access level
	 * @param input The interview's input
	 * @return The interview's distinct set of values, which receives its rows
	 */
	private InvocableSoqlPlanner.Variant addInput(InvocableSoql.Input input) {
		System.AccessLevel accessLevel = input?.getAccessLevel();
		String levelName = (accessLevel == System.AccessLevel.SYSTEM_MODE) ? 'SYSTEM_MODE' : 'USER_MODE';
		String key = levelName + ':' + input?.queryDefinition;
		InvocableSoqlPlanner.Batch batch = this.batches?.get(key) ?? new InvocableSoqlPlanner.Batch(input, accessLevel);
		this.batches?.put(key, batch);
		return batch?.addInput(input);
	}

	/**
	 * @description Normalizes a value so equal values match: decimals ignore scale, ex: 100 and 100.00, and text
	 * ignores case unless its field is case-sensitive, like SOQL. IDs are already 18 characters, via
	 * `InvocableSoqlQuery.coerce`, so their case-insensitive form is still unique
	 * @param value A field value, or a value the field was compared to
	 * @param isCaseSensitive Whether the field compares text case-sensitively
	 * @return The value's key
	 */
	@TestVisible
	private static String toKey(Object value, Boolean isCaseSensitive) {
		String text = (value instanceof Decimal)
			? ((Decimal) value)?.stripTrailingZeros()?.toPlainString()
			: String.valueOf(value);
		return (value == null || isCaseSensitive == true) ? text : text?.toLowerCase();
	}

	/**
	 * @description Matches a simple LIKE pattern in Apex, the way SOQL would
	 * @param pattern A simple pattern, per `InvocableSoqlPlanner.LikePattern`
	 * @param value A field value
	 * @param isCaseSensitive Whether the field compares text case-sensitively
	 * @return Whether the value matches
	 */
	@TestVisible
	private static Boolean isLikeMatch(String pattern, Object value, Boolean isCaseSensitive) {
		InvocableSoqlPlanner.LikePattern parsed = new InvocableSoqlPlanner.LikePattern(pattern, isCaseSensitive);
		return parsed?.matches(value);
	}

	/**
	 * @description Treats a single value as a one-item list, so EQUALS and IN values merge alike
	 * @param value A value, or a collection of values
	 * @return The values
	 */
	private static List<Object> toList(Object value) {
		List<Object> values = new List<Object>{};
		if (value instanceof Iterable<Object>) {
			for (Object element : (Iterable<Object>) value) {
				values?.add(element);
			}
		} else {
			values?.add(value);
		}
		return values;
	}

	// **** INNER **** //
	/** @description Interviews with the same query and access level, which can share queries **/
	private class Batch {
		private System.AccessLevel accessLevel;
		private InvocableSoqlQuery query;
		/** @description Each distinct set of values, by its JSON **/
		private Map<String, InvocableSoqlPlanner.Variant> variants = new Map<String, InvocableSoqlPlanner.Variant>{};

		/**
		 * @description Parses the query once for every interview that shares it
		 * @param input The first interview's input
		 * @param accessLevel The interviews' access level
		 */
		private Batch(InvocableSoql.Input input, System.AccessLevel accessLevel) {
			this.accessLevel = accessLevel;
			this.query = InvocableSoqlQuery.parse(input?.queryDefinition);
		}

		/**
		 * @description Interviews with the same values share a variant, and so a query
		 * @param input The interview's input
		 * @return The interview's variant
		 */
		private InvocableSoqlPlanner.Variant addInput(InvocableSoql.Input input) {
			List<Object> values = this.query?.resolveValues(input);
			String key = JSON.serialize(values);
			InvocableSoqlPlanner.Variant variant = this.variants?.get(key) ??
				new InvocableSoqlPlanner.Variant(this.query, this.accessLevel, values);
			this.variants?.put(key, variant);
			return variant;
		}

		/**
		 * @description Finds the one condition whose values differ between variants, if only one does
		 * @return The condition's index, or null when none or several differ
		 */
		private Integer findVaryingIndex() {
			List<InvocableSoqlPlanner.Variant> variants = this.variants?.values();
			List<Integer> varying = new List<Integer>{};
			for (Integer index = 0; index < variants?.get(0)?.values?.size(); index++) {
				Set<String> keys = new Set<String>{};
				for (InvocableSoqlPlanner.Variant variant : variants) {
					keys?.add(JSON.serialize(variant?.values?.get(index)));
				}
				if (keys?.size() > 1) {
					varying?.add(index);
				}
			}
			return (varying?.size() == 1) ? varying?.get(0) : null;
		}

		/**
		 * @description Lists the variants a merged query can serve: a null value runs alone, since `= null` means IS
		 * NULL, and so does a LIKE pattern with wildcards in its middle, which a split can't reproduce
		 * @param index The varying condition's index, or null
		 * @return The variants to merge; fewer than two means there's nothing to merge
		 */
		private List<InvocableSoqlPlanner.Variant> getMergeable(Integer index) {
			List<InvocableSoqlPlanner.Variant> mergeable = new List<InvocableSoqlPlanner.Variant>{};
			Boolean isMergeable = index != null && this.query?.isMergeable(index) == true;
			Boolean isPattern =
				isMergeable && !InvocableSoqlPlanner.EQUALITY_OPERATORS?.contains(this.query?.getOperator(index));
			List<InvocableSoqlPlanner.Variant> candidates = isMergeable ? this.variants?.values() : mergeable;
			for (InvocableSoqlPlanner.Variant variant : candidates) {
				Object value = variant?.values?.get(index);
				Boolean isSimple = !isPattern || new InvocableSoqlPlanner.LikePattern((String) value, false)?.isSimple;
				if (value != null && isSimple == true) {
					mergeable?.add(variant);
				}
			}
			return mergeable;
		}

		/**
		 * @description Merges what it can into one query, then runs the remaining variants one query each
		 */
		private void run() {
			Integer index = this.findVaryingIndex();
			List<InvocableSoqlPlanner.Variant> mergeable = this.getMergeable(index);
			if (mergeable?.size() > 1) {
				this.runMerged(index, mergeable);
			}
			for (InvocableSoqlPlanner.Variant variant : this.variants?.values()) {
				variant?.runIfPending();
			}
		}

		/**
		 * @description Unions the varying condition's values into one query, then splits its rows by that field. Each
		 * row keeps its query order within each variant
		 * @param index The varying condition's index
		 * @param mergeable The variants to merge
		 */
		private void runMerged(Integer index, List<InvocableSoqlPlanner.Variant> mergeable) {
			InvocableSoqlPlanner.Splitter splitter = new InvocableSoqlPlanner.Splitter(this.query, index, mergeable);
			List<Object> values = mergeable?.get(0)?.values?.clone();
			values?.set(index, splitter?.getMergedValue());
			List<SObject> rows = this.query?.toSoql(values, this.accessLevel)?.query();
			for (InvocableSoqlPlanner.Variant variant : mergeable) {
				variant.records = new List<SObject>{};
			}
			for (SObject row : rows) {
				for (InvocableSoqlPlanner.Variant variant : splitter?.match(row)) {
					variant?.records?.add(row);
				}
			}
		}
	}

	/**
	 * @description A simple LIKE pattern: text with an optional `%` at either end, ex: `abc%`. Escaped wildcards, ex:
	 * `\%`, are literal text. Any other wildcard makes the pattern complex, which only SOQL can match
	 */
	private class LikePattern {
		private Boolean isCaseSensitive;
		private Boolean isLeading;
		private Boolean isSimple;
		private Boolean isTrailing;
		private String text;

		/**
		 * @description Parses the pattern
		 * @param pattern The pattern, as bound
		 * @param isCaseSensitive Whether the field compares text case-sensitively
		 */
		private LikePattern(String pattern, Boolean isCaseSensitive) {
			this.isCaseSensitive = isCaseSensitive;
			this.isLeading = pattern?.startsWith('%') == true;
			String rest = this.isLeading ? pattern?.substring(1) : pattern;
			this.isTrailing = rest?.endsWith('%') == true && rest?.endsWith('\\%') == false;
			String body = this.isTrailing ? rest?.removeEnd('%') : rest;
			String unescaped = body?.replace('\\\\', '')?.replace('\\%', '')?.replace('\\_', '');
			this.isSimple = unescaped?.containsAny('%_\\') == false;
			this.text = this.unescape(body);
		}

		/**
		 * @description Matches like SOQL, ignoring case unless the field is case-sensitive
		 * @param value A field value
		 * @return Whether the value matches
		 */
		private Boolean matches(Object value) {
			String candidate = InvocableSoqlPlanner.toKey(value, this.isCaseSensitive);
			String expected = InvocableSoqlPlanner.toKey(this.text, this.isCaseSensitive);
			Boolean isMatch;
			if (this.isLeading && this.isTrailing) {
				isMatch = candidate?.contains(expected);
			} else if (this.isLeading) {
				isMatch = candidate?.endsWith(expected);
			} else if (this.isTrailing) {
				isMatch = candidate?.startsWith(expected);
			} else {
				isMatch = candidate?.equals(expected);
			}
			return isMatch == true;
		}

		/**
		 * @description Resolves escapes, ex: `\%` to `%`. Escaped backslashes are split out first, so `\\%` isn't read
		 * as an escaped wildcard
		 * @param body The pattern, without its leading and trailing wildcards
		 * @return The literal text
		 */
		private String unescape(String body) {
			List<String> pieces = new List<String>{};
			for (String piece : body?.split('\\\\\\\\', -1) ?? new List<String>{}) {
				pieces?.add(piece?.replace('\\%', '%')?.replace('\\_', '_'));
			}
			return String.join(pieces, '\\');
		}
	}

	/** @description Splits a merged query's rows back to each variant, by the varying condition's field **/
	private class Splitter {
		private Integer index;
		private Boolean isCaseSensitive;
		private Boolean isPattern;
		private List<InvocableSoqlPlanner.LikePattern> patterns = new List<InvocableSoqlPlanner.LikePattern>{};
		private InvocableSoqlQuery query;
		/** @description Each EQUALS or IN value's variants, by key; indexes, so a duplicate value adds a row once **/
		private Map<String, Set<Integer>> variantsByKey = new Map<String, Set<Integer>>{};
		private List<InvocableSoqlPlanner.Variant> variants;

		/**
		 * @description Indexes each variant's values for matching rows
		 * @param query The query
		 * @param index The varying condition's index
		 * @param variants The variants to split rows between
		 */
		private Splitter(InvocableSoqlQuery query, Integer index, List<InvocableSoqlPlanner.Variant> variants) {
			this.index = index;
			this.isCaseSensitive = query?.isCaseSensitive(index);
			this.isPattern = !InvocableSoqlPlanner.EQUALITY_OPERATORS?.contains(query?.getOperator(index));
			this.query = query;
			this.variants = variants;
			for (Integer position = 0; position < variants?.size(); position++) {
				this.addVariant(position);
			}
		}

		/**
		 * @description Unions every variant's value, coerced as one list, since SOQL binds are strictly typed. EQUALS
		 * and LIKE bind a list as they would a single value, ex: `Name = :list` matches any of them
		 * @return The merged value
		 */
		private Object getMergedValue() {
			List<Object> merged = new List<Object>{};
			for (InvocableSoqlPlanner.Variant variant : this.variants) {
				Object value = variant?.values?.get(this.index);
				merged?.addAll(InvocableSoqlPlanner.toList(value));
			}
			return this.query?.coerce(this.index, merged);
		}

		/**
		 * @description Lists the variants a row belongs to
		 * @param row A row from the merged query
		 * @return The row's variants
		 */
		private List<InvocableSoqlPlanner.Variant> match(SObject row) {
			Object fieldValue = this.query?.getFieldValue(row, this.index);
			return this.isPattern ? this.matchPatterns(fieldValue) : this.matchKeys(fieldValue);
		}

		/**
		 * @description Indexes a variant's value: a pattern, or a key per EQUALS or IN value
		 * @param position The variant's position in `variants`
		 */
		private void addVariant(Integer position) {
			Object value = this.variants?.get(position)?.values?.get(this.index);
			InvocableSoqlPlanner.LikePattern pattern = this.isPattern
				? new InvocableSoqlPlanner.LikePattern((String) value, this.isCaseSensitive)
				: null;
			this.patterns?.add(pattern);
			for (Object element : (this.isPattern ? new List<Object>{} : InvocableSoqlPlanner.toList(value))) {
				String key = InvocableSoqlPlanner.toKey(element, this.isCaseSensitive);
				Set<Integer> positions = this.variantsByKey?.get(key) ?? new Set<Integer>{};
				positions?.add(position);
				this.variantsByKey?.put(key, positions);
			}
		}

		/**
		 * @description Looks up the row's value by key
		 * @param fieldValue The row's value for the varying field
		 * @return The variants with that value
		 */
		private List<InvocableSoqlPlanner.Variant> matchKeys(Object fieldValue) {
			String key = InvocableSoqlPlanner.toKey(fieldValue, this.isCaseSensitive);
			List<InvocableSoqlPlanner.Variant> matches = new List<InvocableSoqlPlanner.Variant>{};
			for (Integer position : this.variantsByKey?.get(key) ?? new Set<Integer>{}) {
				matches?.add(this.variants?.get(position));
			}
			return matches;
		}

		/**
		 * @description Tests the row's value against each variant's pattern
		 * @param fieldValue The row's value for the varying field
		 * @return The variants whose pattern matches
		 */
		private List<InvocableSoqlPlanner.Variant> matchPatterns(Object fieldValue) {
			List<InvocableSoqlPlanner.Variant> matches = new List<InvocableSoqlPlanner.Variant>{};
			for (Integer position = 0; position < this.patterns?.size(); position++) {
				if (this.patterns?.get(position)?.matches(fieldValue) == true) {
					matches?.add(this.variants?.get(position));
				}
			}
			return matches;
		}
	}

	/** @description A distinct set of values in a batch: the interviews that share it share its query and rows **/
	private class Variant {
		private System.AccessLevel accessLevel;
		private InvocableSoqlQuery query;
		/** @description Null until a query fills it, so the batch can tell which variants still need one **/
		private List<SObject> records;
		private String queryString;
		private List<Object> values;

		/**
		 * @description Holds what running the query needs
		 * @param query The query
		 * @param accessLevel The access level
		 * @param values One value per condition
		 */
		private Variant(InvocableSoqlQuery query, System.AccessLevel accessLevel, List<Object> values) {
			this.accessLevel = accessLevel;
			this.query = query;
			this.values = values;
		}

		/**
		 * @description Runs the variant's own query, unless a merged query already filled its rows
		 */
		private void runIfPending() {
			if (this.records == null) {
				this.records = this.query?.toSoql(this.values, this.accessLevel)?.query();
			}
		}

		/**
		 * @description Interviews that share the variant share its query string, rendered once
		 * @return An output for one of the variant's interviews
		 */
		private InvocableSoql.Output toOutput() {
			this.queryString = this.queryString ?? this.query?.toQueryString(this.values);
			return new InvocableSoql.Output(this.records, this.queryString);
		}
	}
}
