workspace()

type StateMachineFibonnaci
  a :: BigInt
  b :: BigInt
  state :: UInt
  function StateMachineFibonnaci()
    stm = new()
    stm.state = 0
    stm
  end
end

function coroutine_fibonnaci(stm::StateMachineFibonnaci) :: BigInt
  if stm.state == 0
    @goto _state_start
  elseif stm.state == 1
    @goto _state_1
  elseif stm.state == 2
    @goto _state_2
  elseif stm.state == 3
    @goto _state_3
  elseif stm.state == 4
    @goto _state_4
  else
    @goto _state_end
  end
  @label _state_start
  stm.state = 999
  stm.a = BigInt(0)
  stm.b = BigInt(1)
  while true
    stm.a, stm.b = stm.b, stm.a+stm.b
    stm.state = 1
    return stm.a
    @label _state_1
    stm.state = 999
    stm.a, stm.b = stm.b, stm.a*stm.b
    stm.state = 2
    return stm.a
    @label _state_2
    stm.state = 999
    stm.a, stm.b = stm.b, stm.b-stm.a
    stm.state = 3
    return stm.a
    @label _state_3
    stm.state = 999
    stm.a, stm.b = stm.b, stm.a*stm.b
    stm.state = 4
    return stm.a
    @label _state_4
    stm.state = 999
  end
  @label _state_end
end

function time_stm(n::Int)
  stm = StateMachineFibonnaci()
  for i = 1:n
    coroutine_fibonnaci(stm)
  end
end

function task_fibonnaci() :: BigInt
  a = BigInt(0)
  b = BigInt(1)
  while true
    a, b = b, a+b
    produce(a)
    a, b = b, a*b
    produce(a)
    a, b = b, b-a
    produce(a)
    a, b = b, a*b
    produce(a)
  end
end

function time_tsk(n::Int)
  tsk = @task task_fibonnaci()
  for i = 1:n
    consume(tsk)
  end
end

@time time_stm(1)
@time time_tsk(1)
@time time_stm(100)
@time time_tsk(100)
