ForwardDiff.jacobian(f, x::ComponentArray, args...) = ForwardDiff.jacobian(f, getdata(x), args...)
