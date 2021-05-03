module ComponentArrays

using ArrayInterface
using LinearAlgebra
using Requires

const FlatIdx = Union{Int, CartesianIndex, AbstractArray}
const FlatOrColonIdx = Union{FlatIdx, Colon}


include("utils.jl")
export fastindices

include("lazyarray.jl")

include("axis.jl")
export AbstractAxis, Axis, PartitionedAxis, ShapedAxis, ViewAxis, FlatAxis

include("componentindex.jl")

include("componentarray.jl")
export ComponentArray, ComponentVector, ComponentMatrix, getaxes, getdata, valkeys

include("set_get.jl")

include("similar_convert_copy.jl")

include("broadcasting.jl")

include("math.jl")

include("show.jl")

include("plot_utils.jl")
export labels, label2index


required(filename) = include(joinpath("if_required", filename))

function __init__()
    @require ConstructionBase="187b0558-2788-49d3-abe0-74a17ed4e7c9" required("constructionbase.jl")
    @require DiffEqBase="2b5f629d-d688-5b77-993f-72d75c75574e" begin
        @require RecursiveFactorization="f2c3362d-daeb-58d1-803e-2bc74f2840b4" required("diffeqbase.jl")
    end
    @require SciMLBase="0bca4576-84f4-4d90-8ffe-ffa030f20462" required("scimlbase.jl")
    @require RecursiveArrayTools="731186ca-8d62-57ce-b412-fbd966d074cd" required("recursivearraytools.jl")
    @require StaticArrays="90137ffa-7385-5640-81b9-e52037218182" required("staticarrays.jl")
    @require ChainRulesCore="d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4" required("chainrulescore.jl")
    @require ReverseDiff="37e2e3b7-166d-5795-8a7a-e32c996b4267" required("reversediff.jl")
end

end