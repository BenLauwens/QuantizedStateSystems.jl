workspace()

type Process
  ch :: Channel
  v :: Any
end

function co(p::Process)
  for i = 1:100
    put!(p.ch, i)
    println(p.v)
  end
end

ch = Channel(0)
p = Process(ch, 0)
t = @task co(p)
bind(ch, t)
schedule(t)
yield()
for i = 1:100
  p.v = take!(ch)
end
