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

function next{F<:FiniteStateMachine}(iter::Iterator{F}, fsm::F)
  fsm.state == typemax(UInt8) && error("Iterator is stopped!")
  (_iterator(fsm), fsm)
end

done{F<:FiniteStateMachine}(iter::Iterator{F}, fsm::F) = fsm.state == typemax(UInt8)

type Fibonnaci <: FiniteStateMachine
  state :: UInt8
  a :: Float64
  b :: Float64
  function Fibonnaci(a::Float64=0.0)
    new(0x0, a)
  end
end

fibonnaci(a::Float64=0) = Iterator{Fibonnaci}(a)

function _iterator{F<:FiniteStateMachine}(fsm::F) :: Float64
  if fsm.state == 0x0
    @goto _state_0_
  elseif fsm.state == 0x1
    @goto _state_1_
  end
  error("Iterator is stopped!")
  @label _state_0_
  fsm.state = 0x2
  fsm.b = fsm.a + one(fsm.a)
  while true
    fsm.state = 0x1
    return fsm.a
    @label _state_1_
    fsm.state = 0x2
    fsm.a, fsm.b = fsm.b, fsm.a+fsm.b
  end
end

for (i, fib) in enumerate(fibonnaci(1.0))
  i > 10 && break
  println(i, ": ", fib)
end
