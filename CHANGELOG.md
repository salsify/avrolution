# avrolution

## v0.9.0
- Add support for Ruby 3.2.
- Drop support for Ruby 2.6.
- 
## v0.8.0
- Added the ability to register all schemas found under `Avrolution.root` with the task
  `rake avro:register_all_schemas`.

## v0.7.2
- Fix a bug related to Ruby 3.0 keyword arguments in
  AvroSchemaRegistry::Client#register_without_lookup.

## v0.7.1
- Adjust Rake task definitions to work with Ruby 3.0.

## v0.7.0
- Add support for Ruby 3.0.
- Drop support for Ruby < 2.6.
- Use frozen string literals.

## v0.6.1
- Add missing require to `Avrolution::Rake::BaseTask`.

## v0.6.0
- Do not check compatibility for previously registered schemas.

## v0.5.0
- Require `avro-resolution_canonical_form` v0.2.0 or later to use
  `avro-patches` instead of `avro-salsify-fork`.

## v0.4.4
- Report current compatibility BOTH as FULL since BOTH is deprecated.

## v0.4.3
- Allow deleted schema files during deploy.

## v0.4.2
- Fix typo in template file.

## v0.4.1
- Exclude `vendor/bundle` under `Avrolution.root` when checking schema
  compatibility.

## v0.4.0
- Support a Proc for the configuration of `compatibility_schema_registry_url`
  and `deployment_schema_registry_url`.
- Environment variables now take priority over assigned values for
  `Avrolution.compatibility_schema_registry_url` and
  `Avrolution.deployment_schema_registry_url`.

## v0.3.0
- Add rake task to register new schema versions.

## v0.2.0
- Add Rails generator to create `avro_compatibility_breaks.txt` file.
- Replace the dependency on `avromatic` with `avro_schema_registry-client`.
- Reverse the identification of BACKWARD and FORWARD compatibility levels
  with the latest registered version.

## v0.1.0
- Add rake task to check the compatibility of schemas against a schema registry.
