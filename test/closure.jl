workspace()

function fibonnaci(a::BigInt=BigInt(0), b::BigInt=BigInt(1)) :: Function
  _state = 0x00
  function fib(ret::Any = nothing) :: BigInt
    _state == 0x00 && @goto _STATE_0
    _state == 0x01 && @goto _STATE_1
    error("Iterator has stopped!")
    @label _STATE_0
    _state = 0xff
    while true
      _state = 0x01
      return a
      @label _STATE_1
      _state = 0xff
      a, b = b, a+b
    end
  end
end

type Fibonnaci
  _state :: UInt8
  a :: BigInt
  b :: BigInt
  Fibonnaci(a::BigInt=BigInt(0), b::BigInt=BigInt(1)) = new(0x00, a, b)
end

function (fib::Fibonnaci)() :: BigInt
  fib._state == 0x00 && @goto _STATE_0
  fib._state == 0x01 && @goto _STATE_1
  error("Iterator has stopped!")
  @label _STATE_0
  fib._state = 0xff
  while true
    fib._state = 0x01
    return fib.a
    @label _STATE_1
    fib._state = 0xff
    fib.a, fib.b = fib.b, fib.a+fib.b
  end
end

function test_clo(n::Int)
  fib = fibonnaci()
  for i in 1:n
    fib()
  end
end

function test_stm(n::Int)
  fib = Fibonnaci()
  for i in 1:n
    fib()
  end
end

n = 10000
test_clo(1)
println("Closure")
@time test_clo(n)
test_stm(1)
println("StateMachine")
@time test_stm(n)
