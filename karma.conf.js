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
            "test/components/host/attributes.sly",
            "test/components/host/base.sly",
            "test/components/host/siblings.sly",
            "test/components/host/withtext.sly",
            "test/components/host/nested.sly",
            "test/components/host/events.sly",
            "test/components/text/*.sly",
            "test/components/helper/each/*.sly",
            "test/components/helper/if/*.sly",
            "test/components/helper/model/counter.sly",
            "test/**/*.js"
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