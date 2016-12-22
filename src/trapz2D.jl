function trapz2D(f::Function, low::Vector{Float64}, high::Vector{Float64}, steps::Vector{Int})
  mask = ones(Float64, steps[1], steps[2])
  mask[1,:] /= 2
  mask[end,:] /= 2
  mask[:,1] /= 2
  mask[:,end] /= 2
  x = linspace(low[1], high[1], steps[1])
  y = linspace(low[2], high[2], steps[2])
  xx = repmat(x, 1, steps[2])
  yy = repmat(transpose(y), steps[1], 1)
  sum(f(xx, yy).*mask)*prod(high - low)/prod(steps-1)
end

println(trapz2D((x,y)->x.^2+y.^2, [0.0, 0.0], [1.0, 2.0], [120, 130]))
