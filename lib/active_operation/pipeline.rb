module ActiveOperation
  class Pipeline < Base
    class OperationFactory < SimpleDelegator
      def initialize(operation_class, options = {})
        super(operation_class)
        @_options = options
      end

      def new(context, *input)
        keyword_input_names = inputs.select(&:keyword?).map(&:name)
        positional_args = input.shift(inputs.count(&:positional?))

        attributes_from_input = input.last.kind_of?(Hash) ? input.pop.slice(*keyword_input_names) : {}
        attributes_from_input.delete_if { |_, value| value.nil? }

        attributes_from_pipeline = Array(@_options).each_with_object({}) do |(key, value), result|
          result[key] = value.kind_of?(Proc) ? context.instance_exec(&value) : value
        end

        __getobj__.new *positional_args, attributes_from_input.merge(attributes_from_pipeline)
      end
    end

    class << self
      def operations
        []
      end

      def use(operation, options = {})
        operation = ActiveOperation::Base.from_proc(operation) if operation.kind_of?(Proc)

        if operations.empty?
          inputs = operation.inputs

          inputs.each do |input|
            input input.name, type: input.type
          end
        end

        (@operations ||= []) << OperationFactory.new(operation, options)
      end

      def compose(*operations, &block)
        raise ArgumentError, "Expects either an array of operations or a block with configuration instructions" unless !!block ^ !operations.empty?

        if block
          Class.new(self, &block)
        else
          Class.new(self) do
            operations.each do |operation|
              use operation
            end
          end
        end
      end

      protected

      def inherited(subclass)
        super

        subclass.define_singleton_method(:operations) do
          superclass.operations + Array(@operations)
        end
      end
    end

    protected

    def execute
      values = ->(input) { self[input.name] }

      positional_arguments = self.class.inputs.select(&:positional?).map(&values)
      keyword_arguments = self.class.inputs.select(&:keyword?).each_with_object({}) do |input, kwargs|
        kwargs[input.name] = values.call(input)
      end
      arguments = positional_arguments.push(keyword_arguments)

      self.class.operations.inject(arguments) do |data, operation|
        operation = if data.respond_to?(:to_ary)
                      operation.new(self, *data)
                    else
                      operation.new(self, data)
                    end

        operation.perform

        output = operation.output

        halt output if operation.halted?

        output
      end
    end
  end
end
