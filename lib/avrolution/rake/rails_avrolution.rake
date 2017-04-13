require 'avrolution/rake/check_compatibility_task'
require 'avrolution/rake/add_compatibility_break_task'
require 'avrolution/rake/register_schemas_task'

Avrolution::Rake::AddCompatibilityBreakTask.define(dependencies: %i(environment))
Avrolution::Rake::CheckCompatibilityTask.define(dependencies: %i(environment))
Avrolution::Rake::RegisterSchemasTask.define(dependencies: %i(environment))
