require "active_support/callbacks"
require "smart_properties"

module ActiveOperation
  class Error < RuntimeError; end
  class AlreadyCompletedError < Error; end

  def self.terminator
    ->(target, result_lambda) {
      terminate = true
      catch(:interrupt) do
        result_lambda.call
        terminate = false
      end
      terminate
    }
  end
end

require "active_operation/version"
require "active_operation/base"
