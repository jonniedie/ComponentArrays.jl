module ComponentArrays

using LinearAlgebra: Adjoint

const FlatIdx = Union{UnitRange, Int, CartesianIndex}

include("Axis.jl")
include("CArray.jl")
include("set_get.jl")
include("broadcasting.jl")
include("math.jl")

export Axis, CArray

end # module
