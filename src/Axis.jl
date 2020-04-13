
# Axis
struct Axis{L,IdxMap} end

const NullAxis = Axis{0, NamedTuple()}
const FlatAxis{L} = Axis{L, NamedTuple()}

const VarAxes = Tuple{Vararg{<:Axis}}

Axis{L,IdxMap}(x) where {L,IdxMap} = Axis{IdxMap}()
Axis(x::Type{Axis{L,IdxMap}}) where {L,IdxMap} = Axis{L,IdxMap}()
Axis(L, IdxMap) = Axis{length(L),IdxMap}()
Axis(::Number, IdxMap) = NullAxis()
Axis(::Colon, IdxMap) = Axis{lastof(IdxMap),IdxMap}()
Axis(tup) = Axis(tup...)

_axes(::Type{<:Axes}) where {Axes<:VarAxes} = map(x->x(), (Axes.types...,))

idxmap(::Axis{L,IdxMap}) where {L,IdxMap} = IdxMap
idxmap(::Type{Axis{L,IdxMap}}) where {L,IdxMap} = IdxMap

totuple(x) = (x, NamedTuple())
totuple(x::Tuple) = x

Base.length(::Axis{L,IdxMap}) where {L,IdxMap} = L
Base.length(::Type{Axis{L,IdxMap}}) where {L,IdxMap} = L

Base.IndexStyle(::Type{<:Axis}) = IndexLinear()

lastof(x) = x[end]
lastof(x::Union{Tuple, NamedTuple}) = lastof(x[end])

Base.firstindex(x::Axis) = 1
Base.lastindex(x::Axis{L,IdxMap}) where {L,IdxMap} = lastof(IdxMap)

Base.first(x::Axis) = 1
Base.last(x::Axis{L,IdxMap}) where {L,IdxMap} = lastof(IdxMap)

remove_nulls() = ()
remove_nulls(x) = (x,)
remove_nulls(x::NullAxis) = ()
remove_nulls(x1, x2, args...) = (x1, remove_nulls(x2, args...)...)
remove_nulls(x1::NullAxis, x2, args...) = (remove_nulls(x2, args...)...,)

# Not sure merging is actually a good idea
Base.merge(ax1::Ax1, ax2::Ax2) where {Ax1<:Axis, Ax2<:Axis} = merge(Ax1, Ax2)()
Base.merge(Ax::Type{<:Axis{L,IdxMap}}, ::Type{<:Axis{L,IdxMap}}) where {L,IdxMap} = Ax
Base.merge(::Type{<:Axis{L,IdxMap1}}, ::Type{<:Axis{L,IdxMap2}}) where {L,IdxMap1,IdxMap2} =
    Axis{L, merge(IdxMap1, IdxMap2)}
Base.merge(::Type{<:Axis{<:L1}}, ::Type{<:Axis{<:L2}}) where {L1,L2} =
    error("Incompatible axis lengths $L1 and $L2")


## Conversion and promotion
Base.convert(::Type{<:Ax1}, ax::Ax2) where {Ax1<:Axis,Ax2<:Axis} = promote_type(Ax1,Ax2)()

Base.promote_rule(Ax1::Type{<:Axis}, Ax2::Type{<:Axis}) = promote_type(Ax1, Ax2)

Base.promote_type(Ax1::Type{<:VarAxes}, Ax2::Type{<:VarAxes}) = typeof(promote.(_axes(Ax1), _axes(Ax2))[1])
function Base.promote_type(Ax1::Type{<:Axis{L1,I1}}, Ax2::Type{<:Axis{L2,I2}}) where {L1,L2,I1,I2}
    if L1==L2
        return merge(Ax1,Ax2)
    else
        return error("Axes must be same length for promotion, these have lengths $L1 and $L2")
    end
end
Base.promote_type(::Type{<:NullAxis}, Ax::Type{Axis{L1,I1}}) where {L1,I1} = Ax
Base.promote_type(Ax::Type{Axis{L1,I1}}, ::Type{<:NullAxis}) where {L1,I1} = Ax
Base.promote_type(::Type{<:NullAxis}, ::Type{<:NullAxis}) = NullAxis
