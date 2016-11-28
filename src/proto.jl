using TaylorSeries
using Polynomials
using Roots
using NLsolve
using Plots

plotlyjs()
tₚ = Float64[]
xa₁ = Float64[]
xa₂ = Float64[]
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

function nth_derivative(q₀::Vector{Float64}, res::Vector{Float64}, f::Function, q::Vector{Taylor1{Float64}}, i::Int)
  q[i].coeffs[1:end-1] = q₀
  x = integrate(f(q))
  res[1:end-1] = x.coeffs[2:end-1] - q₀[2:end]
  res[end] = x.coeffs[end]
end

function test(order::Int, Δq::Float64)
  λ, P = eig([0.0 0.01; -100.0 -100.0])
  C = inv(P)*[0.0; 2020.0]
  E = -C./λ
  D = -E + inv(P)*[0.0; 20.0]
  f = [f₁, f₂]
  q = [Taylor1(zeros(order+1))+0.0, Taylor1(zeros(order+1))+20.0]
  x = [integrate(f[1](q), 0.0), integrate(f[2](q), 20.0)]
  println(x)
  for i in 1:order-1
    x = [integrate(f[1](x), 0.0), integrate(f[2](x), 20.0)]
    println(x)
  end
  q = deepcopy(x)
  q[1].coeffs[end] = 0.0
  q[2].coeffs[end] = 0.0
  #q[1].coeffs[1] = 0.0 + 0.5*sign(x[1].coeffs[end])*Δq
  #q[2].coeffs[1] = 20.0 + 0.5*sign(x[2].coeffs[end])*Δq
  tₓ = [0.0, 0.0]
  tₙ = [0.0, 0.0]
  tₐ = [0.0, 0.0]
  t = 0.0
  tₒ = 0.0
  it = [0, 0]
  start = true
  while t < 2000.0
    t, i = findmin(tₙ)
    it[i] += 1
    xₐ = P*(D.*exp(λ*t)+E)
    if t-tₒ > 0.0
      for tt in 0.0:(t-tₒ)/3:t-tₒ
        push!(tₚ, tₒ+tt)
        push!(x₁, evaluate(x[1], tt))#x[1].coeffs[1])
        push!(x₂, evaluate(x[2], tt))#x[2].coeffs[1])
        push!(q₁, evaluate(q[1], tt))#q[1].coeffs[1])
        push!(q₂, evaluate(q[2], tt))#q[2].coeffs[1])
        push!(xa₁, (P*(D.*exp(λ*(tₒ+tt))+E))[1])
        push!(xa₂, (P*(D.*exp(λ*(tₒ+tt))+E))[2])
      end
    end
    x[i] = evaluate(x[i], Taylor1([t-tₓ[i], 1.0]))
    tₓ[i] = t
    j = 3 - i
    q[j] = evaluate(q[j], Taylor1([t-tₐ[j], 1.0]))
    println("----q_$j: $(q[j])")
    tₐ[j] = t
    #  q̲ = deepcopy(q)
    #  q̲[i] = x[i]-Δq
    #  q̲[i].coeffs[end] = 0.0
    #  x̲ = integrate(f[i](q̲), x[i].coeffs[1])
    #  q̅ = deepcopy(q)
    #  q̅[i] = x[i]+Δq
    #  q̅[i].coeffs[end] = 0.0
    #  x̅ = integrate(f[i](q̅), x[i].coeffs[1])
    #  println("----q̲: $(q̲[i])")
    #  println("----q̅: $(q̅[i])")
    #  println("----x̲: $(x̲)")
    #  println("----x̅: $(x̅)")
    # if sign(x̲.coeffs[end]) == sign(x̅.coeffs[end]) == sign(x[i].coeffs[end])
    #   if x̲.coeffs[end] > 0.0
    #     q[i] = deepcopy(q̅[i])
    #     x[i] = deepcopy(x̅)
    #   else
    #     q[i] = deepcopy(q̲[i])
    #     x[i] = deepcopy(x̲)
    #   end
    qₙ = deepcopy(q)
    if x[i].coeffs[end] > 0.0
      qₙ[i] = x[i]+Δq
    else
      qₙ[i] = x[i]-Δq
    end
    qₙ[i].coeffs[end] = 0.0
    xₙ = integrate(f[i](qₙ), x[i].coeffs[1])
    println("----x_$i: $(x[i])")
    println("----xₙ: $xₙ")
    if sign(xₙ.coeffs[end]) == sign(x[i].coeffs[end])
      q[i] = deepcopy(qₙ[i])
      x[i] = deepcopy(xₙ)
      if x[i].coeffs[2:end] == q[i].coeffs[2:end]
        tₙ[i] = Inf
      else
        p = x[i].coeffs-q[i].coeffs
        p[1] = -Δq
        a = fzeros(Poly(p))
        p[1] = Δq
        b = fzeros(Poly(p))
        # a = fzeros(Poly((x[j]-q[j]-δq[j]-Δq).coeffs))
        # b = fzeros(Poly((x[j]-q[j]-δq[j]+Δq).coeffs))
        tₙ[i] = t + minimum(filter(v->v>0, [a..., b..., Inf]))
        #tₙ[j] = t + minimum([filter(v->v>0, fzeros(Poly(p)))..., Inf])
      end
    else
      q₀ = deepcopy(q[i].coeffs[1:end-1])
      q₀[1] = deepcopy(x[i].coeffs[1])
      q[i].coeffs[1:end-1] = nlsolve((qᵢ, res)->nth_derivative(qᵢ, res, f[i], deepcopy(q), i), q₀).zero
      tₙ[i] = Inf
      #x[i] = integrate(f[i](q), xₙ.coeffs[1])
      x[i] = deepcopy(q[i])
      #x[i].coeffs[1] = x̲.coeffs[1]
      x[i].coeffs[1] = xₙ.coeffs[1]
      if abs(q[i].coeffs[1]-x[i].coeffs[1]) > Δq# && tₒ != t
        #q[i].coeffs[1] = x[i].coeffs[1] - sign(q[i].coeffs[1]+x[i].coeffs[1]) * Δq
        #tₙ[i] = t
        x[i].coeffs[1] = q[i].coeffs[1] - 0.5*sign(q[i].coeffs[1]-x[i].coeffs[1]) * Δq
      end
    end
    println("----q_$i: $(q[i])")
    tₐ[i] = t
    # qₑ = Taylor1[]
    # push!(qₑ, Taylor1([x[1].coeffs..., 0.0]))
    # push!(qₑ, Taylor1([x[2].coeffs..., 0.0]))
    # xₑ = integrate(f[i](qₑ), x[i].coeffs[1])
    # println(xₑ)
    # tₑ = t-xₑ.coeffs[end-1]/xₑ.coeffs[end]/(order+1)
    # println(tₑ)
    # if tₑ > 0 && tₑ < tₙ[i]
    #   tₙ[i] = tₑ
    # end
     println("----t_$i: $(tₙ[i])")
     println("----x_$i: $(x[i])")
    #for j = 1:2
      x₀ = evaluate(x[j], t-tₓ[j])
      tₓ[j] = t
      x[j] = integrate(f[j](q), x₀)
      println("----x_$j: $(x[j])")
      if x[j].coeffs[2:end] == q[j].coeffs[2:end]
        tₙ[j] = Inf
      else
        p = x[j].coeffs-q[j].coeffs
        p[1] = -Δq
        a = fzeros(Poly(p))
        p[1] = Δq
        b = fzeros(Poly(p))
        # a = fzeros(Poly((x[j]-q[j]-δq[j]-Δq).coeffs))
        # b = fzeros(Poly((x[j]-q[j]-δq[j]+Δq).coeffs))
        tₙ[j] = t + minimum(filter(v->v>0, [a..., b..., Inf]))
        #tₙ[j] = t + minimum([filter(v->v>0, fzeros(Poly(p)))..., Inf])
      end
      println("----t_$j: $(tₙ[j])")
    #end
    tₒ = t
    println("$t $i $(xₐ[1]) $(abs(x[1].coeffs[1]-xₐ[1])) $(xₐ[2]) $(abs(x[2].coeffs[1]-xₐ[2]))")
  end
  println(it)
end

test(4, 0.00005)
plot(tₚ, [x₁-xa₁, x₂-xa₂])
