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

macro yield(val, fsm, n::UInt8)
  quote
    $(esc(fsm)).state = $n
    return $(esc(val))
    $(Expr(:symboliclabel, :($(Symbol(:_state_,:($n))))))
    $(esc(fsm)).state = $(typemax(UInt8))
  end
end

macro yield(val)
  quote
    return $(esc(val))
  end
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

type StateCount
  n :: UInt8
end

function modifyExpr2(expr::Expr, sc::StateCount)
  if expr.head == :macrocall && expr.args[1] == Symbol("@yield")
    sc.n += one(UInt8)
    push!(expr.args, :fsm)
    push!(expr.args, sc.n)
  end
  for i in 1:length(expr.args)
    expr.args[i] = modifyExpr2(expr.args[i], sc)
  end
  expr
end

function modifyExpr2(expr, sc::StateCount)
  expr
end

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
      $((:($slotname :: $slottype) for (slotname, slottype) in slots)...)
      function $type_name($((:($arg::$(slots[:($arg)])) for arg in args)...))
        fsm = new()
        fsm.state = 0x0
        $((:(fsm.$arg = $arg) for arg in args)...)
        fsm
      end
    end
  end
  eval(type_expr)
  new_expr = modifyExpr1(deepcopy(expr.args[2]), keys(slots))
  modifyExpr2(new_expr, StateCount(0x0))
  func_expr = quote
    function _iterator(fsm::$type_name)
      if fsm.state == 0x0
        @goto _state_0
      elseif fsm.state == 0x1
        @goto _state_1
      end
      error("Iterator has stopped!")
      @label _state_0
      fsm.state = typemax(UInt8)
      $((:($arg) for arg in new_expr.args)...)
    end
  end
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

@iterator function fibonnaci(a::Float64=0.0; b::Float64=1.0) :: Float64
  while true
    @yield a
    a, b = b, a+b
  end
end

for (i, fib) in enumerate(fibonnaci(1.0))
  i > 10000 && break
  #println(i, ": ", fib)
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
