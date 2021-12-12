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

### Shutdown
In case the pooled resources need to be explicitly shut down, there is support for that:
```
pool = HumbleResourcePool.new(size: 10) { DBClient.new }
pool.register_shutdown_proc {|r| r.close}
  # do stuff
pool.shutdown
```
That's all there is to it!

