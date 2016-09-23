require "active_support/callbacks"
require "delegate"
require "smart_properties"

module ActiveOperation
  class Error < RuntimeError; end
  class AlreadyCompletedError < Error; end
end

require_relative "active_operation/version"
require_relative "active_operation/input"
require_relative "active_operation/base"
require_relative "active_operation/pipeline"

require_relative "active_operation/matcher" if defined?(:RSpec)
