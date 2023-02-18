module ComponentArrays

import ChainRulesCore
import StaticArrayInterface, ArrayInterface

using LinearAlgebra
using Requires

const FlatIdx = Union{Integer, CartesianIndex, CartesianIndices, AbstractArray{<:Integer}}
const FlatOrColonIdx = Union{FlatIdx, Colon}


include("utils.jl")
export fastindices # Deprecated

include("lazyarray.jl")

include("axis.jl")
export AbstractAxis, Axis, PartitionedAxis, ShapedAxis, ViewAxis, FlatAxis

include("componentarray.jl")
export ComponentArray, ComponentVector, ComponentMatrix, getaxes, getdata, valkeys

include("componentindex.jl")
export KeepIndex

include("array_interface.jl")
# Base methods: parent, size, elsize, axes, reinterpret, hcat, vcat, permutedims, IndexStyle, to_indices, to_index, getindex, setindex!, view, pointer, unsafe_convert, strides, stride
# StaticArrayInterface methods: strides, size, parent_type

include("linear_algebra.jl")
# Base methods: *, \, /
# StaticArrayInterface methods: lu_instance

include("namedtuple_interface.jl")
# Base methods: hash, ==, keys, haskey, propertynames, getproperty, setproperty!

include("similar_convert_copy.jl")
# Base methods: similar, zero, copy, copyto!, deepcopy, convert (to Array and NamedTuple), promote

include("broadcasting.jl")
# Base methods: BroadcastStyle, convert(to Broadcasted{Nothing}), similar, map, dataids
# Broadcast methods: BroadcastStyle, broadcasted, broadcast_unalias

include("show.jl")

include("plot_utils.jl")
export labels, label2index

include("compat/chainrulescore.jl")


required(filename) = include(joinpath("compat", filename))

function __init__()
    @require ConstructionBase="187b0558-2788-49d3-abe0-74a17ed4e7c9" required("constructionbase.jl")
    @require SciMLBase="0bca4576-84f4-4d90-8ffe-ffa030f20462" required("scimlbase.jl")
    @require RecursiveArrayTools="731186ca-8d62-57ce-b412-fbd966d074cd" required("recursivearraytools.jl")
    @require StaticArrays="90137ffa-7385-5640-81b9-e52037218182" required("staticarrays.jl")
    @require ReverseDiff="37e2e3b7-166d-5795-8a7a-e32c996b4267" required("reversediff.jl")
    @require GPUArrays="0c68f7d7-f131-5f86-a1c3-88cf8149b2d7" required("gpuarrays.jl")
end

end