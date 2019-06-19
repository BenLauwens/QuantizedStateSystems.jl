using QuantizedStateSystems

@model function my_model(t, x)
  dx = t*x
end