require 'active_support/callbacks'

class ActiveOperation::Base
  include SmartProperties
  include ActiveSupport::Callbacks

  attr_writer :output
  attr_accessor :error

  property :state, accepts: [:initialized, :halted, :succeeded, :failed], required: true, default: :initialized
  protected :state=

  define_callbacks :execute
  define_callbacks :error, scope: [:name]
  define_callbacks :succeeded, scope: [:name]
  define_callbacks :halted, scope: [:name]

  class << self
    def perform(*args)
      new(*args).call
    end
    ruby2_keywords :perform if respond_to?(:ruby2_keywords, true)

    def from_proc(execute)
      Class.new(self) do
        positional_arguments = []
        keyword_arguments = []

        execute.parameters.each do |type, name|
          case type
          when :req
            input name, type: :positional, required: true
            positional_arguments << name
          when :keyreq
            input name, type: :keyword, required: true
            keyword_arguments << name
          else
            raise ArgumentError, "Argument type not supported: #{type}"
          end
        end

        define_method(:execute) do
          args = positional_arguments.map { |name| self[name] }
          opts = keyword_arguments.map { |name| [name, self[name]] }.to_h

          if opts.empty?
            execute.call(*args)
          else
            execute.call(*args, **opts)
          end
        end
      end
    end

    def call(*args)
      perform(*args)
    end
    ruby2_keywords :call if respond_to?(:ruby2_keywords, true)

    def inputs
      []
    end

    def to_proc
      proc = ->(*args) {
        perform(*args)
      }
      proc.ruby2_keywords if proc.respond_to?(:ruby2_keywords)
      proc
    end

    protected

    def input(name, type: :positional, **configuration)
      property(name, type: type, **configuration)
    end

    def property(name, type: :keyword,  **configuration)
      @inputs ||= []

      if type == :positional
        @inputs << ActiveOperation::Input.new(type: :positional, property: super(name, required: true, **configuration))
      else
        @inputs << ActiveOperation::Input.new(type: :keyword, property: super(name, **configuration))
      end
    end

    def before(*args, &callback)
      set_callback(:execute, :before, *args, &callback)
    end

    def around(*args, &callback)
      set_callback(:execute, :around, *args, &callback)
    end

    def after(*args, &callback)
      set_callback(:execute, :after, *args, &callback)
    end

    def error(*args, &callback)
      set_callback(:error, :after, *args, &callback)
    end

    def succeeded(*args, &callback)
      set_callback(:succeeded, :after, *args, &callback)
    end

    def halted(*args, &callback)
      set_callback(:halted, :after, *args, &callback)
    end

    private

    def method_added(method)
      super
      protected method if method == :execute
    end

    def inherited(subclass)
      super

      subclass.define_singleton_method(:inputs) do
        superclass.inputs + Array(@inputs)
      end
    end
  end

  around do |operation, callback|
    catch(:abort) do
      callback.call
    end
  end

  def initialize(*args)
    arity = self.class.inputs.count(&:positional?)
    arguments = args.shift(arity)
    attributes = args.last.kind_of?(Hash) ? args.pop : {}

    raise ArgumentError, "wrong number of arguments #{arguments.length + args.length} for #{arity}" unless args.empty?

    self.class.inputs.select(&:positional?).each_with_index do |input, index|
      attributes[input.name] = arguments[index]
    end

    super(attributes)
  end

  def perform
    run_callbacks :execute do
      catch(:abort) do
        next if completed?
        @output = execute
        self.state = :succeeded
      end
    end

    run_callbacks :halted if halted?
    run_callbacks :succeeded if succeeded?

    self.output
  rescue => error
    self.state = :failed
    self.error = error
    run_callbacks :error
    raise
  end

  def call
    perform
  end

  def output
    call unless self.completed?
    @output
  end

  def halted?
    state == :halted
  end

  def succeeded?
    state == :succeeded
  end

  def completed?
    halted? || succeeded?
  end

  protected

  def execute
    raise NotImplementedError
  end

  def halt(*args)
    raise ActiveOperation::AlreadyCompletedError if completed?

    self.state = :halted
    @output = args.length > 1 ? args : args.first
    throw :abort
  end

  def succeed(*args)
    raise ActiveOperation::AlreadyCompletedError if completed?

    self.state = :succeeded
    @output = args.length > 1 ? args : args.first
    throw :abort
  end
end
