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
    @mutex.synchronize do
      @available.count
    end
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

      resource = @available.pop
      @in_use << resource
      resource
    end
  end

  def check_in(resource)
    @mutex.synchronize do
      resource = @in_use.select {|r| r === resource}.first
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
        @in_use.each {|r| @shutdown_proc.call(r)}
      end
    end
  end
end
