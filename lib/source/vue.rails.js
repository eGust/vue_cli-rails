const { env } = require('process');

module.exports = (() => {
  let settings = {};

  /* eslint-disable global-require,import/no-extraneous-dependencies */
  const WebpackAssetsManifest = require('webpack-assets-manifest');
  try {
    const yaml = require('js-yaml');
    const { readFileSync, readdirSync, lstatSync } = require('fs');
    const { resolve } = require('path');

    const railsEnv = env.RAILS_ENV || 'development';
    const config = yaml.safeLoad(readFileSync(resolve('config/vue.yml'), 'utf8'))[railsEnv];
    const root = resolve(__dirname);
    const po = (config.public_output_path || 'vue_assets').replace(/(^\/+|\/+$)/g, '');
    const { manifestOutput, alias = {}, devServer = {} } = config;
    if (devServer.contentBase) {
      devServer.contentBase = resolve(root, devServer.contentBase);
    }
    const entry = {};
    const assetRoot = resolve(root, 'app/assets/vue/views');
    const findAllJsFiles = (path) => {
      readdirSync(path).forEach((fn) => {
        const filename = resolve(path, fn);
        const stat = lstatSync(filename);
        if (stat.isDirectory()) {
          findAllJsFiles(filename);
        } else if (stat.isFile() && fn.endsWith('.js')) {
          entry[filename.slice(assetRoot.length + 1, -3)] = filename;
        }
      });
    };
    findAllJsFiles(assetRoot);

    settings = {
      ...config,
      env: railsEnv,
      root,
      outputDir: resolve(root, 'public', po),
      publicPath: `/${po}/`,
      alias: Object.keys(alias).reduce((obj, key) => ({
        ...obj,
        [key]: resolve(root, alias[key]),
      }), {}),
      manifestOutput: resolve(root, manifestOutput),
      devServer,
      entry,
    };
  } catch (e) {
    const { execSync } = require('child_process');

    settings = JSON.parse(execSync('bundle exec rake vue:json_config', {
      cwd: __dirname,
      encoding: 'utf8',
    }));
  }
  /* eslint-enable global-require,import/no-extraneous-dependencies */

  const assets = {};
  const manifest = {
    plugin: WebpackAssetsManifest,
    assets,
    options: {
      assets,
      entrypoints: true,
      writeToDisk: true,
      publicPath: true,
      output: settings.manifestOutput,
    },
  };

  return {
    ...settings,
    manifest,
    isProd: settings.env === 'production',
  };
})();
