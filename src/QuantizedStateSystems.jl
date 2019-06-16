isdefined(Base, :__precompile__) && __precompile__()

"""
Main module for QuantizedStateSystems.jl
"""
module QuantizedStateSystems

  include("model.jl")
  include("quantizer.jl")
  include("integrator.jl")

end