workspace()

function fibonnaci_yield(super)
  a = 0.0
  println("hi")
  i = yieldto(super, a)
  println(i, " ", "ho")
  a
end

ct = current_task()
fib = @task fibonnaci_yield(ct)
for i = 1.0:5.0
  #if !istaskdone(fib)
    println(i, " ", fib.state)
    try
      #schedule(ct)
      println(yieldto(fib, i))
    catch
    end
  #end
end
