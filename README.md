# Humble Resource Pool

A simple, no-frills thread-safe resource pool for use with any kind of resource.

# Usage
`HumbleResourcePool` uses a simple check_out/check_in interface to get resources from the pool.
```
require "humble_resource_pool"

pool = HumbleResourcePool.new(size: 10) { DBClient.new }

# explicitly check-out and check-in when done
client = pool.check_out
  # do stuff
pool.check_in(client)

# or use with & block
pool.with do |client|
  # do stuff
end
```
Note: If all available resources are checked out, subsequent calls to `check_out` or `with` will throw a `HumbleResourcePool::NoResourcesAvailableError` 
Also: All resources are created at pool initialization time. 

### Shutdown
In case the pooled resources need to be explicitly shut down, there is support for that:
```
pool = HumbleResourcePool.new(size: 10) { DBClient.new }
pool.register_shutdown_proc {|r| r.close}
  # do stuff
pool.shutdown
```
Note: When `shutdown` is invoked, even if resources are currently checked out, the registered 
shutdown proc will be called for each resources created in the pool. Caller takes responsibility
for ensuring all pooled resources are released before invoking `shutdown`.

### Resource availability
```
pool = HumbleResourcePool.new(size: 10) { DBClient.new }
pool.num_available  # => 10
client = pool.check_out
pool.num_available  # => 9
```
That's all there is to it!

