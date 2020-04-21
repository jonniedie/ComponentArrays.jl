module ComponentArrays

using LinearAlgebra: Adjoint

const FlatIdx = Union{UnitRange, Int, CartesianIndex, AbstractArray{<:Int}}

include("Axis.jl")
include("CArray.jl")
include("set_get.jl")
include("broadcasting.jl")
include("math.jl")

export Axis, NAxis
export CArray, CVector, CMatrix

end # module
