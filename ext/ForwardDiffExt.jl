module ForwardDiffExt

using ComponentArrays
isdefined(Base, :get_extension) ? (using ForwardDiff) : (using ..ForwardDiff)

ForwardDiff.jacobian(f, x::ComponentArray, args...) = ForwardDiff.jacobian(f, getdata(x), args...)

end
