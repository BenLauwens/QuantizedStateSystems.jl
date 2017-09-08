using TaylorSeries
#using Plots

#plotlyjs()

tₚ = Float64[]
xe₁ = Float64[]
xe₂ = Float64[]
x₁ = Float64[]
x₂ = Float64[]
q₁ = Float64[]
q₂ = Float64[]

function linear(coeff::Vector{Float64})
  if coeff[2] == 0.0
    res = Complex{Float64}[Inf]
  else
    res = Complex{Float64}[-coeff[1] / coeff[2]]
  end
  return res
end

function quadratic(coeff::Vector{Float64})
  if coeff[3] == 0.0
    res = linear(coeff[1:2])
  else
    res = Array{Complex{Float64}}(2)
    if coeff[1] == 0.0
      res[1] = 0.0
      res[2] = linear(coeff[2:3])
    else
      if coeff[2] == 0.0
        r = -coeff[1] / coeff[3]
        if r < 0.0
          res[1] = sqrt(-r)*im
          res[2] = -imag(res[1])*im
        else
          res[1] = sqrt(r)
          res[2] = -real(res[1])
        end
      else
        Δ = 1.0 - 4coeff[1]*coeff[3] / (coeff[2]*coeff[2])
        if Δ < 0.0
          res[1] = -0.5coeff[2]/coeff[3]+0.5coeff[2]*sqrt(-Δ)/coeff[3]*im
          res[2] = real(res[1]) - imag(res[1])*im
        else
          q = -0.5*(1.0+sign(coeff[2])*sqrt(Δ))*coeff[2]
          res[1] = q / coeff[3]
          res[2] = coeff[1] / q
        end
      end
    end
  end
  return res
end

function cubic(coeff::Vector{Float64})
  if coeff[4] == 0.0
    res = quadratic(coeff[1:3])
  else
    res = Array{Complex{Float64}}(3)
    if coeff[1] == 0.0
      res[1] = 0.0
      res[2:3] = quadratic(coeff[2:4])
    else
      A = coeff[3]/coeff[4]
      B = coeff[2]/coeff[4]
      C = coeff[1]/coeff[4]
      Q = (A^2-3B)/9
      R = (2*A^3-9A*B+27C)/54
      S = -A/3
      if R^2 < Q^3
        P = -2*sqrt(Q)
        ϕ = acos(R/sqrt(Q^3))
        res[1] = P*cos(ϕ/3)+S
        res[2] = P*cos((ϕ+2π)/3)+S
        res[3] = P*cos((ϕ-2π)/3)+S
      else
        T = -sign(R)*cbrt(abs(R)+sqrt(R^2-Q^3))
        U = 0.0
        if T != 0.0
          U = Q/T
        end
        V = 0.5*(T+U)
        W = 0.5*sqrt(3)*(T-U)
        res[1] = S+2V
        res[2] = S-V+W*im
        res[3] = conj(res[2])
      end
    end
  end
  return res
end

function quartic(coeff::Vector{Float64})
  if coeff[5] == 0.0
    res = cubic(coeff[1:4])
  else
    res = Array{Complex{Float64}}(4)
    if coeff[1] == 0.0
      res[1] = 0.0
      res[2:4] = cubic(coeff[2:5])
    else
      a₀ = coeff[1]/coeff[5]
      a₁ = coeff[2]/coeff[5]
      a₂ = coeff[3]/coeff[5]
      a₃ = coeff[4]/coeff[5]
      y₁ = cubic([4a₂*a₀-a₁^2-a₃^2*a₀, a₁*a₃-4a₀, -a₂, 1.0])[1]
      R = sqrt(0.25a₃^2-a₂+y₁)
      if R == 0.0
        A = 0.75a₃^2-2a₂
        B = 2*sqrt(y₁^2-4a₀)
      else
        A = 0.75a₃^2-R^2-2a₂
        B = (a₃*a₂-2a₁-0.25a₃^3)/R
      end
      D = sqrt(A+B)
      E = sqrt(A-B)
      res[1] = -0.25a₃+0.5R+0.5D
      res[2] = res[1]-D
      res[3] = -0.25a₃-0.5R+0.5E
      res[4] = res[3]-E
    end
  end
  return res
end

function roots(coeff::Vector{Float64}) :: Vector{Complex{Float64}}
  n = length(coeff)
  if n == 1
    res = Complex{Float64}[]
  elseif n == 2
    res = linear(coeff)
  elseif n == 3
    res = quadratic(coeff)
  elseif n == 4
    res = cubic(coeff)
  elseif n == 5
    res = quartic(coeff)
  else
    if coeff[n] == 0.0
      res = roots(coeff[1:n-1])
    else
      res = Array{Complex{Float64}}(n-1)
      if coeff[1] == 0.0
        res[1] = 0.0
        res[2:n-1] = roots(coeff[2:n])
      else
        mat = zeros(Float64, n-1, n-1)
        mat[2:n-1, 1:n-2] = eye(Float64, n-2)
        mat[:, n-1] = - coeff[1:n-1] / coeff[n]
        res[1:n-1] = eigvals(mat)
        #res[1:n-1] = roots(Poly(coeff))
      end
    end
  end
  return res
end

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

function integrate_ode(f::Function, q₀::Float64, q::Vector{Taylor1{Float64}}, order::Int, i::Int)
  q[i].coeffs[2:end] = 0.0
  q[i].coeffs[1] = q₀
  for n in 1:order
    q[i].coeffs[n+1] = f(q).coeffs[n]/n
  end
  q[i]
end

function nth_derivative(q₀::Float64, f::Function, q::Vector{Taylor1{Float64}}, order::Int, i::Int)
  q[i].coeffs[2:end] = 0.0
  q[i].coeffs[1] = q₀
  q[i] = integrate(f(q), q₀)
  for k in 1:order-1
    q[i] = integrate(f(q), q₀)
  end
  q[i].coeffs[end]
  #integrate_ode(f, q₀, q, order, i).coeffs[end]
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
  q = [0*Taylor1(zeros(order+1))+0.0, 0*Taylor1(zeros(order+1))+20.0]
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
  while t < duration && sum(it) < 100000
    tₒ = t
    t, i = findmin(tₙ)
    ##println("-------- $tₙ, $i")
    j = 3 - i
    it[i] += 1
    xe = P*diagm(exp.(λ*t))*inv(P)*[0.0; 20.0]+P*diagm((exp.(λ*t)-1)./λ)*inv(P)*[0.0;2020.0]
    if t-tₒ > 0.0
      for tt in 0.0:(t-tₒ)/20:t-tₒ
        xe = P*diagm(exp.(λ*(tₒ+tt)))*inv(P)*[0.0; 20.0]+P*diagm((exp.(λ*(tₒ+tt))-1)./λ)*inv(P)*[0.0;2020.0]
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
    ##println("$t, $i, q = $(q[i])")
    q[j] = evaluate(q[j], Taylor1([t-tₒ, 1.0]))
    ##println("$t, $j, q = $(q[j])")
    q[i] = deepcopy(x[i])
    q[i][end] = 0.0
    tₙ[i] = t + (abs(Δq/x[i].coeffs[end]))^(1.0/order)
    #println("$t, $i, q = $(q[i])")
    #println("$t, $i, x = $(x[i])")
    x₀ = evaluate(x[j], t-tₒ)
    x[j] = integrate(f[j](q), x₀)
    #println("$t, $j, x = $(x[j])")
    p = (x[j]-q[j]).coeffs
    p[1] -= Δq
    a = roots(p)
    p[1] += 2Δq
    b = roots(p)
    r = filter(v->abs(imag(v)) < 1.0e-15 && real(v)>=0.0, [a..., b...])
    min_r = Inf
    for val_r in r
      if real(val_r) < min_r
        min_r = real(val_r)
      end
    end
    tₙ[j] = t + min_r
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
δ = 1e-6
@time test(4, δ, 500.0)
#plot(tₚ, [abs(x₁-xe₁), abs(x₂-xe₂)])
println("$(mean(abs.(x₁-xe₁))), $(maximum(abs.(x₁-xe₁))), $(mean(abs.(x₂-xe₂))), $(maximum(abs.(x₂-xe₂))), $(2δ)")
#plot(tₚ, [x₁, q₁, xe₁, x₂, q₂, xe₂])
