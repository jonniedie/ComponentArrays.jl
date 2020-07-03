module ComponentArrays

using ArrayInterface
using LinearAlgebra
using Requires

const FlatIdx = Union{UnitRange, Int, CartesianIndex, AbstractArray, Colon}


include("utils.jl")
include("axis.jl")
include("componentindex.jl")
include("componentarray.jl")
include("set_get.jl")
include("similar_convert_copy.jl")
include("broadcasting.jl")
include("math.jl")
include("show.jl")
include("plot_utils.jl")


# If using for differential equations, the Array(sol) overload in RecursiveArrayTools will
# concatenate the ComponentVectors while preserving their ComponentArrayness
required(filename) = include(joinpath("if_required", filename))

function __init__()
    @require ConstructionBase="187b0558-2788-49d3-abe0-74a17ed4e7c9" required("constructionbase.jl")
    @require DiffEqBase="2b5f629d-d688-5b77-993f-72d75c75574e" required("diffeqbase.jl")
    @require RecursiveArrayTools="731186ca-8d62-57ce-b412-fbd966d074cd" required("recursivearraytools.jl")
    @require StaticArrays="90137ffa-7385-5640-81b9-e52037218182" required("staticarrays.jl")
    @require Zygote="e88e6eb3-aa80-5325-afca-941959d7151f" required("zygote.jl")
end


export AbstractAxis, Axis, PartitionedAxis, ShapedAxis, ViewAxis, FlatAxis

export ComponentArray, ComponentVector, ComponentMatrix

export getdata, getaxes, fastindices, labels, label2index

end