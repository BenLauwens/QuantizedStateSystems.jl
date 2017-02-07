workspace()

type FiniteStateMachine
  a :: Float64
end

function (fsm::FiniteStateMachine)(val::Any)
  if isa(val, Float64)
    fsm.a = val
  end
end

fsm = FiniteStateMachine(1.0)
println(fsm)
fsm(2.0)
println(fsm)
