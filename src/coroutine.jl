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
      local lambda_info = @code_typed($name($((:($val) for (arg, val) in args)...)))
      for i in 2:length(lambda_info.slotnames)
        $slots[lambda_info.slotnames[i]]=lambda_info.slottypes[i]
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
    b = 2.0
    while true
      a, b = b, a+b
      @produce a
    end
  end a=>1.0
  println(fib)
  @time for i in 1:n
    consume(fib)
  end
  println(fib)
end

test_fibonnaci(5)
