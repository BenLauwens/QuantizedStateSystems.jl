workspace()

type Fibonnaci
  _state :: UInt8
  a :: Float64
  b :: Float64
  Fibonnaci(a::Float64, b::Float64) = new(0x00, a, b)
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
    isa(_ret, Exception) && throw(_ret)
    fsm._state = 0xff
    fsm.a, fsm.b = fsm.b, fsm.a+fsm.b
  end
end

fib = Fibonnaci(0.0, 1.0)
for i in 1:10
  println(fib())
end
println(fib(error("Enough!")))
