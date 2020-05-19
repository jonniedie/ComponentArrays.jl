abstract type AbstractAxis{IdxMap} end

const VarAxes = Tuple{Vararg{<:AbstractAxis}}

@inline indexmap(::AbstractAxis{IdxMap}) where IdxMap = IdxMap
@inline indexmap(::Type{<:AbstractAxis{IdxMap}}) where IdxMap = IdxMap


"""
    ax = Axis(nt::NamedTuple)

Gives named component access for `ComponentArray`s.
# Examples

```jldoctest
julia> using ComponentArrays

julia> ax = Axis{(a = 1, b = View(2:7, 2, (a = 1, b = 2)), c = View(8:10, (a = 1, b = 2:3)))}();

julia> A = [100, 4, 1.3, 1, 1, 4.4, 0.4, 2, 1, 45];

julia> ca = ComponentArray(A, ax)
ComponentArray{Float64}(a = 100.0, b = [(a = 4.0, b = 1.3), (a = 1.0, b = 1.0), (a = 4.4, b = 0.4)], c = (a = 2.0, b = [1.0, 45.0]))

julia> ca.a
100.0

julia> ca.b
3-element Array{ComponentArray{Tuple{Axis{(a = 1, b = 2)}},Float64,1,SubArray{Float64,1,Array{Float64,1},Tuple{UnitRange{Int64}},true}},1}:
 (a = 4.0, b = 1.3)
 (a = 1.0, b = 1.0)
 (a = 4.4, b = 0.4)

julia> ca.c
ComponentArray{Float64}(a = 2.0, b = [1.0, 45.0])

julia> ca.c.b
2-element view(::Array{Float64,1}, 9:10) with eltype Float64:
  1.0
 45.0
```
"""
struct Axis{IdxMap} <: AbstractAxis{IdxMap} end
@inline Axis(IdxMap::NamedTuple) = Axis{IdxMap}()
Axis(;kwargs...) = Axis((;kwargs...))


# Revise.jl seems to be having an issue with calling NamedTuple() inside the type def
const unnamedtuple = NamedTuple()
const FlatAxis = Axis{unnamedtuple}

struct NullAxis <: AbstractAxis{nothing} end

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
const NotShapedOrPartitionedAxis = Union{Axis{IdxMap}, FlatAxis, NullAxis} where {IdxMap}
const NotShapedAxis = Union{Axis{IdxMap}, FlatAxis, NullAxis} where {IdxMap}

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
const NotPartitionedAxis = Union{Axis{IdxMap}, FlatAxis, NullAxis, ShapedAxis{Shape, IdxMap}} where {Shape, IdxMap}



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



Axis(ax::AbstractAxis) = ax
Axis(ax::PartitionedAxis) = ax.ax
Axis(ax::ViewAxis) = ax.ax
Axis(::Number) = NullAxis()
Axis(::NamedTuple{()}) = FlatAxis()
Axis(x) = FlatAxis()


const VarAxes = Tuple{Vararg{<:AbstractAxis}}

numaxes(::PartitionedAxis{N,IdxMap}) where {N,IdxMap} = N
numaxes(::Type{PartitionedAxis{N,IdxMap}}) where {N,IdxMap} = N

remove_nulls() = ()
remove_nulls(x) = (x,)
remove_nulls(::NullAxis) = ()
remove_nulls(x1, x2, args...) = (x1, remove_nulls(x2, args...)...)
remove_nulls(::NullAxis, x2, args...) = (remove_nulls(x2, args...)...,)

fill_flat(Ax::Type{<:VarAxes}, N) = fill_flat(getaxes(Ax), N) |> typeof
function fill_flat(Ax::VarAxes, N)
    axs = getaxes(Ax)
    n = length(axs)
    if N>n
        axs = (axs..., ntuple(x -> FlatAxis(), N-n)...)
    end
    return axs
end

Base.propertynames(::AbstractAxis{IdxMap}) where IdxMap = propertynames(IdxMap)