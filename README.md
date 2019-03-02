# VueCli::Rails

Rails is cool. Vue is a cool boy too. Let's make them even cooler!

## Installation

Add this line to your Rails application's `Gemfile`:

```ruby
gem 'vue_cli-rails'
```

And then execute:

    $ bundle install
    $ bundle exec rake vue:create

Follow the steps and copy demo codes.

## Requirements

- Ruby: 2.3.8, 2.4.5, 2.5.3, 2.6.1
- Rails: 4.2.11, 5.2,2, 6.0beta2
- Node: [8.9+](https://cli.vuejs.org/guide/installation.html)

## Features

- Feel free to use `npm` or `yarn`
- Full features of [@vue/cli](https://cli.vuejs.org/)
- Run `webpack-dev-server` together with Rails dev server
- Just use `RAILS_ENV`. Get rid of `NODE_ENV`.

## Usage

- `rake vue:create`

  Install required packages and configurations.

  1. Select package manager: Y=`yarn`, N=`npm`

      - Directly use npm if yarn has not been installed.
      - Prefer yarn by default unless detect `package-lock.json`

  2. Auto install `@vue/cli` globally
  3. Invoke `vue create` to initialize Vue project

      When detected `package.json`
      - Y (Yes): Fully overwrite
      - N (No): Skip
      - A (Auto): You won't loss anything (`old_config.merge(new_config)`)
      - K (Keep): Keep all your settings already have (`new_config.merge(old_config)`)

  4. Install `js-yaml` and `webpack-assets-manifest`
  5. Deleting Vue demo code under `src` folder
  6. Copy demo code to under `app` folder and update `config/routes.rb`
  7. Copy `vue.rails.js` and `vue.config.js`

      - Do not change `vue.rails.js`! This rake task will always restore `vue.rails.js` back.
      - Yes you can update `vue.config.js`. Just make sure you know what are you won't break the configuration. You can chance `config/vue.yml` instead.

  8. Generate `config/vue.yml`

      - The convention is: `camelCase` for regular `vue.config.js`, `snake_case` for special usage.
      - You can find a full list of [Vue CLI config options below](#valid-vue-cli-config-options).
      - And special options [here](#special-options)

- Files structure

    Put ONLY your entry-point files under `app/assets/vue/views` folder. Entry-point is a `.js` file. Webpack sees JavaScript files as the center of entry-point rather than HTML. Thus all style files, images, fonts or other assets are related with JS files. This gem will find all `.js` and pass them as entry-points to webpack.

    You may have interest of path alias in `config/vue.yml`.

- Helper `vue_entry`

    It works like `javascript_include_tag`, or combination of `stylesheet_pack_tag` and `javascript_packs_with_chunks_tag` in Webpacker. I will explain why only one tag rather than 3 tags.

    A typical usage will be like:

    ```html
    <!-- file - app/views/layout/vue.html.erb -->
    <!DOCTYPE html>
      <html>
      <head>
        <title>Vue</title>
        <%= csrf_meta_tags %>
      </head>
      <body>
        <div id="app"></div><%= yield %>
      </body>
    </html>
    ```

    ```haml
    -# file - app/views/views/foo.html.erb
    <%= vue_entry('foo') %>
    ```

    ```js
    // file - app/assets/vue/views/foo.js
    import Vue from 'vue';

    import Foo from '~views/Foo.vue';

    new Vue({
      render: h => h(Foo),
    }).$mount('#app');
    ```

    Suppose `~views: app/assets/vue/components/views` is configured in `config/vue.yml`

    ```js
    // file - app/assets/vue/views/foo.js
    import Vue from 'vue';

    import Foo from '~/Foo.vue';

    new Vue({
      render: h => h(Foo),
    }).$mount('#app');
    ```

    ```vue
    # file - app/assets/vue/components/views/Foo.vue
    <template>
      <div id="foo">
        <h1>Foo</h1>
      </div>
    </template>

    <script>
    export default {
      name: 'Foo',
    };
    </script>

    <style scoped>
    #foo {
      color: green;
    }
    </style>
    ```

- `rake rake vue:compile`

    Compile Vue assets. Please specify `RAILS_ENV=production` to compile assets for production.

    However, you can invoke `vue-cli-service build` (if `vue-cli-service` installed globally, or you can use `npx vue-cli-service build` or `yarn exec vue-cli-service build`) with `RAILS_ENV=production` to build assets.

    > A good practice is to use [`cross-env`](https://www.npmjs.com/package/cross-env) to pass `RAILS_ENV=production`. So `cross-env RAILS_ENV=production vue-cli-service build` will work on any platform and shell.

- `rake vue:json_config`

    Converts `config/vue.yml` to JSON to be used by `vue.rails.js`.

    `vue.rails.js` prefers parsing `config/vue.yml` with `js-yaml`. So this is just in case. You may suffer performance issue when your Rails app grow big.

- `rake vue:support[formats]`

    Adds template or style language support. Vue ships with supporting `pug`, `sass`, `less` and `stylus` out-of-box. How ever, you still have to install some loaders manually if you did not select that language with `vue:create`.

    You can add multiple languages at the same time: `rake vue:support[pug,stylus]`

> You may need to invoke with `bundle exec rake vue:...`. Rails 5 and above also supports `rails vue:...`.

## Special Options

### `manifest_output`

Where to put `manifest.json` which required by Rails.

All entry-points will be compiled into assets files. Rails needs `manifest.json` to know what are the files and will serve all its JS/CSS tags.

### `package_manager`

Pretty straightforward, which package manager will be used. Valid value: `npm` or `yarn`. It does NOT support `pnpm` or other package managers. You can find the reason in [Q&A](#Q&A).

### `public_output_path`

This is

## Valid Vue CLI config Options

You can check the full list on [Vue CLI website](https://cli.vuejs.org/config/).

- Special

  - publicPath - see [`public_output_path`](#public_output_path)
  - outputDir - see [`public_output_path`](#public_output_path)

- Supported

  - [x] filenameHashing
  - [x] lintOnSave
  - [x] runtimeCompiler
  - [x] transpileDependencies
  - [x] productionSourceMap
  - [x] crossorigin
  - [x] css
  - [x] devServer
  - [x] parallel
  - [x] pwa
  - [x] pluginOptions

- Unsupported

  - [ ] baseUrl - Deprecated
  - [ ] assetsDir - ignored
  - [ ] indexPath - N/A
  - [ ] pages - N/A
  - [ ] integrity - N/A
  - [ ] configureWebpack - directly edit `vue.config.js`
  - [ ] chainWebpack - directly edit `vue.config.js`

## Q&A

- Why not webpacker?

    1. WIP

Currently `vue.config.js` is reading configurations from `vue.rails.js` which depends on `js-yaml`. It will fallback to `bundle exec rake vue:json_config` without `js-yaml` installed. You may suffer performance issue if your rake tasks are slow.
