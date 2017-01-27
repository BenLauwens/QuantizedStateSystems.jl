workspace()

function fibonnaci_yieldto(super::Task)
  a = 0.0
  b = 1.0
  while true
    yieldto(super, a)
    a, b = b, a + b
  end
end

function test_yieldto(n::Int)
  ct = current_task()
  fib = @task fibonnaci_yieldto(ct)
  for i in 1:n
    a = yieldto(fib)
  end
end

function fibonnaci_yield(super::Task)
  a = 0.0
  b = 1.0
  while true
    Base.schedule_and_wait(super, a)
    a, b = b, a + b
  end
end

function test_yield(n::Int)
  ct = current_task()
  fib = @task fibonnaci_yield(ct)
  for i in 1:n
    a = Base.schedule_and_wait(fib)
  end
end

function fibonnaci_produce()
  a = 0.0
  b = 1.0
  while true
    produce(a)
    a, b = b, a + b
  end
end

function test_consume(n::Int)
  fib = @task fibonnaci_produce()
  for i in 1:n
    a = consume(fib)
  end
end

function fibonnaci_channel(ch::Channel)
  a = 0.0
  b = 1.0
  while true
    put!(ch, a)
    a, b = b, a+b
  end
end

function test_channel(n::Int)
  fib = Channel(fibonnaci_channel; ctype=Float64, csize=0)
  for i in 1:n
    a = take!(fib)
  end
end

type Fib
  a :: Float64
  b :: Float64
  state :: UInt8
end

function fibonnaci_stm(fib::Fib)
  if fib.state == 0x0
    @goto start
  end
  if fib.state == 0x1
    @goto s1
  end
  @goto stop
  @label start
  fib.state = 0x2
  fib.a = 0.0
  fib.b = 1.0
  while true
    fib.state = 0x1
    return fib.a
    @label s1
    fib.state = 0x2
    fib.a, fib.b = fib.b, fib.a + fib.b
  end
  @label stop
end

function test_stm(n::Int)
  fib = Fib(0.0, 0.0, 0x0)
  for i in 1:n
    a = fibonnaci_stm(fib)
  end
end

n = 10000
test_yieldto(1)
println("yieldto")
@time test_yieldto(n)
test_yield(1)
println("schedule_and_wait")
@time test_yield(n)
if VERSION < v"0.6.0-dev"
  test_consume(1)
  println("produce")
  @time test_consume(n)
else
  test_channel(1)
  println("channel")
  @time test_channel(n)
end
test_stm(1)
println("statemachine")
@time test_stm(n)
