require 'active_support/core_ext/object/blank'

namespace :avro do
  desc 'Add an Avro schema compatibility break. Parameters: name, fingerprint, with_compatibility, after_compatibility'
  task add_compatibility_break: [:environment] do
    compatibility_break_args = ENV.to_h.slice('name', 'fingerprint', 'with_compatibility', 'after_compatibility').symbolize_keys

    missing_args = %w(name fingerprint).select do |arg|
      compatibility_break_args[arg].blank?
    end

    if missing_args.any?
      puts missing_args.map { |arg| "#{arg} can't be blank" }.join(', ')
      puts 'Usage: rake avro:add_compatibility_break name=<name> fingerprint=<fingerprint> [with_compatibility=<default:NONE>] [after_compatibility=<compatibility>]'
      exit(1)
    end

    Avrolution::CompatibilityBreaksFile.add(**compatibility_break_args)
  end

  desc 'Check that all Avro schemas are compatible with latest registered in production'
  task check_compatibility: [:environment] do
    check = Avrolution::CompatibilityCheck.new.call
    if check.success?
      puts 'All schemas are compatible'
    else
      puts "Incompatible schemas found: #{check.incompatible_schemas.join(', ')}"
      exit(1)
    end
  end
end
