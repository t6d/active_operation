class ActiveOperation::Base
  include SmartProperties
  include ActiveSupport::Callbacks

  attr_accessor :output
  attr_accessor :error

  property :state, accepts: [:initialized, :halted, :succeeded, :failed], required: true, default: :initialized
  protected :state=

  define_callbacks :execute
  define_callbacks :error

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

    private

    def method_added(method)
      super
      protected method if method == :execute
    end
  end

  def run
    self.output = catch(:interrupt) do
      run_callbacks :execute do
        execute
      end
    end

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

  protected

  def execute
    raise NotImplementedError
  end

  def halt(*args)
    self.state = :halted
    throw :interrupt, *args
  end

  def succeed(*args)
    self.state = :succeeded
    throw :interrupt, *args
  end
end
