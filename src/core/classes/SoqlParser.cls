/**
 * @description Parses SOQL query strings into structured {@link Soql.Builder} representations.
 * Handles all standard SOQL clauses including SELECT, FROM, WHERE, GROUP BY, HAVING, ORDER BY,
 * LIMIT, OFFSET, USING SCOPE, WITH, FOR, and ALL ROWS.
 */
@SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity')
public class SoqlParser {
	private static final String SELECT_KEYWORD = 'SELECT';
	private static final String FROM_KEYWORD = 'FROM';
	private static final String WHERE_KEYWORD = 'WHERE';
	private static final String GROUP_BY_KEYWORD = 'GROUP BY';
	private static final String HAVING_KEYWORD = 'HAVING';
	private static final String ORDER_BY_KEYWORD = 'ORDER BY';
	private static final String LIMIT_KEYWORD = 'LIMIT';
	private static final String OFFSET_KEYWORD = 'OFFSET';
	private static final String USING_SCOPE_KEYWORD = 'USING SCOPE';
	private static final String WITH_KEYWORD = 'WITH';
	private static final String FOR_KEYWORD = 'FOR';
	private static final String ALL_ROWS_KEYWORD = 'ALL ROWS';
	private static final Integer MAX_INT = 2147483647;

	private static final Map<String, Soql.Function> FUNCTION_MAP = new Map<String, Soql.Function>{
		'AVG' => Soql.Function.AVG,
		'CALENDAR_MONTH' => Soql.Function.CALENDAR_MONTH,
		'CALENDAR_QUARTER' => Soql.Function.CALENDAR_QUARTER,
		'CALENDAR_YEAR' => Soql.Function.CALENDAR_YEAR,
		'COUNT' => Soql.Function.COUNT,
		'COUNT_DISTINCT' => Soql.Function.COUNT_DISTINCT,
		'DAY_IN_MONTH' => Soql.Function.DAY_IN_MONTH,
		'DAY_IN_WEEK' => Soql.Function.DAY_IN_WEEK,
		'DAY_IN_YEAR' => Soql.Function.DAY_IN_YEAR,
		'DAY_ONLY' => Soql.Function.DAY_ONLY,
		'FISCAL_MONTH' => Soql.Function.FISCAL_MONTH,
		'FISCAL_QUARTER' => Soql.Function.FISCAL_QUARTER,
		'FISCAL_YEAR' => Soql.Function.FISCAL_YEAR,
		'FORMAT' => Soql.Function.FORMAT,
		'HOUR_IN_DAY' => Soql.Function.HOUR_IN_DAY,
		'MIN' => Soql.Function.MIN,
		'MAX' => Soql.Function.MAX,
		'SUM' => Soql.Function.SUM,
		'WEEK_IN_MONTH' => Soql.Function.WEEK_IN_MONTH,
		'WEEK_IN_YEAR' => Soql.Function.WEEK_IN_YEAR
	};

	private static final Map<String, Soql.Scope> SCOPE_MAP = new Map<String, Soql.Scope>{
		'DELEGATED' => Soql.Scope.DELEGATED,
		'EVERYTHING' => Soql.Scope.EVERYTHING,
		'MINE' => Soql.Scope.MINE,
		'MINE_AND_MY_GROUPS' => Soql.Scope.MINE_AND_MY_GROUPS,
		'MY_TERRITORY' => Soql.Scope.MY_TERRITORY,
		'MY_TEAM_TERRITORY' => Soql.Scope.MY_TEAM_TERRITORY,
		'TEAM' => Soql.Scope.TEAM
	};

	private static final Map<String, Soql.Operator> OPERATOR_MAP = new Map<String, Soql.Operator>{
		'=' => Soql.EQUALS,
		'!=' => Soql.NOT_EQUALS,
		'>' => Soql.GREATER_THAN,
		'>=' => Soql.GREATER_OR_EQUAL,
		'<' => Soql.LESS_THAN,
		'<=' => Soql.LESS_OR_EQUAL,
		'IN' => Soql.IN_COLLECTION,
		'NOT IN' => Soql.NOT_IN_COLLECTION,
		'LIKE' => Soql.LIKE_RAW,
		'NOT LIKE' => Soql.NOT_LIKE_RAW
	};

	/**
	 * @description Parses a SOQL query string and applies the parsed clauses to the given builder.
	 * @param builder The {@link Soql.Builder} to populate with parsed clauses
	 * @param queryString The SOQL query string to parse
	 */
	public void parse(Soql.Builder builder, String queryString) {
		Map<String, Integer> positions = this.findKeywordPositions(queryString);
		this.applyParsers(builder, queryString, positions);
	}

	/**
	 * @description Scans a query string and returns the character position of each SOQL keyword found
	 * at the top level (not inside parentheses or string literals).
	 * @param queryString The SOQL query string to scan
	 * @return A map of keyword to its starting character position
	 */
	public Map<String, Integer> findKeywordPositions(String queryString) {
		Map<String, Integer> positions = new Map<String, Integer>();
		List<String> keywords = new List<String>{
			USING_SCOPE_KEYWORD, GROUP_BY_KEYWORD, ORDER_BY_KEYWORD,
			FROM_KEYWORD, WHERE_KEYWORD, WITH_KEYWORD, HAVING_KEYWORD,
			LIMIT_KEYWORD, OFFSET_KEYWORD, FOR_KEYWORD, ALL_ROWS_KEYWORD
		};
		String upper = queryString.toUpperCase();
		Integer parenDepth = 0;
		Boolean inString = false;
		for (Integer i = 0; i < upper.length(); i++) {
			String c = queryString.substring(i, i + 1);
			if (c == '\'' && (i == 0 || queryString.substring(i - 1, i) != '\\')) {
				inString = !inString;
			} else if (c == '(' && !inString) {
				parenDepth++;
			} else if (c == ')' && !inString) {
				parenDepth--;
			} else if (parenDepth == 0 && !inString) {
				for (String keyword : keywords) {
					this.tryRecordKeyword(positions, upper, keyword, i);
				}
			}
		}
		positions.put(SELECT_KEYWORD, 0);
		return positions;
	}

	/**
	 * @description Returns the keyword that immediately follows the given keyword in the query,
	 * based on character positions.
	 * @param positions The keyword position map from {@link #findKeywordPositions}
	 * @param currentKeyword The keyword to find the successor of
	 * @return The next keyword name, or null if there is none
	 */
	public String getNextKeyword(Map<String, Integer> positions, String currentKeyword) {
		List<String> allKeywords = new List<String>{
			SELECT_KEYWORD, FROM_KEYWORD, WHERE_KEYWORD, GROUP_BY_KEYWORD, HAVING_KEYWORD,
			ORDER_BY_KEYWORD, LIMIT_KEYWORD, OFFSET_KEYWORD, USING_SCOPE_KEYWORD, WITH_KEYWORD,
			FOR_KEYWORD, ALL_ROWS_KEYWORD
		};
		Integer currentPos = positions.get(currentKeyword);
		if (currentPos == null) {
			return null;
		}
		String nextKeyword = null;
		Integer nextPos = MAX_INT;
		for (String keyword : allKeywords) {
			Integer pos = positions.get(keyword);
			if (pos != null && pos > currentPos && pos < nextPos) {
				nextPos = pos;
				nextKeyword = keyword;
			}
		}
		return nextKeyword;
	}

	/**
	 * @description Extracts the text of a clause by slicing between the start of one keyword and
	 * the start of the next, trimming the keyword itself and surrounding whitespace.
	 * @param queryString The full SOQL query string
	 * @param positions The keyword position map from {@link #findKeywordPositions}
	 * @param keyword The keyword whose clause content to extract
	 * @param nextKeyword The keyword that terminates the clause, or null if none follows
	 * @return The trimmed clause text, or an empty string if the keyword is not present
	 */
	@SuppressWarnings('PMD.ExcessiveParameterList')
	public String extractClause(String queryString, Map<String, Integer> positions, String keyword, String nextKeyword) {
		Integer startPos = positions.get(keyword);
		if (startPos == null) {
			return '';
		}
		Integer endPos = this.calculateEndPos(queryString, positions, nextKeyword);
		return queryString.substring(startPos + keyword.length(), endPos).trim();
	}

	/**
	 * @description Parses a single WHERE/HAVING condition expression of the form
	 * {@code field operator value}.
	 * @param str The condition string to parse
	 * @return A {@link Soql.Condition} representing the parsed condition
	 */
	public Soql.Condition parseCondition(String str) {
		List<String> operators = new List<String>{ 'NOT IN', 'NOT LIKE', '!=', '>=', '<=', '>', '<', '=', 'IN', 'LIKE' };
		for (String op : operators) {
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
	 * @description Finds the index of the closing parenthesis that matches the opening parenthesis
	 * at {@code openIndex}, accounting for nested parentheses.
	 * @param str The string to search
	 * @param openIndex The index of the opening parenthesis
	 * @return The index of the matching closing parenthesis, or the string length if not found
	 */
	public Integer findMatchingParen(String str, Integer openIndex) {
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
	 * @description Parses a parenthesized subquery token and registers it as a SELECT item on the
	 * builder.
	 * @param builder The {@link Soql.Builder} to add the subquery to
	 * @param subqueryStr The parenthesized subquery string, e.g. {@code (SELECT Id FROM Contacts)}
	 */
	public void parseSubquery(Soql.Builder builder, String subqueryStr) {
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
	 * @description Parses a raw SOQL value token into an appropriate Apex type (Boolean, Date,
	 * DateTime, Integer, Decimal, List, or String).
	 * @param token The raw value token from the query
	 * @return The parsed value, or the original token string if no conversion applies
	 */
	public Object parseValue(String token) {
		String trimmed = token.trim();
		String upper = trimmed.toUpperCase();
		if (upper == 'NULL') { return null; }
		if (upper == 'TRUE') { return true; }
		if (upper == 'FALSE') { return false; }
		if (trimmed.startsWith(':')) { return trimmed; }
		if (trimmed.startsWith('\'')) { return this.parseStringLiteral(trimmed); }
		if (trimmed.startsWith('(')) { return this.parseList(trimmed); }
		if (this.isDateTime(upper)) { return this.parseDateTime(trimmed); }
		if (this.isDate(upper)) { return this.parseDate(trimmed); }
		return this.parseNumeric(trimmed);
	}

	private void applyParsers(Soql.Builder builder, String queryString, Map<String, Integer> positions) {
		this.parseSelect(builder, this.extractClause(queryString, positions, SELECT_KEYWORD, FROM_KEYWORD));
		this.parseFrom(builder, this.extractClause(queryString, positions, FROM_KEYWORD, this.getNextKeyword(positions, FROM_KEYWORD)));
		String whereClause = this.extractClause(queryString, positions, WHERE_KEYWORD, this.getNextKeyword(positions, WHERE_KEYWORD));
		if (String.isNotBlank(whereClause)) {
			this.parseWhere(builder, whereClause);
		}
		String groupBy = this.extractClause(queryString, positions, GROUP_BY_KEYWORD, this.getNextKeyword(positions, GROUP_BY_KEYWORD));
		if (String.isNotBlank(groupBy)) {
			this.parseGroupBy(builder, groupBy);
		}
		String havingClause = this.extractClause(queryString, positions, HAVING_KEYWORD, this.getNextKeyword(positions, HAVING_KEYWORD));
		if (String.isNotBlank(havingClause)) {
			this.parseHaving(builder, havingClause);
		}
		String orderBy = this.extractClause(queryString, positions, ORDER_BY_KEYWORD, this.getNextKeyword(positions, ORDER_BY_KEYWORD));
		if (String.isNotBlank(orderBy)) {
			this.parseOrderBy(builder, orderBy);
		}
		String lim = this.extractClause(queryString, positions, LIMIT_KEYWORD, this.getNextKeyword(positions, LIMIT_KEYWORD));
		if (String.isNotBlank(lim)) {
			this.parseLimit(builder, lim);
		}
		String off = this.extractClause(queryString, positions, OFFSET_KEYWORD, this.getNextKeyword(positions, OFFSET_KEYWORD));
		if (String.isNotBlank(off)) {
			this.parseOffset(builder, off);
		}
		String usingScope = this.extractClause(queryString, positions, USING_SCOPE_KEYWORD, this.getNextKeyword(positions, USING_SCOPE_KEYWORD));
		if (String.isNotBlank(usingScope)) {
			this.parseUsingScope(builder, usingScope);
		}
		String withClause = this.extractClause(queryString, positions, WITH_KEYWORD, this.getNextKeyword(positions, WITH_KEYWORD));
		if (String.isNotBlank(withClause)) {
			this.parseWith(builder, withClause);
		}
		String forClause = this.extractClause(queryString, positions, FOR_KEYWORD, this.getNextKeyword(positions, FOR_KEYWORD));
		if (String.isNotBlank(forClause)) {
			this.parseFor(builder, forClause);
		}
		if (positions.containsKey(ALL_ROWS_KEYWORD)) {
			this.parseAllRows(builder);
		}
	}

	private Integer calculateEndPos(String queryString, Map<String, Integer> positions, String nextKeyword) {
		if (nextKeyword == null) {
			return queryString.length();
		}
		Integer nextPos = positions.get(nextKeyword);
		return nextPos != null ? nextPos : queryString.length();
	}

	@SuppressWarnings('PMD.ExcessiveParameterList')
	private void tryRecordKeyword(Map<String, Integer> positions, String upper, String keyword, Integer i) {
		Integer endIndex = i + keyword.length();
		if (endIndex > upper.length() || upper.substring(i, endIndex) != keyword) {
			return;
		}
		Boolean beforeOk = (i == 0 || upper.substring(i - 1, i) == ' ');
		Boolean afterOk = (endIndex >= upper.length() || upper.substring(endIndex, endIndex + 1) == ' ');
		if (beforeOk && afterOk && !positions.containsKey(keyword)) {
			positions.put(keyword, i);
		}
	}

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

	private Boolean isAggregation(String token) {
		String upper = token.toUpperCase();
		Integer parenPos = upper.indexOf('(');
		if (parenPos <= 0) {
			return false;
		}
		return FUNCTION_MAP.containsKey(upper.substring(0, parenPos).trim());
	}

	private void parseAggregation(Soql.Builder builder, String token) {
		builder.addSelect(this.buildAggregation(token));
	}

	private Soql.Aggregation buildAggregation(String token) {
		String upper = token.toUpperCase();
		Integer openParen = upper.indexOf('(');
		Integer closeParen = this.findMatchingParen(token, openParen);
		Soql.Aggregation agg = new Soql.Aggregation(
			FUNCTION_MAP.get(upper.substring(0, openParen).trim()),
			token.substring(openParen + 1, closeParen).trim()
		);
		if (closeParen < token.length() - 1) {
			String alias = token.substring(closeParen + 1).trim();
			if (String.isNotBlank(alias)) {
				agg.withAlias(alias);
			}
		}
		return agg;
	}

	private void parseFrom(Soql.Builder builder, String fromStr) {
		builder.setFrom(fromStr);
	}

	private void parseWhere(Soql.Builder builder, String whereStr) {
		builder.setWhereCriteria(this.parseCriteriaLogic(whereStr));
	}

	private void parseHaving(Soql.Builder builder, String havingStr) {
		builder.setHavingCriteria(this.parseCriteriaLogic(havingStr));
	}

	private Soql.ConditionalLogic parseCriteriaLogic(String str) {
		Soql.Criteria criteria = this.parseExpr(str);
		if (criteria instanceof Soql.Condition) {
			Soql.ConditionalLogic logic = new Soql.ConditionalLogic();
			logic.addCondition((Soql.Condition) criteria);
			return logic;
		}
		return (Soql.ConditionalLogic) criteria;
	}

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

	private Soql.Criteria parseFactor(String str) {
		String trimmed = str.trim();
		if (trimmed.startsWith('(') && this.findMatchingParen(trimmed, 0) == trimmed.length() - 1) {
			return this.parseExpr(trimmed.substring(1, trimmed.length() - 1).trim());
		}
		return this.parseCondition(trimmed);
	}

	private Integer findOperatorPosition(String str, String operator) {
		Integer parenDepth = 0;
		Boolean inString = false;
		String strUpper = str.toUpperCase();
		for (Integer i = 0; i <= str.length() - operator.length(); i++) {
			String c = str.substring(i, i + 1);
			if (c == '\'' && (i == 0 || str.substring(i - 1, i) != '\\')) {
				inString = !inString;
			} else if (!inString) {
				if (c == '(') {
					parenDepth++;
				} else if (c == ')') {
					parenDepth--;
				} else if (parenDepth == 0 && strUpper.substring(i, i + operator.length()) == operator && this.isAtWordBoundary(str, i, operator)) {
					return i;
				}
			}
		}
		return -1;
	}

	private Boolean isAtWordBoundary(String str, Integer i, String operator) {
		Integer afterPos = i + operator.length();
		Boolean beforeOk = (i == 0 || str.substring(i - 1, i) == ' ');
		String afterChar = afterPos < str.length() ? str.substring(afterPos, afterPos + 1) : '';
		return beforeOk && (afterPos >= str.length() || afterChar == ' ' || afterChar == '(');
	}

	private Object parseStringLiteral(String trimmed) {
		return trimmed.substring(1, trimmed.length() - 1).replace('\\\'', '\'');
	}

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

	private Object parseDateTime(String trimmed) {
		try {
			return DateTime.valueOfGmt(trimmed);
		} catch (Exception e) {
			return trimmed;
		}
	}

	private Object parseDate(String trimmed) {
		try {
			return Date.valueOf(trimmed);
		} catch (Exception e) {
			return trimmed;
		}
	}

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

	private void parseOrderBy(Soql.Builder builder, String orderByStr) {
		for (String item : this.splitTopLevelKeyword(orderByStr, ',')) {
			builder.addRawOrderBy(item.trim());
		}
	}

	private void parseGroupBy(Soql.Builder builder, String groupByStr) {
		for (String item : this.splitTopLevelKeyword(groupByStr, ',')) {
			builder.addGroupBy(item.trim());
		}
	}

	private void parseUsingScope(Soql.Builder builder, String usingScopeStr) {
		Soql.Scope scope = SCOPE_MAP.get(usingScopeStr.toUpperCase());
		if (scope != null) {
			builder.setScope(scope);
		}
	}

	private void parseWith(Soql.Builder builder, String withStr) {
		builder.setWithClause(withStr);
	}

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

	private void parseAllRows(Soql.Builder builder) {
		builder.setUsage(Soql.Usage.ALL_ROWS);
	}

	private void parseLimit(Soql.Builder builder, String limitStr) {
		builder.setRowLimit(Integer.valueOf(limitStr));
	}

	private void parseOffset(Soql.Builder builder, String offsetStr) {
		builder.setRowOffset(Integer.valueOf(offsetStr));
	}

	private List<String> splitTopLevelKeyword(String str, String keyword) {
		List<String> parts = new List<String>();
		Integer parenDepth = 0;
		Boolean inString = false;
		Integer lastPos = 0;
		String strUpper = str.toUpperCase();
		for (Integer i = 0; i <= str.length() - keyword.length(); i++) {
			String c = str.substring(i, i + 1);
			if (c == '\'' && (i == 0 || str.substring(i - 1, i) != '\\')) {
				inString = !inString;
			} else if (!inString) {
				if (c == '(') {
					parenDepth++;
				} else if (c == ')') {
					parenDepth--;
				} else if (parenDepth == 0 && strUpper.substring(i, i + keyword.length()) == keyword) {
					parts.add(str.substring(lastPos, i));
					lastPos = i + keyword.length();
					i = lastPos - 1;
				}
			}
		}
		if (lastPos < str.length()) {
			parts.add(str.substring(lastPos));
		} else if (lastPos == str.length() && parts.isEmpty()) {
			parts.add(str);
		}
		return parts;
	}

	private Boolean isDateTime(String str) {
		if (str == null || str.length() < 10 || !str.contains('T')) {
			return false;
		}
		return this.isValidDatePrefix(str.substring(0, 10));
	}

	private Boolean isDate(String str) {
		return str != null && str.length() == 10 && this.isValidDatePrefix(str);
	}

	private Boolean isValidDatePrefix(String datePrefix) {
		if (datePrefix == null || datePrefix.length() != 10) {
			return false;
		}
		if (datePrefix.substring(4, 5) != '-' || datePrefix.substring(7, 8) != '-') {
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
}
