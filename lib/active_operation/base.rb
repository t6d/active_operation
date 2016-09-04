class ActiveOperation::Base
  include SmartProperties
  include ActiveSupport::Callbacks

  attr_accessor :output
  attr_accessor :error

  property :state, accepts: [:initialized, :halted, :succeeded, :failed], required: true, default: :initialized
  protected :state=

  define_callbacks :execute, terminator: ActiveOperation.terminator
  define_callbacks :error
  define_callbacks :succeeded
  define_callbacks :halted

  class << self
    def perform(*args)
      new(*args).perform
    end

    def run(*args)
      new(*args).run
    end

    protected

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
  end

  around do |operation, callback|
    catch(:interrupt) do
      callback.call
    end
  end

  def run
    run_callbacks :execute do
      catch(:interrupt) do
        next if completed?
        self.output = execute
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

  def perform
    run
    output
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
    self.output = args.length > 1 ? args : args.first
    throw :interrupt
  end

  def succeed(*args)
    raise ActiveOperation::AlreadyCompletedError if completed?

    self.state = :succeeded
    self.output = args.length > 1 ? args : args.first
    throw :interrupt
  end
end
