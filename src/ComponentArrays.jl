module ComponentArrays

using LinearAlgebra: Adjoint, Transpose
using Requires

const FlatIdx = Union{UnitRange, Int, CartesianIndex, AbstractArray{<:Int}}


include("utils.jl")
include("axis.jl")
include("componentindex.jl")
include("componentarray.jl")
include("set_get.jl")
include("similar_convert_copy.jl")
include("broadcasting.jl")
include("math.jl")
include("show.jl")


recarrtools_required() = include(joinpath("if_required", "recursivearraytools.jl"))

function __init__()
    @require RecursiveArrayTools="731186ca-8d62-57ce-b412-fbd966d074cd" recarrtools_required()
end


export Axis, PartitionedAxis, ShapedAxis, ViewAxis

export ComponentArray, ComponentVector, ComponentMatrix
export CArray, CVector, CMatrix
export getdata, getaxes, fastindices

end