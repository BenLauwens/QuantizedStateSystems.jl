using Base.Test

testpath(f) = joinpath(dirname(@__FILE__), f)

for test_file in [
  "iterator_example.jl",
  "statefunctions.jl",
  "closure.jl",]
  include(testpath(test_file))
end
