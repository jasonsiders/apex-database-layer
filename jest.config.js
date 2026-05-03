const { jestConfig } = require("@salesforce/sfdx-lwc-jest/config");

module.exports = {
	...jestConfig,
	modulePathIgnorePatterns: ["<rootDir>/.localdevserver"],
	moduleNameMapper: {
		"^lightning/toast$": "<rootDir>/src/plugins/flow-actions/lwc/.jest/__mocks__/lightning/toast",
		// Stub out flowDmlSection so slot content is always rendered in tests.
		// flowDmlSection.test.js imports the real component via relative path to bypass this.
		"^c/flowDmlSection$": "<rootDir>/src/plugins/flow-actions/lwc/flowDmlSection/__stubs__/flowDmlSection.js",
		...jestConfig.moduleNameMapper
	},
	collectCoverageFrom: [
		"src/plugins/flow-actions/lwc/**/*",
		"!src/plugins/flow-actions/lwc/**/*.html",
		"!src/plugins/flow-actions/lwc/**/*.css",
		"!**/__tests__/**",
		"!**/__stubs__/**"
	],
	coverageReporters: ["text", "text-summary", "html"],
	coveragePathIgnorePatterns: [
		"<rootDir>/node_modules/",
		"<rootDir>/.localdevserver/"
	]
};
