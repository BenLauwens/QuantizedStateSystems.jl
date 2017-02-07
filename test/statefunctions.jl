workspace()

type Fibonnaci
  _state :: UInt8
  a :: Float64
  b :: Float64
  Fibonnaci(a::Float64=0.0, b::Float64=1.0) = new(0x00, a, b)
end

function (fsm::Fibonnaci)(_ret::Any=nothing) :: Float64
  fsm._state == 0x00 && @goto _STATE_0
  fsm._state == 0x01 && @goto _STATE_1
  error("Statefunction has finished!")
  @label _STATE_0
  fsm._state = 0xff
  while true
    fsm._state = 0x01
    return fsm.a
    @label _STATE_1
    fsm._state = 0xff
    fsm.a, fsm.b = fsm.b, fsm.a+fsm.b
  end
end

function test_stm(n::Int)
  fib = Fibonnaci()
  for i in 1:n
    fib()
  end
end

n = 10000
test_stm(10)
println("Statefunction")
for i = 1:40
  @time test_stm(n)
end
