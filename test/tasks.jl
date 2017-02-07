type Process
  t :: Task
  function Process()
    new()
  end
end

function fibonnaci(t::Task)
  a = 0.0
  b = 1.0
  println("hi")
  for i = 1:20
    println(yieldto(t, a))
    a, b = b, a+b
  end
  println("ho")
  yieldto(t, a)
end

ct = current_task()
t = @task fibonnaci(ct)
a = yieldto(t)
for i = 1:20
  println("ha")
  a = yieldto(t, a)
end
println("he")
