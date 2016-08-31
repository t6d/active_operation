class ActiveOperation::Base
  include SmartProperties
  include ActiveSupport::Callbacks

  property :output
  property :state, accepts: [:initialized, :aborted, :succeeded], required: true, default: :initialized
  protected :state=

  define_callbacks :execute

  class << self
    def call(*args)
      new(*args).call
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

    private

    def method_added(method)
      super
      protected method if method == :execute
    end
  end

  def call
    self.output = catch(:abort) do
      run_callbacks :execute do
        execute
      end
    end
  end

  def aborted?
    state == :aborted
  end

  def succeeded?
    state == :succeeded
  end

  protected

  def execute
    raise NotImplementedError
  end

  def abort(*args)
    self.state = :aborted
    throw :abort, *args
  end
end
