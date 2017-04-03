require 'avrolution/rake/check_compatibility_task'
require 'avrolution/rake/add_compatibility_break_task'

Avrolution::Rake::AddCompatibilityBreakTask.define(dependencies: %i(environment))
Avrolution::Rake::CheckCompatibilityTask.define(dependencies: %i(environment))
