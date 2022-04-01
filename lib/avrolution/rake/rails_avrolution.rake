# frozen_string_literal: true

require 'avrolution/rake/check_compatibility_task'
require 'avrolution/rake/add_compatibility_break_task'
require 'avrolution/rake/register_all_schemas_task'
require 'avrolution/rake/register_schemas_task'

Avrolution::Rake::AddCompatibilityBreakTask.define(dependencies: [:environment])
Avrolution::Rake::CheckCompatibilityTask.define(dependencies: [:environment])
Avrolution::Rake::RegisterAllSchemasTask.define(dependencies: [:environment])
Avrolution::Rake::RegisterSchemasTask.define(dependencies: [:environment])
