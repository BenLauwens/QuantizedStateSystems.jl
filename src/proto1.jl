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

function brent(f::Function, x0::Number, x1::Number, args...;
               xtol::AbstractFloat=1e-7, ytol=2eps(Float64),
               maxiter::Integer=50)
    EPS = eps(Float64)
    y0 = f(x0,args...)
    y1 = f(x1,args...)
    if abs(y0) < abs(y1)
        # Swap lower and upper bounds.
        x0, x1 = x1, x0
        y0, y1 = y1, y0
    end
    x2 = x0
    y2 = y0
    x3 = x2
    bisection = true
    for _ in 1:maxiter
        # x-tolerance.
        if abs(x1-x0) < xtol
            return x1
        end

        # Use inverse quadratic interpolation if f(x0)!=f(x1)!=f(x2)
        # and linear interpolation (secant method) otherwise.
        if abs(y0-y2) > ytol && abs(y1-y2) > ytol
            x = x0*y1*y2/((y0-y1)*(y0-y2)) +
                x1*y0*y2/((y1-y0)*(y1-y2)) +
                x2*y0*y1/((y2-y0)*(y2-y1))
        else
            x = x1 - y1 * (x1-x0)/(y1-y0)
        end

        # Use bisection method if satisfies the conditions.
        delta = abs(2EPS*abs(x1))
        min1 = abs(x-x1)
        min2 = abs(x1-x2)
        min3 = abs(x2-x3)
        if (x < (3x0+x1)/4 && x > x1) ||
           (bisection && min1 >= min2/2) ||
           (!bisection && min1 >= min3/2) ||
           (bisection && min2 < delta) ||
           (!bisection && min3 < delta)
            x = (x0+x1)/2
            bisection = true
        else
            bisection = false
        end

        y = f(x,args...)
        # y-tolerance.
        if abs(y) < ytol
            return x
        end
        x3 = x2
        x2 = x1
        if sign(y0) != sign(y)
            x1 = x
            y1 = y
        else
            x0 = x
            y0 = y
        end
        if abs(y0) < abs(y1)
            # Swap lower and upper bounds.
            x0, x1 = x1, x0
            y0, y1 = y1, y0
        end
    end
    error("Max iteration exceeded")
end

function nth_derivative(q₀::Float64, f::Function, q::Vector{Taylor1{Float64}}, order::Int, i::Int)
  q[i].coeffs[2:end] = 0.0
  q[i].coeffs[1] = q₀
  q[i] = integrate(f(q), q₀)
  for k in 1:order-1
    q[i] = integrate(f(q), q₀)
  end
  q[i].coeffs[end]
end

function nth_derivative_time(t₀, f::Function, q::Vector{Taylor1{Float64}}, order::Int, i::Int)
  qq = deepcopy(q)
  for (j, ta) in enumerate(qq)
    qq[j] = evaluate(ta, Taylor1([0, t₀]))
  end
  q₀ = qq[i].coeffs[1]
  qq[i].coeffs[2:end] = 0.0
  qq[i].coeffs[1] = q₀
  qq[i] = integrate(f(qq), q₀)
  for k in 1:order-1
    qq[i] = integrate(f(qq), q₀)
  end
  println("$t₀, $(qq[i].coeffs[end])")
  qq[i].coeffs[end]
end

function f₁(q::Vector)
  0.01*q[2]
end

function f₂(q::Vector)
  2020.0-100.0*q[1]-100.0*q[2]
end

function test(order::Int, Δq::Float64, duration::Float64)
  λ, P = eig([0.0 0.01; -100.0 -100.0])
  C = inv(P)*[0.0; 2020.0]
  E = -C./λ
  D = -E + inv(P)*[0.0; 20.0]
  f = [f₁, f₂]
  q = [Taylor1(zeros(order+1))+0.0, Taylor1(zeros(order+1))+20.0]
  x = [integrate(f[1](q), 0.0), integrate(f[2](q), 20.0)]
  for i in 1:order-1
    q = deepcopy(x)
    x = [integrate(f[1](q), 0.0), integrate(f[2](q), 20.0)]
  end
  #q = deepcopy(x)
  #q[1].coeffs[end] = 0.0
  #q[2].coeffs[end] = 0.0
  tₙ = [0.0, 0.0]
  t = 0.0
  it = [0, 0]
  start = true
  while t < duration && sum(it) < 10000
    tₒ = t
    t, i = findmin(tₙ)
    println("-------- $tₙ, $i")
    j = 3 - i
    it[i] += 1
    xe = P*diagm(exp(λ*t))*inv(P)*[0.0; 20.0]+P*diagm((exp(λ*t)-1)./λ)*inv(P)*[0.0;2020.0]
    if t-tₒ > 0.0
      for tt in 0.0:(t-tₒ)/20:t-tₒ
        xe = P*diagm(exp(λ*(tₒ+tt)))*inv(P)*[0.0; 20.0]+P*diagm((exp(λ*(tₒ+tt))-1)./λ)*inv(P)*[0.0;2020.0]
        push!(tₚ, tₒ+tt)
        push!(x₁, evaluate(x[1], tt))#x[1].coeffs[1])
        push!(x₂, evaluate(x[2], tt))#x[2].coeffs[1])
        push!(q₁, evaluate(q[1], tt))#q[1].coeffs[1])
        push!(q₂, evaluate(q[2], tt))#q[2].coeffs[1])
        push!(xe₁, xe[1])
        push!(xe₂, xe[2])
      end
    end
    x₀ = evaluate(x[i], t-tₒ)
    x[i] = evaluate(x[i], Taylor1([t-tₒ, 1.0]))
    q[i] = evaluate(q[i], Taylor1([t-tₒ, 1.0]))
    println("$t, $i, q = $(q[i])")
    q[j] = evaluate(q[j], Taylor1([t-tₒ, 1.0]))
    println("$t, $j, q = $(q[j])")
    q̲ = deepcopy(q)
    q̲[i] = Taylor1(zeros(order+1))+x₀-Δq
    x̲ = integrate(f[i](q̲), x₀)
    for k in 1:order-1
      q̲[i] = x̲-Δq
      x̲ = integrate(f[i](q̲), x₀)
    end
    println("$t, $i, x̲ = $x̲")
    q̲[i] = x̲-Δq
    q̲[i].coeffs[end] = 0.0
    q̅ = deepcopy(q)
    q̅[i] = Taylor1(zeros(order+1))+x₀+Δq
    x̅ = integrate(f[i](q̅), x₀)
    for k in 1:order-1
      q̅[i] = x̅+Δq
      x̅ = integrate(f[i](q̅), x₀)
    end
    println("$t, $i, x̅ = $x̅")
    q̅[i] = x̅+Δq
    q̅[i].coeffs[end] = 0.0
    println("$t, $i, x = $(x[i])")
    if x̲.coeffs[end] * x̅.coeffs[end] > 0.0
      if x̅.coeffs[end] > 0.0
        x[i] = deepcopy(x̅)
        q = deepcopy(q̅)
        #q[i] = deepcopy(x[i])
        #q[i].coeffs[1] += Δq
        #q[i].coeffs[end] = 0.0
      else
        x[i] = deepcopy(x̲)
        q = deepcopy(q̲)
        #q[i] = deepcopy(x[i])
        #q[i].coeffs[1] -= Δq
        #q[i].coeffs[end] = 0.0
      end
      #x[i] = integrate(f[i](q), x₀)
      tₙ[i] = t + (abs(Δq/x[i].coeffs[end]))^(1.0/order)
      # if x[i].coeffs[2:end] == q[i].coeffs[2:end]
      #   tₙ[i] = Inf
      # else
      #   p = x[i].coeffs-q[i].coeffs
      #   p[1] = -Δq
      #   a = roots(Poly(p))
      #   p[1] = Δq
      #   b = roots(Poly(p))
      #   r = filter(v->abs(imag(v)) < 1.0e-15 && real(v)>=0.0, [a..., b...])
      #   min_r = Inf
      #   for val_r in r
      #     if real(val_r) < min_r
      #       min_r = real(val_r)
      #     end
      #   end
      #   tₙ[i] = t + min_r
      # end
      # t₂ = brent(nth_derivative_time, 0.0, tₙ[i]-t, f[i], deepcopy(q), order, i)
      # println("$(tₙ[i]), $(t₂+t)")
      # if t₂ > 0.0 && t + t₂ < tₙ[i]
      #   tₙ[i] = t + t₂
      # end
    # if x[i].coeffs[end] > 0.0
    #   q[i] = Taylor1(zeros(order+1))+x₀+Δq
    #   x̃ = integrate(f[i](q), x₀)
    #   for k in 1:order-1
    #      q[i] = x̃+Δq
    #      x̃ = integrate(f[i](q), x₀)
    #   end
    # else
    #   q[i] = Taylor1(zeros(order+1))+x₀-Δq
    #   x̃ = integrate(f[i](q), x₀)
    #   for k in 1:order-1
    #      q[i] = x̃-Δq
    #      x̃ = integrate(f[i](q), x₀)
    #   end
    # end
    # println("$t, $i, x = $(x[i])")
    # println("$t, $i, x̃ = $(x̃)")
    # if x̃.coeffs[end] * x[i].coeffs[end] > 0.0
    #   x[i] = deepcopy(x̃)
    #   tₙ[i] = t + (abs(Δq/x[i].coeffs[end]))^(1.0/order)
    #   # q₀ = copy(q[i].coeffs[1])
    #   # q[i] = deepcopy(x[i])
    #   # q[i].coeffs[1] = q₀
    #   # q[i].coeffs[end] = 0.0
    #   # x[i] = integrate(f[i](q), x₀)
    #   # for k in 1:order-1
    #   #    q[i] = deepcopy(x[i])
    #   #    q[i].coeffs[1] = q₀
    #   #    x[i] = integrate(f[i](q), x₀)
    #   # end
    #   # p = x[i].coeffs-q[i].coeffs
    #   # p[1] = -Δq
    #   # a = roots(Poly(p))
    #   # p[1] = Δq
    #   # b = roots(Poly(p))
    #   # r = filter(v->abs(imag(v)) < 1.0e-15 && real(v)>=0.0, [a..., b...])
    #   # min_r = Inf
    #   # for val_r in r
    #   #   if real(val_r) < min_r
    #   #     min_r = real(val_r)
    #   #   end
    #   # end
    #   # tₙ[i] = t + min_r
    # elseif x[i].coeffs[end] > 0.0 && x[i].coeffs[end] * x̅.coeffs[end] > 0.0
    #   x[i] = deepcopy(x̅)
    #   q = deepcopy(q̅)
    #   tₙ[i] = t + (abs(Δq/x[i].coeffs[end]))^(1.0/order)
    # elseif x[i].coeffs[end] < 0.0 && x[i].coeffs[end] * x̲.coeffs[end] > 0.0
    #   x[i] = deepcopy(x̲)
    #   q = deepcopy(q̲)
    #   tₙ[i] = t + (abs(Δq/x[i].coeffs[end]))^(1.0/order)
    else
      q̃ = brent(nth_derivative, x₀-Δq, x₀+Δq, f[i], deepcopy(q), order, i; xtol=min(Δq/100,1e-7))
      q[i] = Taylor1(zeros(order+1))+q̃
      x[i] = integrate(f[i](q), x₀)
      for k in 1:order-1
        q[i] = deepcopy(x[i])
        q[i].coeffs[1] = q̃
        x[i] = integrate(f[i](q), x₀)
      end
      q[i].coeffs[end] = 0.0
      if x[i].coeffs[2:end] == q[i].coeffs[2:end]
        tₙ[i] = Inf
      else
        p = x[i].coeffs-q[i].coeffs
        p[1] = -Δq
        a = roots(Poly(p))
        p[1] = Δq
        b = roots(Poly(p))
        r = filter(v->abs(imag(v)) < 1.0e-15 && real(v)>=0.0, [a..., b...])
        min_r = Inf
        for val_r in r
          if real(val_r) < min_r
            min_r = real(val_r)
          end
        end
        tₙ[i] = t + min_r
      end
    end
    println("$t, $i, q = $(q[i])")
    println("$t, $i, x = $(x[i])")
    x₀ = evaluate(x[j], t-tₒ)
    x[j] = integrate(f[j](q), x₀)
    println("$t, $j, x = $(x[j])")
    if x[j].coeffs[2:end] == q[j].coeffs[2:end]
      tₙ[j] = Inf
    else
      p = x[j].coeffs-q[j].coeffs
      p[1] = -Δq
      a = roots(Poly(p))
      p[1] = Δq
      b = roots(Poly(p))
      r = filter(v->abs(imag(v)) < 1.0e-15 && real(v)>=0.0, [a..., b...])
      min_r = Inf
      for val_r in r
        if real(val_r) < min_r
          min_r = real(val_r)
        end
      end
      tₙ[j] = t + min_r
    end
    # t₂ = brent(nth_derivative_time, 0.0, tₙ[j]-t, f[j], deepcopy(q), order, i)
    # println("$(tₙ[j]), $(t₂+t)")
    # if t₂ > 0.0 && t + t₂ < tₙ[j]
    #   tₙ[j] = t + t₂
    # end
    # if start
    #   tₙ[j] = 0.0
    #   start = false
    # end
  end
  println(it)
end
δ = 5e-8
test(4, δ, 500.0)
plot(tₚ, [abs(x₁-xe₁), abs(x₂-xe₂)])

#plot(tₚ, [x₁, q₁, xe₁, x₂-20.0, q₂-20.0, xe₂-20.0])
gui()

println("$(mean(abs(x₂-xe₂))), $(maximum(abs(x₂-xe₂))), $(2δ)")
