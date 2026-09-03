# GH #180 + #181

## #180 — selectAll() ignores field read access

**Root cause:** [Soql.cls:624-626](src/core/classes/Soql.cls#L624-L626) adds every field from the
describe unconditionally. Builder defaults to `USER_MODE` ([Soql.cls:576](src/core/classes/Soql.cls#L576)),
and user-mode SOQL *rejects* inaccessible fields rather than dropping them.

**Fix:** skip fields failing `isAccessible()` — but only when `this.accessLevel == USER_MODE`.
Filtering in `SYSTEM_MODE` would silently drop fields the caller explicitly asked to bypass FLS for,
which is a behavior regression for existing users. Order matters: call `setAccessLevel()` before
`selectAll()`. Document that in the ApexDoc.

- [ ] Test: `selectAll()` in USER_MODE omits an inaccessible field
- [ ] Test: `selectAll()` after `setAccessLevel(SYSTEM_MODE)` keeps every field
- [ ] Adjust `shouldSelectAllFields` to SYSTEM_MODE (its "all User fields" assertion is FLS-dependent)
- [ ] Implement the guard + ApexDoc note
- [ ] Wiki: `The-Soql.Builder-Class.md` selectAll section

## #181 — bare date literals get quoted

**Root cause is NOT in SoqlParser.** `ValueParser.parse` correctly falls through to the raw String
for `TODAY` / `NEXT_N_QUARTERS:2` ([SoqlParser.cls:895](src/core/classes/SoqlParser.cls#L895)).
The quoting happens downstream in [Soql.cls:1378-1386](src/core/classes/Soql.cls#L1378-L1386):

```apex
for (String excludedModifier : new Set<String>{ 'LAST_N_DAYS', ':', '(' }) {
```

`LAST_N_DAYS` is the *only* date literal in the passthrough list — which is exactly the inconsistency
the issue reports (`LAST_N_DAYS:30` works, `NEXT_N_QUARTERS:2` doesn't).

**Fix:** replace the `LAST_N_DAYS` special case with one regex covering the full SOQL date-literal
grammar. `Condition.processString` is the shared choke point, so this also fixes token-built queries
(`addWhere(CloseDate, EQUALS, 'THIS_MONTH')` is broken today too — the issue is wrong that they're
unaffected).

- [ ] Test: every fixed keyword round-trips unquoted
- [ ] Test: every `LAST_N_*` / `NEXT_N_*` / `N_*_AGO` form round-trips unquoted
- [ ] Test: a genuine string value is still quoted (no over-match)
- [ ] Implement regex + constant
- [ ] Wiki if the docs mention relative date handling

## Validate
- [ ] Deploy + 100% coverage on changed classes
- [ ] `sf code-analyzer run` clean
- [ ] `/refactor`, `/ponytail-review`
