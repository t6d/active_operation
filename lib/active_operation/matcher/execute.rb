module ActiveOperation
  module Matcher
    module Execute
      class Matcher
        class ConfigurationError < RuntimeError
        end

        def when_called_with(*input)
          @input = input
          self
        end

        def and_return(output)
          @expected_output = output
          self
        end

        def because_of(error, message = nil)
          @expected_error = error
          @expected_message = message
          self
        end

        def description
          description = "execute"
          description << " and return #{format_arguments(expected_output)}" if expected_output
          description << " when called with the following arguments: #{format_arguments(*input)}" if input && input.any?
          description
        end

        def matches?(executable)
          raise ConfigurationError, "Error specified" if expected_error
          perform(executable)
          succeeded? && output_as_expected?
        end

        def does_not_match?(executable)
          raise ConfigurationError, "Output specified" if expected_output
          perform(executable)
          failed? && error_as_expected? && message_as_expected?
        end

        def failure_message
          if !output_as_expected?
            [
              "incorrect return value:",
              "expected: #{expected_output.inspect}",
              "got: #{given_output.inspect}"
            ].join("\n")
          elsif failed?
            "the execution failed with the following error: #{format_error_message(given_error, given_message)}"
          end
        end

        def failure_message_when_negated
          if failed?
            [
              "wrong error raised:",
              "expected: #{format_error_message(expected_error, expected_message)}",
              "got: #{format_error_message(given_error, given_message)}"
            ].join("\n")
          else
            "no error was raised"
          end
        end

        protected

        attr_reader :input
        attr_reader :expected_error, :given_error
        attr_reader :expected_message, :given_message
        attr_reader :expected_output, :given_output

        def perform(operation)
          @given_output = operation.call(*input)
        rescue => error
          @given_error = error.class
          @given_message = error.message
        end

        def succeeded?
          given_error.nil?
        end

        def failed?
          !succeeded?
        end

        def message_as_expected?
          return true if expected_message.nil?
          expected_message === given_message
        end

        def error_as_expected?
          return true if expected_error.nil?
          given_error < expected_error
        end

        def output_as_expected?
          return true unless given_output
          expected_output == given_output
        end

        private

        def format_error_message(error, message)
          formatted_message = error.name
          formatted_message << ", #{message.inspect}" unless message.nil? || message.strip == ""
          formatted_message
        end

        def format_arguments(*arguments)
          arguments.map(&:inspect).join(", ")
        end

        def humanize(*args)
          args = args.map(&:inspect)
          last_element = args.pop
          args.length > 0 ? [args.join(", "), last_element].join(" and ") : last_element
        end
      end

      def execute
        Matcher.new
      end
    end
  end
end

RSpec.configure do |config|
  config.include ActiveOperation::Matcher::Execute
end
