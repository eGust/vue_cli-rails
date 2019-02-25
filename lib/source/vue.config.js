// const CompressionWebpackPlugin = require('compression-webpack-plugin');
// const { BundleAnalyzerPlugin } = require('webpack-bundle-analyzer');

const {
  entry,
  css,
  alias,
  outputDir,
  devServer,
  publicPath,
  manifest,
  isProd,
} = require('./vue.rails');

module.exports = {
  outputDir,
  publicPath,
  devServer,
  css,
  chainWebpack: (config) => {
    config
      // clear entry points if there is any
      .entryPoints
      .clear()
      .end()
      /* [DO NOT EDIT!] begin */
      .plugin('manifest')
      .use(manifest.plugin)
      .init(Plugin => new Plugin(manifest.options))
      .end()
      /* [DO NOT EDIT!] end */
      .plugins
      // disable copy plugin
      .delete('copy')
      // disable generating html
      .delete('html')
      .delete('preload')
      .delete('prefetch')
      .end();
    if (isProd) {
      // put your custom code here
      // Example: yarn -D compression-webpack-plugin webpack-bundle-analyzer
      /*
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
          openAnalyzer: true,
          reportFilename: resolve(__dirname, 'tmp/bundle-analyzer-report.html'),
          analyzerMode: 'static',
        }));
      */
    }
  },
  configureWebpack: {
    entry,
    resolve: {
      alias,
    },
    output: {
      filename: '[name].[hash:8].js',
      chunkFilename: 'js/[name].[hash:8].js',
    },
  },
};
