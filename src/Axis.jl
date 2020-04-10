
# Axis
struct Axis{L,IdxMap} end
NullAxis = Axis{0, NamedTuple()}
FlatAxis{L} = Axis{L, NamedTuple()}

Axis{L,IdxMap}(x) where {L,IdxMap} = Axis{IdxMap}()
Axis(x::Type{Axis{L,IdxMap}}) where {L,IdxMap} = Axis{L,IdxMap}()
Axis(L, IdxMap) = Axis{length(L),IdxMap}()
Axis(::Number, IdxMap) = NullAxis()
Axis(::Colon, IdxMap) = Axis{lastof(IdxMap),IdxMap}()
Axis(tup) = Axis(tup...)

idxmap(::Axis{L,IdxMap}) where {L,IdxMap} = IdxMap
idxmap(::Type{Axis{L,IdxMap}}) where {L,IdxMap} = IdxMap

totuple(x) = (x, NamedTuple())
totuple(x::Tuple) = x

lastof(x) = x[end]
lastof(x::Union{Tuple, NamedTuple}) = lastof(x[end])

Base.length(::Axis{L,IdxMap}) where {L,IdxMap} = L
Base.length(::Type{Axis{L,IdxMap}}) where {L,IdxMap} = L

Base.IndexStyle(::Type{<:Axis}) = IndexLinear()

# Base.UnitRange(x::Axis) where T = 1:length(x)
# Base.UnitRange{T}(x::Axis) where T = 1:length(x)
# Base.UnitRange{T}(x::Axis) where T<:Real = 1:length(x)

# Base.checkindex(tb, x1::Axis, x2) = checkindex(tb, UnitRange(x1), x2)
# Base.checkindex(tb, x1, x2::Axis) = checkindex(tb, x1, UnitRange(x2))
# Base.checkindex(tb, x1::Axis, x2::Axis) = checkindex(tb, UnitRange(x1), UnitRange(x2))

Base.firstindex(x::Axis) = 1
Base.lastindex(x::Axis{L,IdxMap}) where {L,IdxMap} = lastof(IdxMap)

Base.first(x::Axis) = 1
Base.last(x::Axis{L,IdxMap}) where {L,IdxMap} = lastof(IdxMap)

remove_nulls() = ()
remove_nulls(x) = (x,)
remove_nulls(x::NullAxis) = ()
remove_nulls(x1, x2, args...) = (x1, remove_nulls(x2, args...)...)
remove_nulls(x1::NullAxis, x2, args...) = (remove_nulls(x2, args...)...,)
