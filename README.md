# VueCli::Rails

Get `vue-cli` working on Rails

## Installation

Add this line to your Rails application's `Gemfile`:

```ruby
gem 'vue_cli-rails'
```

And then execute:

    $ bundle install
    $ bundle exec rake vue:create

Add those lines to your `config/routes.rb`:

```ruby
  get 'vue/foo' => 'vue#foo'
  get 'vue/bar' => 'vue#bar'
```

> Currently `rake vue:create` will overwrite all files, please be careful!

## Usage

This gem is fully depends on `vue-cli`. You can do everything with [`vue.config.js`](https://cli.vuejs.org/config/) just don't break `manifest` plugin which required by `vue_cli-rails`.

When you starting `rails server` with development mode, `vue-cli-service serve` will be running at the same time.

Please use `RAILS_ENV=production` to build your production assets. `NODE_ENV` will be ignored!

You can put `app/assets/vue/manifest.dev.json` into your VCS ignore list.

## Warning

Currently `vue.config.js` is reading configurations from `vue.rails.js` which depends on `js-yaml`. It will fallback to `bundle exec rake vue:json_config` without `js-yaml` installed. You may suffer performance issue if your rake tasks are slow.
