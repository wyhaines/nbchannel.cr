# nbchannel

This is a subclass of the standard Crystal Channel to make it into a non-blocking Channel implementation. The normal Crystal Channel blocks on receive, and on send if the channel the channel has no buffer, or if the fixed-size buffer is full. This non-blocking channel implementation makes it possible to send and receive messages asynchronously, with no blocking on either receive or send.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     nbchannel:
       github: wyhaines/nbchannel
   ```

2. Run `shards install`

## Usage

```crystal
require "nbchannel"
```

An instance of `NBChannel` is created in almost exactly the same way as standard Crystal `Channel`. The only difference is that an `NBChannel` has infinite capacity, so there is no capacity argument to `#new`.

```crystal
channel = NBChannel(String).new
```

Once created, any Fiber/Thread should be able to `#send` to an `NBChannel` without ever blocking on the send.

```crystal
channel.send("I am a message.")
```

Messages can be received from a channel in a blocking or a nonblocking manner.

```crystal
channel = NBChannel(String).new
spawn channel.send("I am a message.")
msg = channel.receive # This will block until a message is sent.
```

```crystal
channel = NBChannel(String).new
spawn do
  x = rand.seconds * 1.0
  puts "sleeping #{x}"
  sleep x
  channel.send("Gotcha!")
end

y = rand.seconds
puts "waiting #{y}"
sleep y

puts channel.receive? || "You escaped the trap!"
```

## Contributing

1. Fork it (<https://github.com/wyhaines/nbchannel/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Kirk Haines](https://github.com/wyhaines) - creator and maintainer
