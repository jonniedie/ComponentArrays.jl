module ComponentArrays

using LinearAlgebra: Adjoint, Transpose

const FlatIdx = Union{UnitRange, Int, CartesianIndex, AbstractArray{<:Int}}

include("utils.jl")
include("Axis.jl")
include("CArray.jl")
include("set_get.jl")
include("similar_convert_copy.jl")
include("broadcasting.jl")
include("math.jl")
include("show.jl")

export Axis, NAxis
export CArray, CVector, CMatrix
export getaxes, getdata
export fastindices

end # module
