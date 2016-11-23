module QuantizedStateSystems

  using TaylorSeries

  type Variable

  end

  type Model

  end

  abstract Quantizer

  type ExplicitQuantizer <: Quantizer

  end

  type Integrator{Q<:Quantizer}
    quantizer :: Q
    function Integrator()

    end

  end

end
