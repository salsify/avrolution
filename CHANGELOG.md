# avrolution

## v0.5.0
- Require 'avro-patches' instead of `avro-salsify-fork`.

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
