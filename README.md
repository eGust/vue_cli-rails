# VueCli::Rails

[![Build Status](https://travis-ci.com/eGust/vue_cli-rails.svg?branch=master)](https://travis-ci.com/eGust/vue_cli-rails)

Let's make cool boy Vue even cooler on Rails!

[Change Log](./CHANGELOG.md)

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

## Features

- Feel free to use `yarn` or `npm`.
- Single `vue_entry` rather than confusing `javascript_packs_with_chunks_tag`, `stylesheet_pack_tag`, `javascript_packs_tag`, etc.
- Get all benefits of [Vue CLI](https://cli.vuejs.org/).

  - Powered by `webpack` 4
  - DRY: all-in-one configuration file rather than repeating for `webpack`, `eslint` and etc.
  - Out-of-box tooling: Babel, TypeScript, PWA, `vue-router`, `Vuex`, CSS pre-processors, linter and testing tools.
  - Enhanced alias support in `jest.config.js`.

- Run `webpack-dev-server` together with Rails server in dev mode.
- Just single `RAILS_ENV`, no more `NODE_ENV`.
- Rails way configurations in `config/vue.yml`.

## Getting started

Out-of-box workflow:

1. Make sure `@vue/cli` already installed globally via `npm` (`npm i -g @vue/cli`) or `yarn` (`yarn global add @vue/cli`)
2. `bundle exec rake vue:create` and follow the steps.

    > Don NOT select `In package.json` for "Where do you prefer placing config for Babel, PostCSS, ESLint, etc.?". Some functionalities like alias of jest may not work.

3. Put your JavaScript files under `app/assets/vue/entry_points`.
4. Insert your entry point by `vue_entry 'entry_point'` in views or `render vue: 'entry_point'` in controllers.
5. `webpack-dev-server` auto starts alongside `rails server` in dev mode.
6. Invoke `env RAILS_ENV=production bundle exec rake vue:compile` to compile assets (you still must manually set `RAILS_ENV` to `production`).

> More settings are available in `config/vue.yml`

## Usage

### Core

#### Concept: Entry Point and File structure

The root path of your Vue assets is `app/assets/vue`. This gem will generate several folders. However, `app/assets/vue/entry_points` is the only one matters.

> The entry path is [configurable](#general-settings-file-is-configvueyml) in `config/vue.xml`.

Webpack sees one JavaScript file as the center of a web page rather than HTML. Thus all styles, images, fonts and other assets are related to a JS files by `import 'css/png/svg/woff2/json'`. Any `.js` file under `app/assets/vue/entry_points` will be a entry-point.

Please ONLY puts your entry-point files under entry folder with `.js` extension name.

> Be aware, `.js.erb` and `.vue.erb` are NOT supported. I will explain the reason in [Q&A section](#difference-from-webpacker).

If you are new to modern front-end development, or more specifically with `webpack` in this case, please read [Q&A section](#qa) for more information.

#### Helper `vue_entry`

`vue_entry` is like `javascript_include_tag` and `stylesheet_link_tag` which generates relative assets links for your entry point. (It's like `javascript_packs_with_chunks_tag` in Webpacker 4. I will explain why it's different in [Q&A](#qa).)

> You may have interest of path alias in `config/vue.yml`.

#### Use `render vue: <entry_point>` in controllers

Usually you only need `<div id="app"></div>` and `vue_entry 'entry/point'` to render a Vue page. You can use `render vue: 'entry/point'` inside your controller.

This method is simply a wrap of `render html: vue_entry('entry_point'), layout: true`. So you can pass any arguments supported by `render` including `layout`.

<details><summary>For example</summary>

```ruby
# app/controllers/my_vue_controller
class MyVueController < ApplicationController
  layout 'vue_base'

  def foo
    render vue: 'foo/bar'
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

- `entry_path`

  Entry point folder. Default: `app/assets/vue`

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

  Adds template or style language support. Vue ships with supporting `pug`, `slm`, `sass`, `less` and `stylus` out-of-box. How ever, you still have to install some loaders manually if you did not select that language with `vue:create`.

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

- `vue:inspect`

    Alias of `vue inspect`, `npx vue-cli-service inspect` or `yarn exec vue-cli-service inspect`. Display the webpack configuration file.

> You may need to invoke `rake` with `bundle exec`. Rails 5 and above supports new `rails rake:task` flavor.

## Migrate from Webpacker

It's very easy to migrate from Webpacker.

1. Install this gem and `bundle install`
2. Install `@vue/cli` globally and follow the instructions of `rake vue:create`;
3. Edit `config/vue.yml`, set `default/entry_path` to `source_path` (by default `app/javascript`) joins `source_entry_path` (by default `packs`);
4. Change all `javascript_packs_with_chunks_tag` to `vue_entry`;
5. Fix all nonsense `xxxx_packs_tag`;
6. If you mind `public_output_path` and `manifest_output`, you can change them to follow Webpacker values;
    > I strongly NOT recommend to put `manifest_output.json` under `public` folder;
7. Update `vue.config.js` if you have any customized webpack configurations;
    > You can inspect webpack settings at anytime with `rake vue:inspect` or `vue inspect`
8. Directly `rails s` to start dev server;
    > You can get rid of `bin/webpack-dev-server` and `bin/webpack` now. However, still recommend `rake vue:node_dev` and run `yarn dev` so it will kill `webpack-dev-server` properly when your Rails dev server stopped.
9. Call `env RAILS_ENV=production rake vue:compile[with_rails_assets]` instead of `env RAILS_ENV=production rake assets:precompile` to compile all assets for production.
10. Delete unused Webpacker files

  - `bin/webpack-dev-server`
  - `bin/webpack`
  - `config/webpack`
  - `config/webpacker.yml`

> Strongly recommend to backup your codebase before the migration.

Enjoy Hot Module Replacement now!

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

    + const { configureWebpack: { entry, output, resolve, module: cwModule } } = getSettings('configureWebpack');

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
    +    module: cwModule,
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

## Trouble Shooting & Known Issues

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

    > I know it is not Rails-way at all. I don't want to waste time to reinvent it - you are already using Node, why it bothers you?

- My API does not work with CSRF token

    Because Vue does not have opinion of Ajax (or JSON API) preference, you must implement what `jquery-ujs` does by yourself. There is an example in vanilla JS with [querySelector](https://developer.mozilla.org/en-US/docs/Web/API/Document/querySelector) (which should work for IE8+) and [Fetch API](https://developer.mozilla.org/en/docs/Web/API/Fetch_API):

    ```JS
    async (url, data) => {
      const $csrfParam = document.querySelector('meta[name="csrf-param"]');
      const $csrfToken = document.querySelector('meta[name="csrf-token"]');
      const csrfParam = ($csrfParam && $csrfParam.getAttribute('content')) || undefined;
      const csrfToken = ($csrfToken && $csrfToken.getAttribute('content')) || undefined;

      try {
        const response = await fetch(url, {
          method: 'POST',
          headers: {
            'Content-type': 'application/json',
            'X-CSRF-Token': csrfToken,
          },
          body: JSON.stringify({
            ...data,
            [csrfParam]: csrfToken,
          }),
        });

        if (!response.ok) {
          // handle bad response
        }

        return response.json();
      } catch (e) {
        // handle failed case
      }
    }
    ```

    Alternatively you can turn off CSRF token and set [SameSite cookie](https://gist.github.com/will/05cb64dc343296dec4d58b1abbab7aaf) if all your clients no longer use IE. [Modern browsers](https://caniuse.com/#feat=same-site-cookie-attribute) can handle `SameSite` flag to [prevent CSRF attacks](http://www.sjoerdlangkemper.nl/2016/04/14/preventing-csrf-with-samesite-cookie-attribute/).

- My Jest complains about `import`

    Seems `transformIgnorePatterns` in `jest.config.js` not working the same way in different environments. I found sometimes `<rootDir>/node_modules/` works while `/node_modules/` works on another machine. Try to change the order and you will find which one works for you.

- Mocha tests not working

    This is a known issue and I am not going to fix it recently.

- TypeScript can not find my aliases

    This is a known issue. TS is still using `tsconfig.json` rather than a `.js` or `.ts` file. You must manually update it for now. I will try to find a way out.

- My `yarn test:...`/`npm run test:...` not working properly

    The test requires setting `RAILS_ENV=test`. You can invoke `rake vue:test[unit]` `rake vue:test[e2e]` instead.

- Got errors like `command "..." does not exist` for `rake vue:lint/test`

    This rake task simply invokes `vue-cli-service test:...`. Those commands will be generated by some vue plugins. It won't be available unless you got correct plugin installed.

<details><summary>Q & A</summary>

## Q&A

### Can I get rid of `js-yaml` and `webpack-assets-manifest`

Only `webpack-assets-manifest` is a required dependency. It will be used to generate `manifest.json` which required for both dev and prod.

`vue.rails.js` uses `js-yaml` for parsing `config/vue.yml`. It will fallback to `rake vue:json_config` if `js-yaml` not been installed. However, when your Rails app grow bigger, you will very likely find rake tasks start slower and slower.

### Can I use HAML for template inside .vue files

Short answer I don't know and I don't recommend. There are several HAML packages but all are too old. JS world suggests [pug](https://pugjs.org). You can also use [slm](https://github.com/slm-lang/slm) if you prefer [Slim](http://slim-lang.com/). Both are quite similar to CSS selector syntax, which means you don't really need to spend time to learn.

Just `rake vue:support[pug,slm]` and try them out: `<template lang="pug">` or `<template lang="slm">`.

### Does it support pnpm

No.

The reason is Vue CLI does not support `pnpm` very well, or `npm` does not support `@vue/cli`. Who knows.

You still have a chance to get it worked by giving `pnpm --shamefully-flatten` flag, which makes [no difference from `npm` or `yarn`](https://pnpm.js.org/docs/en/faq.html#solution-3).

If someday they support each other, I'd like to support `pnpm` as well.

### Your demo code seems awful

Yes I admit it. Personally I'd like to directly write SPA with webpack tooling for front-end. Back-end will be a separated project, and it will be a Rails-API or Sinatra project if I want to use ActiveRecord.

`webpack-dev-server` can simply be configured with a proxy and I can use something like `npm-run-all` to start 2 services at the same time. I had to write some not-so-good code to get those things done in Rails.

The demo is more Rails way - separated layouts and views. SPA world uses some client router like `vue-router`.

### It does not work on Windows

Sorry, I don't think many gems work on Windows. Please install a virtual machine and run Linux on it. This gem is very likely working with `WSL`, however you may suffer performance issues due to its [file system](https://github.com/Microsoft/WSL/issues/873#issuecomment-425272829)

Currently `vue.config.js` is reading configurations from `vue.rails.js` which depends on `js-yaml`. It will fallback to `bundle exec rake vue:json_config` without `js-yaml` installed. Your rake tasks may spend a minute to load which apparently is not a good idea.

### Will you support SSR

I do want to support SSR. However, the way [Vue officially provided](https://ssr.vuejs.org/) requires you to write separated code for client and server then compile with Webpack, which is quite complicated.[ `prerender-spa-plugin`](https://github.com/chrisvfritz/prerender-spa-plugin) might be easier to achieve it.

I will do more investigation like how [Nuxt.js](https://nuxtjs.org/) does SSR. But I can't guarantee anything now.

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

    I just don't buy it. It could be a security issue, especially for a startup or small company where Rails is widely being adapted. There are plenty ways if you intended to open your source, like [Gitlab does](https://gitlab.com/gitlab-org/gitlab-ce/). You should not do unaware contribution.

    You can manually set `productionSourceMap` to `true` in `config/vue.yml`. Good on you!

8. This gem puts `manifest.json` in `app/assets/vue` directory by default than `public`.

    Again, I have no idea why Webpacker doing that.

9. `webpack-dev-server` automatically starts with `rails server` in dev mode.

    I don't understand why not to start the killing feature of webpack. Stop wasting your life on stupidly refreshing and waiting the whole page being reloaded while debugging front-end code.

    If your computer is too slow, ask your boss to buy a good one. You deserve it.

10. Less configurations and easier to understand.

    Only a few platform-specific settings available. All others are very standard.

</details>

## Explanation by Demo

<details><summary>Copy Demo Code</summary>

### Install

Run `bundle exec rake vue:create` or `rails vue:create` in Rails 5+, and follow the steps:

```bash
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

```txt
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

    $ yarn lint # npm run lint

Run Jest

    $ yarn test:unit # npm run test:unit

### Compile Assets

First let's compile the assets

```bash
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

Your file names could be different from mine. Don't worry, we won't look those files. There are the files you will get:

```txt
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

### How Entry Point works

Let's take a look at `app/assets/vue/manifest.json`:

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

As mentioned above, there are 2 files under `app/assets/vue/entry_points` folder: `foo.js` and `bar.js`. They will become entry points in `manifest.json`. When you call `render vue: 'bar'` in `VueDemoController` or `<%= vue_entry('foo') %>` in `app/views/vue_demo/foo.html.erb`, `vue_entry` will look for them in `entrypoints` of `manifest.json`, then generate `<link href="<path>" rel="stylesheet">` and `<script src="<path>"></script>` for each asset.

It's slightly different on dev server. This gem will send requests to webpack-dev-server and fetch the paths on-the-fly. The request will be GET `http://localhost:3080/__manifest/?<entry_point>` for each `vue_entry`. You can also send GET request to `http://localhost:3080/__manifest/?!!INSPECT!!` to get the full manifest.

</details>
