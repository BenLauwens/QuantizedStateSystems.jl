workspace()

function my_consume(producer::Task, values...)
  println(producer.state)
  istaskdone(producer) && return wait(producer)
  ct = current_task()
  ct.result = length(values)==1 ? values[1] : values
  Base.schedule_and_wait(producer)
  return producer.result
end

function my_produce(consumer::Task, values...)
  ct = current_task()
  ct.result = length(values)==1 ? values[1] : values
  Base.schedule_and_wait(consumer)
  return consumer.result
end

function produce_my(v)
    ct = current_task()
    consumer = ct.consumers
    ct.consumers = nothing
    Base.schedule_and_wait(consumer, v)
    return consumer.result
end
produce_my(v...) = produce_my(v)

function consume_my(producer::Task, values...)
    istaskdone(producer) && return wait(producer)
    ct = current_task()
    ct.result = length(values)==1 ? values[1] : values
    producer.consumers = ct
    producer.state == :runnable ? Base.schedule_and_wait(producer) : wait()
end

function fibonnaci()
  a = 0.0
  b = 1.0
  for i in 1:10
    println("ho")
    println(produce_my(a))
    a, b = b, a+b
  end
  println("hi")
  a
end

producer = @task fibonnaci()
for i in 1:11
  println(consume_my(producer, i))
end
