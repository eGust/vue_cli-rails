const { env } = require('process');

module.exports = (() => {
  let settings = {};
  const assets = {};

  try {
    /* eslint-disable global-require,import/no-extraneous-dependencies */
    const yaml = require('js-yaml');
    const { readFileSync, readdirSync, lstatSync } = require('fs');
    const { resolve } = require('path');
    /* eslint-enable global-require,import/no-extraneous-dependencies */

    const railsEnv = env.RAILS_ENV || 'development';
    const config = yaml.safeLoad(readFileSync(resolve('config/vue.yml'), 'utf8'))[railsEnv];
    const root = resolve(__dirname);
    const pop = (config.public_output_path || 'vue_assets').replace(/(^\/+|\/+$)/g, '');
    const {
      manifest_output: manifestOutput,
      js_output: output,
      alias = {},
      devServer,

      filenameHashing,
      lintOnSave,
      runtimeCompiler,
      transpileDependencies,
      productionSourceMap,
      crossorigin,
      css,
      parallel,
      pwa,
      pluginOptions,
    } = config;

    if (devServer && devServer.contentBase) {
      devServer.contentBase = resolve(root, devServer.contentBase);
    }
    const entry = {};
    const assetRoot = resolve(root, 'app/assets/vue/entry_points');
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

    try {
      findAllJsFiles(assetRoot);
    } catch (_e) {
      //
    }

    settings = {
      env: railsEnv,
      root,
      manifestOutput: manifestOutput && resolve(root, manifestOutput),

      outputDir: resolve(root, 'public', pop),
      publicPath: `/${pop}/`,
      configureWebpack: {
        entry,
        output,
        resolve: {
          alias: Object.keys(alias).reduce((obj, key) => ({
            ...obj,
            [key]: resolve(root, alias[key]),
          }), {}),
        },
      },

      jestModuleNameMapper: Object.keys(alias).reduce((obj, key) => ({
        ...obj,
        [`^${key.replace(/[-[{}()+.,^$#/\s\]]/g, '\\$&')}/(.*)$`]: `<rootDir>/${
          alias[key].replace(/^\//, '').replace(/\/$/, '')
        }/$1`,
      }), {}),

      devServer: devServer && {
        ...devServer,
        before(app) {
          app.get('/__manifest/', ({ query }, res) => {
            const entryPoint = Object.keys(query || {})[0];
            res.json(entryPoint === '!!INSPECT!!' ? assets : assets.entrypoints[entryPoint]);
          });
        },
      },
      filenameHashing,
      lintOnSave,
      runtimeCompiler,
      transpileDependencies,
      productionSourceMap,
      crossorigin,
      css,
      parallel,
      pwa,
      pluginOptions,
    };
  } catch (e) {
    /* eslint-disable-next-line global-require,import/no-extraneous-dependencies */
    const { execSync } = require('child_process');

    console.error(e);
    settings = JSON.parse(execSync('bundle exec rake vue:json_config', {
      cwd: __dirname,
      encoding: 'utf8',
    }));
  }

  const getSettingsFromKeys = keys => [].concat(keys).filter(s => s)
    .reduce((cfg, k) => {
      const v = settings[k];
      return v === undefined ? cfg : { ...cfg, [k]: v };
    }, {});
  const { jestModuleNameMapper } = settings;
  const isProd = settings.env === 'production';

  return {
    isProd,
    manifest: {
      /* eslint-disable-next-line global-require,import/no-extraneous-dependencies */
      plugin: require('webpack-assets-manifest'),
      options: {
        assets,
        entrypoints: true,
        writeToDisk: !!settings.manifestOutput,
        publicPath: true,
        output: settings.manifestOutput || '',
      },
    },
    jestModuleNameMapper,
    getSettings: (keys = Object.keys(settings)) => getSettingsFromKeys(keys),
    pickUpSettings: ([lines]) => getSettingsFromKeys(lines.split('\n').map(s => s.trim())),
  };
})();
