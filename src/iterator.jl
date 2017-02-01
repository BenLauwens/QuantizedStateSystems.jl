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

macro yield(val)
  :($(esc(val)))
end

function getArguments(expr)
  args = Symbol[]
  kws = Symbol[]
  params = Symbol[]
  if expr.args[1].head == :call
    expr_args = expr.args[1].args
  else
    expr_args = expr.args[1].args[1].args
  end
  for arg in expr_args
    if isa(arg, Symbol)
      push!(args, arg)
    elseif arg.head == Symbol("::")
      push!(args, arg.args[1])
    elseif arg.head == :kw
      if isa(arg.args[1], Symbol)
        push!(kws, arg.args[1])
      else
        push!(kws, arg.args[1].args[1])
      end
    elseif arg.head == :parameters
      if isa(arg.args[1], Symbol)
        push!(params, arg.args[1])
      elseif arg.args[1].head == :kw
        if isa(arg.args[1].args[1], Symbol)
          push!(params, arg.args[1].args[1])
        else
          push!(params, arg.args[1].args[1].args[1])
        end
      end
    end
  end
  [args..., kws..., params...]
end

function getSlots(expr)
  slots = Dict{Symbol, Type}()
  name = gensym()
  if expr.args[1].head == :call
    expr.args[1].args[1] = name
  else
    expr.args[1].args[1].args[1] = name
  end
  eval(quote
    $expr
    for (code_info, data_type) in code_typed($name)
      for i in 2:length(code_info.slotnames)
        $slots[code_info.slotnames[i]] = code_info.slottypes[i]
      end
    end
  end)
  slots
end

function modifyExpr1(expr::Expr, symbols)
  for i in 1:length(expr.args)
    if typeof(expr.args[i]) == Symbol && expr.args[i] ∈ symbols
      expr.args[i] = :(fsm.$(expr.args[i]))
    else
      expr.args[i] = modifyExpr1(expr.args[i], symbols)
    end
  end
  expr
end

function modifyExpr1(expr, symbols)
  expr
end

function transform1(expr::Expr, n::UInt8=0x00)
  line = false
  for (i, arg) in enumerate(expr.args)
    if isa(arg, Expr) && arg.head == :line
      line = true
      continue
    elseif isa(arg, Expr) && arg.head ==:macrocall && arg.args[1] == Symbol("@yield")
      expr.args[i] = arg.args[2]
      sym = gensym()
      n += one(UInt8)
      insert!(expr.args, i, :(fsm.state = $n))
      insert!(expr.args, i+2, :(fsm.state = 0xff))
      insert!(expr.args, i+2, :(@label $(Symbol("_state",:($n)))))
    elseif line
      n = transform2(expr, arg, i, n)
      line = false
    else
      n = transform1(arg, n)
    end
  end
  n
end

transform1(arg, n::UInt8) = n

function transform2(super::Expr, expr::Expr, line_no::Int, n::UInt8)
  for (i, arg) in enumerate(expr.args)
    if isa(arg, Expr) && arg.head == :line
      line_no = i+1
      super = expr
      continue
    elseif isa(arg, Expr) && arg.head == :macrocall && arg.args[1] == Symbol("@yield")
      expr.args[i] = :(fsm._ret)
      sym = gensym()
      n += one(UInt8)
      insert!(super.args, line_no, :(fsm.state = 0xff))
      insert!(super.args, line_no, :(@label $(Symbol("_state",:($n)))))
      insert!(super.args, line_no, arg.args[2])
      insert!(super.args, line_no, :(fsm.state = $n))
    else
      n = transform2(super, arg, line_no, n)
    end
  end
  n
end

transform2(super::Expr, arg, line_no, n::UInt8) = n

function cleanup(expr::Expr)
  for (i, arg) in enumerate(expr.args)
    if isa(arg, Expr) && arg.head == :line
      deleteat!(expr.args, i)
    else
      cleanup(arg)
    end
  end
end

cleanup(arg) = nothing

macro iterator(expr)
  if isa(expr, Expr) && expr.head == :function

  else
    error("Not a function definition")
  end
  args = getArguments(expr)
  slots = getSlots(deepcopy(expr))
  delete!(slots, Symbol("#temp#"))
  func_name = shift!(args)
  type_name = gensym()
  type_expr = quote
    type $type_name <: FiniteStateMachine
      state :: UInt8
      _ret :: Any
      $((:($slotname :: $slottype) for (slotname, slottype) in slots)...)
      function $type_name($((:($arg::$(slots[:($arg)])) for arg in args)...))
        fsm = new()
        fsm.state = 0x00
        fsm._ret = nothing
        $((:(fsm.$arg = $arg) for arg in args)...)
        fsm
      end
    end
  end
  eval(type_expr)
  new_expr = modifyExpr1(deepcopy(expr.args[2]), keys(slots))
  n = transform1(new_expr)
  func_expr = quote
    function _iterator(fsm::$type_name)
      fsm.state == 0x00 && @goto _start
      $((:(fsm.state == $i && @goto $(Symbol("_state",:($i)))) for i in 0x01:n)...)
      error("Iterator has stopped!")
      @label _start
      fsm.state = 0xff
      $((:($arg) for arg in new_expr.args)...)
    end
  end
  println(cleanup(func_expr))
  eval(func_expr)
  call_expr = deepcopy(expr)
  if call_expr.args[1].head == Symbol("::")
    call_expr.args[1] = call_expr.args[1].args[1]
  end
  call_expr.args[2] = quote
    Iterator{$type_name}($((:($arg) for arg in args)...))
  end
  call_expr
end

@iterator function fibonnaci(a::Float64=0.0; b=1.0) :: Float64
  while true
    @yield return a
    a, b = b, a+b
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
