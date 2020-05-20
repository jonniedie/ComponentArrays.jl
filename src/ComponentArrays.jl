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


# If using for differential equations, the Array(sol) overload in RecursiveArrayTools will
# concatenate the ComponentVectors while preserving their ComponentArrayness
required(filename) = include(joinpath("if_required", filename))

function __init__()
    @require RecursiveArrayTools="731186ca-8d62-57ce-b412-fbd966d074cd" required("recursivearraytools.jl")
    @require StaticArrays="90137ffa-7385-5640-81b9-e52037218182" required("staticarrays.jl")
end


export AbstractAxis, Axis, PartitionedAxis, ShapedAxis, ViewAxis

export ComponentArray, ComponentVector, ComponentMatrix
export CArray, CVector, CMatrix

export getdata, getaxes, fastindices

end