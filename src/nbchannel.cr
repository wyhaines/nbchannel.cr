class NBChannel(T) < Channel(T)
  VERSION = "0.1.0"

  def initialize
    @capacity = 0
    @closed = false

    @senders = Crystal::PointerLinkedList(Sender(T)).new
    @receivers = Crystal::PointerLinkedList(Receiver(T)).new

    @queue = Deque(T).new
  end

  protected def send_internal(value : T)
    if @closed
      DeliveryState::Closed
    elsif receiver_ptr = dequeue_receiver
      receiver_ptr.value.data = value
      receiver_ptr.value.state = DeliveryState::Delivered
      receiver_ptr.value.fiber.enqueue

      DeliveryState::Delivered
    else
      (queue = @queue) && queue << value

      DeliveryState::Delivered
    end
  end

  def receive? : T?
    receive_impl(nonblocking: true) { return nil }
  end

  private def receive_impl(nonblocking : Bool = false, &)
    receiver = Receiver(T).new

    @lock.lock

    state, value = receive_internal

    case state
    in .delivered?
      @lock.unlock
      raise "BUG: Unexpected UseDefault value for delivered receive" if value.is_a?(UseDefault)
      value
    in .closed?
      @lock.unlock
      yield
    in .none?
      if nonblocking
        yield
      else
        receiver.fiber = Fiber.current
        @receivers.push pointerof(receiver)
        @lock.unlock

        Crystal::Scheduler.reschedule

        case receiver.state
        in .delivered?
          receiver.data
        in .closed?
          yield
        in .none?
          raise "BUG: Fiber was awaken without channel delivery state set"
        end
      end
    end
  end

  protected def receive_internal
    if (queue = @queue) && !queue.empty?
      deque_value = queue.shift
      if sender_ptr = dequeue_sender
        queue << sender_ptr.value.data
        sender_ptr.value.state = DeliveryState::Delivered
        sender_ptr.value.fiber.enqueue
      end

      {DeliveryState::Delivered, deque_value}
    elsif @closed
      {DeliveryState::Closed, UseDefault.new}
    else
      {DeliveryState::None, UseDefault.new}
    end
  end
end
