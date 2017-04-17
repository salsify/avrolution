# avrolution

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
