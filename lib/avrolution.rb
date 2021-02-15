# frozen_string_literal: true

require 'avrolution/version'
require 'logger'

module Avrolution
  class PassthruLogger < Logger
    def initialize(*)
      super
      @formatter = ->(_severity, _time, _progname, msg) { "#{msg}\n" }
    end
  end
end

require 'active_support/core_ext/object/try'
require 'avrolution/configuration'
require 'avrolution/compatibility_break'
require 'avrolution/compatibility_breaks_file'
require 'avrolution/compatibility_check'
require 'avrolution/register_schemas'

require 'avrolution/railtie' if defined?(Rails)
