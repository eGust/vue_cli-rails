// Please do NOT edit settings required by vue_cli-rails
/* [DO NOT EDIT!] begin */
const { execSync } = require('child_process');
const { env } = require('process');
const WebpackAssetsManifest = require('webpack-assets-manifest');
/* [DO NOT EDIT!] end */

// const CompressionWebpackPlugin = require('compression-webpack-plugin');
// const { BundleAnalyzerPlugin } = require('webpack-bundle-analyzer');

const settings = JSON.parse(execSync('bundle exec rake vue:json_config', {
  cwd: __dirname,
  encoding: 'utf8',
}));
env.NODE_ENV = settings.env;
const isProd = env.NODE_ENV === 'production';

const {
  entry,
  css,
  alias,
  outputDir,
  devServer,
  publicPath,
  manifestOutput,
} = settings;

module.exports = {
  outputDir,
  publicPath,
  devServer,
  chainWebpack: (config) => {
    config
      // clear entry points if there is any
      .entryPoints
      .clear()
      .end()
      /* [DO NOT EDIT!] begin */
      .plugin('manifest')
      .use(WebpackAssetsManifest)
      .init(Plugin => new Plugin({
        integrity: false,
        entrypoints: true,
        writeToDisk: true,
        publicPath: true,
        output: manifestOutput,
      }))
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
  css,
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
