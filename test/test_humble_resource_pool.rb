gem "minitest"

require "minitest/autorun"
require_relative "../lib/humble_resource_pool"

class TestConnectionPool < Minitest::Test

  class GenericResource
    def initialize(name)
      @name = name
      @alive = true
    end

    def name
      @name
    end

    def shutdown!
      @alive = false
    end

    def alive?
      @alive
    end
  end

  def test_basic_usage
    size = rand(1..10)
    pool = HumbleResourcePool.new(size: size) {|i| GenericResource.new("resource #{i+1}")}
    assert pool.num_available == size

    resources = []
    size.times { resources << pool.check_out }
    assert pool.num_available == 0

    resources.each {|r| pool.check_in(r)}
    assert pool.num_available == size
  end

  def test_with_usage
    size = rand(1..10)
    pool = HumbleResourcePool.new(size: size) {|i| GenericResource.new("resource #{i+1}")}
    assert pool.num_available == size

    pool.with do |r|
      assert pool.num_available == size-1
    end

    assert pool.num_available == size
  end

  def test_multithreaded
    size = 10
    pool = HumbleResourcePool.new(size: size) {|i| GenericResource.new("resource #{i+1}")}
    assert pool.num_available == size
    tries = 0

    num_tests = 10000
    threads = (1..size).map do |thread_id|
      Thread.new(thread_id) do |tid|
        num_tests.times do 
          pool.with {|r|}
          tries += 1
        end
      end
    end
    threads.each(&:join)

    assert tries == size * num_tests
    assert pool.num_available == size
  end

  def test_shutdown_behavior
    pool = HumbleResourcePool.new(size: 1) {|i| GenericResource.new("resource #{i+1}")}
    pool.register_shutdown_proc {|r| r.shutdown!}
    r = pool.check_out
    assert r.alive? == true

    pool.shutdown
    assert r.alive? == false
  end

  def test_out_of_resources
    size = rand(1..10)
    pool = HumbleResourcePool.new(size: size) {|i| GenericResource.new("resource #{i+1}")}
    assert pool.num_available == size

    # check out all the resources
    resources = []
    size.times { resources << pool.check_out }
    assert pool.num_available == 0

    # next call to check_out should fail
    error = nil
    begin 
      pool.check_out
    rescue HumbleResourcePool::NoResourcesAvailableError => e
      error = e
    end

    assert !error.nil?
  end
end