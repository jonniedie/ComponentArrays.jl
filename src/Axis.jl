
# Axis
struct Axis{IdxMap} end

const NullAxis = Axis{Nothing}
const FlatAxis = Axis{NamedTuple()}
const NullorFlatAxis = Union{NullAxis, FlatAxis}

const VarAxes = Tuple{Vararg{<:Axis}}

Axis{IdxMap}(x) where {IdxMap} = Axis{IdxMap}()
Axis(x::Type{Axis{IdxMap}}) where {IdxMap} = Axis{IdxMap}()
Axis(L, IdxMap) = Axis{IdxMap}()
Axis(::Number, IdxMap) = NullAxis()
Axis(::Colon, IdxMap) = Axis{IdxMap}()
Axis(tup) = Axis(tup...)

_axes(x::VarAxes) where {Axes<:VarAxes} = _axes(typeof(x))
_axes(::Type{<:Axes}) where {Axes<:VarAxes} = map(x->x(), (Axes.types...,))

idxmap(::Axis{IdxMap}) where IdxMap = IdxMap
idxmap(::Type{Axis{IdxMap}}) where IdxMap = IdxMap

# Base.length(::Axis{L,IdxMap}) where {L,IdxMap} = L
# Base.length(::Type{Axis{L,IdxMap}}) where {L,IdxMap} = L

# Base.IndexStyle(::Type{<:Axis}) = IndexLinear()

lastof(x) = x[end]
lastof(x::Union{Tuple, NamedTuple}) = lastof(x[end])

Base.firstindex(x::Axis) = 1
Base.lastindex(x::Axis{IdxMap}) where {IdxMap} = lastof(IdxMap)

Base.first(x::Axis) = 1
Base.last(x::Axis{IdxMap}) where {IdxMap} = lastof(IdxMap)

remove_nulls() = ()
remove_nulls(x) = (x,)
remove_nulls(x::NullAxis) = ()
remove_nulls(x1, x2, args...) = (x1, remove_nulls(x2, args...)...)
remove_nulls(x1::NullAxis, x2, args...) = (remove_nulls(x2, args...)...,)

fill_flat(::Type{Axes}, N) where Axes<:VarAxes = fill_flat(_axes(Axes), N) |> typeof
function fill_flat(Ax::VarAxes, N)
    axs = _axes(Ax)
    n = length(axs)
    if N>n
        axs = (axs..., ntuple(x -> FlatAxis(), N-n)...)
    end
    return axs
end

# Not sure merging is actually a good idea
Base.merge(ax1::Ax1, ax2::Ax2) where {Ax1<:Axis, Ax2<:Axis} = merge(Ax1, Ax2)()
Base.merge(Ax::Type{<:Axis{IdxMap}}, ::Type{<:Axis{IdxMap}}) where {IdxMap} = Ax
Base.merge(::Type{<:Axis{IdxMap1}}, ::Type{<:Axis{IdxMap2}}) where {IdxMap1,IdxMap2} =
    Axis{merge(IdxMap1, IdxMap2)}
# Base.merge(::Type{<:Axis{<:L1}}, ::Type{<:Axis{<:L2}}) where {L1,L2} =
#     error("Incompatible axis lengths $L1 and $L2")


## Conversion and promotion
Base.convert(::Type{<:Ax1}, ax::Ax2) where {Ax1<:Axis,Ax2<:Axis} = promote_type(Ax1,Ax2)()

Base.promote_rule(Ax1::Type{<:Axis}, Ax2::Type{<:Axis}) = promote_type(Ax1, Ax2)

Base.promote_type(Ax1::Type{<:VarAxes}, Ax2::Type{<:VarAxes}) = typeof(promote.(_axes(Ax1), _axes(Ax2))[1])
function Base.promote_type(Ax1::Type{<:Axis{I1}}, Ax2::Type{<:Axis{I2}}) where {I1,I2}
    return merge(Ax1, Ax2)
end
Base.promote_type(::Type{<:NullAxis}, Ax::Type{Axis{I1}}) where {I1} = Ax
Base.promote_type(Ax::Type{Axis{I1}}, ::Type{<:NullAxis}) where {I1} = Ax
Base.promote_type(::Type{<:NullAxis}, ::Type{<:NullAxis}) = NullAxis
