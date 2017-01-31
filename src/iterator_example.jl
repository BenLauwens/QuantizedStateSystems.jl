workspace()

import Base.start, Base.next, Base.done

abstract FiniteStateMachine

type Iterator{F<:FiniteStateMachine}
  args :: Tuple
  function Iterator(args...)
    new(args)
  end
end

function Iterator{F<:FiniteStateMachine}(::Type{F}, args...)
  Iterator{F}(args...)
end

start{F<:FiniteStateMachine}(iter::Iterator{F}) = F(iter.args...)

next{F<:FiniteStateMachine}(iter::Iterator{F}, fsm::F) = (_iterator(fsm), fsm)

done{F<:FiniteStateMachine}(iter::Iterator{F}, fsm::F) = fsm.state == 0xff

type Fibonnaci <: FiniteStateMachine
  state :: UInt8
  a :: Float64
  b :: Float64
  function Fibonnaci(a::Float64, b::Float64)
    new(0x00, a, b)
  end
end

fibonnaci(a::Float64=0.0, b::Float64=1.0) = Iterator{Fibonnaci}(a, b)

function _iterator{F<:FiniteStateMachine}(fsm::F) :: Float64
  if fsm.state == 0x00
    @goto _state_0_
  end
  if fsm.state == 0x01
    @goto _state_1_
  end
  error("Iterator has stopped!")
  @label _state_0_
  fsm.state = 0xff
  while true
    fsm.state = 0x01
    return fsm.a
    @label _state_1_
    fsm.state = 0x02
    fsm.a, fsm.b = fsm.b, fsm.a+fsm.b
  end
end

for (i, fib) in enumerate(fibonnaci(1.0))
  i > 10 && break
  println(i, ": ", fib)
end

function test_stm(n::Int)
  iter = fibonnaci()
  fib = start(iter)
  for i in 1:n
    next(iter, fib)
  end
end

n = 10000
test_stm(1)
println("statemachine")
@time test_stm(n)
