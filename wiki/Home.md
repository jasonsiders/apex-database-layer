# `apex-database-layer`

Welcome to `apex-database-layer`, an open-source library used to easily mock Salesforce database operations in Apex.

## Features

Apex Database Layer was designed to be feature-rich, yet easy to use, closely mirroring standard platform patterns.

You get the following out of the box:

- Support for all standard `Database` class DML & SOQL operations
- Easily mock [DML operations](./Mocking-DML-Operations) and [SOQL queries](./Mocking-SOQL-Queries).
- A [Query framework](./The-Soql-Class) that enables strongly-typed, yet dynamic SOQL queries.
- Easily [generate test records](./Generating-Test-Records) without using DML or SOQL.
- [Switch between real & mock database operations](./The-DatabaseLayer-Class#useMocks) in Apex Tests, with a single line of code
- An optional [Plugin Framework](./The-Plugin-Framework) allows you to fine-tune the platform to your exact use case.
- Simplicity: The framework uses just a couple of Apex classes (and a custom metadata type, to support Plugins).

Best of all, the framework is built 100% on the Salesforce platform, using standard Salesforce technology. It's open source, and free, and it always will be.

## Installation

`apex-database-layer` is available for free. It can be downloaded in one of two flavors:

- As an _unlocked_ package with no namespace
- As a _managed_ package, using the `apxsp` namespace

You can find the latest or past versions in the [Releases](https://github.com/jasonsiders/apex-database-layer/releases) tab.

Use the following command to install the package in your environment:

```sh
sf package install --package {{package_version_id}} --wait 10
```

## Usage

Once intalled, use [`DatabaseLayer.Dml`](./Performing-DML-Operations) for all of your DML operations:

```apex
// Don't use these standard apex DML methods:
insert account;
Database.insert(account);
// Use this instead:
DatabaseLayer.Dml.doInsert(account);
```

Use [`DatabaseLayer.Soql`](./Performing-SOQL-Queries) for all of your SOQL queries:

```apex
List<Account> accounts = (List<Account>) DatabaseLayer.Soql.newQuery(Account.SObjectType)
  ?.addSelect(Account.Name)
  ?.addWhere(Account.OwnerId, Soql.EQUALS, UserInfo.getUserId())
  ?.addOrderBy(Account.LastModifiedDate, Soql.SortDirection.DESCENDING)
  ?.setRowLimit(200)
  ?.toSoql()
  ?.query();
```

Once this is done, you can instantly decouple your `Dml` and `Soql` operations from the Salesforce database in apex tests, with just a [single line of code](./The-DatabaseLayer-Class#useMocks):

```apex
DatabaseLayer.useMocks();
```

In apex tests, you can easily [generate test records](./Generating-Test-Records) for use in mocks, that would otherwise require extensive database operations:

```apex
// This operation takes ~2ms; would require 4 separate DML operations otherwise:
OpportunityContactRole contactRole = (OpportunityContactRole) new MockRecord(OpportunityContactRole.SObjectType)
  ?.withId()
  ?.toSObject();
```

## Want To Learn More?

Check out the sidebar for articles about:

- Mocking database operations, and why it's important
- Techniques for mocking using the framework
- Documentation for all public classes & methods
