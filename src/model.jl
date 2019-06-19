abstract type AbstractModel end

struct Model <: AbstractModel

  function Model()

  end
end

macro model(expr::Expr)
  expr.head != :function && error("Expression is not a function definition!")
  func_def = splitdef(expr)
  dump(func_def)
  nothing
end