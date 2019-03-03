// const { resolve } = require('path');
// const CompressionWebpackPlugin = require('compression-webpack-plugin');
// const { BundleAnalyzerPlugin } = require('webpack-bundle-analyzer');

const railsConfig = require('./vue.rails');

const {
  manifest,
  pickUpSettings,
  // isProd,
  // getSettings, // (keys: string[]) => Object. Returns all available settings by default
} = railsConfig;

module.exports = {
  ...pickUpSettings`
    outputDir
    publicPath
    devServer
    configureWebpack

    filenameHashing
    lintOnSave
    runtimeCompiler
    transpileDependencies
    productionSourceMap
    crossorigin
    css
    parallel
    pwa
    pluginOptions
  `,
  chainWebpack: (config) => {
    /* [DO NOT EDIT!] begin */
    config
      // clear entry points if there is any
      .entryPoints
      .clear()
      .end()
      .plugins
      // disable copy plugin
      .delete('copy')
      // disable generating html
      .delete('html')
      .delete('preload')
      .delete('prefetch')
      .end();
    if (manifest) {
      config
        .plugin('manifest')
        .use(manifest.plugin)
        .init(Plugin => new Plugin(manifest.options))
        .end();
    }
    /* [DO NOT EDIT!] end */

    /* put your custom code here
    // Example: npm/yarn add -D compression-webpack-plugin webpack-bundle-analyzer
    if (isProd) {
      config
        .plugin('compression')
        .use(CompressionWebpackPlugin)
        .init(Plugin => new Plugin({
          filename: '[path].gz[query]',
          algorithm: 'gzip',
          test: new RegExp('\\.(js|css)$'),
          // minimum 5K
          threshold: 1024 * 5,
        // minRatio: 0.6,
        }))
        .end()
        .plugin('analyzer')
        .use(BundleAnalyzerPlugin)
        .init(Plugin => new Plugin({
          reportFilename: resolve(__dirname, 'tmp/bundle-analyzer-report.html'),
          analyzerMode: 'static',
        }));
    }
    // */
  },
};
