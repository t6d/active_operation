module ActiveOperation
  class Pipeline < Base

    class OperationFactory < SimpleDelegator
      def initialize(operation_class, options = {})
        super(operation_class)
        @_options = options
      end

      def new(context, *input)
        input = input.shift(inputs.map(&:positional?).count)
        __getobj__.new *input, Hash[Array(@_options).map do |key, value|
          [key, value.kind_of?(Proc) ? context.instance_exec(&value) : value]
        end]
      end
    end

    class << self
      def operations
        []
      end

      def use(operation, options = {})
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
      keyword_arguments = self.class.inputs.select(&:keyword?).map(&values)
      arguments = positional_arguments.push(keyword_arguments)

      self.class.operations.inject(arguments) do |data, operation|
        operation = if data.respond_to?(:to_ary)
                      operation.new(self, *data)
                    else
                      operation.new(self, data)
                    end
        operation.perform

        if operation.halted?
          halt operation.output
        end

        operation.output
      end
    end
  end
end
