macro yield(val)
  :($(esc(val)))
end

expr = quote
  a = 0.0
  b = 1.0
  while true
    try
      @yield return a
      a, b = b, a+b
    catch exc
      println(exc)
    end
  end
end

dump(expr.args[6].args[2].args[2])
