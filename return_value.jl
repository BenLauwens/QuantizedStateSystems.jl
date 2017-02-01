macro yield(val)
  :($(esc(val)))
end

expr = :(function my_test(fsm)
    @yield return 1.0
    while true
      if 3 > 2
        b = @yield return 2.0
      else
        println(@yield return 3.0)
      end
    end
  end
)

Meta.show_sexpr(expr)

function transform1(expr::Expr, syms::Vector{Symbol}=Symbol[])
  line = false
  for (i, arg) in enumerate(expr.args)
    println(arg)
    if isa(arg, Expr) && arg.head == :line
      line = true
      continue
    elseif isa(arg, Expr) && arg.head ==:macrocall && arg.args[1] == Symbol("@yield")
      expr.args[i] = arg.args[2]
      sym = gensym()
      insert!(expr.args, i, :(fms.state = $sym))

      push!(syms, sym)
      insert!(expr.args, i+2, :(fms.state = :_stop))
      insert!(expr.args, i+2, Expr(:symboliclabel, :($sym)))

    elseif line
      syms = transform2(expr, arg, i, syms)
      line = false
    else
      syms = transform1(arg, syms)
    end
  end
  syms
end

transform1(arg, syms::Vector{Symbol}) = syms

function transform2(super::Expr, expr::Expr, line_no::Int, syms::Vector{Symbol})
  for (i, arg) in enumerate(expr.args)
    println(arg)
    if isa(arg, Expr) && arg.head == :line
      line_no = i+1
      super = expr
      continue
    elseif isa(arg, Expr) && arg.head == :macrocall && arg.args[1] == Symbol("@yield")
      expr.args[i] = :(fsm._ret)
      sym = gensym()
      push!(syms, sym)
      insert!(super.args, line_no, :(fms.state = :_stop))
      insert!(super.args, line_no, Expr(:symboliclabel, :($sym)))
      insert!(super.args, line_no, arg.args[2])
      insert!(super.args, line_no, :(fms.state = $sym))
    else
      syms = transform2(super, arg, line_no, syms)
    end
  end
  syms
end

transform2(super::Expr, arg, line_no, syms::Vector{Symbol}) = syms

syms = transform1(expr)

println(expr)

dump(syms)
