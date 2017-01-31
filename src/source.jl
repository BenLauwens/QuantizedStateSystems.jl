workspace()

macro yield(val)
  quote
    return $(esc(val))
  end
end

abstract FiniteStateMachine

start(iter::Function) = 0x0
next(iter::Function, fsm::FiniteStateMachine) = iter(fsm)
done(iter::Function, fsm::FiniteStateMachine) = fsm.state == typemax(UInt8)

macro iterator(expr)
  if isa(expr, Expr) && expr.head == :function
    dump(expr)
    eval(:($expr))
  end
  if isa(expr, Expr) && expr.head == :call
    println("hi")
    file, line_no = eval(:(@functionloc $expr))
    println(file)
    io = open(file, "r")
    source = readstring(io)
    close(io)
    name = convert(String, expr.args[1])
    index = searchindex(source, "function $name(")
    println(parse(source, index)[1])
  else
    println("ho")
    println(expr)
  end
  quote
    nothing
  end
end

@iterator function fibonnaci(a::Float64=0.0, b::Float64=1.0) :: Float64
  while true
    @yield a
    a, b = b, a+b
  end
end

println(@iterator fibonnaci(2.0, 3.0))
