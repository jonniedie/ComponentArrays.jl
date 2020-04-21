"""
    ax = Axis(nt::NamedTuple)

Axes for named component access of CArrays. These are a little confusing and poorly
    thought-out, so maybe don't use them directly.

# Examples

```julia-repl
julia> ax = Axis(a=1, b=2:3, c=(4:10, (a=(1:3, (a=1, b=2:3)), b=4:7)));

julia> A = [100, 4, 1.3, 1, 1, 4.4, 0.4, 2, 1, 45];

julia> cvec = CArray(A, ax); cmat = CArray(a .* a', ax, ax);

julia> cmat[:c,:c] * ca.c

```
"""
struct Axis{IdxMap} end

struct NAxis{N, IdxMap} end
NAxis(N::Integer, nt::NamedTuple) = NAxis{N,nt}()
NAxis(N::Integer, ax::Axis{IdxMap}) where IdxMap = N > 0 ? NAxis{N,IdxMap}() : error("N must be greater than 0, this one is $N")

const NullAxis = Axis{Nothing}
const FlatAxis = Axis{NamedTuple()}
const NullorFlatAxis = Union{NullAxis, FlatAxis}
const AxisorNAxis = Union{Axis, NAxis}

const VarAxes = Tuple{Vararg{<:Axis}}

Axis{IdxMap}(x) where {IdxMap} = Axis{IdxMap}()
Axis(x::Type{Axis{IdxMap}}) where {IdxMap} = Axis{IdxMap}()
Axis(L, IdxMap) = Axis{IdxMap}()
Axis(::Number, IdxMap) = NullAxis()
Axis(::Colon, IdxMap) = Axis{IdxMap}()
Axis(i, IdxMap, N) = NAxis(N, Axis(i, IdxMap))
Axis(tup) = Axis(tup...)
Axis(nt::NamedTuple) = Axis{nt}()
Axis(;kwargs...) = Axis{(;kwargs...)}()

idxmap(::Axis{IdxMap}) where IdxMap = IdxMap
idxmap(::Type{Axis{IdxMap}}) where IdxMap = IdxMap

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

fill_flat(::Type{Axes}, N) where Axes<:VarAxes = fill_flat(getaxes(Axes), N) |> typeof
function fill_flat(Ax::VarAxes, N)
    axs = getaxes(Ax)
    n = length(axs)
    if N>n
        axs = (axs..., ntuple(x -> FlatAxis(), N-n)...)
    end
    return axs
end

Base.propertynames(ax::Axis{IdxMap}) where IdxMap = propertynames(IdxMap)

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

Base.promote_type(Ax1::Type{<:VarAxes}, Ax2::Type{<:VarAxes}) = typeof(promote.(getaxes(Ax1), getaxes(Ax2))[1])
function Base.promote_type(Ax1::Type{<:Axis{I1}}, Ax2::Type{<:Axis{I2}}) where {I1,I2}
    return merge(Ax1, Ax2)
end
Base.promote_type(::Type{<:NullAxis}, Ax::Type{Axis{I1}}) where {I1} = Ax
Base.promote_type(Ax::Type{Axis{I1}}, ::Type{<:NullAxis}) where {I1} = Ax
Base.promote_type(::Type{<:NullAxis}, ::Type{<:NullAxis}) = NullAxis
