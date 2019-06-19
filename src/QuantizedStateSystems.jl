isdefined(Base, :__precompile__) && __precompile__()

"""
Main module for QuantizedStateSystems.jl
"""
module QuantizedStateSystems

  using MacroTools
  using TaylorSeries

  export @model 

  include("model.jl")
  include("quantizer.jl")
  include("integrator.jl")

end