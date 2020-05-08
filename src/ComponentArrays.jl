module ComponentArrays

using LinearAlgebra: Adjoint, Transpose

const FlatIdx = Union{UnitRange, Int, CartesianIndex, AbstractArray{<:Int}}

include("utils.jl")
include("axis.jl")
include("componentarray.jl")
include("set_get.jl")
include("similar_convert_copy.jl")
include("broadcasting.jl")
include("math.jl")
include("show.jl")

export Axis, NAxis
export ComponentArray, CArray, CVector, CMatrix
export getaxes, getdata
export fastindices

end # module
