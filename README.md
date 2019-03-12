# VueCli::Rails

Let's make cool boy Vue even cooler on Rails!

## Installation

Add this line to your Rails application's `Gemfile`:

```ruby
gem 'vue_cli-rails'
```

And then execute:

    $ bundle install

## Requirements

- Ruby >= 2.3
- Rails >= 4.2
- Node >= [8.9+](https://cli.vuejs.org/guide/installation.html)
- Optional: `yarn`

> The auto-testing for CI still WIP. Sorry I can't guarantee it works for now.

## Features

- Feel free to use `yarn` or `npm`.
- Single `vue_entry` rather than confusing `stylesheet_pack_tag`, `javascript_packs_tag` and `javascript_packs_with_chunks_tag`.
- Get all benefits of [@vue/cli](https://cli.vuejs.org/).

    - Powered by `webpack` 4
    - DRY: all-in-one configuration file rather than repeating for `webpack`, `eslint` and etc.
    - Out-of-box tooling: Babel, TypeScript, PWA, `vue-router`, `vuex`, CSS pre-processors, linter and testing tools.
    - Enhanced alias support in `jest.config.js`.

- Run `webpack-dev-server` together with Rails server with development mode.
- Just single `RAILS_ENV`, no more `NODE_ENV`.
- Rails way configurations in `config/vue.yml`.

## Getting started

Out-of-box workflow:

1. `bundle exec rake vue:create` and follow the steps.

    > Don NOT select `In package.json` for "Where do you prefer placing config for Babel, PostCSS, ESLint, etc.?". Some functionalities like alias of jest may not work.

2. Put your JavaScript files under `app/assets/vue/entry_points`.
3. Insert your entry point by `vue_entry 'entry_point'` in views or `render_vue 'entry_point'` in controllers.
4. `webpack-dev-server` auto starts alongside `rails server` in dev mode.
5. Invoke `env RAILS_ENV=production bundle exec rake vue:compile` to compile assets (you still must manually set `RAILS_ENV` to `production`).

> More settings are available in `config/vue.yml`

## Usage

### Core

#### Concept: Entry Point and File structure

The root path of your Vue assets is `app/assets/vue`. This gem will generate several folders. However, `app/assets/vue/entry_points` is the only one matters.

Webpack sees one JavaScript file as the center of a web page rather than HTML. Thus all styles, images, fonts and other assets are related to a JS files by `import 'css/png/svg/woff2/json'`. Any `.js` file under `app/assets/vue/entry_points` will be a entry-point.

Please ONLY puts your entry-point files under `app/assets/vue/entry_points` folder with `.js` extension name.

> Be aware, `.js.erb` and `.vue.erb` are NOT supported. I will explain the reason in [Q&A section](#difference-from-webpacker).

If you are new to modern front-end development, or more specifically with `webpack` in this case, please read [Q&A section](#qa) for more information.

#### Helper `vue_entry`

`vue_entry` is like `javascript_include_tag` and `stylesheet_link_tag` which generates relative assets links for your entry point. (It's like `javascript_packs_with_chunks_tag` in Webpacker 4. I will explain why it's different in [Q&A](#qa).)

> You may have interest of path alias in `config/vue.yml`.

<details><summary>For example</summary>

- File structure:

 ```text
 [+] app
     [+] assets
         [+] vue
             [+] entry_points - Folder for entry points
                 [+] foo
                     [-] bar.js - entry point: import '~views/FooBar.vue'
             [+] views - alias `~views`
                 [-] FooBar.vue - Vue component for `foo/bar`
     [+] controllers
         [+] foo_controller.rb - controller
     [+] views
         [+] layout
             [-] vue.html.erb - Vue layout
         [+] foo
             [-] bar.html.erb - View render: `vue_entry('foo/bar')`
 ```

- `alias` in `config/vue.yml`:

 ```yaml
 # default
   alias:
     ~views: app/assets/vue/views
 ```

- Your controller:

 ```ruby
 # app/controllers/foo_controller.rb

 class FooController < ApplicationController
   layout 'vue'
 end
 ```

- Your view:

 ```html
 <!-- file - app/views/foo/bar.html.erb -->
 <%= vue_entry('foo/bar') %>
 ```

- Entry point JS:

 ```js
 // file - app/assets/vue/entry_points/foo/bar.js
 import Vue from 'vue';

 import Foo from '~views/FooBar.vue';

 new Vue({
   render: h => h(Foo),
 }).$mount('#app');
 ```

- Your Vue component for your entry point:

 ```vue
 // file - app/assets/vue/views/FooBar.vue
 <template>
   <div id="foo-bar">
     <h1>Foo/bar</h1>
   </div>
 </template>

 <script>
 export default {
   name: 'FooBar',
 };
 </script>

 <style scoped>
 #foo-bar {
   color: green;
 }
 </style>
 ```

- Layout:

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

</details>

#### Use `render_vue` in controllers

Usually you only need `<div id="app"></div>` and `vue_entry 'entry/point'` to render a Vue page. You can use `render_vue 'entry/point'` inside your controller.

This method is simply a wrap of `render html: vue_entry('entry_point'), layout: true`. So you can pass any arguments supported by `render` including `layout`.

<details><summary>For example</summary>

```ruby
# app/controllers/my_vue_controller
class MyVueController < ApplicationController
  layout 'vue_base'

  def foo
    render_vue 'foo/bar'
  end
end
```

```html
<!-- app/views/layouts/vue_base.erb -->
<!DOCTYPE html>
<html>
<head>
  <title>My Vue</title>
</head>
<body>
  <div id="app"></div>
  <%= yield %>
</body>
</html>
```

```js
// app/assets/vue/entry_points/foo/bar.js

import Vue from 'vue';

import Bar from '../views/Bar.vue';

Vue.config.productionTip = false;

new Vue({
  render: h => h(Bar),
}).$mount('#app');
```

</details>

#### Public Output Path

If the default setting `vue_assets` does not bother you at all, you can ignore this section.

Actually `public_output_path` in `config/vue.yml` is very simple - just a sub path under `public` directory. You might suffer some problems by changing it without understanding how it works:

- My regular assets no longer work in dev mode server.
- I lost all my files in `public` folder. (Using a VCS would get your ass saved.)
- Where are my compiled assets for prod under `public/assets` directory?

<details><summary>TL, DR - DO NOT name it as any path used by anything else</summary>

- It's being used in:

  - Rails dev server will forward all request under `/#{public_output_path}` to `webpack-dev-server`;
  - Webpack will put all compiled assets under `public/#{public_output_path}`. Unfortunately, it always remove the entire folder before compiling.

- Alternative ways

  - For dev proxy problem: to set different values for `development` and `production` mode in `config/vue.yml`.
  - For deleting folder when set it to `assets` for prod: run `rake vue:compile[with_rails_assets]` to invoke `rake compile:assets` as well.

</details>

#### Summary

If you still feel confusing, please create a new project and select copy demo code.

I will explain what happens in [Explanation by Demo](#explanation-by-demo).

### Available Settings

#### General settings file is `config/vue.yml`

- `manifest_output`

  Where to put `manifest.json` which required by Rails production mode. You can set it in development mode for inspection.

  All entry-points will be compiled into assets files. Rails needs `manifest.json` to know what are the files and will serve all its JS/CSS tags.

- `package_manager`

  Pretty straightforward, which package manager will be used. Valid value: `npm` or `yarn`. It does NOT support `pnpm` or other package managers. You can find the reason in [Q&A](#qa).

- `public_output_path`

  Because it is very important I put it in core [section](#public-output-path).

- `launch_dev_service` (NOT available for `production` mode)

  `rails server` will launch it when starting by default `vue-cli-service serve`. It will be invoked by `npx vue-cli-service serve` or `yarn exec vue-cli-service serve` depends on your `package_manager`.

- `camelCase` settings will be used in `vue.config.js`

  Please see [available options](#valid-vue-cli-config-options).

- `alias`

    It's basically `resolve/alias` for Webpack. However, you don't have to config this settings in `.eslintrc.js` and `jest.config.js` again and again. `@vue/cli` will pass the settings to eslint via its plugin. The configuration for jest will be generated and passed to `jest.config.js` through `vue.rails.js`.

#### Customize your webpack configurations in `vue.config.js`

Feel free to update `vue.config.js` by yourself. There are some lines of boiler-plate code to adapt `compression-webpack-plugin` and `webpack-bundle-analyzer`.

### Rake Tasks

- `vue:create`

  Install required packages and configurations. You should run this task to get `@vue/cli` initializing your project.

  <details><summary>What it does for you</summary>

  1. Select package manager: Y=`yarn`, N=`npm`

      - Directly use npm if yarn has not been installed.
      - Prefer yarn by default unless detect `package-lock.json`

  2. Auto install `@vue/cli` globally with your package manager.
  3. Invoke `vue create` to initialize Vue project.

      When detected existing `package.json`
      - `Y` - Yes: Fully overwrite
      - `N` - No: Skip
      - `A` - Auto: You won't loss anything (`old_config.merge(new_config)`)
      - `K` - Keep: Keep all your settings already have (`new_config.merge(old_config)`)

  4. Install `js-yaml` and `webpack-assets-manifest`
  5. Deleting Vue demo code under `src` folder
  6. Copy demo code to under `app` folder and update `config/routes.rb`
  7. Copy `vue.rails.js` and `vue.config.js`

      - Do not change `vue.rails.js`! This rake task will always restore `vue.rails.js` back.
      - Yes you can update `vue.config.js`. Just make sure you know what are you won't break the configuration. You can chance `config/vue.yml` instead.

  8. Generate `config/vue.yml`

      - The convention is: `camelCase` for regular `vue.config.js`, `snake_case` for special usage.
      - You can find a full list of [Vue CLI config options below](#valid-vue-cli-config-options).
      - All available options [here](#available-options)

  > BE AWARE: the default option for `config/vue.yml` is `Y` (to replace existing file), otherwise your package manager change won't be saved. All your files won't be overwritten silently except `vue.rails.js`.

  </details>

- `vue:compile`

  Compile Vue assets. Please specify `RAILS_ENV=production` to compile assets for production.

  Optional argument: `[with_rails_assets]` to invoke `rake compile:assets` after it finished.

  However, you can invoke `vue-cli-service build` (if `vue-cli-service` installed globally, or you can use `npx vue-cli-service build` or `yarn exec vue-cli-service build`) with `RAILS_ENV=production` to build assets.

  > A good practice is to use [`cross-env`](https://www.npmjs.com/package/cross-env) to pass `RAILS_ENV=production`. So `cross-env RAILS_ENV=production vue-cli-service build` will work on any platform and shell.

- `vue:json_config`

  Converts `config/vue.yml` to JSON to be used by `vue.rails.js`.

  `vue.rails.js` prefers parsing `config/vue.yml` with `js-yaml`. So this is just in case. You may suffer performance issue when your Rails app grow big.

- `vue:support[formats]`

  Adds template or style language support. Vue ships with supporting `pug`, `sass`, `less` and `stylus` out-of-box. How ever, you still have to install some loaders manually if you did not select that language with `vue:create`.

  You can add multiple languages at the same time: `rake vue:support[pug,stylus]`

- `vue:node_env`

  Adds `cross-env` and `npm-run-all` to your `devDependencies` in `package.json`, and adds `dev`, `prod`, `serve` and `rails-s` to `scripts` as well.

  It enables you to start rails dev server alongside `webpack-dev-server` without pain, and compile production assets.

  ```bash
  # to start `rails s` and `webpack-dev-server` together
  npm run dev
  # or
  yarn dev

  # same as `/usr/bin/env RAILS_ENV=production bundle exec vue:compile`
  npm run prod
  # or
  yarn prod
  ```

  You can update `scripts/rails-s` and/or `scripts/prod` if you need to more stuff:

  ```json
  {
    "scripts": {
      "rails-s": "cross-env NO_WEBPACK_DEV_SERVER=1 rails s -b 0.0.0.0",
      "prod": "cross-env RAILS_ENV=production bundle exec rake vue:compile[with_rails_assets]"
    }
  }
  ```

> You may need to invoke `rake` with `bundle exec`. Rails 5 and above supports new `rails rake:task` flavor.

## Valid Vue CLI config Options

You can check the full list on [Vue CLI official website](https://cli.vuejs.org/config/).

- Special

  - publicPath - see [`public_output_path`](#public-output-path)
  - outputDir - see [`public_output_path`](#public-output-path)
  - configureWebpack - `vue.rails.js` will generate it. `entry`, `output` and `resolve/alias` are heavily required by this gem. So you must manually update it in `vue.config.js` very carefully.
    <details><summary>Demo</summary>

    Changes to `vue.config.js`

    ```diff
    const {
      manifest,
      pickUpSettings,
      // isProd,
    -  // getSettings,
    +  getSettings,
    } = railsConfig;

    + const { configureWebpack: { entry, output, resolve } } = getSettings('configureWebpack');

    module.exports = {
      ...pickUpSettings`
        outputDir
        publicPath
        devServer
    -    configureWebpack

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
    +  configureWebpack: {
    +    entry,
    +    output,
    +    resolve,
    +  },
      chainWebpack: (config) => {
    ```

    </details>

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
  - [ ] chainWebpack - directly edit `vue.config.js`

## Trouble-shooting

- My dev server can't find assets

    Sometimes your `webpack-dev-server` might still be running while Rails dev server had terminated. For example, you had executed `exit!` in `pry`.

    Usually `webpack-dev-server` should be killed when next time you start `rails server`. However, for some reason it could fail and the new `webpack-dev-server` will listen to another port. Then you must manually kill them:

    ```bash
    lsof -i:3080 -sTCP:LISTEN -Pn
    kill -9 <pid>
    ```

    Alternatively, you can run `rake vue:node_dev` and always start your dev server with:

    ```bash
    npm run dev
    # or
    yarn dev
    ```

    > I know it is not Rails-way at all. I don't want to waste time to just get it worked properly in Rails way - you are already using Node, why it bothers you?

<details><summary>Q & A</summary>

## Q&A

### Difference from Webpacker

1. Webpacker is designed more generic. `vue_cli-rails` is opinionated to just get `@vue/cli` worked.
2. Due to the ease of use of `@vue/cli` this gem is much easier to configure.
3. This gem does not support `.erb` files at all

    It does not make any sense to me. What's the benefit? What if someone wants to pass dynamic data in production, which the way `erb` supposed to work for? Should it launch webpack and spend maybe 10s to compiled it on-the-fly?

    If you want some dynamic data, you should fetch it via some API. That's my opinion and why I don't even think it should have this feature.

4. This gem only provides 1 helper `vue_entry` rather than `stylesheet_pack_tag`, `javascript_pack_tag`, `javascript_packs_with_chunks_tag`, `image_pack_tag` and etc. in Webpacker

    - First of all, JS files are the center of modern front-end world.
    - Modern front-end bundlers like webpack offer lots of fancy features with tools like Babel, TypeScript, eslint and etc. They can take care of all your assets, and always give you correct set of assets.
    - Webpack 4 is even smarter to split common code into chunks.
    - Vue also provides some awesome features like scoped styles, async components.

    All those functionalities are just working out-of-box. You should not even touch them. There is no point of managing assets by yourself. You will eventually shot on your foot:

    - Why my component does not look right? Because you forgot to change your `stylesheet_pack_tag` after renaming the file.
    - Why my styles from another component aren't working? Because your component uses scoped styles, which designed to only work for that component.
    - Why my component does not work anymore? Because there is a new asset and you never write a `_tag` for it.

    Trust me, you are not smarter than webpack. This design will save your time.

5. This gem supports both `npm` and `yarn`. Webpacker requires `yarn` to be installed.

    `npm` and `yarn` are not much different nowadays. I myself prefer `yarn`. But you should be able to use `npm` which ships with node itself to reduce the complexity of deployment.

    Unfortunately it does not support [`pnpm`](#does-it-support-pnpm)

6. Webpacker ships with plenty of node dependencies in `dependencies` section rather than `devDependencies`.

    I'd say this is another thing does not make sense to me. Even there is no real difference for front-end projects, I'd expect a project follows common pattern: the packages will be used in your front-end code should be in `dependencies`.

7. `productionSourceMap` is off by default for production

    You may or may not know [Rails turn this flag on by default](https://github.com/rails/webpacker/issues/769#issuecomment-458216151).

    I just don't buy it. It could be a security issue, especially for a startup or small company where Rails is widely being adapted. It's not fair enough to your customers.

    You can manually turn it on in `config/vue.yml`. It would be totally on your own risk because you intended to do that.

8. It does not put `manifest.json` under `public` folder.

    Again, I have no idea why doing that.

9. `webpack-dev-server` automatically starts with `rails server` in dev mode.

    I don't understand why not to start the killing feature of webpack. Stop wasting your life on stupidly refreshing and waiting the whole page being reloaded while debugging front-end code.

    If your computer is too slow, ask your boss to buy a good one. You deserve it.

10. Less configurations and easier to understand.

    Only a few platform-specific settings available. All others are very standard.

### Can I get rid of `js-yaml` and `webpack-assets-manifest`

Only `webpack-assets-manifest` is a required dependency. It will be used to generate `manifest.json` which required for both dev and prod.

`vue.rails.js` uses `js-yaml` for parsing `config/vue.yml`. It will fallback to `rake vue:json_config` if `js-yaml` not been installed. However, when your Rails app grow bigger, you will very likely find rake tasks start slower and slower.

### Does it support pnpm

No.

The reason is `@vue/cli` does not support `pnpm` very well, or `npm` does not support `@vue/cli`. Who knows.

You still have a chance to get it worked by giving `pnpm --shamefully-flatten` flag, which makes [no difference from `npm` or `yarn`](https://pnpm.js.org/docs/en/faq.html#solution-3).

If someday they support each other, I'd like to support `pnpm` as well.

### Your demo code seems awful

Yes I admit it. Personally I'd like to directly write SPA with webpack tooling for front-end. Back-end will be a separated project, and it will be a Rails-API or Sinatra project if I want to use ActiveRecord.

`webpack-dev-server` can simply be configured with a proxy and I can use something like `npm-run-all` to start 2 services at the same time. I had to write some not-so-good code to get those things done in Rails.

The demo is more Rails way - separated layouts and views. SPA world uses client routers like `vue-router`.

### It does not work on Windows

Sorry, I don't think many gems work on Windows. Please install a virtual machine and run Linux on it. This gem is very likely working with `WSL`, however you may suffer performance issues due to [slow file system](https://github.com/Microsoft/WSL/issues/873#issuecomment-425272829)

Currently `vue.config.js` is reading configurations from `vue.rails.js` which depends on `js-yaml`. It will fallback to `bundle exec rake vue:json_config` without `js-yaml` installed. You may suffer performance issue if your rake tasks are slow.

</details>

## Explanation by Demo

<!-- <details><summary>Explanation by Demo</summary> -->

### Install

Run `bundle exec rake vue:create` or `rails vue:create` in Rails 5+, and follow the steps:

```
$ bundle exec rake vue:create
Which package manager to use? (Y=yarn, N=npm) [Yn]
...
? Generate project in current directory? Yes
...
? Check the features needed for your project: Babel, Linter, Unit
? Pick a linter / formatter config: Airbnb
? Pick additional lint features: (Press <space> to select, <a> to toggle all, <i> to invert selection)Lint on save
? Pick a unit testing solution: Jest
? Where do you prefer placing config for Babel, PostCSS, ESLint, etc.? In dedicated config files
...
Do you want to copy demo code? (Y=Yes, N=No) [yN]y
...
```

### First Taste

Now with `rails s`, open `http://localhost:3000/vue_demo/foo` in a browser you should be able to see a red big red "Foo" with blue "Hello Vue!".

Do not stop your rails server, open `app/assets/vue/views/Foo.vue` in your editor:

```diff
<template>
  <div id="app">
    <h1>Foo</h1>
-    <HelloWorld msg="Vue!"></HelloWorld>
+    <HelloWorld msg="Rails!"></HelloWorld>
  </div>
</template>
```

Change `msg="Vue!"` to `msg="Rails!"` and save. You will the text in your browser changed to "Hello Rails!". You can change styles or edit `app/assets/vue/components/HelloWorld.vue` and immediately see the result as well.

This functionality is called [HMR (Hot Module Replacement)](https://webpack.js.org/concepts/hot-module-replacement/) which is the killing feature provided by webpack-dev-server. You will soon fail in love with this feature and never want to go back to manually refresh your browser again and again.

### What in the box

```
.
├── app
│   ├── assets
│   │   └── vue
│   │       ├── components
│   │       │   ├── HelloWorld.vue
│   │       │   └── layouts
│   │       │       ├── App.vue
│   │       │       └── index.js
│   │       ├── entry_points
│   │       │   ├── bar.js
│   │       │   └── foo.js
│   │       └── views
│   │           ├── Bar.vue
│   │           └── Foo.vue
│   ├── controllers
│   │   └── vue_demo_controller.rb
│   └── views
│       ├── layouts
│       │   └── vue_demo.html.erb
│       └── vue_demo
│           └── foo.html.erb
├── config
│   ├── routes.rb
│   └── vue.yml
├── tests
│   └── unit
│       └── example.spec.js
├── .browserslistrc
├── .editorconfig
├── .eslintrc.js
├── .gitignore
├── babel.config.js
├── jest.config.js
├── package.json
├── postcss.config.js
├── vue.config.js
├── vue.rails.js
└── yarn.lock
```

You can run ESLint by

    $ yarn lint

Run Jest

    $ yarn test:unit

### Compile Assets

First let's compile the assets

```
$ env RAILS_ENV=production bundle exec rake vue:compile
run: yarn exec vue-cli-service build
...
  File                                      Size             Gzipped

  public/vue_assets/js/chunk-vendors.b54    82.49 KiB        29.80 KiB
  85759.js
  public/vue_assets/js/foo.dcbad15e.js      2.74 KiB         1.23 KiB
  public/vue_assets/js/bar.d4fc59af.js      2.03 KiB         1.00 KiB
  public/vue_assets/css/foo.4bbe6793.css    0.12 KiB         0.11 KiB
  public/vue_assets/css/bar.96de90a8.css    0.02 KiB         0.04 KiB

  Images and other types of assets omitted.
...
```

Your file names could be different from mine. Don't worry, we won't look those files. There are the files you got:

```
.
├── app
│   ├── assets
│   │   └── vue
│   │       └── manifest.json
└── public
    └── vue_assets
        ├── css
        │   ├── bar.96de90a8.css
        │   └── foo.4bbe6793.css
        └── js
            ├── bar.d4fc59af.js
            ├── chunk-vendors.b5485759.js
            └── foo.dcbad15e.js
```

Let have a look at `app/assets/vue/manifest.json`:

```json
{
  "bar.css": "/vue_assets/css/bar.96de90a8.css",
  "bar.js": "/vue_assets/js/bar.d4fc59af.js",
  "chunk-vendors.js": "/vue_assets/js/chunk-vendors.b5485759.js",
  "entrypoints": {
    "bar": {
      "js": [
        "/vue_assets/js/chunk-vendors.b5485759.js",
        "/vue_assets/js/bar.d4fc59af.js"
      ],
      "css": [
        "/vue_assets/css/bar.96de90a8.css"
      ]
    },
    "foo": {
      "js": [
        "/vue_assets/js/chunk-vendors.b5485759.js",
        "/vue_assets/js/foo.dcbad15e.js"
      ],
      "css": [
        "/vue_assets/css/foo.4bbe6793.css"
      ]
    }
  },
  "foo.css": "/vue_assets/css/foo.4bbe6793.css",
  "foo.js": "/vue_assets/js/foo.dcbad15e.js"
}
```

<!-- </details> -->
