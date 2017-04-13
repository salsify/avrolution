# avrolution

## v0.3.0
- Add rake task to register new schema versions.

## v0.2.0
- Add Rails generator to create `avro_compatibility_breaks.txt` file.
- Replace the dependency on `avromatic` with `avro_schema_registry-client`.
- Reverse the identification of BACKWARD and FORWARD compatibility levels
  with the latest registered version.

## v0.1.0
- Add rake task to check the compatibility of schemas against a schema registry.
