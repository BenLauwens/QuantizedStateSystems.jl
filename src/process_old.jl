workspace()

function getSymbols(expr::Expr)
  symbols = Set{Symbol}()
  start = 1
  if expr.head == :call
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
    if typeof(param.args[2]) == Symbol
      args[param.args[1]] = esc(param.args[2])
    else
      args[param.args[1]] = param.args[2]
    end
  end
  args
end

function modifyExpr(expr, symbols)
  start = 1
  if expr.head == :line
    new_expr = Expr(expr.head, expr.args...)
    start = length(expr.args) + 1
  elseif expr.head == :call
    new_expr = Expr(expr.head, expr.args[1])
    start = 2
  else
    new_expr = Expr(expr.head)
  end
  for i in start:length(expr.args)
    new_expr = modify
  end
  println(new_expr)
  new_expr
end

macro Process(name, expr, params...)
  symbols = getSymbols(expr)
  args = getArguments(params)
  proc_function = :(
    function $(Symbol(name, "Function"))(arg)
      $(modifyExpr(expr, symbols))
    end
  )
  println(proc_function)
  proc_type = :(
    type $(Symbol(name, "Process"))
      $(collect(symbols)...)
      func :: Function
    end
  )
  proc_constr = :(
    function $(Symbol(name, "Process"))($((:($arg) for (arg, val) in args)...))
      pr = new()
      $((:(pr.$arg = $arg) for arg in keys(args))...)
      pr.func = $(Symbol(name, "Function"))
      pr
    end
  )
  push!(proc_type.args[3].args, proc.constr)
  eval(proc_type)
  :()
end

c = 5

d = @Process MyTest begin
  if a > 0
    b = 2
  end
end a=>1 b=>c

println(d)
