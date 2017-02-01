function play(f::Function)
  println("hi")
  f()
  println("ho")
end

function do_some()
@goto _jump
  for i in 1:4
    play() do
      @label _jump
      println("ha")
    end
  end
end

do_some()
