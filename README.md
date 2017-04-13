# avrolution

Support for the evolution of Avro schemas stored in a schema registry.

This gem provides utilities to help with the management of Avro JSON schemas in a
schema registry. The compatibility of Avro JSON schema files can be checked
against a registry. Expected compatibility breaks can also be declared.

## Installation

Add this gem to your application's Gemfile, typically in a dev/test group:

```ruby
group :development, :test do
  gem 'avrolution'
end
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install avrolution

Within a Rails project, create an `avro_compatibility_breaks.txt` file at
`Rails.root` by running:

    $ rails generate avrolution:install

## Configuration

The gem supports the following configuration:

* `root` - The directory to search for Avro JSON schemas (`.avsc`). This is also
  the default location for the compatibility breaks file. In a Rails application,
  `Avrolution.root` defaults to `Rails.root`.
* `compatibility_breaks_file` - The path to the compability breaks file. Defaults
  to `#{Avrolution}.root/avro_compatibility_breaks.txt`.
* `compatibility_schema_registry_url` - The URL for the schema registry to use
  for compatibility checking. `ENV['COMPATIBILITY_SCHEMA_REGISTRY_URL']` is used
  as the default.
* `deployment_schema_registry_url` - The URL for the schema registry to use
  when registering new schema version. `ENV['DEPLOYMENT_SCHEMA_REGISTRY_URL']`
  is used as the default.
* `logger` - A logger used by the rake tasks in this gem. This does _NOT_ default
  to `Rails.logger` in Rails applications.

## Usage

### Avro Compatibility Check Rake Task

There is a rake task to check the compatibility of all Avro JSON schemas under
`Avrolution.root` against a schema registry.

For Rails applications, the `avro:check_compatibility` task is automatically
defined via a Railtie.

This task does not require any arguments. It checks the
compatibility of all Avro JSON schemas found recursively under `Avrolution.root`
against the schema registry `Avroluion.compatibility_schema_registry_url` or
`ENV['COMPATIBILITY_SCHEMA_REGISTRY_URL']`.

```bash
rake avro:check_compatibility
```

If a schema is incompatible, then `Avrolution.compatibility_breaks_file` is also
consulted. If the schema is still incompatible with the last registered version
then the differences are displayed and the command to add a compatibility break
is printed.

For non-Rails projects, tasks can be defined as:

```ruby
require 'avrolution/rake/check_compatibility_task'
Avrolution::Rake::CheckCompatibilityTask.define
```

### Avro Register Schemas Rake Task

There is a rake task to register new schemas.

For Rails applications, the `avro:register_schemas` task is automatically
defined via a Railtie.

This rake task requires a comma-separated list of files for the schemas to register.

```bash
rake avro:register_schemas schemas=/app/avro/schemas/one.avsc,/app/avro/schema/two.avsc
```

Schemas are registered against the schema registry
`Avroluion.deployment_schema_registry_url` or
`ENV['DEPLOYMENT_SCHEMA_REGISTRY_URL']`.

The `Avrolution.compatibility_breaks_file` is consulted prior to registering the
schema, and if an entry is found then the specified compatibility settings are
used.

For non-Rails projects, tasks can be defined as:

```ruby
require 'avroluation/rake/register_schemas_task'
Avrolution::Rake::RegisterSchemasTask.define
```

### Avro Add Compatibility Break Rake Task

There is a rake task add an entry to the `Avrolution.compatibility_breaks_file`.

This rake task accepts the following arguments:
* `name` - The full name of the Avro schema.
* `fingerprint` - The Resolution fingerprint as a hex string.
* `with_compatibility` - Optional compatibility level to use for the check and
 during registration.
* `after_compatibility` - Optional compatibility level to set after registration.

```bash
rake avro:add_compatibility_break name=com.salsify.alerts.example_value \
  fingerprint=36a2035c15c1bbbfe895494697d1f760171d00ab4fd39d0616261bf6854374f9 \
  with_compatibility=BACKWARD after_compatibility=FULL
```

For Rails applications, the `avro:add_compatibility_break` task is automatically
defined via a Railtie.

For non-Rails projects tasks can be defined as:

```ruby
require 'avrolution/rake/add_compatibility_break_task'
Avrolution::Rake::AddCompatibilityBreakTask.define
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then,
run `rake spec` to run the tests. You can also run `bin/console` for an
interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. 

To release a new version, update the version number in `version.rb`, and then
run `bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/salsify/avrolution.## License

The gem is available as open source under the terms of the
[MIT License](http://opensource.org/licenses/MIT).

