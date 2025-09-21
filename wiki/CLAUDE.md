# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Context

This is a GitHub wiki repository for the **apex-database-layer** project, an open-source Salesforce Apex library that provides database operation mocking and query building capabilities.

## Common Operations

Since this is a wiki repository, the primary tasks involve:

- **Editing documentation**: Modify existing `.md` files to update content, fix formatting, or add new information
- **Adding new documentation**: Create new `.md` files for new features or concepts
- **Updating cross-references**: Ensure links between wiki pages remain accurate when content is moved or renamed

### Specific Documentation Standards

- Ensure all _global_ classes, and their _global_ properties and methods are documented. Private classes/properties/methods do not need to be documented.
- Link to other files in the repository where possible, and exclude the `.md` file extension in the link. [For Example.](./The-Dml-Class)
- Use backticks or `<code>` tags where appropriate.
- Use examples from the repository's test classes where appropriate, to demonstrate functionality.

## Architecture Overview

### Core Components Documentation Structure

The wiki is organized around these main architectural components:

1. **DatabaseLayer Class**: Central access point providing `DatabaseLayer.Dml` and `DatabaseLayer.Soql` properties
2. **DML Operations**:
   - `Dml` class for real database operations
   - `MockDml` class for testing without database interaction
   - `Dml.Request`, `Dml.Operation` enum, and other supporting classes
3. **SOQL Operations**:
   - `Soql` class with fluent query builder pattern
   - `MockSoql` class for query mocking in tests
   - Extensive supporting classes: `Soql.Builder`, `Soql.Condition`, `Soql.AggregateResult`, etc.
4. **Mock Testing Framework**:
   - `MockRecord` for generating test data
   - `MockDml.Database` for simulating database state
   - `MockSoql.ConditionalLogic` interface for dynamic query behavior
5. **Plugin Framework**: Extension system using `DatabaseLayerSetting__mdt` custom metadata

### Key Patterns

- **Mocking Strategy**: Use `DatabaseLayer.useMocks()` to switch from real to mock database operations
- **Fluent API**: Query building uses method chaining pattern
- **Test Isolation**: All database operations can be mocked to avoid actual Salesforce database interaction
- **Plugin Architecture**: Custom metadata type enables extensibility without code modification

## Important Documentation Conventions

- Class documentation files follow pattern: `The-[ClassName]-Class.md`
- Enum documentation follows pattern: `The-[ClassName].[EnumName]-Enum.md`
- Interface documentation follows pattern: `The-[ClassName].[InterfaceName]-Interface.md`
- Plugin documentation follows pattern: `Plugin:-[PluginName].md`
- Cross-references use relative links: `./The-DatabaseLayer-Class.md`
- Code examples are consistently formatted with Apex syntax highlighting

## Key Wiki Pages

- `Home.md`: Main entry point with installation and basic usage
- `_Sidebar.md`: Navigation structure for the entire wiki
- `The-DatabaseLayer-Class.md`: Core API documentation
- `Mocking-DML-Operations.md` & `Mocking-SOQL-Queries.md`: Testing strategy guides
- `The-Plugin-Framework.md`: Extension mechanism documentation

## Migration and Versioning

- Migration guides are provided for major version changes (e.g., `Migration-Guide-v3.0.0.md`)
- The library supports both managed package (with `apxsp` namespace) and unlocked package installations
