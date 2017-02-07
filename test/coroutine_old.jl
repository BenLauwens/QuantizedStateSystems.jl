workspace()

import Base.consume, Base.@label, Base.@goto

macro goto(expr::Expr)
  Expr(:symbolicgoto, :($expr))
end

macro label(expr::Expr)
  Expr(:symboliclabel, :($expr))
end

function getSymbols(expr::Expr)
  symbols = Set{Symbol}()
  start = 1
  if expr.head == :call || expr.head == :macrocall
    start = 2
  elseif expr.head == :line
    start = length(expr.args) + 1
  end
  for i in start:length(expr.args)
    symbols = union(symbols, getSymbols(expr.args[i]))
  end
  symbols
end

function getSymbols(sym::Symbol) :: Set{Symbol}
  Set([sym])
end

function getSymbols(sym) :: Set{Symbol}
  Set{Symbol}()
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

type Produce
  n :: UInt8
end

function modifyExpr(expr::Expr, symbols)
  for i in 1:length(expr.args)
    if typeof(expr.args[i]) == Symbol && expr.args[i] ∈ symbols
      expr.args[i] = :(cor.$(expr.args[i]))
    else
      expr.args[i] = modifyExpr(expr.args[i], symbols)
    end
  end
  expr
end

function modifyExpr(expr, symbols)
  expr
end

function processExpr(expr::Expr, n::Produce=Produce(0x0))
  if expr.head == :macrocall && expr.args[1] == Symbol("@produce")
    n.n += one(n.n)
    a = n.n
    push!(expr.args, n.n)
  end
  for i in 1:length(expr.args)
    expr.args[i] = processExpr(expr.args[i], n)
  end
  expr
end

function processExpr(expr, n::Produce)
  expr
end

abstract Coroutine

function consume(cor::Coroutine)
  cor.func(cor)
end

macro produce(val, n::UInt8)
  quote
    cor.state = $n
    return $val
    $(Expr(:symboliclabel, :($(Symbol(:_state_,:($n))))))
    cor.state = $(typemax(UInt8))
  end
end

macro elsegoto(n::UInt8)
  Expr(:if, :(cor.state == $n), Expr(:block, Expr(:symbolicgoto, :($(Symbol(:_state_,:($n)))))))
end

macro coroutine(name::Symbol, expr::Expr, params...)
  symbols = getSymbols(expr)
  args = getArguments(params)
  n = Produce(0x0)
  new_expr = processExpr(deepcopy(expr), n)
  new_expr = modifyExpr(new_expr, symbols)
  func_name = gensym()
  eval(
    quote
      type $name <: Coroutine
        state :: UInt8
        func :: Function
        $((:($arg :: $(typeof(val))) for (arg, val) in args)...)
        $(collect(setdiff(symbols, keys(args)))...)
        function $name($((:($arg) for (arg, val) in args)...))
          cor = new()
          cor.state = 0
          cor.func = $func_name
          $((:(cor.$arg = $arg) for arg in keys(args))...)
          cor
        end
      end
      function $func_name(cor::$name)
        if cor.state == 0
          @goto _state_start
        end
        $((:(@elsegoto $i) for i in 0x01:n.n)...)
        @goto _state_end
        @label _state_start
        $((:($arg) for arg in new_expr.args)...)
        @label _state_end
      end
    end)
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
  @time for i in 1:n
    consume(fib)
  end
end

function fibonnaci()
  a = 1.0
  b = 2.0
  while true
    a, b = b, a+b
    produce(a)
  end
end

function test_task_fibonnaci(n::Int)
  fib = @task fibonnaci()
  @time for i in 1:n
    consume(fib)
  end
end

test_fibonnaci(1)
test_fibonnaci(125000)
test_task_fibonnaci(1)
test_task_fibonnaci(125000)
