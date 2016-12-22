using ODE
using Plots

function f₁(q::Vector)
  0.01*q[2]
end

function f₂(q::Vector)
  2020.0-100.0*q[1]-100.0*q[2]
end

function f(t::Float64, q::Vector{Float64})
  [f₁(q), f₂(q)]
end

@time t, x = ode4s(f, [0.0, 20.0], 0.0:1.5:500.0;reltol=1.0e-9)

λ, P = eig([0.0 0.01; -100.0 -100.0])
C = inv(P)*[0.0; 2020.0]
E = -C./λ
D = -E + inv(P)*[0.0; 20.0]


x₁ = Vector{Float64}()
x₂ = Vector{Float64}()
xe₁ = Vector{Float64}()
xe₂ = Vector{Float64}()
for v in x
  push!(x₁, v[1])
  push!(x₂, v[2])
end

for tt in t
  xe = P*diagm(exp(λ*(tt)))*inv(P)*[0.0; 20.0]+P*diagm((exp(λ*(tt))-1)./λ)*inv(P)*[0.0;2020.0]
  push!(xe₁, xe[1])
  push!(xe₂, xe[2])
end

plot(t, [x₁, x₂, xe₁, xe₂])
gui()
println("$(mean(abs(x₁-xe₁))), $(maximum(abs(x₁-xe₁))), $(mean(abs(x₂-xe₂))), $(maximum(abs(x₂-xe₂)))")
