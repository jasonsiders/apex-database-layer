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
		'LIKE' => Soql.CONTAINS,
		'NOT LIKE' => Soql.NOT_CONTAINS
	};

	public void parse(Soql.Builder builder, String queryString) {
		Map<String, Integer> keywordPositions = this.findKeywordPositions(queryString);

		String selectStr = this.extractClause(queryString, keywordPositions, SELECT_KEYWORD, FROM_KEYWORD);
		String fromStr = this.extractClause(queryString, keywordPositions, FROM_KEYWORD, this.getNextKeyword(keywordPositions, FROM_KEYWORD));
		String whereStr = this.extractClause(queryString, keywordPositions, WHERE_KEYWORD, this.getNextKeyword(keywordPositions, WHERE_KEYWORD));
		String groupByStr = this.extractClause(queryString, keywordPositions, GROUP_BY_KEYWORD, this.getNextKeyword(keywordPositions, GROUP_BY_KEYWORD));
		String havingStr = this.extractClause(queryString, keywordPositions, HAVING_KEYWORD, this.getNextKeyword(keywordPositions, HAVING_KEYWORD));
		String orderByStr = this.extractClause(queryString, keywordPositions, ORDER_BY_KEYWORD, this.getNextKeyword(keywordPositions, ORDER_BY_KEYWORD));
		String limitStr = this.extractClause(queryString, keywordPositions, LIMIT_KEYWORD, this.getNextKeyword(keywordPositions, LIMIT_KEYWORD));
		String offsetStr = this.extractClause(queryString, keywordPositions, OFFSET_KEYWORD, this.getNextKeyword(keywordPositions, OFFSET_KEYWORD));
		String usingScopeStr = this.extractClause(queryString, keywordPositions, USING_SCOPE_KEYWORD, this.getNextKeyword(keywordPositions, USING_SCOPE_KEYWORD));
		String withStr = this.extractClause(queryString, keywordPositions, WITH_KEYWORD, this.getNextKeyword(keywordPositions, WITH_KEYWORD));
		String forStr = this.extractClause(queryString, keywordPositions, FOR_KEYWORD, this.getNextKeyword(keywordPositions, FOR_KEYWORD));
		String allRowsStr = this.extractClause(queryString, keywordPositions, ALL_ROWS_KEYWORD, this.getNextKeyword(keywordPositions, ALL_ROWS_KEYWORD));

		this.parseSelect(builder, selectStr);
		this.parseFrom(builder, fromStr);
		if (String.isNotBlank(whereStr)) {
			this.parseWhere(builder, whereStr);
		}
		if (String.isNotBlank(groupByStr)) {
			this.parseGroupBy(builder, groupByStr);
		}
		if (String.isNotBlank(havingStr)) {
			this.parseHaving(builder, havingStr);
		}
		if (String.isNotBlank(orderByStr)) {
			this.parseOrderBy(builder, orderByStr);
		}
		if (String.isNotBlank(limitStr)) {
			this.parseLimit(builder, limitStr);
		}
		if (String.isNotBlank(offsetStr)) {
			this.parseOffset(builder, offsetStr);
		}
		if (String.isNotBlank(usingScopeStr)) {
			this.parseUsingScope(builder, usingScopeStr);
		}
		if (String.isNotBlank(withStr)) {
			this.parseWith(builder, withStr);
		}
		if (String.isNotBlank(forStr)) {
			this.parseFor(builder, forStr);
		}
		if (keywordPositions.containsKey(ALL_ROWS_KEYWORD)) {
			this.parseAllRows(builder);
		}
	}

	private Map<String, Integer> findKeywordPositions(String queryString) {
		Map<String, Integer> positions = new Map<String, Integer>();
		List<String> keywords = new List<String>{
			USING_SCOPE_KEYWORD, GROUP_BY_KEYWORD, ORDER_BY_KEYWORD,
			FROM_KEYWORD, WHERE_KEYWORD, WITH_KEYWORD, HAVING_KEYWORD,
			LIMIT_KEYWORD, OFFSET_KEYWORD, FOR_KEYWORD, ALL_ROWS_KEYWORD
		};

		String upper = queryString.toUpperCase();
		Integer parenDepth = 0;
		Boolean inStringLiteral = false;

		for (Integer i = 0; i < upper.length(); i++) {
			String c = queryString.substring(i, i + 1);

			if (c == '\'' && (i == 0 || queryString.substring(i - 1, i) != '\\')) {
				inStringLiteral = !inStringLiteral;
			}

			if (!inStringLiteral) {
				if (c == '(') {
					parenDepth++;
				} else if (c == ')') {
					parenDepth--;
				}
			}

			if (parenDepth == 0 && !inStringLiteral) {
				for (String keyword : keywords) {
					if (upper.substring(i).startsWithIgnoreCase(keyword)) {
						Integer endIndex = i + keyword.length();
						Boolean beforeOk = (i == 0 || upper.substring(i - 1, i) == ' ');
						Boolean afterOk = (endIndex >= upper.length() || upper.substring(endIndex, endIndex + 1) == ' ');

						if (beforeOk && afterOk && !positions.containsKey(keyword)) {
							positions.put(keyword, i);
						}
					}
				}
			}
		}

		positions.put(SELECT_KEYWORD, 0);
		return positions;
	}

	private String getNextKeyword(Map<String, Integer> positions, String currentKeyword) {
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
		Integer nextPos = 999999;

		for (String keyword : allKeywords) {
			Integer pos = positions.get(keyword);
			if (pos != null && pos > currentPos && pos < nextPos) {
				nextPos = pos;
				nextKeyword = keyword;
			}
		}

		return nextKeyword;
	}

	private String extractClause(String queryString, Map<String, Integer> positions, String keyword, String nextKeyword) {
		Integer startPos = positions.get(keyword);
		if (startPos == null) {
			return '';
		}

		startPos = startPos + keyword.length();

		Integer endPos;
		if (nextKeyword == null) {
			endPos = queryString.length();
		} else {
			Integer nextPos = positions.get(nextKeyword);
			endPos = nextPos != null ? nextPos : queryString.length();
		}

		String clause = queryString.substring(startPos, endPos).trim();
		return clause;
	}

	private void parseSelect(Soql.Builder builder, String selectStr) {
		builder.deselectAll();
		List<String> selectItems = this.splitTopLevel(selectStr, ',');

		for (String item : selectItems) {
			String trimmed = item.trim();
			if (trimmed.startsWith('(')) {
				this.parseSubquery(builder, trimmed);
			} else if (this.isAggregation(trimmed)) {
				this.parseAggregation(builder, trimmed);
			} else {
				builder.addSelect(trimmed);
			}
		}
	}

	private Boolean isAggregation(String token) {
		String upper = token.toUpperCase();
		Integer parenPos = upper.indexOf('(');
		if (parenPos <= 0) {
			return false;
		}

		String functionName = upper.substring(0, parenPos).trim();
		return FUNCTION_MAP.containsKey(functionName);
	}

	private void parseSubquery(Soql.Builder builder, String subqueryStr) {
		String innerContent = subqueryStr.substring(1, subqueryStr.length() - 1).trim();
		Integer fromPos = innerContent.toUpperCase().indexOf(' FROM ');

		if (fromPos < 0) {
			return;
		}

		String selectPart = innerContent.substring(0, fromPos).trim();
		String fromPart = innerContent.substring(fromPos + 6).trim();
		String[] fromTokens = fromPart.split(' ');
		String fromEntity = fromTokens[0];

		if (selectPart.toUpperCase().startsWith('SELECT ')) {
			selectPart = selectPart.substring(7).trim();
		}

		Soql.InnerQuery innerQuery = new Soql.InnerQuery(fromEntity);
		new SoqlParser().parse(innerQuery, 'SELECT ' + selectPart + ' FROM ' + fromPart);
		builder.addSelect((Soql.Selectable) innerQuery);
	}

	private void parseAggregation(Soql.Builder builder, String token) {
		String upper = token.toUpperCase();
		Integer openParen = upper.indexOf('(');
		Integer closeParen = this.findMatchingParen(token, openParen);

		String functionName = upper.substring(0, openParen).trim();
		String innerField = token.substring(openParen + 1, closeParen).trim();
		Soql.Function fn = FUNCTION_MAP.get(functionName);

		Soql.Aggregation agg = new Soql.Aggregation(fn, innerField);

		if (closeParen < token.length() - 1) {
			String afterParen = token.substring(closeParen + 1).trim();
			String alias = afterParen.trim();
			if (String.isNotBlank(alias)) {
				agg.withAlias(alias);
			}
		}

		builder.addSelect(agg);
	}

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

	private void parseFrom(Soql.Builder builder, String fromStr) {
		builder.setFrom(fromStr.trim());
	}

	private void parseWhere(Soql.Builder builder, String whereStr) {
		Soql.Criteria criteria = this.parseExpr(whereStr);
		if (criteria instanceof Soql.Condition) {
			Soql.ConditionalLogic logic = new Soql.ConditionalLogic();
			logic.addCondition((Soql.Condition) criteria);
			builder.setWhereCriteria(logic);
		} else {
			builder.setWhereCriteria((Soql.ConditionalLogic) criteria);
		}
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
			String innerStr = trimmed.substring(1, trimmed.length() - 1).trim();
			return this.parseExpr(innerStr);
		}
		return this.parseCondition(trimmed);
	}

	private Soql.Condition parseCondition(String str) {
		List<String> operators = new List<String>{ 'NOT IN', 'NOT LIKE', '!=', '>=', '<=', '>', '<', '=', 'IN', 'LIKE' };

		for (String op : operators) {
			Integer opPos = this.findOperatorPosition(str, op);
			if (opPos >= 0) {
				String fieldName = str.substring(0, opPos).trim();
				String value = str.substring(opPos + op.length()).trim();
				Soql.Operator operator = OPERATOR_MAP.get(op.toUpperCase());
				if (operator == null) {
					operator = Soql.EQUALS;
				}
				return new Soql.Condition(fieldName, operator, this.parseValue(value));
			}
		}

		return new Soql.Condition(str, Soql.EQUALS, null);
	}

	private Integer findOperatorPosition(String str, String operator) {
		Integer parenDepth = 0;
		Boolean inString = false;

		for (Integer i = 0; i <= str.length() - operator.length(); i++) {
			String c = str.substring(i, i + 1);

			if (c == '\'' && (i == 0 || str.substring(i - 1, i) != '\\')) {
				inString = !inString;
			} else if (!inString) {
				if (c == '(') {
					parenDepth++;
				} else if (c == ')') {
					parenDepth--;
				} else if (parenDepth == 0 && str.substring(i).toUpperCase().startsWith(operator)) {
					return i;
				}
			}
		}

		return -1;
	}

	private Object parseValue(String token) {
		String t = token.trim().toUpperCase();

		if (t == 'NULL') {
			return null;
		}
		if (t == 'TRUE') {
			return true;
		}
		if (t == 'FALSE') {
			return false;
		}
		if (token.trim().startsWith(':')) {
			return token.trim();
		}
		if (token.trim().startsWith('\'')) {
			String unquoted = token.trim().substring(1, token.trim().length() - 1);
			return unquoted.replace('\\\'', '\'');
		}
		if (token.trim().startsWith('(')) {
			String parenthetical = token.trim().substring(1, token.trim().length() - 1);
			if (parenthetical.toUpperCase().contains('SELECT')) {
				return token.trim();
			}
			List<String> items = this.splitTopLevel(parenthetical, ',');
			List<String> result = new List<String>();
			for (String item : items) {
				String cleaned = item.trim();
				if (cleaned.startsWith('\'') && cleaned.endsWith('\'')) {
					cleaned = cleaned.substring(1, cleaned.length() - 1);
				}
				result.add(cleaned);
			}
			return result;
		}

		if (this.isDateTime(t)) {
			try {
				return DateTime.valueOfGmt(token.trim());
			} catch (Exception e) {
				return token.trim();
			}
		}
		if (this.isDate(t)) {
			try {
				return Date.valueOf(token.trim());
			} catch (Exception e) {
				return token.trim();
			}
		}

		try {
			return Integer.valueOf(token.trim());
		} catch (Exception e) {
		}

		try {
			return Decimal.valueOf(token.trim());
		} catch (Exception e) {
		}

		return token.trim();
	}

	private void parseOrderBy(Soql.Builder builder, String orderByStr) {
		List<String> items = this.splitTopLevel(orderByStr, ',');
		for (String item : items) {
			builder.addRawOrderBy(item.trim());
		}
	}

	private void parseGroupBy(Soql.Builder builder, String groupByStr) {
		List<String> items = this.splitTopLevel(groupByStr, ',');
		for (String item : items) {
			builder.addGroupBy(item.trim());
		}
	}

	private void parseUsingScope(Soql.Builder builder, String usingScopeStr) {
		String scopeName = usingScopeStr.trim().toUpperCase();
		Soql.Scope scope = SCOPE_MAP.get(scopeName);
		if (scope != null) {
			builder.setScope(scope);
		}
	}

	private void parseWith(Soql.Builder builder, String withStr) {
		builder.setWithClause(withStr.trim());
	}

	private void parseFor(Soql.Builder builder, String forStr) {
		String trimmed = forStr.trim().toUpperCase();
		if (trimmed.startsWith('UPDATE')) {
			builder.setUsage(Soql.Usage.FOR_UPDATE);
		} else if (trimmed.startsWith('VIEW')) {
			builder.setUsage(Soql.Usage.FOR_VIEW);
		} else if (trimmed.startsWith('REFERENCE')) {
			builder.setUsage(Soql.Usage.FOR_REFERENCE);
		}
	}

	private void parseAllRows(Soql.Builder builder) {
		builder.setUsage(Soql.Usage.ALL_ROWS);
	}

	private void parseHaving(Soql.Builder builder, String havingStr) {
		Soql.Criteria criteria = this.parseExpr(havingStr);
		if (criteria instanceof Soql.Condition) {
			Soql.ConditionalLogic logic = new Soql.ConditionalLogic();
			logic.addCondition((Soql.Condition) criteria);
			builder.setHavingCriteria(logic);
		} else {
			builder.setHavingCriteria((Soql.ConditionalLogic) criteria);
		}
	}

	private void parseLimit(Soql.Builder builder, String limitStr) {
		Integer rowLimit = Integer.valueOf(limitStr.trim());
		builder.setRowLimit(rowLimit);
	}

	private void parseOffset(Soql.Builder builder, String offsetStr) {
		Integer rowOffset = Integer.valueOf(offsetStr.trim());
		builder.setRowOffset(rowOffset);
	}

	private List<String> splitTopLevel(String str, String delimiter) {
		List<String> parts = new List<String>();
		Integer parenDepth = 0;
		Boolean inString = false;
		Integer lastPos = 0;

		for (Integer i = 0; i < str.length(); i++) {
			String c = str.substring(i, i + 1);

			if (c == '\'' && (i == 0 || str.substring(i - 1, i) != '\\')) {
				inString = !inString;
			} else if (!inString) {
				if (c == '(') {
					parenDepth++;
				} else if (c == ')') {
					parenDepth--;
				} else if (parenDepth == 0 && str.substring(i).startsWith(delimiter)) {
					parts.add(str.substring(lastPos, i));
					lastPos = i + delimiter.length();
					i = lastPos - 1;
				}
			}
		}

		if (lastPos < str.length()) {
			parts.add(str.substring(lastPos));
		}

		return parts;
	}

	private List<String> splitTopLevelKeyword(String str, String keyword) {
		List<String> parts = new List<String>();
		Integer parenDepth = 0;
		Boolean inString = false;
		Integer lastPos = 0;

		for (Integer i = 0; i <= str.length() - keyword.length(); i++) {
			String c = str.substring(i, i + 1);

			if (c == '\'' && (i == 0 || str.substring(i - 1, i) != '\\')) {
				inString = !inString;
			} else if (!inString) {
				if (c == '(') {
					parenDepth++;
				} else if (c == ')') {
					parenDepth--;
				} else if (parenDepth == 0 && str.substring(i).toUpperCase().startsWith(keyword)) {
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
		if (str == null || str.length() < 10) {
			return false;
		}
		String prefix = str.substring(0, 10);
		return this.isValidDatePrefix(prefix) && str.contains('T');
	}

	private Boolean isDate(String str) {
		if (str == null || str.length() != 10) {
			return false;
		}
		return this.isValidDatePrefix(str);
	}

	private Boolean isValidDatePrefix(String datePrefix) {
		if (datePrefix == null || datePrefix.length() != 10) {
			return false;
		}
		if (datePrefix.substring(4, 5) != '-' || datePrefix.substring(7, 8) != '-') {
			return false;
		}
		String yearPart = datePrefix.substring(0, 4);
		String monthPart = datePrefix.substring(5, 7);
		String dayPart = datePrefix.substring(8, 10);

		try {
			Integer year = Integer.valueOf(yearPart);
			Integer month = Integer.valueOf(monthPart);
			Integer day = Integer.valueOf(dayPart);
			return year >= 1900 && year <= 2100 && month >= 1 && month <= 12 && day >= 1 && day <= 31;
		} catch (Exception e) {
			return false;
		}
	}
}
