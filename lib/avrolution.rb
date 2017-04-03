require 'avrolution/version'

module Avrolution
  class PassthruLogger < Logger
    def initialize(*)
      super
      @formatter = ->(_severity, _time, _progname, msg) { "#{msg}\n" }
    end
  end
end

require 'salsify_avro/compatibility/compatibility_break'
require 'salsify_avro/compatibility/compatibility_breaks_file'
require 'salsify_avro/compatibility/check'
