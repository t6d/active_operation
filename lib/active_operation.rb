require "active_support/callbacks"
require "smart_properties"

module ActiveOperation
  class Error < RuntimeError; end
  class AlreadyCompletedError < Error; end
end

require "active_operation/version"
require "active_operation/input"
require "active_operation/base"
