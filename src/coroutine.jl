workspace()

import Base.consume

abstract Coroutine

function consume(cor::Coroutine)
  cor.func(cor)
end

function getArguments(params)
  args = Dict{Symbol, Any}()
  for param in params
    if typeof(param.args[2]) == Expr
      args[param.args[1]] = eval(param.args[2])
    else
      args[param.args[1]] = param.args[2]
    end
  end
  args
end

function getSlots(args::Dict{Symbol, Any}, expr::Expr)
  slots = Dict{Symbol, Type}()
  name = gensym()
  eval(
    quote
      function $name($((:($arg::typeof($val)) for (arg, val) in args)...))
        $((:($arg) for arg in expr.args)...)
      end
      code_info, data_type = @code_typed($name($((:($val) for (arg, val) in args)...)))
      for i in 2:length(code_info.slotnames)
        $slots[code_info.slotnames[i]] = code_info.slottypes[i]
      end
    end
    )
  slots
end

macro produce(val)
  println("something went wrong")
  nothing
end

macro coroutine(name::Symbol, expr::Expr, params...)
  args = getArguments(params)
  slots = getSlots(args, expr)
  func_name = gensym()
  type_expr = quote
    type $name <: Coroutine
      state :: Symbol
      func :: Function
      $((:($slotname :: $slottype) for (slotname, slottype) in slots)...)
      function $name($((:($arg::$(slots[:($arg)])) for (arg, val) in args)...))
        cor = new()
        cor.state = :_state_start
        cor.func = $func_name
        $((:(cor.$arg = $arg) for arg in keys(args))...)
        cor
      end
    end
  end
  eval(type_expr)
  func_expr = quote
    function $func_name(cor::$name)

    end
  end
  eval(func_expr)
  quote
    $name($((:($val) for (arg, val) in args)...))
  end
end

function test_fibonnaci(n::Int)
  fib = @coroutine Fibonnaci begin
    b = 1.0
    while true
      a, b = b, a+b
      @produce a
    end
  end a=>0.0
  @time for i in 1:n
    consume(fib)
  end
end

function fibonnaci_task()
  a = 0.0
  b = 1.0
  while true
    a, b = b, a+b
    produce(a)
  end
end

function test_fibonnaci_task(n::Int)
  fib = Task(fibonnaci_task)
  @time for i in 1:n
    consume(fib)
  end
end

function fibonnaci_channel(c::Channel)
  a = 0.0
  b = 1.0
  while true
    a, b = b, a+b
    put!(c, a)
  end
end

function test_fibonnaci_channel(n::Int)
  chnl = Channel(fibonnaci_channel)
  @time for i in 1:n
    take!(chnl)
  end
end

test_fibonnaci(1)
test_fibonnaci(10000)
test_fibonnaci_task(1)
test_fibonnaci_task(10000)
test_fibonnaci_channel(1)
test_fibonnaci_channel(10000)
