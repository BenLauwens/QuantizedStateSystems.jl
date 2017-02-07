function play(f::Function, g::String)
  println(g)
  f("ha")
  println("ho")
end

function do_some()
  play("hi") do h
    println(h)
  end
end

do_some()

dump(:(
  play("hi") do h
    println(h)
  end
))

dump(:(
play((h)->println(h), "hi")
))
