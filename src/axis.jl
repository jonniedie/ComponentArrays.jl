abstract type AbstractAxis{IdxMap} end

@inline indexmap(::AbstractAxis{IdxMap}) where IdxMap = IdxMap
@inline indexmap(::Type{<:AbstractAxis{IdxMap}}) where IdxMap = IdxMap


# struct FlatAxis <: AbstractAxis{NamedTuple()} end

struct NullAxis <: AbstractAxis{nothing} end
const VarAxes = Tuple{Vararg{<:AbstractAxis}}


"""
    ax = Axis(nt::NamedTuple)

Gives named component access for `ComponentArray`s.
# Examples

```
julia> using ComponentArrays

julia> ax = Axis((a = 1, b = ViewAxis(2:7, PartitionedAxis(2, (a = 1, b = 2))), c = ViewAxis(8:10, (a = 1, b = 2:3))));

julia> A = [100, 4, 1.3, 1, 1, 4.4, 0.4, 2, 1, 45];

julia> ca = ComponentArray(A, ax)
ComponentVector{Float64}(a = 100.0, b = [(a = 4.0, b = 1.3), (a = 1.0, b = 1.0), (a = 4.4, b = 0.4)], c = (a = 2.0, b = [1.0, 45.0]))

julia> ca.a
100.0

julia> ca.b
3-element LazyArray{ComponentVector{Float64,SubArray...}}:
 ComponentVector{Float64,SubArray...}(a = 4.0, b = 1.3)
 ComponentVector{Float64,SubArray...}(a = 1.0, b = 1.0)
 ComponentVector{Float64,SubArray...}(a = 4.4, b = 0.4)

julia> ca.c
ComponentVector{Float64,SubArray...}(a = 2.0, b = [1.0, 45.0])

julia> ca.c.b
2-element view(::Vector{Float64}, 9:10) with eltype Float64:
  1.0
 45.0
```
"""
struct Axis{IdxMap} <: AbstractAxis{IdxMap} end
@inline Axis(IdxMap::NamedTuple) = Axis{IdxMap}()
Axis(;kwargs...) = Axis((;kwargs...))
function Axis(symbols::Union{AbstractVector{Symbol}, NTuple{N,Symbol}}) where {N}
    return Axis((;(symbols .=> eachindex(symbols))...))
end
Axis(symbols::Symbol...) = Axis(symbols)

const FlatAxis = Axis{NamedTuple()}
const NullorFlatAxis = Union{NullAxis, FlatAxis}



"""
    sa = ShapedAxis(shape, index_map)

Preserves higher-dimensional array components in `ComponentArray`s (matrix components, for
example)
"""
struct ShapedAxis{Shape, IdxMap} <: AbstractAxis{IdxMap} end
@inline ShapedAxis(Shape, IdxMap) = ShapedAxis{Shape, IdxMap}()
ShapedAxis(Shape) = ShapedAxis(Shape, NamedTuple())
ShapedAxis(::Tuple{<:Int}) = FlatAxis()

const Shape = ShapedAxis

unshape(ax) = ax
unshape(ax::ShapedAxis) = Axis(indexmap(ax))

Base.size(::ShapedAxis{Shape, IdxMap}) where {Shape, IdxMap} = Shape



"""
    pa = PartitionedAxis(partition_size, index_map)

Axis for creating arrays of `ComponentArray`s
"""
struct PartitionedAxis{PartSz, IdxMap, Ax<:AbstractAxis{IdxMap}} <: AbstractAxis{IdxMap}
    ax::Ax
    
    function PartitionedAxis(PartSz, ax::AbstractAxis{IdxMap}) where IdxMap
        return new{PartSz,IdxMap,typeof(ax)}(ax)
    end
end
PartitionedAxis{PartSz,IdxMap,Ax}() where {PartSz,IdxMap,Ax} = PartitionedAxis(PartSz, Ax())
PartitionedAxis(PartSz, IdxMap) = PartitionedAxis(PartSz, Axis(IdxMap))

const Partition = PartitionedAxis

Base.size(::PartitionedAxis{PartSz,IdxMap}) where {PartSz,IdxMap} = PartSz
Base.size(::Type{PartitionedAxis{PartSz,IdxMap}}) where {PartSz,IdxMap} = PartSz



"""
    va = ViewAxis(parent_index, index_map)

Axis for creating arrays of `ComponentArray`s
"""
struct ViewAxis{Inds, IdxMap, Ax<:AbstractAxis{IdxMap}} <: AbstractAxis{IdxMap}
    ax::Ax
    function ViewAxis(Inds, ax::AbstractAxis{IdxMap}) where IdxMap
        return new{Inds,IdxMap,typeof(ax)}(ax)
    end
    ViewAxis(Inds, ::NullorFlatAxis) = Inds
end
# ViewAxis{Inds,IdxMap,Ax}() where {Inds,IdxMap,Ax} = PartitionedAxis(Inds, Ax())
ViewAxis{Inds,IdxMap,Ax}() where {Inds,IdxMap,Ax} = ViewAxis(Inds, Ax())
ViewAxis(Inds, IdxMap) = ViewAxis(Inds, Axis(IdxMap))
ViewAxis(Inds) = Inds

const View = ViewAxis
const NullOrFlatView{Inds,IdxMap} = ViewAxis{Inds,IdxMap,<:NullorFlatAxis}

viewindex(::ViewAxis{Inds,IdxMap}) where {Inds,IdxMap} = Inds
viewindex(::Type{<:ViewAxis{Inds,IdxMap}}) where {Inds,IdxMap} = Inds
viewindex(i) = i


Axis(ax::AbstractAxis) = ax
Axis(ax::PartitionedAxis) = ax.ax
Axis(ax::ViewAxis) = ax.ax

# Get rid of this
Axis(::Number) = NullAxis()
Axis(::NamedTuple{()}) = FlatAxis()
Axis(x) = FlatAxis()

const NotShapedAxis = Union{Axis{IdxMap}, FlatAxis, NullAxis} where {IdxMap}
const NotPartitionedAxis = Union{Axis{IdxMap}, FlatAxis, NullAxis, ShapedAxis{Shape, IdxMap}} where {Shape, IdxMap}
const NotShapedOrPartitionedAxis = Union{Axis{IdxMap}, FlatAxis, NullAxis} where {IdxMap}


Base.merge(axs::Axis...) = Axis(merge(indexmap.(axs)...))

Base.lastindex(ax::AbstractAxis) = last(viewindex(last(indexmap(ax))))

Base.keys(ax::AbstractAxis) = keys(indexmap(ax))

reindex(i, offset) = i .+ offset
reindex(ax::FlatAxis, _) = ax
reindex(ax::Axis, offset) = Axis(map(x->reindex(x, offset), indexmap(ax)))
reindex(ax::ViewAxis, offset) = ViewAxis(viewindex(ax) .+ offset, indexmap(ax))

# Get AbstractAxis index
@inline Base.getindex(::AbstractAxis, idx::FlatIdx) = ComponentIndex(idx)
@inline Base.getindex(ax::AbstractAxis, ::Colon) = ComponentIndex(:, ax)
@inline Base.getindex(::AbstractAxis{IdxMap}, s::Symbol) where IdxMap =
    ComponentIndex(getproperty(IdxMap, s))
