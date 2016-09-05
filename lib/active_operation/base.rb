class ActiveOperation::Base
  include SmartProperties
  include ActiveSupport::Callbacks

  attr_accessor :output
  attr_accessor :error

  property :state, accepts: [:initialized, :halted, :succeeded, :failed], required: true, default: :initialized
  protected :state=

  define_callbacks :execute
  define_callbacks :error
  define_callbacks :succeeded
  define_callbacks :halted

  class << self
    def call(*args)
      new(*args).call
    end

    def output(*args)
      new(*args).output
    end

    def inputs
      []
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

  def initialize(*positional_arguments, **keyword_arguments)
    expected_positional_arguments = self.class.inputs.select(&:positional?)

    raise ArgumentError, "wrong number of arguments" if positional_arguments.length != expected_positional_arguments.length

    super(
      keyword_arguments.merge(
        expected_positional_arguments.zip(positional_arguments).map { |input, value| [input.name, value] }.to_h
      )
    )
  end

  def call
    run_callbacks :execute do
      catch(:abort) do
        next if completed?
        @output = execute
        self.state = :succeeded
      end
    end

    run_callbacks :halted if halted?
    run_callbacks :succeeded if succeeded?

    self
  rescue => error
    self.state = :failed
    self.error = error
    run_callbacks :error
    raise
  end

  def output
    call if @output.nil?
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

  def when_succeeded(&callback)
    callback.call(output) if succeeded?
  end

  def when_halted(&callback)
    callback.call(output) if halted?
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
