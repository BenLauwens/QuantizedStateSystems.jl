workspace()

function fibonnaci(a::Float64=0.0) :: Function
  _state = 0x00
  b = 1.0
  function fib(ret::Any = nothing) :: Float64
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

function test_clo(n::Int)
  fib = fibonnaci()
  for i in 1:n
    fib()
  end
end

n = 10000
test_clo(10)
println("statemachine")
for i = 1:40
  @time test_clo(n)
end
