require "./spec_helper"

describe NBChannel do
  it "can send and receive synchronously" do
    channel = NBChannel(Int32).new
    channel.send 7
    channel.receive.should eq 7
  end

  it "blocks, in blocking mode, on receive, and handles N sends" do
    channel = NBChannel(Int32).new
    msgs = (1..100).to_a
    msgs.each do |i|
      sleep i.microseconds
      channel.send i
    end
    msgs.each do |i|
      channel.receive.should eq i
    end
  end

  it "never blocks on sends" do
    channel = NBChannel(UInt64).new
    counter = Atomic.new(0_u64)
    start_time = Time.monotonic
    end_time = start_time + 2.seconds
    spawn do
      loop do
        10000.times do
          channel.send counter.get
          counter.add 1_u64
        end
        break if Time.monotonic > end_time
      end
    end
    sleep 1
    last = 0_u64
    while (last = channel.receive) < (counter.get - 1); end

    last.should eq(counter.get - 1)
  end

  it "raises errors when channel is closed in before/during sends and receives" do
    channel = NBChannel(Int32).new
    channel.close
    expect_raises NBChannel::ClosedError do
      channel.receive
    end

    channel = NBChannel(Int32).new
    spawn channel.close
    expect_raises NBChannel::ClosedError do
      channel.receive
    end

    expect_raises NBChannel::ClosedError do
      channel.send 7
    end
  end

  it "nonblocking receives work as expected" do
    channel = NBChannel(Int32).new
    start_time = Time.monotonic
    end_time = start_time + 2.seconds
    last = 0_u64
    spawn do
      loop do
        10000.times do
          foo = channel.receive?
          last = foo if foo
        end
        break if Time.monotonic > end_time
      end
    end
    10000000.times do |counter|
      channel.send counter
    end
    sleep 1
    last.should eq 9999999
  end
end
