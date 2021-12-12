class HumbleResourcePool
  DEFAULT_SIZE = 4

  class NoResourcesAvailableError < ::RuntimeError; end

  def initialize(size: DEFAULT_SIZE)
    raise ArgumentError("No resource factory given") unless block_given?

    @available = []
    @in_use = []
    @mutex = Thread::Mutex.new
    @size = size
    @size.times {|i| @available << yield(i)}

    @shutdown_proc = nil
  end

  def num_available
    @available.count
  end

  def register_shutdown_proc(&block)
    raise ArgumentError("No shutdown block given") unless block_given?
    @shutdown_proc = block
  end

  def with 
    if block_given?
      resource = check_out
      yield resource
      check_in resource
    end
  end
  
  def check_out
    @mutex.synchronize do
      if @available.length == 0
        raise NoResourcesAvailableError
      end

      # pop a resource off the @available stack and add it to @in_use
      resource = @available.pop
      @in_use << resource
      resource
    end
  end

  def check_in(resource)
    @mutex.synchronize do
      # remove the resource from the @in_use array and add it back to @available
      resource = @in_use.select {|r| r === resource}.first

      # if we can't find the passed-in resource, something weird happened. Perhaps
      # the caller returned the wrong object?
      if !resource.nil?
        @in_use -= [resource]
        @available << resource
      end
    end
  end

  def shutdown
    if @shutdown_proc
      @mutex.synchronize do
        @available.each {|r| @shutdown_proc.call(r)}
        # This humble resource pool hopes the caller won't shut things down
        # until they've checked in all resources, but if they don't we'll shut 
        # them down just the same. 
        @in_use.each {|r| @shutdown_proc.call(r)}
      end
    end
  end
end
