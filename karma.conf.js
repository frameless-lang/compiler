const util = require('util');
const exec = util.promisify(require('child_process').exec);

module.exports = function (config) {
    config.set({
        basePath: ".",
        frameworks: ["jasmine"],
        browsers: ["ChromeHeadless", "FirefoxHeadless"],
        autoWatch: false,
        singleRun: true,
        files: [
            {
                pattern: "vendor/strictly/**/*.js",
                type: "module",
                included: false,
            },
            {
                pattern: "test/components/**/*.sly",
                type: "module"
            },
            "test/**/*.js"
        ],
        exclude: [
            "test/components/host/style.sly",
            "test/components/host/namespace.sly",
            "test/components/helper/model/dependencies.sly",
            "test/components/nesting/**",
            "test/components/structural/list/**/*.sly",
        ],
        preprocessors: {
            "**/*.sly": ["strictly"]
        },
        plugins: [
            {
                "preprocessor:strictly": ["factory", function () {
                    return async (_, file) => {
                        file.path = file.originalPath.replace(/\.sly$/, '.js');

                        const { stdout, stderror } = await exec(`cabal v2-run --verbose=silent strictly-compiler ${file.originalPath}`);
                        if (stderror) {
                            throw stderror;
                        }

                        return stdout;
                    }
                }],
            },
            "karma-jasmine",
            "karma-chrome-launcher",
            "karma-firefox-launcher"
        ]
    });
};