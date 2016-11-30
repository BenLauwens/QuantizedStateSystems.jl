using TaylorSeries
using Polynomials
using Roots
using Plots

plotlyjs()
tₚ = Float64[]
xe₁ = Float64[]
xe₂ = Float64[]
x₁ = Float64[]
x₂ = Float64[]
q₁ = Float64[]
q₂ = Float64[]

function f₁(q::Vector)
  0.01*q[2]
end

function f₂(q::Vector)
  2020.0-100.0*q[1]-100.0*q[2]
end

function test(duration::Float64)
  λ, P = eig([0.0 0.01; -100.0 -100.0])
  Λ = diagm(λ)
  println(λ)
  C = inv(P)*[0.0; 2020.0]
  E = -C./λ
  D = -E + inv(P)*[0.0; 20.0]
  println(P*inv(Λ)*inv(P)*[0.0; 2020.0])
  #push!(tₚ, 0.0)
  #push!(xe₁, 0.0)
  #push!(xe₂, 20.0)
  for t in 0.0:1.0:duration
    xe = P*diagm(exp(λ*t))*inv(P)*[0.0; 20.0]+P*diagm((exp(λ*t)-1)./λ)*inv(P)*[0.0;2020.0]#P*(D.*exp(λ*(t))+E)
    push!(tₚ, t)
    push!(xe₁, xe[1])
    push!(xe₂, xe[2])
    println(xe)
  end
end

test(1500.0)
plot(tₚ, [xe₂])
