using TaylorSeries
using PolynomialRoots

function f₁(q::Vector)
  0.01*q[2]
end

function f₂(q::Vector)
  2020.0-100.0*q[1]-100.0*q[2]
end

function bisect(f, qₘ, qₚ, i)
  fₘ = integrate(f(qₘ)).coeffs[end]
  fₚ = integrate(f(qₚ)).coeffs[end]
  while abs(fₘ) > 10e-6 && abs(fₚ) > 10e-6
    qₙ = qₘ[i].coeffs[1] - fₘ * (qₚ[i].coeffs[1] - qₘ[i].coeffs[1]) / (fₚ - fₘ)
    q = qₘ
    q[i].coeffs[1] = qₙ
    fₙ = integrate(f(qₚ)).coeffs[end]
    if fₙ*fₘ > 0.0
      qₘ = q
      fₘ = fₙ
    else
      qₚ = q
      fₚ = fₙ
    end
  end
  if abs(fₘ) < abs(fₚ)
    return qₘ
  else
    return qₚ
  end
end

f = [f₁, f₂]
Δq = 1.0
q = [Taylor1([0.0, 0.0]), Taylor1([20.0, 0.0])]
x = [integrate(f[1](q), 0.0), integrate(f[2](q), 20.0)]
tₓ = [0.0, 0.0]
tₙ = [0.0, 0.0]
tₐ = [0.0, 0.0]
t = 0.0
while t < 200.0
  t, i = findmin(tₙ)
  x[i] = evaluate(x[i], Taylor1([t, 1.0]))
  tₐ[i] = t
  qₚ = copy(q)
  qₚ[i] = x[i] + Δq
  qₚ[i].coeffs[end] = 0.0
  qₘ = copy(q)
  qₘ[i] = x[i] - Δq
  qₘ[i].coeffs[end] = 0.0
  xₚ = integrate(f[i](qₚ))
  xₘ = integrate(f[i](qₘ))
  if evaluate(qₚ[i]-xₚ)*xₚ.coeffs[end] > 0.0
    q[i] = qₚ[i]
    tₙ[i] += abs(Δq/xₚ.coeffs[end])
  elseif evaluate(qₘ[i]-xₘ)*xₘ.coeffs[end] > 0.0
    q[i] = qₘ[i]
    tₙ[i] += abs(Δq/xₘ.coeffs[end])
  else
    q[i] = bisect(f[i], qₘ, qₚ, i)
    tₙ[i] = Inf
  end
  for j = 1:2
    q[j] = evaluate(q[j], Taylor1([t-tₐ[j], 1.0]))
    tₐ[j] = t
  end
  for j = 1:2
    x₀ = evaluate(x[j], t-tₓ[j])
    tₓ[j] = t
    x[j] = integrate(f[j](q), x₀)
    println(roots((x[j]-q[j]).coeffs))
  end
  t = 300.0
end
