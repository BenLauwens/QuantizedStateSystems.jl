workspace()

import Base.start, Base.next, Base.done

abstract FiniteStateMachine

type Iterator{F<:FiniteStateMachine}
  args :: Tuple
  Iterator(args...) = new(args)
end

Iterator{F<:FiniteStateMachine}(::Type{F}, args...) = Iterator{F}(args...)

start{F<:FiniteStateMachine}(iter::Iterator{F}) = F(iter.args...)

next{F<:FiniteStateMachine}(iter::Iterator{F}, fsm::F, ret::Any=nothing) = (_iterator(fsm, ret), fsm)

done{F<:FiniteStateMachine}(iter::Iterator{F}, fsm::F) = fsm._state == 0xff

macro yield(val)
  :($(esc(val)))
end

function getArguments(expr) :: Vector{Symbol}
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

function getSlots(expr::Expr) :: Dict{Symbol, Type}
  slots = Dict{Symbol, Type}()
  name = gensym()
  copy_expr = deepcopy(expr)
  if expr.args[1].head == :call
    copy_expr.args[1].args[1] = name
  else
    copy_expr.args[1].args[1].args[1] = name
  end
  if VERSION < v"0.6.0-dev"
    code_expr = quote
      $copy_expr
      for lambda_info in code_typed($name)
        for i in 2:length(lambda_info.slotnames)
          $slots[lambda_info.slotnames[i]] = lambda_info.slottypes[i]
        end
      end
    end
  else
    code_expr = quote
      $copy_expr
      for (code_info, data_type) in code_typed($name)
        for i in 2:length(code_info.slotnames)
          $slots[code_info.slotnames[i]] = code_info.slottypes[i]
        end
      end
    end
  end
  eval(code_expr)
  delete!(slots, Symbol("#temp#"))
  slots
end

function transformVars!(expr::Expr, symbols)
  for i in 1:length(expr.args)
    if isa(expr.args[i], Symbol) && in(expr.args[i], symbols)
      expr.args[i] = :(_fsm.$(expr.args[i]))
    elseif isa(expr.args[i], Expr)
      transformVars!(expr.args[i], symbols)
    end
  end
end

function transformYield!(expr::Expr, n::UInt8=0x00, super::Expr=:(), line_no::Int=0) :: UInt8
  for (i, arg) in enumerate(expr.args)
    if isa(arg, Expr)
      if arg.head == :line
        line_no = i+1
        super = expr
      elseif arg.head == :macrocall && arg.args[1] == Symbol("@yield")
        n += one(UInt8)
        if expr == super
          expr.args[i] = :(_fsm._state = 0xff)
        else
          expr.args[i] = :(_ret)
          insert!(super.args, line_no, :(_fsm._state = 0xff))
        end
        insert!(super.args, line_no, :(@label $(Symbol("_STATE_",:($n)))))
        insert!(super.args, line_no, arg.args[2])
        insert!(super.args, line_no, :(_fsm._state = $n))
      else
        n = transformYield!(arg, n, super, line_no)
      end
    end
  end
  n
end

function removeLine!(expr::Expr)
  to_remove = Int[]
  for (i, arg) in enumerate(expr.args)
    if isa(arg, Expr)
      if arg.head == :line
        push!(to_remove, i)
      else
        removeLine!(arg)
      end
    end
  end
  for i in reverse(to_remove)
    deleteat!(expr.args, i)
  end
end

macro iterator(expr::Expr)
  expr.head != :function && error("Not a function definition!")
  args = getArguments(expr)
  func_name = shift!(args)
  type_name = gensym()
  slots = getSlots(expr)
  type_expr = :(
    type $type_name <: FiniteStateMachine
      _state :: UInt8
      $((:($slotname :: $(slottype == Union{} ? Any : :($slottype))) for (slotname, slottype) in slots)...)
      function $type_name($((:($arg::$(slots[:($arg)])) for arg in args)...))
        fsm = new()
        fsm._state = 0x00
        $((:(fsm.$arg = $arg) for arg in args)...)
        fsm
      end
    end
  )
  removeLine!(type_expr)
  eval(type_expr)
  new_expr = deepcopy(expr.args[2])
  transformVars!(new_expr, keys(slots))
  n = transformYield!(new_expr)
  func_expr = :(
    function _iterator(_fsm::$type_name, _ret::Any)
      _fsm._state == 0x00 && @goto _STATE_0
      $((:(_fsm._state == $i && @goto $(Symbol("_STATE_",:($i)))) for i in 0x01:n)...)
      error("Iterator has stopped!")
      @label _STATE_0
      _fsm._state = 0xff
      $((:($arg) for arg in new_expr.args)...)
    end
  )
  if expr.args[1].head == Symbol("::")
    func_expr.args[1] = Expr(Symbol("::"), func_expr.args[1], expr.args[1].args[2])
  end
  eval(func_expr)
  call_expr = deepcopy(expr)
  if call_expr.args[1].head == Symbol("::")
    call_expr.args[1] = call_expr.args[1].args[1]
  end
  call_expr.head = Symbol("=")
  call_expr.args[2] = :(Iterator{$type_name}($((:($arg) for arg in args)...)))
  call_expr
end

@iterator function fibonnaci(a::Float64=0.0; b::Float64=1.0) :: Float64
  while true
    @yield return a
    a, b = b, a+b
  end
end

for (i, fib) in enumerate(fibonnaci(1.0))
  i > 10 && break
  println(i, ": ", fib)
end

function test_fsm(n::Int)
  iter = fibonnaci()
  fib = start(iter)
  for i in 1:n
    next(iter, fib)
  end
end

n = 10000
test_fsm(1)
println("finite statemachine")
for i = 1:40
  @time test_fsm(n)
end
