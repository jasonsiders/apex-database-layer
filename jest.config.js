const { jestConfig } = require("@salesforce/sfdx-lwc-jest/config");

module.exports = {
	...jestConfig,
	modulePathIgnorePatterns: ["<rootDir>/.localdevserver"],
	moduleNameMapper: {
		// Stub out flowDmlSection so slot content is always rendered in tests.
		// flowDmlSection.test.js imports the real component via relative path to bypass this.
		"^c/flowDmlSection$":
			"<rootDir>/src/plugins/flow-actions/lwc/flowDmlSection/__stubs__/flowDmlSection.js",
		...jestConfig.moduleNameMapper
	},
	collectCoverageFrom: [
		"src/plugins/flow-actions/lwc/**/*.js",
		"!**/__tests__/**",
		"!**/__stubs__/**"
	]
};
