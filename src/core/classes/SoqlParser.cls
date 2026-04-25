/**
 * @description Parses SOQL query strings into structured {@link Soql.Builder} representations.
 * Handles all standard SOQL clauses including SELECT, FROM, WHERE, GROUP BY, HAVING, ORDER BY,
 * LIMIT, OFFSET, USING SCOPE, WITH, FOR, and ALL ROWS.
 */
@SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.PropertyNamingConventions')
public class SoqlParser {
	// prettier-ignore
	private static final String ALL_ROWS_KEYWORD { get { return 'ALL ROWS'; } }
	// prettier-ignore
	private static final String FOR_KEYWORD { get { return 'FOR'; } }
	// prettier-ignore
	private static final String FROM_KEYWORD { get { return 'FROM'; } }
	// prettier-ignore
	private static final String GROUP_BY_KEYWORD { get { return 'GROUP BY'; } }
	// prettier-ignore
	private static final String HAVING_KEYWORD { get { return 'HAVING'; } }
	// prettier-ignore
	private static final String LIMIT_KEYWORD { get { return 'LIMIT'; } }
	// prettier-ignore
	private static final String OFFSET_KEYWORD { get { return 'OFFSET'; } }
	// prettier-ignore
	private static final String ORDER_BY_KEYWORD { get { return 'ORDER BY'; } }
	// prettier-ignore
	private static final String SELECT_KEYWORD { get { return 'SELECT'; } }
	// prettier-ignore
	private static final String USING_SCOPE_KEYWORD { get { return 'USING SCOPE'; } }
	// prettier-ignore
	private static final String WHERE_KEYWORD { get { return 'WHERE'; } }
	// prettier-ignore
	private static final String WITH_KEYWORD { get { return 'WITH'; } }
	// prettier-ignore
	private static final Integer MAX_INT { get { return 2147483647; } }
	// prettier-ignore
	private static final List<String> ALL_KEYWORDS { get { return new List<String>{ SELECT_KEYWORD, FROM_KEYWORD, WHERE_KEYWORD, GROUP_BY_KEYWORD, HAVING_KEYWORD, ORDER_BY_KEYWORD, LIMIT_KEYWORD, OFFSET_KEYWORD, USING_SCOPE_KEYWORD, WITH_KEYWORD, FOR_KEYWORD, ALL_ROWS_KEYWORD }; } }
	// prettier-ignore
	private static final Map<String, Soql.Function> FUNCTION_MAP { get { return new Map<String, Soql.Function>{ 'AVG' => Soql.Function.AVG, 'CALENDAR_MONTH' => Soql.Function.CALENDAR_MONTH, 'CALENDAR_QUARTER' => Soql.Function.CALENDAR_QUARTER, 'CALENDAR_YEAR' => Soql.Function.CALENDAR_YEAR, 'COUNT' => Soql.Function.COUNT, 'COUNT_DISTINCT' => Soql.Function.COUNT_DISTINCT, 'DAY_IN_MONTH' => Soql.Function.DAY_IN_MONTH, 'DAY_IN_WEEK' => Soql.Function.DAY_IN_WEEK, 'DAY_IN_YEAR' => Soql.Function.DAY_IN_YEAR, 'DAY_ONLY' => Soql.Function.DAY_ONLY, 'FISCAL_MONTH' => Soql.Function.FISCAL_MONTH, 'FISCAL_QUARTER' => Soql.Function.FISCAL_QUARTER, 'FISCAL_YEAR' => Soql.Function.FISCAL_YEAR, 'FORMAT' => Soql.Function.FORMAT, 'HOUR_IN_DAY' => Soql.Function.HOUR_IN_DAY, 'MAX' => Soql.Function.MAX, 'MIN' => Soql.Function.MIN, 'SUM' => Soql.Function.SUM, 'WEEK_IN_MONTH' => Soql.Function.WEEK_IN_MONTH, 'WEEK_IN_YEAR' => Soql.Function.WEEK_IN_YEAR }; } }
	// Operators ordered by precedence: multi-word and longer tokens first to prevent partial matches
	// prettier-ignore
	private static final Map<String, Soql.Operator> OPERATOR_MAP { get { return new Map<String, Soql.Operator>{ '!=' => Soql.NOT_EQUALS, '<' => Soql.LESS_THAN, '<=' => Soql.LESS_OR_EQUAL, '=' => Soql.EQUALS, '>' => Soql.GREATER_THAN, '>=' => Soql.GREATER_OR_EQUAL, 'IN' => Soql.IN_COLLECTION, 'LIKE' => Soql.LIKE_RAW, 'NOT IN' => Soql.NOT_IN_COLLECTION, 'NOT LIKE' => Soql.NOT_LIKE_RAW }; } }
	// prettier-ignore
	private static final List<String> OPERATOR_PRECEDENCE { get { return new List<String>{ 'NOT IN', 'NOT LIKE', '!=', '>=', '<=', '>', '<', '=', 'IN', 'LIKE' }; } }
	// prettier-ignore
	private static final Map<String, Soql.Scope> SCOPE_MAP { get { return new Map<String, Soql.Scope>{ 'DELEGATED' => Soql.Scope.DELEGATED, 'EVERYTHING' => Soql.Scope.EVERYTHING, 'MINE' => Soql.Scope.MINE, 'MINE_AND_MY_GROUPS' => Soql.Scope.MINE_AND_MY_GROUPS, 'MY_TEAM_TERRITORY' => Soql.Scope.MY_TEAM_TERRITORY, 'MY_TERRITORY' => Soql.Scope.MY_TERRITORY, 'TEAM' => Soql.Scope.TEAM }; } }
	/**
	 * @description Parses a SOQL query string and applies the parsed clauses to the given builder.
	 * @param builder The {@link Soql.Builder} to populate with parsed clauses
	 * @param queryString The SOQL query string to parse
	 */
	public void parse(Soql.Builder builder, String queryString) {
		ParseContext ctx = new ParseContext(queryString, new Scanner(queryString).scan());
		this.applyParsers(builder, ctx);
	}

	// ── PRIVATE ───────────────────────────────────────────────────────────

	/**
	 * @description Dispatches each SOQL clause to its corresponding parse method.
	 * @param builder The {@link Soql.Builder} to populate
	 * @param ctx The {@link ParseContext} containing the query string and keyword positions
	 */
	private void applyParsers(Soql.Builder builder, ParseContext ctx) {
		this.parseSelect(builder, this.extractClause(ctx, SELECT_KEYWORD));
		this.parseFrom(builder, this.extractClause(ctx, FROM_KEYWORD));
		String whereClause = this.extractClause(ctx, WHERE_KEYWORD);
		if (String.isNotBlank(whereClause)) {
			this.parseWhere(builder, whereClause);
		}
		String groupBy = this.extractClause(ctx, GROUP_BY_KEYWORD);
		if (String.isNotBlank(groupBy)) {
			this.parseGroupBy(builder, groupBy);
		}
		String havingClause = this.extractClause(ctx, HAVING_KEYWORD);
		if (String.isNotBlank(havingClause)) {
			this.parseHaving(builder, havingClause);
		}
		String orderBy = this.extractClause(ctx, ORDER_BY_KEYWORD);
		if (String.isNotBlank(orderBy)) {
			this.parseOrderBy(builder, orderBy);
		}
		String lim = this.extractClause(ctx, LIMIT_KEYWORD);
		if (String.isNotBlank(lim)) {
			this.parseLimit(builder, lim);
		}
		String off = this.extractClause(ctx, OFFSET_KEYWORD);
		if (String.isNotBlank(off)) {
			this.parseOffset(builder, off);
		}
		String usingScope = this.extractClause(ctx, USING_SCOPE_KEYWORD);
		if (String.isNotBlank(usingScope)) {
			this.parseUsingScope(builder, usingScope);
		}
		String withClause = this.extractClause(ctx, WITH_KEYWORD);
		if (String.isNotBlank(withClause)) {
			this.parseWith(builder, withClause);
		}
		String forClause = this.extractClause(ctx, FOR_KEYWORD);
		if (String.isNotBlank(forClause)) {
			this.parseFor(builder, forClause);
		}
		if (ctx.positions?.containsKey(ALL_ROWS_KEYWORD) == true) {
			this.parseAllRows(builder);
		}
	}

	/**
	 * @description Builds an {@link Soql.Aggregation} from a function call token such as
	 * {@code COUNT(Id) cnt}.
	 * @param token The raw aggregation token
	 * @return The constructed {@link Soql.Aggregation}
	 */
	private Soql.Aggregation buildAggregation(String token) {
		String upper = token.toUpperCase();
		Integer openParen = upper.indexOf('(');
		Integer closeParen = this.findMatchingParen(token, openParen);
		Soql.Aggregation agg = new Soql.Aggregation(
			FUNCTION_MAP.get(upper.substring(0, openParen).trim()),
			token.substring(openParen + 1, closeParen).trim()
		);
		String alias = token.substring(closeParen + 1).trim();
		if (String.isNotBlank(alias)) {
			agg.withAlias(alias);
		}
		return agg;
	}

	/**
	 * @description Extracts the text of a clause by slicing between the start of {@code keyword}
	 * and the start of the next keyword, trimming the keyword name and surrounding whitespace.
	 * @param ctx The {@link ParseContext} holding the query and positions
	 * @param keyword The keyword whose clause content to extract
	 * @return The trimmed clause text, or an empty string if the keyword is absent
	 */
	private String extractClause(ParseContext ctx, String keyword) {
		Integer startPos = ctx.positions?.get(keyword);
		if (startPos == null) {
			return '';
		}
		String nextKeyword = this.getNextKeyword(ctx.positions, keyword);
		Integer endPos = nextKeyword == null
			? ctx.queryString.length()
			: (ctx.positions.get(nextKeyword) ?? ctx.queryString.length());
		return ctx.queryString.substring(startPos + keyword.length(), endPos).trim();
	}

	/**
	 * @description Scans {@code queryString} and returns the starting position of each SOQL
	 * keyword found at the top level (not inside parentheses or string literals).
	 * @param queryString The SOQL query string to scan
	 * @return A map of keyword to its starting character position
	 */
	private Map<String, Integer> findKeywordPositions(String queryString) {
		return new Scanner(queryString).scan();
	}

	/**
	 * @description Finds the index of the closing parenthesis that matches the opening parenthesis
	 * at {@code openIndex}, accounting for nested parentheses.
	 * @param str The string to search
	 * @param openIndex The index of the opening parenthesis
	 * @return The index of the matching closing parenthesis, or the string length if none found
	 */
	@TestVisible
	private Integer findMatchingParen(String str, Integer openIndex) {
		Integer depth = 0;
		for (Integer i = openIndex; i < str.length(); i++) {
			String c = str.substring(i, i + 1);
			if (c == '(') {
				depth++;
			} else if (c == ')') {
				depth--;
				if (depth == 0) {
					return i;
				}
			}
		}
		return str.length();
	}

	/**
	 * @description Finds the starting index of {@code operator} in {@code str} at the top level
	 * (not inside parentheses or string literals), respecting word boundaries for alphabetic
	 * operators.
	 * @param str The condition string to scan
	 * @param operator The operator token to locate
	 * @return The index of the operator, or -1 if not found
	 */
	private Integer findOperatorPosition(String str, String operator) {
		String strUpper = str.toUpperCase();
		Integer parenDepth = 0;
		Boolean inString = false;
		for (Integer i = 0; i <= str.length() - operator.length(); i++) {
			String c = str.substring(i, i + 1);
			if (c == '\'' && (i == 0 || str.substring(i - 1, i) != '\\')) {
				inString = (inString == false);
			} else if (inString == false) {
				if (c == '(') {
					parenDepth++;
				} else if (c == ')') {
					parenDepth--;
				} else if (
					parenDepth == 0 &&
					strUpper.substring(i, i + operator.length()) == operator &&
					this.isAtWordBoundary(str, i, operator)
				) {
					return i;
				}
			}
		}
		return -1;
	}

	/**
	 * @description Returns the keyword that immediately follows {@code currentKeyword} in the
	 * query, based on character positions.
	 * @param positions The keyword position map
	 * @param currentKeyword The keyword to find the successor of
	 * @return The next keyword name, or null if none follows
	 */
	private String getNextKeyword(Map<String, Integer> positions, String currentKeyword) {
		Integer currentPos = positions?.get(currentKeyword);
		if (currentPos == null) {
			return null;
		}
		String nextKeyword = null;
		Integer nextPos = MAX_INT;
		for (String keyword : ALL_KEYWORDS) {
			Integer pos = positions.get(keyword);
			if (pos != null && pos > currentPos && pos < nextPos) {
				nextPos = pos;
				nextKeyword = keyword;
			}
		}
		return nextKeyword;
	}

	/**
	 * @description Returns true if {@code token} is an aggregation function call (e.g.
	 * {@code COUNT(Id)}).
	 * @param token The SELECT item token to inspect
	 * @return True if the token begins with a known aggregate function name followed by {@code (}
	 */
	private Boolean isAggregation(String token) {
		String upper = token.toUpperCase();
		Integer parenPos = upper.indexOf('(');
		return parenPos > 0 && FUNCTION_MAP.containsKey(upper.substring(0, parenPos).trim());
	}

	/**
	 * @description Returns true if the operator at position {@code i} in {@code str} is surrounded
	 * by word boundaries (spaces, parentheses, or string start/end).
	 * @param str The condition string
	 * @param i The starting index of the operator
	 * @param operator The operator text
	 * @return True if both the before and after characters qualify as word boundaries
	 */
	private Boolean isAtWordBoundary(String str, Integer i, String operator) {
		Integer afterPos = i + operator.length();
		Boolean beforeOk = (i == 0 || str.substring(i - 1, i) == ' ');
		String afterChar = afterPos < str.length() ? str.substring(afterPos, afterPos + 1) : '';
		return beforeOk && (afterPos >= str.length() || afterChar == ' ' || afterChar == '(');
	}

	/**
	 * @description Returns true if {@code str} looks like an ISO 8601 date (10 characters,
	 * YYYY-MM-DD format).
	 * @param str The uppercase string to test
	 * @return True if it matches a date pattern
	 */
	private Boolean isDate(String str) {
		return str?.length() == 10 && this.isValidDatePrefix(str);
	}

	/**
	 * @description Returns true if {@code str} looks like an ISO 8601 datetime (at least 10
	 * characters, contains 'T', and starts with a valid date prefix).
	 * @param str The uppercase string to test
	 * @return True if it matches a datetime pattern
	 */
	private Boolean isDateTime(String str) {
		return str?.length() >= 10 && str.contains('T') && this.isValidDatePrefix(str.substring(0, 10));
	}

	/**
	 * @description Returns true if {@code datePrefix} is a plausible YYYY-MM-DD date prefix
	 * within the range 1900–2100.
	 * @param datePrefix A 10-character string to validate
	 * @return True if it parses as a valid calendar date
	 */
	private Boolean isValidDatePrefix(String datePrefix) {
		if (datePrefix?.length() != 10 || datePrefix.substring(4, 5) != '-' || datePrefix.substring(7, 8) != '-') {
			return false;
		}
		try {
			Integer year = Integer.valueOf(datePrefix.substring(0, 4));
			Integer month = Integer.valueOf(datePrefix.substring(5, 7));
			Integer day = Integer.valueOf(datePrefix.substring(8, 10));
			return year >= 1900 && year <= 2100 && month >= 1 && month <= 12 && day >= 1 && day <= 31;
		} catch (Exception e) {
			return false;
		}
	}

	/**
	 * @description Sets the ALL ROWS clause on the builder.
	 * @param builder The {@link Soql.Builder} to modify
	 */
	private void parseAllRows(Soql.Builder builder) {
		builder.setUsage(Soql.Usage.ALL_ROWS);
	}

	/**
	 * @description Adds an aggregation SELECT item to the builder.
	 * @param builder The {@link Soql.Builder} to modify
	 * @param token The raw aggregation token
	 */
	private void parseAggregation(Soql.Builder builder, String token) {
		builder.addSelect(this.buildAggregation(token));
	}

	/**
	 * @description Splits {@code str} on top-level AND tokens and returns a parsed
	 * {@link Soql.Criteria} tree.
	 * @param str The AND expression to parse
	 * @return A single {@link Soql.Condition} or a {@link Soql.ConditionalLogic} with ALL_CONDITIONS
	 */
	private Soql.Criteria parseAndExpr(String str) {
		List<String> andParts = this.splitTopLevelKeyword(str, ' AND ');
		if (andParts.size() == 1) {
			return this.parseFactor(andParts[0]);
		}
		Soql.ConditionalLogic logic = new Soql.ConditionalLogic();
		logic.setLogicType(Soql.LogicType.ALL_CONDITIONS);
		for (String part : andParts) {
			logic.addCondition(this.parseFactor(part));
		}
		return logic;
	}

	/**
	 * @description Parses a single WHERE/HAVING condition expression of the form
	 * {@code field operator value}.
	 * @param str The condition string to parse
	 * @return A {@link Soql.Condition} representing the parsed condition
	 */
	@TestVisible
	private Soql.Condition parseCondition(String str) {
		for (String op : OPERATOR_PRECEDENCE) {
			Integer opPos = this.findOperatorPosition(str, op);
			if (opPos >= 0) {
				String fieldName = str.substring(0, opPos).trim();
				String value = str.substring(opPos + op.length()).trim();
				return new Soql.Condition(fieldName, OPERATOR_MAP.get(op), this.parseValue(value));
			}
		}
		return new Soql.Condition(str, Soql.EQUALS, null);
	}

	/**
	 * @description Parses a raw WHERE/HAVING expression into a {@link Soql.ConditionalLogic} tree.
	 * @param str The expression string to wrap
	 * @return A {@link Soql.ConditionalLogic} containing the parsed criteria
	 */
	private Soql.ConditionalLogic parseCriteriaLogic(String str) {
		Soql.Criteria criteria = this.parseExpr(str);
		if (criteria instanceof Soql.Condition) {
			Soql.ConditionalLogic logic = new Soql.ConditionalLogic();
			logic.addCondition((Soql.Condition) criteria);
			return logic;
		}
		return (Soql.ConditionalLogic) criteria;
	}

	/**
	 * @description Parses a raw date string into a {@link Date}, falling back to the raw string
	 * on failure.
	 * @param trimmed The date string to parse
	 * @return A {@link Date} or the original string
	 */
	private Object parseDate(String trimmed) {
		try {
			return Date.valueOf(trimmed);
		} catch (Exception e) {
			return trimmed;
		}
	}

	/**
	 * @description Parses a raw datetime string into a {@link DateTime}, falling back to the raw
	 * string on failure.
	 * @param trimmed The datetime string to parse
	 * @return A {@link DateTime} or the original string
	 */
	private Object parseDateTime(String trimmed) {
		try {
			return DateTime.valueOfGmt(trimmed);
		} catch (Exception e) {
			return trimmed;
		}
	}

	/**
	 * @description Recursively parses a WHERE/HAVING expression, handling OR at the top level.
	 * @param str The expression string to parse
	 * @return A {@link Soql.Criteria} tree
	 */
	private Soql.Criteria parseExpr(String str) {
		List<String> orParts = this.splitTopLevelKeyword(str, ' OR ');
		if (orParts.size() == 1) {
			return this.parseAndExpr(orParts[0]);
		}
		Soql.ConditionalLogic logic = new Soql.ConditionalLogic();
		logic.setLogicType(Soql.LogicType.ANY_CONDITIONS);
		for (String part : orParts) {
			logic.addCondition(this.parseAndExpr(part));
		}
		return logic;
	}

	/**
	 * @description Parses a single term: either a parenthesized sub-expression or a leaf
	 * condition.
	 * @param str The term string to parse
	 * @return A {@link Soql.Criteria}
	 */
	private Soql.Criteria parseFactor(String str) {
		String trimmed = str.trim();
		if (trimmed.startsWith('(') && this.findMatchingParen(trimmed, 0) == trimmed.length() - 1) {
			return this.parseExpr(trimmed.substring(1, trimmed.length() - 1).trim());
		}
		return this.parseCondition(trimmed);
	}

	/**
	 * @description Sets the FOR clause on the builder based on the clause value.
	 * @param builder The {@link Soql.Builder} to modify
	 * @param forStr The FOR clause value (e.g. UPDATE, VIEW, REFERENCE)
	 */
	private void parseFor(Soql.Builder builder, String forStr) {
		String upper = forStr.toUpperCase();
		if (upper.startsWith('UPDATE')) {
			builder.setUsage(Soql.Usage.FOR_UPDATE);
		} else if (upper.startsWith('VIEW')) {
			builder.setUsage(Soql.Usage.FOR_VIEW);
		} else if (upper.startsWith('REFERENCE')) {
			builder.setUsage(Soql.Usage.FOR_REFERENCE);
		}
	}

	/**
	 * @description Sets the FROM clause on the builder.
	 * @param builder The {@link Soql.Builder} to modify
	 * @param fromStr The entity name string
	 */
	private void parseFrom(Soql.Builder builder, String fromStr) {
		builder.setFrom(fromStr);
	}

	/**
	 * @description Parses the GROUP BY clause and adds each field to the builder.
	 * @param builder The {@link Soql.Builder} to modify
	 * @param groupByStr The GROUP BY clause content
	 */
	private void parseGroupBy(Soql.Builder builder, String groupByStr) {
		for (String item : this.splitTopLevelKeyword(groupByStr, ',')) {
			builder.addGroupBy(item.trim());
		}
	}

	/**
	 * @description Parses the HAVING clause into a criteria tree and sets it on the builder.
	 * @param builder The {@link Soql.Builder} to modify
	 * @param havingStr The HAVING clause content
	 */
	private void parseHaving(Soql.Builder builder, String havingStr) {
		builder.setHavingCriteria(this.parseCriteriaLogic(havingStr));
	}

	/**
	 * @description Sets the LIMIT clause on the builder.
	 * @param builder The {@link Soql.Builder} to modify
	 * @param limitStr The LIMIT value string
	 */
	private void parseLimit(Soql.Builder builder, String limitStr) {
		builder.setRowLimit(Integer.valueOf(limitStr));
	}

	/**
	 * @description Parses a parenthesized list value token into a {@link List<String>}.
	 * Returns the raw string unchanged if the list body contains a subquery.
	 * @param trimmed The parenthesized token to parse
	 * @return A {@link List<String>} of values, or the original string for subqueries
	 */
	private Object parseList(String trimmed) {
		String body = trimmed.substring(1, trimmed.length() - 1);
		if (body.toUpperCase().contains('SELECT')) {
			return trimmed;
		}
		List<String> result = new List<String>();
		for (String item : this.splitTopLevelKeyword(body, ',')) {
			String val = item.trim();
			result.add((val.startsWith('\'') && val.endsWith('\'')) ? val.substring(1, val.length() - 1) : val);
		}
		return result;
	}

	/**
	 * @description Parses a raw numeric string into an {@link Integer} or {@link Decimal},
	 * falling back to the original string if parsing fails.
	 * @param trimmed The numeric string to parse
	 * @return An {@link Integer}, {@link Decimal}, or the original string
	 */
	private Object parseNumeric(String trimmed) {
		try {
			return Integer.valueOf(trimmed);
		} catch (Exception intErr) {
			try {
				return Decimal.valueOf(trimmed);
			} catch (Exception decErr) {
				return trimmed;
			}
		}
	}

	/**
	 * @description Sets the OFFSET clause on the builder.
	 * @param builder The {@link Soql.Builder} to modify
	 * @param offsetStr The OFFSET value string
	 */
	private void parseOffset(Soql.Builder builder, String offsetStr) {
		builder.setRowOffset(Integer.valueOf(offsetStr));
	}

	/**
	 * @description Parses the ORDER BY clause and adds each item verbatim to the builder.
	 * @param builder The {@link Soql.Builder} to modify
	 * @param orderByStr The ORDER BY clause content
	 */
	private void parseOrderBy(Soql.Builder builder, String orderByStr) {
		for (String item : this.splitTopLevelKeyword(orderByStr, ',')) {
			builder.addRawOrderBy(item.trim());
		}
	}

	/**
	 * @description Parses the SELECT clause and registers each item (field, aggregation, or
	 * subquery) on the builder.
	 * @param builder The {@link Soql.Builder} to modify
	 * @param selectStr The SELECT clause content (after the SELECT keyword)
	 */
	private void parseSelect(Soql.Builder builder, String selectStr) {
		builder.deselectAll();
		for (String item : this.splitTopLevelKeyword(selectStr, ',')) {
			String token = item.trim();
			if (token.startsWith('(')) {
				this.parseSubquery(builder, token);
			} else if (this.isAggregation(token)) {
				this.parseAggregation(builder, token);
			} else {
				builder.addSelect(token);
			}
		}
	}

	/**
	 * @description Unquotes a single-quoted string literal, unescaping internal quotes.
	 * @param trimmed The quoted token, including surrounding single quotes
	 * @return The unquoted string value
	 */
	private Object parseStringLiteral(String trimmed) {
		return trimmed.substring(1, trimmed.length() - 1).replace('\\\'', '\'');
	}

	/**
	 * @description Parses a parenthesized subquery token and registers it as a SELECT item on the
	 * builder. If the subquery body has no FROM clause, it is silently ignored.
	 * @param builder The {@link Soql.Builder} to add the subquery to
	 * @param subqueryStr The parenthesized subquery string, e.g. {@code (SELECT Id FROM Contacts)}
	 */
	private void parseSubquery(Soql.Builder builder, String subqueryStr) {
		String body = subqueryStr.substring(1, subqueryStr.length() - 1).trim();
		Integer fromPos = body.toUpperCase().indexOf(' FROM ');
		if (fromPos < 0) {
			return;
		}
		String selectPart = body.substring(0, fromPos).trim();
		String fromPart = body.substring(fromPos + 6).trim();
		if (selectPart.toUpperCase().startsWith('SELECT ')) {
			selectPart = selectPart.substring(7).trim();
		}
		Soql.InnerQuery innerQuery = new Soql.InnerQuery(fromPart.split(' ')[0]);
		new SoqlParser().parse(innerQuery, 'SELECT ' + selectPart + ' FROM ' + fromPart);
		builder.addSelect((Soql.Selectable) innerQuery);
	}

	/**
	 * @description Sets the USING SCOPE clause on the builder when the scope name is recognized.
	 * @param builder The {@link Soql.Builder} to modify
	 * @param usingScopeStr The scope name string
	 */
	private void parseUsingScope(Soql.Builder builder, String usingScopeStr) {
		Soql.Scope scope = SCOPE_MAP.get(usingScopeStr?.toUpperCase());
		if (scope != null) {
			builder.setScope(scope);
		}
	}

	/**
	 * @description Parses a raw SOQL value token into an appropriate Apex type (Boolean, Date,
	 * DateTime, Integer, Decimal, List, or String).
	 * @param token The raw value token from the query
	 * @return The parsed value, or the original token string if no conversion applies
	 */
	@TestVisible
	private Object parseValue(String token) {
		String trimmed = token?.trim();
		String upper = trimmed?.toUpperCase();
		if (upper == 'NULL') {
			return null;
		}
		if (upper == 'TRUE') {
			return true;
		}
		if (upper == 'FALSE') {
			return false;
		}
		if (trimmed?.startsWith(':') == true) {
			return trimmed;
		}
		if (trimmed?.startsWith('\'') == true) {
			return this.parseStringLiteral(trimmed);
		}
		if (trimmed?.startsWith('(') == true) {
			return this.parseList(trimmed);
		}
		if (this.isDateTime(upper)) {
			return this.parseDateTime(trimmed);
		}
		if (this.isDate(upper)) {
			return this.parseDate(trimmed);
		}
		return this.parseNumeric(trimmed);
	}

	/**
	 * @description Parses the WHERE clause into a criteria tree and sets it on the builder.
	 * @param builder The {@link Soql.Builder} to modify
	 * @param whereStr The WHERE clause content
	 */
	private void parseWhere(Soql.Builder builder, String whereStr) {
		builder.setWhereCriteria(this.parseCriteriaLogic(whereStr));
	}

	/**
	 * @description Sets the WITH clause on the builder.
	 * @param builder The {@link Soql.Builder} to modify
	 * @param withStr The WITH clause value
	 */
	private void parseWith(Soql.Builder builder, String withStr) {
		builder.setWithClause(withStr);
	}

	/**
	 * @description Splits {@code str} on top-level occurrences of {@code delimiter} (not inside
	 * parentheses or string literals).
	 * @param str The string to split
	 * @param delimiter The delimiter to split on
	 * @return A list of substrings between top-level delimiter occurrences
	 */
	private List<String> splitTopLevelKeyword(String str, String delimiter) {
		List<String> parts = new List<String>();
		String strUpper = str?.toUpperCase() ?? '';
		Integer parenDepth = 0;
		Boolean inString = false;
		Integer lastPos = 0;
		for (Integer i = 0; i <= str.length() - delimiter.length(); i++) {
			String c = str.substring(i, i + 1);
			if (c == '\'' && (i == 0 || str.substring(i - 1, i) != '\\')) {
				inString = (inString == false);
			} else if (inString == false) {
				if (c == '(') {
					parenDepth++;
				} else if (c == ')') {
					parenDepth--;
				} else if (parenDepth == 0 && strUpper.substring(i, i + delimiter.length()) == delimiter) {
					parts.add(str.substring(lastPos, i));
					lastPos = i + delimiter.length();
					i = lastPos - 1;
				}
			}
		}
		if (lastPos < str.length()) {
			parts.add(str.substring(lastPos));
		} else if (parts.isEmpty()) {
			parts.add(str);
		}
		return parts;
	}

	// ── INNER CLASSES ─────────────────────────────────────────────────────

	/**
	 * @description Holds a parsed query's raw string and keyword position map, used to pass
	 * context through the parse pipeline without excessive parameter lists.
	 */
	private class ParseContext {
		/** @description The raw query string being parsed. */
		final String queryString;
		/** @description Map of keyword name to its starting character position in the query. */
		final Map<String, Integer> positions;

		/**
		 * @description Constructs a ParseContext with the given query and positions.
		 * @param queryString The raw SOQL query string
		 * @param positions The keyword position map produced by {@link Scanner#scan}
		 */
		ParseContext(String queryString, Map<String, Integer> positions) {
			this.queryString = queryString;
			this.positions = positions;
		}
	}

	/**
	 * @description Stateful scanner that walks a SOQL query string character-by-character
	 * and records the starting position of each top-level keyword.
	 */
	private class Scanner {
		private final String rawQuery;
		private final String upperQuery;
		private Integer parenDepth = 0;
		private Boolean inString = false;
		private final Map<String, Integer> positions = new Map<String, Integer>();

		/**
		 * @description Constructs a Scanner for the given query string.
		 * @param queryString The SOQL query string to scan
		 */
		private Scanner(String queryString) {
			this.rawQuery = queryString;
			this.upperQuery = queryString?.toUpperCase() ?? '';
		}

		/**
		 * @description Walks the query and returns a map of keyword to character position.
		 * SELECT is always recorded at position 0; all other keywords are detected at top level only.
		 * @return The keyword position map
		 */
		private Map<String, Integer> scan() {
			for (Integer i = 0; i < this.upperQuery.length(); i++) {
				this.processChar(i);
			}
			this.positions.put(SELECT_KEYWORD, 0);
			return this.positions;
		}

		/**
		 * @description Processes a single character: toggles string mode on unescaped quotes,
		 * tracks paren depth, and attempts to record keyword positions at top level.
		 * @param i The character index to process
		 */
		private void processChar(Integer i) {
			String c = this.rawQuery.substring(i, i + 1);
			if (c == '\'' && this.isNotEscaped(i)) {
				this.inString = (this.inString == false);
			} else if (c == '(' && this.inString == false) {
				this.parenDepth++;
			} else if (c == ')' && this.inString == false) {
				this.parenDepth--;
			} else if (this.parenDepth == 0 && this.inString == false) {
				this.tryRecordAllKeywords(i);
			}
		}

		/**
		 * @description Returns true if the character at {@code i} is not preceded by a backslash.
		 * @param i The character index to test
		 * @return True if the character is unescaped
		 */
		private Boolean isNotEscaped(Integer i) {
			return i == 0 || this.rawQuery.substring(i - 1, i) != '\\';
		}

		/**
		 * @description Attempts to match and record every non-SELECT keyword at position {@code i}.
		 * @param i The character index to test
		 */
		private void tryRecordAllKeywords(Integer i) {
			for (String keyword : ALL_KEYWORDS) {
				if (keyword == SELECT_KEYWORD) {
					continue;
				}
				this.tryRecordKeyword(keyword, i);
			}
		}

		/**
		 * @description Records {@code keyword} at position {@code i} if the query text matches it
		 * there with valid surrounding word boundaries, and it has not already been recorded.
		 * @param keyword The keyword to attempt to match
		 * @param i The character index to test
		 */
		private void tryRecordKeyword(String keyword, Integer i) {
			Integer endIndex = i + keyword.length();
			if (endIndex > this.upperQuery.length() || this.upperQuery.substring(i, endIndex) != keyword) {
				return;
			}
			Boolean beforeOk = (i == 0 || this.upperQuery.substring(i - 1, i) == ' ');
			Boolean afterOk = (endIndex >= this.upperQuery.length() ||
			this.upperQuery.substring(endIndex, endIndex + 1) == ' ');
			if (beforeOk && afterOk && this.positions?.containsKey(keyword) == false) {
				this.positions.put(keyword, i);
			}
		}
	}
}
